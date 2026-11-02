-- BuyEmAll.L is set by the client's locale file, if there is one; missing keys fall back to English (enUS.lua).
BuyEmAll.L = setmetatable(BuyEmAll.L or {}, { __index = BuyEmAll.DefaultL });
local L = BuyEmAll.L;

-- Addon state. Unless noted, these are set when an item is shift-clicked.

BuyEmAll.itemIndex = nil;         -- The item's position in the vendor's list.
BuyEmAll.itemLink = nil;          -- Its link, or nil for entries that have none.
BuyEmAll.itemID = nil;            -- Its item ID. Not set for currencies.
BuyEmAll.itemName = nil;          -- Its name, for the confirmation dialogs.
BuyEmAll.price = nil;             -- Gold cost of one vendor bundle, in copper.
BuyEmAll.preset = nil;            -- How many the vendor sells at once (the bundle size).
BuyEmAll.available = nil;         -- Vendor stock, or -1 for unlimited.
BuyEmAll.stack = nil;             -- The most one purchase can buy: the stack size, or the bundle size for currencies.
BuyEmAll.fit = nil;               -- How many fit in the bags, or under a currency's cap.
BuyEmAll.partialFit = nil;        -- How many of those go into existing partial stacks.
BuyEmAll.afford = nil;            -- How many can be paid for, after any Unique limit.
BuyEmAll.max = nil;               -- The most that can be chosen.
BuyEmAll.defaultStack = nil;      -- What the price covers: the bundle size.
BuyEmAll.split = nil;             -- The amount currently chosen.
BuyEmAll.stackClick = nil;        -- The amount the Stack button will enter.
BuyEmAll.typing = nil;            -- Whether the amount is being typed.
BuyEmAll.AltCurrencyMode = nil;   -- Whether the item is priced in other currencies or items, and so bought in whole bundles.
BuyEmAll.NumAltCurrency = nil;    -- How many of those it's priced in.
BuyEmAll.AltCurrTex = nil;        -- The icon of each.
BuyEmAll.AltCurrPrice = nil;      -- The cost of one bundle in each.
BuyEmAll.AltCurrAfford = nil;     -- How many can be paid for with each.
BuyEmAll.ConfirmNoItemLink = 0;   -- The list position of the entry without a link awaiting confirmation.
BuyEmAll.OrigMerchantItemButton_OnModifiedClick = nil; -- Blizzard's click handler, set in OnLoad.
BuyEmAll.OrigMerchantFrame_OnHide = nil;               -- Blizzard's OnHide script, set in OnLoad.

function BuyEmAll:OnLoad()
    BuyEmAllStackButton:SetText(L.STACK);
    BuyEmAllMaxButton:SetText(L.MAX);

    -- Set up confirmation dialog.

    StaticPopupDialogs["BUYEMALL_CONFIRM"] = {
        preferredIndex = 3,
        text = L.CONFIRM,
        button1 = YES,
        button2 = NO,
        OnAccept = function(dialog) self:DoPurchase(dialog.data) end,
        timeout = 0,
        hideOnEscape = true,
    };
    StaticPopupDialogs["BUYEMALL_CONFIRM2"] = {
        preferredIndex = 3,
        text = L.CONFIRM,
        button1 = YES,
        button2 = NO,
        OnAccept = function(dialog) BuyMerchantItem(self.ConfirmNoItemLink) end,
        timeout = 0,
        hideOnEscape = true,
    };

    -- Clear textures and text to prevent pink textures.

    BuyEmAllCurrency1:SetTexture();
    BuyEmAllCurrency2:SetTexture();
    BuyEmAllCurrency3:SetTexture();
    BuyEmAllCurrencyAmt1:SetText();
    BuyEmAllCurrencyAmt2:SetText();
    BuyEmAllCurrencyAmt3:SetText();

    self.OrigMerchantItemButton_OnModifiedClick = MerchantItemButton_OnModifiedClick;
    MerchantItemButton_OnModifiedClick = function(frame, button)
        self:MerchantItemButton_OnModifiedClick(frame, button);
    end

    self.OrigMerchantFrame_OnHide = MerchantFrame:GetScript("OnHide");
    MerchantFrame:SetScript("OnHide", function(...)
        return self:MerchantFrame_OnHide(...);
    end)

    SLASH_BUYEMALL1 = "/buyemall";
    SlashCmdList["BUYEMALL"] = function(message)
        BuyEmAll:SlashHandler(message);
    end
end


function BuyEmAll:SlashHandler(message)
    if (message == "") then
        print("BuyEmAll: Use /buyemall confirm to enable/disable the large purchase confirm.");
    elseif (message == "confirm") then
        BEAConfirmToggle = not BEAConfirmToggle;
        print("BuyEmAll: Large purchase confirm window " .. (BEAConfirmToggle and "enabled." or "disabled."));
    end
end

-- The client's "Unique (%d)" string as a pattern that captures the number, in whatever language it's in.
local UNIQUE_MULTIPLE_PATTERN = "^" .. string.gsub(string.gsub(ITEM_UNIQUE_MULTIPLE, "[%(%)%.%%%+%-%*%?%[%]%^%$]", "%%%0"), "%%%%d", "(%%d+)") .. "$";

-- How many more of an item can be bought if a Unique line limits it, or nil if none does. Never below 1, so a click
-- at the limit still reaches the server and shows its error. This reads the tooltip because C_Item.GetItemUniquenessByID
-- can't tell: in-game it's false for Hearthstone ("Unique") and true for "Unique-Equipped" items, which aren't limited.
function BuyEmAll:UniqueAllowance(itemIDOrLink)
    local itemID = tonumber(itemIDOrLink) or tonumber(strmatch(itemIDOrLink, "|Hitem:(%d+)"));
    local tooltip = itemID and C_TooltipInfo.GetItemByID(itemID);
    if (not tooltip) then
        return nil;
    end

    for _, line in ipairs(tooltip.lines) do
        local limit = (line.leftText == ITEM_UNIQUE) and 1 or tonumber(strmatch(line.leftText or "", UNIQUE_MULTIPLE_PATTERN));
        if (limit) then
            return max(limit - C_Item.GetItemCount(itemID, true), 1);
        end
    end

    return nil;
end

-- Loads the saved setting, and stops any purchase in progress when the vendor closes.

local BEAframe = CreateFrame("FRAME");
BEAframe:Hide();
BEAframe:RegisterEvent("ADDON_LOADED");
BEAframe:RegisterEvent("MERCHANT_CLOSED");
local function eventHandler(self, event, ...)
    local arg1 = ...;
    if (event == "ADDON_LOADED") and (arg1 == "BuyEmAll") then
        BEAConfirmToggle = not (BEAConfirmToggle == false or BEAConfirmToggle == 0); -- On unless saved as off; older versions saved 0.
    elseif (event == "MERCHANT_CLOSED") then
        BuyEmAll:StopPurchaseLoop();
    end
end

BEAframe:SetScript("OnEvent", eventHandler);

-- Makes sure the BuyEmAll frame goes away, and any purchase in progress stops, when you leave a vendor.

function BuyEmAll:MerchantFrame_OnHide(...)
    BuyEmAllFrame:Hide();
    self:StopPurchaseLoop();
    return self.OrigMerchantFrame_OnHide(...);
end

function BuyEmAll:HasBagEquippedInSlot(slotID)
    local inventorySlotId = C_PaperDollInfo.GetInventorySlotInfo("Bag" .. (slotID - 1) .. "Slot");
    return GetInventoryItemID("player", inventorySlotId) ~= nil;
end

function BuyEmAll:GetFreeBagSpace(itemID)
    local canFit = 0;
    -- Global item functions were removed in 12.1.5; use the C_Item namespace.
    local itemType = C_Item.GetItemFamily(itemID) or 0;
    local stackSize = C_Item.GetItemMaxStackSizeByID(itemID);
    if (stackSize == nil) then
        return 0, 1; -- Item data not cached yet.
    end

    local isReagent = select(17, C_Item.GetItemInfo(itemID));

    for currentBag = Enum.BagIndex.Backpack, Enum.BagIndex.ReagentBag do
        local freeSpace, bagType = C_Container.GetContainerNumFreeSlots(currentBag);
        local canHold;
        if (currentBag == Enum.BagIndex.ReagentBag) then
            canHold = isReagent; -- Reports family 0 like a normal bag, but only takes crafting reagents.
        else
            canHold = bagType == 0 or (BuyEmAll:HasBagEquippedInSlot(currentBag) and (bagType == itemType or bit.band(itemType, bagType) == bagType));
        end
        if (canHold) then
            canFit = canFit + (freeSpace * stackSize);

            local totalBagSlots = C_Container.GetContainerNumSlots(currentBag);
            for currentSlot = 1, totalBagSlots do
                local itemInfo = C_Container.GetContainerItemInfo(currentBag, currentSlot);
                if (itemInfo ~= nil and itemInfo.itemID == itemID) then
                    local itemCount = itemInfo.stackCount or 0;
                    canFit = canFit + (stackSize - itemCount);
                end
            end
        end
    end

    return canFit, stackSize;
end

-- Hooks left-clicks on merchant item buttons.

function BuyEmAll:MerchantItemButton_OnModifiedClick(frame, button)
    self.itemIndex = frame:GetID();

    if (MerchantFrame.selectedTab == 1)
            and (IsShiftKeyDown())
            and not (IsControlKeyDown())
            and not ((button == "RightButton") and (GetMerchantItemLink(self.itemIndex) ~= nil) and (C_AzeriteEmpoweredItem.IsAzeriteEmpoweredItemByID(GetMerchantItemLink(self.itemIndex))))
            and not (ChatFrame1EditBox:HasFocus()) then

        -- Set up various data before showing the BuyEmAll frame.

        self.AltCurrencyMode = false;

        local info = C_MerchantFrame.GetItemInfo(self.itemIndex);
        if (not info) then
            return;
        end

        local name = info.name;
        local price = info.price;
        local quantity = info.stackCount;
        local numAvailable = info.numAvailable;
        local hasExtendedCostInfo = info.hasExtendedCost;

        self.itemName = name;
        self.price = price;
        self.preset = quantity;
        self.available = numAvailable;

        self.itemLink = GetMerchantItemLink(self.itemIndex);

        -- Entries without an item link can't be measured, so just confirm buying one bundle.

        if (self.itemLink == nil) then
            self.ConfirmNoItemLink = self.itemIndex;
            StaticPopup_Show("BUYEMALL_CONFIRM2", quantity, self.itemName);
            return;
        end

        -- Buying a currency with a currency.
        if ((strmatch(self.itemLink, "currency")) and (self.price <= 0 or self.price == nil)) then
            local totalMax = C_CurrencyInfo.GetCurrencyInfoFromLink(self.itemLink).maxQuantity;
            self.fit = (totalMax <= 0 and 10000000 or totalMax);
            self.stack = self.preset;
            self:AltCurrencyHandling(self.itemIndex, frame);
            return;
        end


        if (strmatch(self.itemLink, "item")) then -- Check if purchase is an item and setup the needed variables.
            self.itemID = tonumber(strmatch(self.itemLink, "item:(%d+):"));
            local bagMax, stack = self:GetFreeBagSpace(self.itemID);
            self.stack = stack;
            self.fit = bagMax;
            self.partialFit = self.fit % stack;
        elseif (strmatch(self.itemLink, "currency")) then -- Same for if the purchase is a currency.
            self.stack = self.preset;
            local totalMax = C_CurrencyInfo.GetCurrencyInfoFromLink(self.itemLink).maxQuantity;
            self.fit = (totalMax == 0 and 10000000 or totalMax - C_CurrencyInfo.GetCurrencyInfoFromLink(self.itemLink).quantity)
            self.partialFit = 0; -- Currencies don't have stacks, so there can't be a partial stack.
        end

        if ((hasExtendedCostInfo == true) and (self.price <= 0 or self.price == nil)) then -- Checks for alternate currency information then passes purchase to handler.
            self:AltCurrencyHandling(self.itemIndex, frame);
            return;
        end

        BuyEmAllCurrency1:SetTexture("Interface\\MONEYFRAME\\UI-GoldIcon");
        BuyEmAllCurrency2:SetTexture("Interface\\MONEYFRAME\\UI-SilverIcon"); -- Once known it's a standard transaction, use regular money textures.
        BuyEmAllCurrency3:SetTexture("Interface\\MONEYFRAME\\UI-CopperIcon");


        -- Free items have no cost to limit them. This has to come after the alternate currency check.

        if (self.price <= 0 or self.price == nil) then
            self.afford = self.fit;
        else
            self.afford = floor(GetMoney() / ceil(self.price / self.preset));
        end

        local uniqueAllowance = (self.itemID ~= nil) and self:UniqueAllowance(self.itemLink);
        if (uniqueAllowance) then
            self.afford = min(self.afford, uniqueAllowance);
        end

        self.max = min(self.fit, self.afford);
        if (numAvailable > -1) then
            self.max = min(self.max, numAvailable);
        end
        if (self.max == 0) then
            return;
        elseif (self.max == 1) then
            MerchantItemButton_OnClick(frame, "LeftButton");
            return;
        end

        self.defaultStack = quantity;
        self.split = 1;

        self:SetStackClick();

        self:Show(frame);
    else
        self.OrigMerchantItemButton_OnModifiedClick(frame, button);
    end
end

-- Works out the limits for items priced in other currencies or items, then shows the window.

function BuyEmAll:AltCurrencyHandling(itemIndex, frame)
    self.AltCurrencyMode = true;

    self.NumAltCurrency = GetMerchantItemCostInfo(itemIndex);

    self.AltCurrTex = {};
    self.AltCurrPrice = {};
    self.AltCurrAfford = {};

    if (self.NumAltCurrency <= 0) then
        self.afford = self.fit;
    else
        for i = 1, self.NumAltCurrency do
            local altCurrTex, altCurrPrice, altCurrLink = GetMerchantItemCostItem(itemIndex, i);
            self.AltCurrTex[i] = altCurrTex;
            self.AltCurrPrice[i] = altCurrPrice;

            if (strmatch(altCurrLink, "currency")) then -- Item/Currency link check
                self.AltCurrAfford[i] = floor(C_CurrencyInfo.GetCurrencyInfoFromLink(altCurrLink).quantity / self.AltCurrPrice[i]) * self.preset; -- Calculate how many can be purchased.
            else
                self.AltCurrAfford[i] = floor((C_Item.GetItemCount(tonumber(strmatch(altCurrLink, "item:(%d+):")), true)) / self.AltCurrPrice[i]) * self.preset; -- Calculate how many can be purchased.
            end
        end
    self.afford = self.AltCurrAfford[1];
    end

    if (self.NumAltCurrency > 1) then
        for i = 2, self.NumAltCurrency do
            self.afford = min(self.afford, self.AltCurrAfford[i] or 999999);
        end
    end

    local uniqueAllowance = (self.itemID ~= nil) and self:UniqueAllowance(self.itemLink);
    if (uniqueAllowance) then
        self.afford = min(self.afford, uniqueAllowance);
    end

    self.max = min(self.fit, self.afford);

    if (self.available > -1) then
        self.max = min(self.max, self.available * self.preset);
    end

    -- Only whole bundles can be bought, and bag space need not be a whole number of them.
    if (self.preset > 1) then
        self.max = self.max - (self.max % self.preset);
    end

    if (self.max == 0) then
        return;
    elseif (self.max == 1) then
        MerchantItemButton_OnClick(frame, "LeftButton");
        return;
    end

    self.defaultStack = self.preset;
    self.split = self.defaultStack;

    self.partialFit = self.fit % self.stack;
    self:SetStackClick();

    self:Show(frame);
end

-- Prepare the various UI elements of the BuyEmAll frame and show it.

function BuyEmAll:Show(frame)
    self.typing = false;
    BuyEmAllLeftButton:Disable();
    BuyEmAllRightButton:Enable();

    BuyEmAllStackButton:Enable();
    if (self.max < self.stackClick) then
        BuyEmAllStackButton:Disable();
    end

    BuyEmAllFrame:ClearAllPoints();
    BuyEmAllFrame:SetPoint("BOTTOMLEFT", frame, "TOPLEFT", 0, 0);

    BuyEmAllFrame:Show(frame);
    self:UpdateDisplay();
end


-- If the amount is more than stack and defaultStack, show a confirmation. Otherwise, do the purchase.

function BuyEmAll:VerifyPurchase(amount)
    amount = amount or self.split;

    if (self.AltCurrencyMode == true) then
        amount = self:AltCurrRounding(amount);
    end

    if (amount > 0) then
        if (amount > self.stack) and (amount > self.defaultStack) then
            if (BEAConfirmToggle == true) then
                self:DoConfirmation(amount);
            else
                self:DoPurchase(amount);
            end
        else
            self:DoPurchase(amount);
        end
    end
end

-- The outer layers of this code are from Treeston on the MMO-Champion forums, with changes. Link: https://is.gd/25JTV1

-- The purchase run in progress.

local framePurchAmount = 0;  -- Size of each full purchase.
local frameNumLoops = 0;     -- Full purchases left.
local frameLeftover = 0;     -- Size of the final smaller purchase left, or 0.
local frameItemIndex;        -- The item's position in the vendor's list.
local frameItemLinkID;       -- "item:12345" part of the link being bought, to detect the vendor list changing mid-run.
local frameTotal = 0;        -- Amount the run was started with, for the stopped-early message.

local PurchaseLoopFrame = CreateFrame("Frame");

-- Returns the "item:12345" / "currency:123" part of a link, or nil.
local function LinkID(link)
    return link and strmatch(link, "|H(%a+:%d+)") or nil;
end

-- Stops a purchase run in progress, saying how much was left unbought if it was cut short.
function BuyEmAll:StopPurchaseLoop()
    PurchaseLoopFrame:SetScript("OnUpdate", nil);
    local remaining = frameNumLoops * framePurchAmount + frameLeftover;
    frameNumLoops, frameLeftover = 0, 0;
    if (remaining > 0) then
        print(format(L.PURCHASE_STOPPED, remaining, frameTotal));
    end
end

-- Runs as PurchaseLoopFrame's OnUpdate script, so self is that frame rather than BuyEmAll.
function BuyEmAll:onUpdate(sinceLastUpdate)
    self.sinceLastUpdate = (self.sinceLastUpdate or 0) + sinceLastUpdate;
    if (self.sinceLastUpdate >= 0.5) then -- Half a second between purchases.
        if (frameNumLoops == 0) and (frameLeftover == 0) then
            PurchaseLoopFrame:SetScript("OnUpdate", nil); -- When purchasing is done, clear the script so it's not running constantly.
            return;
        end
        -- No link may only mean its data isn't loaded yet, so give it a few seconds. Closing the vendor still stops the run at once.
        local linkID = LinkID(GetMerchantItemLink(frameItemIndex));
        if (linkID == nil) and (self.sinceLastUpdate < 5) then
            return;
        end
        -- The vendor's list changed so this index is now a different item: stop rather than buy the wrong thing.
        if (linkID ~= frameItemLinkID) then
            BuyEmAll:StopPurchaseLoop();
            return;
        end
        if (frameNumLoops == 0) and (frameLeftover ~= 0) then
            BuyMerchantItem(frameItemIndex, frameLeftover);
            frameLeftover = 0;
        elseif (frameNumLoops > 0) then
            BuyMerchantItem(frameItemIndex, framePurchAmount);
            frameNumLoops = frameNumLoops - 1;
        end
        self.sinceLastUpdate = 0;
    end
end

-- End of code from Treeston.

-- Makes the actual purchase(s)
function BuyEmAll:DoPurchase(amount)
    BuyEmAllFrame:Hide();
    local numLoops, purchAmount, leftover;

    if (strmatch(self.itemLink, "currency")) then -- Currencies skip the loop and are bought all at once.
        BuyMerchantItem(self.itemIndex, amount);
        return;
    end

    if (amount <= self.stack) then
        purchAmount = amount;
        numLoops = 1;
        leftover = 0;
    else
        purchAmount = self.stack;
        numLoops = floor(amount / self.stack);
        leftover = amount % self.stack;
    end

    framePurchAmount = purchAmount;
    frameNumLoops = numLoops;
    frameLeftover = leftover;
    frameItemIndex = self.itemIndex;
    frameItemLinkID = LinkID(self.itemLink);
    frameTotal = amount;

    PurchaseLoopFrame.sinceLastUpdate = 0;
    PurchaseLoopFrame:SetScript("OnUpdate", BuyEmAll.onUpdate);
end

-- Items bought with alternate currencies come in bundles of self.preset (the vendor's stack count), and,
-- like Blizzard's own stack split frame, only whole bundles are bought. Rounds up to a whole bundle;
-- AltCurrencyHandling keeps self.max a whole number of bundles, so this can't go past it.

function BuyEmAll:AltCurrRounding(purchase)
    local preset = self.preset or 1;
    if (preset <= 1) or (purchase % preset == 0) then
        return purchase;
    end

    return purchase + (preset - (purchase % preset));
end

-- Updates the buttons and the cost for the amount currently chosen.

function BuyEmAll:UpdateDisplay()
    BuyEmAllLeftButton:Enable();
    BuyEmAllRightButton:Enable();
    BuyEmAllMaxButton:Enable();
    if (self.split == self.max) then
        BuyEmAllRightButton:Disable();
        BuyEmAllMaxButton:Disable();
    end
    if (self.AltCurrencyMode == false) and (self.split == 1) then
        BuyEmAllLeftButton:Disable();
    end
    if (self.AltCurrencyMode == true) and (self.split == self.preset) then
        BuyEmAllLeftButton:Disable();
    end

    self:SetStackClick();
    BuyEmAllStackButton:Enable();
    if (self.max < self.stackClick) then
        BuyEmAllStackButton:Disable();
    end

    local purchase = self.split;

    if (self.AltCurrencyMode == false) then
        local cost = ceil(purchase * (self.price / self.defaultStack));
        local gold = floor(cost / 10000);
        local silver = floor((cost / 100) % 100);
        local copper = floor(cost % 100);

        BuyEmAllCurrencyAmt1:SetText(gold);
        BuyEmAllCurrencyAmt2:SetText(silver);
        BuyEmAllCurrencyAmt3:SetText(copper);

    elseif (#self.AltCurrPrice >= 1) then
        local amount = self:AltCurrRounding(purchase);
        local numPurchases = amount / self.preset; -- Only whole bundles can be bought with alternate currencies.

        BuyEmAllCurrencyAmt1:SetText(numPurchases * self.AltCurrPrice[1]);
        BuyEmAllCurrency1:SetTexture(self.AltCurrTex[1]);
        BuyEmAllCurrencyAmt2:SetText(numPurchases * (self.AltCurrPrice[2] or 0));
        BuyEmAllCurrency2:SetTexture(self.AltCurrTex[2]);
        if (self.AltCurrPrice[2] == nil) then BuyEmAllCurrencyAmt2:SetText() end
        BuyEmAllCurrencyAmt3:SetText(numPurchases * (self.AltCurrPrice[3] or 0));
        BuyEmAllCurrency3:SetTexture(self.AltCurrTex[3]);
        if (self.AltCurrPrice[3] == nil) then BuyEmAllCurrencyAmt3:SetText() end
    end

    BuyEmAllText:SetText(self.split);
end


-- Shows the confirmation dialog.

function BuyEmAll:DoConfirmation(amount)
    local dialog = StaticPopup_Show("BUYEMALL_CONFIRM", amount, self.itemName);
    dialog.data = amount;
end


-- Calculates the amount that the Stack button will enter.

function BuyEmAll:SetStackClick()
    local increase = (self.partialFit - self.split) % self.stack; -- The room to the next amount that fills a stack.
    self.stackClick = self.split + (increase == 0 and self.stack or increase);
end

function BuyEmAll:DeStackClick()
    local decrease = tonumber(BuyEmAllText:GetText());
    local lowest = (self.AltCurrencyMode == true) and self.preset or 1;
    self.split = max(decrease - self.stack, lowest);
    self:UpdateDisplay();
end


-- OnClick handler for the four main buttons.

function BuyEmAll:OnClick(frame, button)
    if (frame == BuyEmAllOkayButton) then
        local amount = tonumber(BuyEmAllText:GetText());
        self:VerifyPurchase(amount);
    elseif (frame == BuyEmAllCancelButton) then
        BuyEmAllFrame:Hide();
    elseif (frame == BuyEmAllStackButton) then
        if (button == "LeftButton") then
            self.split = self.stackClick;
            self:UpdateDisplay();
            if (frame:IsEnabled() == true) then
                self:OnEnter(frame);
            else
                GameTooltip:Hide();
            end
        elseif (button == "RightButton") then
            self:DeStackClick();
            self:UpdateDisplay();
            if (frame:IsEnabled() == true) then
                self:OnEnter(frame);
            else
                GameTooltip:Hide();
            end
        end
    elseif (frame == BuyEmAllMaxButton) then
        self.split = self.max;
        self:UpdateDisplay();
    end
end


-- Allows you to type a number to buy. This is adapted directly from the Default UI's code.

function BuyEmAll:OnChar(text)
    if (text < "0") or (text > "9") then -- Ignore anything that isn't a digit.
        return;
    end

    if (self.typing == false) then -- Typing replaces the amount rather than adding to it.
        self.typing = true;
        self.split = 0;
    end


    local input = (self.split * 10) + text;

    if (input == self.split) then -- A 0 at the start changes nothing, and the amount can't be 0.
        if (self.split == 0) then
            self.split = 1;
        end
        self:UpdateDisplay();
        return;
    end
    if (input <= self.max) then
        self.split = input;
    else
        self.split = self.max;
    end
    self:UpdateDisplay();
end


-- Key handler for keys other than 0-9.

function BuyEmAll:OnKeyDown(key)
    if (key == "BACKSPACE") or (key == "DELETE") then
        if (self.typing == false) or (self.split == 1) then
            return;
        end

        self.split = floor(self.split / 10);
        if (self.split <= 1) then
            self.split = 1;
            self.typing = false;
        end

        self:UpdateDisplay();
    elseif (key == "ENTER") then
        self:VerifyPurchase();
    elseif (key == "ESCAPE") then
        BuyEmAllFrame:Hide();
    elseif (key == "LEFT") or (key == "DOWN") then
        BuyEmAll:Left_Click();
    elseif (key == "RIGHT") or (key == "UP") then
        BuyEmAll:Right_Click();
    elseif (key == "PRINTSCREEN") then
        Screenshot();
    end
end


-- Lowers the amount by one, or by one bundle in alternate-currency mode.

function BuyEmAll:Left_Click()
    if (self.AltCurrencyMode == false) then
        self.split = max(self.split - 1, 1);
        self:UpdateDisplay();
    else
        self.split = max(self.split - self.preset, self.preset);
        self:UpdateDisplay();
    end
end


-- Raises the amount by one, or by one bundle in alternate-currency mode.

function BuyEmAll:Right_Click()
    if (self.AltCurrencyMode == false) then
        self.split = min(self.split + 1, self.max);
        self:UpdateDisplay();
    else
        self.split = min(self.split + self.preset, self.max);
        self:UpdateDisplay();
    end
end


-- This table is used for the two functions that follow.

BuyEmAll.lines = {
    stack = {
        label = L.STACK_PURCH,
        field = "stackClick",
        { label = L.STACK_SIZE, field = "stack" },
        { label = L.PARTIAL, field = "partialFit" },
    },
    max = {
        label = L.MAX_PURCH,
        field = "max",
        { label = L.AFFORD, field = "afford" },
        { label = L.FIT, field = "fit" },
        {
            label = L.AVAILABLE,
            field = "available",
            Hide = function()
                return BuyEmAll.available < 0; -- -1 means unlimited stock.
            end
        },
    },
}


-- Shows tooltips when you hover over the Stack or Max buttons.

function BuyEmAll:OnEnter(frame)
    local lines = self.lines[frame == BuyEmAllMaxButton and "max" or "stack"];

    lines.amount = self[lines.field];
    for _, line in ipairs(lines) do
        line.amount = self[line.field];
    end

    self:CreateTooltip(frame, lines);
end


-- Creates the tooltip from the given lines table. See the structure of lines above for more insight.

function BuyEmAll:CreateTooltip(frame, lines)
    GameTooltip:SetOwner(frame, "ANCHOR_BOTTOMRIGHT");
    GameTooltip:SetText(lines.label .. "|cFFFFFFFF - |r" .. GREEN_FONT_COLOR_CODE .. lines.amount .. "|r");

    for _, line in ipairs(lines) do
        if (not (line.Hide and line.Hide())) then
            local color = line.amount == lines.amount and GREEN_FONT_COLOR or HIGHLIGHT_FONT_COLOR;
            GameTooltip:AddDoubleLine(line.label, line.amount, 1, 1, 1, color.r, color.g, color.b);
        end
    end

    GameTooltip:Show();
end


-- Hides the tooltip.

function BuyEmAll:OnLeave()
    GameTooltip:Hide();
end

-- When the BuyEmAll frame is closed, close any confirmations waiting for a response as well as clear the currencies.

function BuyEmAll:OnHide()
    BuyEmAllCurrency1:SetTexture();
    BuyEmAllCurrency2:SetTexture();
    BuyEmAllCurrency3:SetTexture();
    BuyEmAllCurrencyAmt1:SetText();
    BuyEmAllCurrencyAmt2:SetText();
    BuyEmAllCurrencyAmt3:SetText();
    StaticPopup_Hide("BUYEMALL_CONFIRM");
end
