-- Runs BuyEmAll's tests with no game client, and exits non-zero if anything failed.
-- Needs LuaJIT (Lua 5.1 semantics, like the client). From the repository root:
--   luajit tests/run_tests.lua
-- An optional argument tests another copy of the addon, such as an older version:
--   luajit tests/run_tests.lua path/to/copy

package.path = ((arg[0] or ""):match("^(.*)[/\\][^/\\]*$") or ".") .. "/?.lua;" .. package.path
local T = require("testkit")
local check, note, newClient, item, altItem = T.check, T.note, T.newClient, T.item, T.altItem

-- Starts a 50-item run of stack-20 items: 20, 20, 10, one every 0.5 s.
local function startRun()
    local c = newClient({ items = { item(1) } })
    c:click(1)
    c.env.BuyEmAll:DoPurchase(50)
    return c
end

print("--- #1 shift-click on 12.1.5 APIs")
do
    local c = newClient({ items = { item(1) } })
    local ok, err = pcall(function() c:click(1) end)
    check("#1 shift-click opens the frame with no removed-API call", ok and c.env.BuyEmAllFrame.shown, err)
    check("#1 fit is computed from free slots x stack (200)", c.env.BuyEmAll.fit == 200, c.env.BuyEmAll.fit)
end

print("--- #2 purchase loop")
do
    local c = startRun()
    c:tick(6)
    check("#2 uninterrupted run buys 20,20,10", c:quantities() == "20,20,10", c:quantities())
    check("#2 uninterrupted run prints no stop message", #c.printed == 0, c.printed[1])
    check("#2 finished run clears OnUpdate", c.loopFrame:GetScript("OnUpdate") == nil)

    c = startRun()
    c:tick(1)
    c.items[1] = nil
    c:event("MERCHANT_CLOSED")
    c.env.MerchantFrame:GetScript("OnHide")(c.env.MerchantFrame)
    c:tick(5)
    check("#2 MERCHANT_CLOSED stops further buys", c:quantities() == "20", c:quantities())
    check("#2 event + OnHide print one message, with 30 of 50", #c.printed == 1 and c.printed[1]:find("30 of 50", 1, true), table.concat(c.printed, " | "))

    c = startRun()
    c:tick(1)
    c.env.MerchantFrame:GetScript("OnHide")(c.env.MerchantFrame)
    c:tick(5)
    check("#2 MerchantFrame OnHide alone stops further buys", c:quantities() == "20", c:quantities())

    c = startRun()
    c:tick(1)
    c.items[1] = item(2)
    c:tick(5)
    check("#2 a different item at the index is never bought", c:quantities() == "20", c:quantities())
    check("#2 list change prints the stop message", #c.printed == 1, #c.printed)

    c = startRun()
    c:tick(1)
    c.items[1].link = "|cffa335ee|Hitem:1:9999:::::::80:::::|h[Item1]|h|r"
    c:tick(5)
    check("#2 same item ID with a different link suffix keeps buying", c:quantities() == "20,20,10", c:quantities())

    c = startRun()
    c:tick(1)
    c:event("MERCHANT_CLOSED")
    c.buys = {}
    c.env.BuyEmAll:DoPurchase(25)
    c:tick(4)
    check("#2 a new run works after a stopped one", c:quantities() == "20,5", c:quantities())

    c = startRun()
    c:tick(1)
    local saved = c.items[1].link
    c.items[1].link = nil
    c:tick(1)
    c.items[1].link = saved
    c:tick(4)
    check("#24 a link that returns after nil finishes the run", c:quantities() == "20,20,10", c:quantities())
    check("#24 a link that returns after nil prints nothing", #c.printed == 0, c.printed[1])

    c = startRun()
    c:tick(1)
    saved = c.items[1].link
    c.items[1].link = nil
    c:tick(8)
    c.items[1].link = saved
    check("#24 nil for 4 s keeps the run alive", c.loopFrame:GetScript("OnUpdate") ~= nil and #c.printed == 0, c.printed[1])
    c:tick(4)
    check("#24 nil for 4 s then back finishes the run", c:quantities() == "20,20,10", c:quantities())

    c = startRun()
    c:tick(1)
    c.items[1].link = nil
    c:tick(20)
    check("#24 a link that stays nil stops the run", c.loopFrame:GetScript("OnUpdate") == nil, "still running")
    check("#24 a link that stays nil buys nothing more", c:quantities() == "20", c:quantities())
    check("#24 a link that stays nil prints 30 of 50", #c.printed == 1 and c.printed[1]:find("30 of 50", 1, true), table.concat(c.printed, " | "))

    c = startRun()
    c:tick(1)
    c.items[1].link = nil
    c:tick(2)
    c:event("MERCHANT_CLOSED")
    check("#24 closing the vendor during the wait stops at once", c.loopFrame:GetScript("OnUpdate") == nil and #c.printed == 1, #c.printed)
    c:tick(5)
    check("#24 closing the vendor during the wait buys nothing more", c:quantities() == "20", c:quantities())

    c = startRun()
    c:tick(1)
    c.items[1].link = nil
    c:tick(20)
    c.items[1] = item(1)
    c.buys, c.printed = {}, {}
    c.env.BuyEmAll:DoPurchase(50)
    c.items[1].link = nil
    c:tick(2)
    check("#24 a stopped run's timer doesn't cut the next run's wait short", c.loopFrame:GetScript("OnUpdate") ~= nil and #c.printed == 0, c.printed[1])
end

print("--- #3 locale fallback")
do
    for _, loc in ipairs({ "itIT", "enGB", "enUS" }) do
        local ok, c = pcall(newClient, { locale = loc })
        check("#3 " .. loc .. " loads and uses English", ok and c.env.BuyEmAll.L.MAX == "Max", not ok and c or nil)
    end
    for _, loc in ipairs({ "deDE", "esES", "esMX", "frFR", "koKR", "ptBR", "ruRU", "zhCN", "zhTW" }) do
        local ok, c = pcall(newClient, { locale = loc })
        if not ok then
            check("#3 " .. loc .. " loads", false, c)
        else
            local missing, formatted = {}, pcall(string.format, c.env.BuyEmAll.L.PURCHASE_STOPPED, 30, 50)
            for k in pairs(c.env.BuyEmAll.DefaultL) do
                if c.env.BuyEmAll.L[k] == nil then missing[#missing + 1] = k end
            end
            check("#3 " .. loc .. " resolves every key", #missing == 0 and formatted, table.concat(missing, ","))
        end
    end
    local c = newClient({ locale = "deDE" })
    check("#3 deDE keeps its own translation", c.env.BuyEmAll.L.CONFIRM:find("Bist du") ~= nil)
    check("#3 deDE falls back per key for PURCHASE_STOPPED", c.env.BuyEmAll.L.PURCHASE_STOPPED == c.env.BuyEmAll.DefaultL.PURCHASE_STOPPED)
end

print("--- #4 alternate-currency cost lines")
do
    for n, want in pairs({ [1] = { "2", nil, nil }, [2] = { "2", "4", nil }, [3] = { "2", "4", "6" } }) do
        local c = newClient({ items = { altItem(1, n) } })
        c:click(1)
        local e = c.env
        local got = { e.BuyEmAllCurrencyAmt1:GetText(), e.BuyEmAllCurrencyAmt2:GetText(), e.BuyEmAllCurrencyAmt3:GetText() }
        check(("#4 %d currencies show the right lines"):format(n),
            got[1] == want[1] and got[2] == want[2] and got[3] == want[3],
            tostring(got[1]) .. "/" .. tostring(got[2]) .. "/" .. tostring(got[3]))
    end
end

print("--- #5 bundle rounding")
do
    local b = newClient().env.BuyEmAll
    local function round(preset, maxv, n)
        b.preset, b.max = preset, maxv
        b.NumAltCurrency, b.AltCurrPrice = 1, { 2 } -- Read by the pre-fix version of the function.
        local ok, r = pcall(b.AltCurrRounding, b, n)
        return ok and r or ("error: " .. tostring(r))
    end
    check("#5 7 of bundle 5, max 100 rounds up to 10", round(5, 100, 7) == 10)
    check("#5 exact bundle is unchanged", round(5, 100, 10) == 10)
    check("#5 bundle 1 is unchanged", round(1, 8, 7) == 7)
    check("#5 bundle 0 is unchanged (no NaN)", round(0, 8, 7) == 7)
    check("#5 nil bundle is unchanged", round(nil, 8, 7) == 7)

    local c = newClient({ items = { altItem(1, 1, 5) }, freeSlots = 1, stackSize = 8 })
    c:click(1)
    local e = c.env
    check("#23 8 free, bundle 5: max is 5", e.BuyEmAll.max == 5, e.BuyEmAll.max)
    e.BuyEmAll:OnClick(e.BuyEmAllMaxButton, "LeftButton")
    check("#23 Max shows 5, at the cost of one bundle",
        e.BuyEmAllText:GetText() == "5" and e.BuyEmAllCurrencyAmt1:GetText() == "2",
        e.BuyEmAllText:GetText() .. " / " .. e.BuyEmAllCurrencyAmt1:GetText())
    e.BuyEmAll:OnClick(e.BuyEmAllOkayButton, "LeftButton")
    c:tick(2)
    check("#23 Okay buys one bundle of 5, within bag space", c:quantities() == "5", c:quantities())

    c = newClient({ items = { altItem(1, 1, 5) }, freeSlots = 1, stackSize = 3 })
    c:click(1)
    check("#23 3 free, bundle 5: the window stays closed", not c.env.BuyEmAllFrame.shown and c.env.BuyEmAll.max == 0, c.env.BuyEmAll.max)
    check("#23 3 free, bundle 5: nothing is bought", #c.buys == 0 and c.onClick == 0, c.onClick)

    c = newClient({ items = { altItem(1, 1, 5) }, freeSlots = 2, stackSize = 8 })
    c:click(1)
    check("#23 16 free, bundle 5: max is 15", c.env.BuyEmAll.max == 15, c.env.BuyEmAll.max)

    c = newClient({ items = { altItem(1, 1, 1) }, freeSlots = 1, stackSize = 8 })
    c:click(1)
    check("#23 bundle 1: max stays 8", c.env.BuyEmAll.max == 8, c.env.BuyEmAll.max)

    c = newClient({ items = { altItem(1, 1, 5) }, freeSlots = 1, stackSize = 8 })
    c.items[1].numAvailable = 1
    c:click(1)
    check("#23 limited stock of 1 bundle: max is 5", c.env.BuyEmAll.max == 5, c.env.BuyEmAll.max)
end

print("--- #22 confirm setting")
do
    local function afterLoad(saved)
        local c = newClient()
        c.env.BEAConfirmToggle = saved
        c:event("ADDON_LOADED", "BuyEmAll")
        return c.env.BEAConfirmToggle
    end
    check("#22 saved false stays off", afterLoad(false) == false)
    check("#22 saved 0 becomes off", afterLoad(0) == false)
    check("#22 saved true stays on", afterLoad(true) == true)
    check("#22 nothing saved defaults to on", afterLoad(nil) == true)

    local c = newClient()
    c.env.BEAConfirmToggle = false
    c:event("ADDON_LOADED", "Blizzard_Other")
    check("#22 another addon's ADDON_LOADED changes nothing", c.env.BEAConfirmToggle == false)
    c:event("ADDON_LOADED", "BuyEmAll")
    c.env.BuyEmAll:SlashHandler("confirm")
    check("#22 toggling from off turns it on", c.env.BEAConfirmToggle == true)
    c.env.BuyEmAll:SlashHandler("confirm")
    check("#22 toggling again turns it off", c.env.BEAConfirmToggle == false)
    c:event("ADDON_LOADED", "BuyEmAll")
    check("#22 off survives a reload", c.env.BEAConfirmToggle == false)

    c = newClient({ items = { item(1) } })
    c.env.BEAConfirmToggle = false
    c:event("ADDON_LOADED", "BuyEmAll")
    c:click(1)
    c.env.BuyEmAll:VerifyPurchase(50)
    check("#22 off skips the dialog on a large purchase", #c.popups == 0, #c.popups)
    c = newClient({ items = { item(1) } })
    c.env.BEAConfirmToggle = true
    c:event("ADDON_LOADED", "BuyEmAll")
    c:click(1)
    c.env.BuyEmAll:VerifyPurchase(50)
    check("#22 on shows the dialog on a large purchase", #c.popups == 1, #c.popups)
end

print("--- #6 arrow keys")
do
    local c = newClient({ items = { item(1) } })
    c:click(1)
    local b = c.env.BuyEmAll
    b:OnKeyDown("LEFT")
    check("#6 LEFT at 1 stays 1", b.split == 1, b.split)
    b:OnKeyDown("DOWN")
    check("#6 DOWN at 1 stays 1", b.split == 1, b.split)
    b:OnKeyDown("RIGHT")
    check("#6 RIGHT from 1 gives 2", b.split == 2, b.split)
    b:OnKeyDown("LEFT")
    check("#6 LEFT from 2 gives 1", b.split == 1, b.split)
    b.split = b.max
    b:OnKeyDown("RIGHT")
    check("#6 RIGHT at max stays at max", b.split == b.max, b.split)
    b:OnKeyDown("UP")
    check("#6 UP at max stays at max", b.split == b.max, b.split)

    c = newClient({ items = { altItem(1, 1, 5) }, freeSlots = 1, stackSize = 20 })
    c:click(1)
    b = c.env.BuyEmAll
    check("#6 bundle mode opens at one bundle", b.split == 5, b.split)
    b:OnKeyDown("LEFT")
    check("#6 bundle mode LEFT at one bundle stays 5", b.split == 5, b.split)
    b:OnKeyDown("RIGHT")
    check("#6 bundle mode RIGHT gives 10", b.split == 10, b.split)
    b.split = b.max
    b:OnKeyDown("RIGHT")
    check("#6 bundle mode RIGHT at max stays at max", b.split == b.max, b.split)
    b.split = 7
    b:OnKeyDown("LEFT")
    check("#6 bundle mode LEFT from typed 7 gives 5", b.split == 5, b.split)
    b.split = 7
    b:OnKeyDown("RIGHT")
    check("#6 bundle mode RIGHT from typed 7 gives 12", b.split == 12, b.split)

    c = newClient({ items = { item(1) } })
    c:click(1)
    b = c.env.BuyEmAll
    b.split = b.max
    b:Right_Click()
    check("#6 on-screen right arrow shares the limit", b.split == b.max, b.split)
    b.split = 1
    b:Left_Click()
    check("#6 on-screen left arrow shares the limit", b.split == 1, b.split)
end

print("--- #8 reagent bag")
do
    -- Free slots and stack size from the in-game probe: all families 0, stack 1000, 4 free in the reagent bag.
    local probed = { [0] = 19, [1] = 35, [2] = 38, [3] = 21, [4] = 26, [5] = 4 }
    local function fit(opts)
        opts.items = { item(1) }
        opts.stackSize = opts.stackSize or 1000
        local c = newClient(opts)
        c:click(1)
        return c.env.BuyEmAll.fit, c
    end
    check("#8 reagent counts the reagent bag (143000)", fit({ bagFree = probed, isReagent = true }) == 143000, (fit({ bagFree = probed, isReagent = true })))
    check("#8 non-reagent ignores the reagent bag (139000)", fit({ bagFree = probed, isReagent = false }) == 139000, (fit({ bagFree = probed, isReagent = false })))
    local noBag = { [0] = 19, [1] = 35, [2] = 38, [3] = 21, [4] = 26 }
    check("#8 reagent with no reagent bag (139000)", fit({ bagFree = noBag, isReagent = true }) == 139000, (fit({ bagFree = noBag, isReagent = true })))
    check("#8 item info not loaded counts no reagent bag, no error", fit({ bagFree = probed, uncached = true }) == 139000, (fit({ bagFree = probed, uncached = true })))
    local partial = { bagFree = { [5] = 1 }, bagSlots = { [5] = 2 }, bagItems = { ["5:1"] = { itemID = 1, stackCount = 400 } }, isReagent = true }
    check("#8 partial stack in the reagent bag counts", fit(partial) == 1600, (fit(partial)))
    local _, c = fit({ bagFree = probed, isReagent = true })
    check("#8 family 0 bags never look up an equipped-bag slot", c.slotNames == nil, c.slotNames and table.concat(c.slotNames, ","))
end

print("--- #9 profession bag and Azerite check")
do
    local function profBag(itemFamily, slots)
        local c = newClient({ items = { item(1) }, stackSize = 20, itemFamily = itemFamily, bagFree = { [0] = 1, [1] = 10 }, bagFamily = { [1] = 8 }, equippedSlots = slots })
        local ok, err = pcall(function() c:click(1) end)
        return ok, err, c
    end
    local ok, err, c = profBag(8, { [31] = 5000 })
    check("#9 profession bag check runs without the global", ok, err)
    check("#9 matching profession bag counts (220)", ok and c.env.BuyEmAll.fit == 220, ok and c.env.BuyEmAll.fit)
    check("#9 slot name for bag 1 is Bag0Slot", c.slotNames and c.slotNames[1] == "Bag0Slot", c.slotNames and c.slotNames[1])
    ok, err, c = profBag(4, { [31] = 5000 })
    check("#9 non-matching profession bag doesn't count (20)", ok and c.env.BuyEmAll.fit == 20, ok and c.env.BuyEmAll.fit or err)

    local function noLink(button)
        local i = item(1)
        i.link = nil
        local client = newClient({ items = { i } })
        local good, e = pcall(function() client:click(1, button) end)
        return good, e, client
    end
    for _, button in ipairs({ "LeftButton", "RightButton" }) do
        local good, e, client = noLink(button)
        check("#9 no-link entry, " .. button .. ": no error", good, e)
        check("#9 no-link entry, " .. button .. ": confirm dialog shows", good and #client.popups == 1 and client.popups[1].name == "BUYEMALL_CONFIRM2", good and #client.popups)
    end

    c = newClient({ items = { item(1) }, isAzerite = true })
    c:click(1, "RightButton")
    check("#9 Azerite item, right-click: frame stays closed", not c.env.BuyEmAllFrame.shown and c.origClicks == 1, c.origClicks)
    c = newClient({ items = { item(1) }, isAzerite = true })
    c:click(1, "LeftButton")
    check("#9 Azerite item, left-click: frame opens", c.env.BuyEmAllFrame.shown)
    c = newClient({ items = { item(1) } })
    c:click(1, "RightButton")
    check("#9 normal item, right-click: frame opens", c.env.BuyEmAllFrame.shown)
end

print("--- #7 unique items")
do
    local function open(opts)
        opts.items = opts.items or { item(1, { price = 100 }) }
        local c = newClient(opts)
        local ok, err = pcall(function() c:click(1) end)
        return c, ok, err
    end
    local c = open({ tooltip = { "Item", "Unique" }, owned = 0 })
    check("#7 Unique, none owned: max 1, bought directly", c.env.BuyEmAll.max == 1 and c.onClick == 1 and not c.env.BuyEmAllFrame.shown, c.env.BuyEmAll.max)
    c = open({ tooltip = { "Unique" }, owned = 1 })
    check("#7 Unique, one owned: still clicks so the server can say why", c.env.BuyEmAll.max == 1 and c.onClick == 1, c.env.BuyEmAll.max)
    c = open({ tooltip = { "Unique (3)" }, owned = 0 })
    check("#7 Unique (3), none owned: max 3 in the window", c.env.BuyEmAll.max == 3 and c.env.BuyEmAllFrame.shown, c.env.BuyEmAll.max)
    c = open({ tooltip = { "Unique (3)" }, owned = 1 })
    check("#7 Unique (3), one owned: max 2", c.env.BuyEmAll.max == 2, c.env.BuyEmAll.max)
    c = open({ tooltip = { "Unique (3)" }, owned = 3 })
    check("#7 Unique (3), three owned: max 1", c.env.BuyEmAll.max == 1 and c.onClick == 1, c.env.BuyEmAll.max)
    c = open({ tooltip = { "Unique (3)" }, owned = 9 })
    check("#7 Unique (3), nine owned: never below 1", c.env.BuyEmAll.max == 1, c.env.BuyEmAll.max)
    c = open({ tooltip = { "Unique (12)" }, owned = 0, freeSlots = 1, stackSize = 5 })
    check("#7 Unique (12) with room for 5: bag space still limits", c.env.BuyEmAll.max == 5, c.env.BuyEmAll.max)
    c = open({ tooltip = { "Unique-Equipped" }, owned = 2 })
    check("#7 Unique-Equipped is not limited", c.env.BuyEmAll.max == 200, c.env.BuyEmAll.max)
    c = open({ tooltip = { "Unique: Gem (3)", "This is Unique (2) they say" }, owned = 0 })
    check("#7 lines merely containing the word are not limits", c.env.BuyEmAll.max == 200, c.env.BuyEmAll.max)
    c = open({ tooltip = { "Item" } })
    check("#7 ordinary item is not limited", c.env.BuyEmAll.max == 200, c.env.BuyEmAll.max)
    local ok, err
    c, ok, err = open({ noTooltip = true })
    check("#7 no tooltip data: no error, no limit", ok and c.env.BuyEmAll.max == 200, err)

    c = open({ itemUnique = "Einzigartig", itemUniqueMultiple = "Einzigartig (%d)", tooltip = { "Einzigartig" }, owned = 0 })
    check("#7 German Unique is limited", c.env.BuyEmAll.max == 1, c.env.BuyEmAll.max)
    c = open({ itemUnique = "Einzigartig", itemUniqueMultiple = "Einzigartig (%d)", tooltip = { "Einzigartig (4)" }, owned = 1 })
    check("#7 German Unique (4), one owned: max 3", c.env.BuyEmAll.max == 3, c.env.BuyEmAll.max)
    c = open({ itemUnique = "\229\148\175\228\184\128", itemUniqueMultiple = "\229\148\175\228\184\128\239\188\136%d\239\188\137", tooltip = { "\229\148\175\228\184\128\239\188\1362\239\188\137" }, owned = 0 })
    check("#7 full-width brackets in a translation still match", c.env.BuyEmAll.max == 2, c.env.BuyEmAll.max)
    c = open({ itemUnique = "Unico", itemUniqueMultiple = "Unico. %d+ [x]", tooltip = { "Unique" }, owned = 0 })
    check("#7 the English word means nothing on another client", c.env.BuyEmAll.max == 200, c.env.BuyEmAll.max)

    c = open({ tooltip = { "Unique (3)" }, owned = 0, money = 200 })
    check("#7 Unique (3) with money for 2: max 2", c.env.BuyEmAll.max == 2, c.env.BuyEmAll.max)
    c = open({ tooltip = { "Unique" }, owned = 0, money = 50 })
    check("#7 Unique with no money: nothing is bought", c.env.BuyEmAll.max == 0 and c.onClick == 0, c.env.BuyEmAll.max)

    c = open({ items = { altItem(1, 1, 1) }, tooltip = { "Unique (2)" }, owned = 0 })
    check("#7 alternate-currency Unique (2): max 2", c.env.BuyEmAll.max == 2, c.env.BuyEmAll.max)
    c = open({ items = { altItem(1, 1, 1) }, tooltip = { "Unique" }, owned = 0 })
    check("#7 alternate-currency Unique: bought directly", c.env.BuyEmAll.max == 1 and c.onClick == 1, c.env.BuyEmAll.max)

    c = newClient({ items = { item(1), item(2, { link = "|cff|Hcurrency:55:0|h[C]|h|r", price = 100, stackCount = 1 }) }, tooltip = { "Unique" } })
    c:click(1)
    c.tooltipArgs = nil
    ok, err = pcall(function() c:click(2) end)
    check("#7 currency after an item reads no tooltip", ok and c.tooltipArgs == nil, err or "called")

    c = newClient({ tooltip = { "Unique" }, owned = 0 })
    check("#7 accepts an item ID", c.env.BuyEmAll:UniqueAllowance(6948) == 1)
    check("#7 accepts an item link", c.env.BuyEmAll:UniqueAllowance(item(6948).link) == 1 and c.tooltipArgs[2] == 6948, c.tooltipArgs[2])
end

print("--- #10 tooltip and Stack right-click")
do
    local b = newClient().env.BuyEmAll
    local hide = b.lines.max[3].Hide
    b.available = -1
    check("#10 unlimited stock hides Vendor has", hide() == true)
    b.available = 1
    check("#10 stock of 1 shows Vendor has", hide() == false)
    b.available = 5
    check("#10 stock of 5 shows Vendor has", hide() == false)

    local function deStack(opts, amount)
        local c = newClient(opts)
        c:click(1)
        local e = c.env
        e.BuyEmAll.split = amount
        e.BuyEmAllText:SetText(amount)
        e.BuyEmAll:OnClick(e.BuyEmAllStackButton, "RightButton")
        return e.BuyEmAll.split
    end
    local gold = function() return { items = { item(1) }, stackSize = 20 } end
    check("#10 gold 50 steps down to 30", deStack(gold(), 50) == 30, deStack(gold(), 50))
    check("#10 gold 20 steps down to 1", deStack(gold(), 20) == 1, deStack(gold(), 20))
    check("#10 gold 5 steps down to 1", deStack(gold(), 5) == 1, deStack(gold(), 5))
    local alt = function(stack) return { items = { altItem(1, 1, 5) }, stackSize = stack, freeSlots = 10 } end
    check("#10 bundle 50, stack 20 steps down to 30", deStack(alt(20), 50) == 30, deStack(alt(20), 50))
    check("#10 bundle 20, stack 20 stops at one bundle", deStack(alt(20), 20) == 5, deStack(alt(20), 20))
    check("#10 bundle 10, stack 7 stops at one bundle", deStack(alt(7), 10) == 5, deStack(alt(7), 10))
end

-- Opens the window on the first item and returns the client, its environment and the addon.
local function open(opts)
    local c = newClient(opts)
    c:click(1)
    return c, c.env, c.env.BuyEmAll
end

local function typeAmount(b, digits)
    for digit in digits:gmatch(".") do b:OnChar(digit) end
end

-- Bags holding one free slot and a partial stack of 15 out of 20, so 25 fit and 5 of them are a partial stack.
local function partialBag()
    return { items = { item(1) }, stackSize = 20, bagFree = { [0] = 1 }, bagSlots = { [0] = 1 }, bagItems = { ["0:1"] = { itemID = 1, stackCount = 15 } } }
end

print("--- Free space")
do
    local c = open(partialBag())
    check("A partial stack in a normal bag counts", c.env.BuyEmAll.fit == 25, c.env.BuyEmAll.fit)
    check("The partial stack's room is kept apart", c.env.BuyEmAll.partialFit == 5, c.env.BuyEmAll.partialFit)

    c = open({ items = { item(1) }, stackSize = 20, bagFree = { [0] = 1 }, bagSlots = { [0] = 1 }, bagItems = { ["0:1"] = { itemID = 2, stackCount = 15 } } })
    check("A partial stack of another item doesn't count", c.env.BuyEmAll.fit == 20, c.env.BuyEmAll.fit)

    c = open({ items = { item(1) }, stackSize = 20, bagFree = { [5] = 1 }, bagSlots = { [5] = 1 }, bagItems = { ["5:1"] = { itemID = 1, stackCount = 15 } } })
    check("A partial stack in a bag that can't hold the item doesn't count", c.env.BuyEmAll.fit == 0, c.env.BuyEmAll.fit)

    local e, b
    c, e, b = open({ items = { item(1) }, stackUnknown = true })
    check("Stack size not loaded: the window stays closed", not e.BuyEmAllFrame.shown and b.max == 0, b.max)
    check("Stack size not loaded: nothing is bought", #c.buys == 0 and c.onClick == 0, c.onClick)
    c.stackUnknown = false
    c:click(1)
    check("Stack size loaded: the next click opens the window", e.BuyEmAllFrame.shown and b.fit == 200, b.fit)
end

print("--- Stack button")
do
    local function stack(e) e.BuyEmAll:OnClick(e.BuyEmAllStackButton, "LeftButton") end

    local _, e, b = open({ items = { item(1) } })
    stack(e)
    check("Stack from 1 gives one stack", b.split == 20 and e.BuyEmAllText:GetText() == "20", b.split)
    stack(e)
    check("Stack from one stack gives two", b.split == 40, b.split)
    b.typing = false
    typeAmount(b, "25")
    stack(e)
    check("Stack from a typed 25 goes to the next whole stack", b.split == 40, b.split)

    _, e, b = open({ items = { item(1) }, money = 3000 })
    stack(e)
    check("Stack is disabled when the next stack is past the most", b.split == 20 and e.BuyEmAllStackButton:IsEnabled() == false, e.BuyEmAllStackButton:IsEnabled())

    _, e, b = open(partialBag())
    stack(e)
    check("Stack fills the partial stack first", b.split == 5, b.split)
    stack(e)
    check("Stack then adds a whole stack", b.split == 25, b.split)
    check("Stack is disabled at the most that fits", e.BuyEmAllStackButton:IsEnabled() == false, e.BuyEmAllStackButton:IsEnabled())

    _, e, b = open(partialBag())
    typeAmount(b, "10")
    stack(e)
    check("#28 a typed amount past the partial stack goes up to the next boundary", b.split == 25, b.split)

    local wrong = {}
    for partial = 0, 19 do
        _, e, b = open(partialBag())
        b.partialFit = partial
        for split = 1, 100 do
            b.split = split
            b:SetStackClick()
            local filled = (b.stackClick - partial) % 20 == 0
            if b.stackClick <= split or b.stackClick - split > 20 or not filled then
                wrong[#wrong + 1] = partial .. "/" .. split .. "->" .. b.stackClick
            end
        end
    end
    check("#28 Stack always goes up, by at most a stack, to where a stack is filled", #wrong == 0, table.concat(wrong, " "):sub(1, 80))

    _, e, b = open({ items = { altItem(1, 1, 5) }, stackSize = 20, freeSlots = 10 })
    stack(e)
    check("Bundles: Stack from one bundle gives one stack", b.split == 20, b.split)
    stack(e)
    check("Bundles: Stack from one stack gives two", b.split == 40, b.split)
end

print("--- Limits")
do
    local function stocked(n) return { items = { item(1, { numAvailable = n }) } } end
    local c, e, b = open(stocked(3))
    check("Stock of 3 limits gold items to 3", b.max == 3 and e.BuyEmAllFrame.shown, b.max)
    c, e, b = open(stocked(1))
    check("Stock of 1 buys directly", b.max == 1 and c.onClick == 1 and not e.BuyEmAllFrame.shown, b.max)
    c, e, b = open(stocked(0))
    check("Stock of 0 buys nothing", b.max == 0 and c.onClick == 0 and not e.BuyEmAllFrame.shown, b.max)
    c, e, b = open(stocked(500))
    check("Stock above what fits leaves bag space as the limit", b.max == 200, b.max)

    c, e, b = open({ items = { item(1) }, money = 2500 })
    check("Money limits the most", b.max == 25, b.max)
    c, e, b = open({ items = { item(1, { price = 0 }) }, money = 0 })
    check("A free item is limited by bag space alone", b.max == 200, b.max)
    c, e, b = open({ items = { altItem(1, 0, 1) } })
    check("An alternate-currency entry with no costs is limited by bag space alone", b.max == 200 and e.BuyEmAllFrame.shown, b.max)

    c, e, b = open({ items = { item(1, { price = 100, stackCount = 5 }) }, money = 1000 })
    check("A gold bundle's price is shared across its items", b.max == 50, b.max)
    e.BuyEmAll:OnClick(e.BuyEmAllMaxButton, "LeftButton")
    check("Max on a gold bundle shows the full cost", b.split == 50 and e.BuyEmAllCurrencyAmt2:GetText() == "10" and e.BuyEmAllCurrencyAmt3:GetText() == "0", e.BuyEmAllCurrencyAmt2:GetText())

    c, e, b = open({ items = { item(1, { price = 12345 }) } })
    check("Gold cost splits into gold, silver and copper", e.BuyEmAllCurrencyAmt1:GetText() == "1" and e.BuyEmAllCurrencyAmt2:GetText() == "23" and e.BuyEmAllCurrencyAmt3:GetText() == "45", e.BuyEmAllCurrencyAmt1:GetText())
end

print("--- Typing an amount")
do
    local function typed(digits, opts)
        local _, e, b = open(opts or { items = { item(1) } })
        typeAmount(b, digits)
        return b.split, e, b
    end
    local split, e = typed("5")
    check("Typing replaces the starting amount", split == 5 and e.BuyEmAllText:GetText() == "5", split)
    check("Typing builds up digits", typed("12") == 12, (typed("12")))
    check("Typing past the most stops at the most", typed("999") == 200, (typed("999")))
    check("Typing 0 first gives 1", typed("0") == 1, (typed("0")))
    check("Letters are ignored", typed("a") == 1, (typed("a")))
    check("Letters between digits are ignored", typed("1a2") == 12, (typed("1a2")))

    local b
    split, e, b = typed("123")
    b:OnKeyDown("BACKSPACE")
    check("Backspace removes a digit", b.split == 12 and e.BuyEmAllText:GetText() == "12", b.split)
    b:OnKeyDown("BACKSPACE")
    check("Backspace to one digit stops at 1", b.split == 1 and b.typing == false, b.split)
    b:OnKeyDown("BACKSPACE")
    check("Backspace at 1 stays 1", b.split == 1, b.split)
    split, e, b = typed("")
    e.BuyEmAll:OnClick(e.BuyEmAllMaxButton, "LeftButton")
    b:OnKeyDown("DELETE")
    check("Delete before typing changes nothing", b.split == 200, b.split)

    local c
    c, e = open({ items = { altItem(1, 1, 5) }, stackSize = 20, freeSlots = 10 })
    typeAmount(e.BuyEmAll, "7")
    check("Bundles: a typed 7 costs two bundles", e.BuyEmAllCurrencyAmt1:GetText() == "4", e.BuyEmAllCurrencyAmt1:GetText())
    e.BuyEmAll:OnClick(e.BuyEmAllOkayButton, "LeftButton")
    c:tick(2)
    check("Bundles: a typed 7 buys two bundles", c:quantities() == "10", c:quantities())

    c, e = open({ items = { altItem(1, 1, 5) }, stackSize = 20, freeSlots = 10 })
    typeAmount(e.BuyEmAll, "7")
    e.BuyEmAll:OnKeyDown("BACKSPACE")
    e.BuyEmAll:OnClick(e.BuyEmAllOkayButton, "LeftButton")
    c:tick(2)
    check("Bundles: backspacing to 1 still buys one bundle", c:quantities() == "5", c:quantities())
end

print("--- Purchase paths")
do
    local function pricedIn(costs, preset)
        return item(1, { price = 0, stackCount = preset or 1, hasExtendedCost = true, costs = costs })
    end
    local itemCost = { tex = "t", price = 2, link = item(555).link }

    local c, e, b = open({ items = { pricedIn({ itemCost }) }, itemCount = 10 })
    check("Priced in an item: owned items limit the most", b.max == 5 and e.BuyEmAllFrame.shown, b.max)
    c, e, b = open({ items = { pricedIn({ altItem(1, 1).costs[1], itemCost }) }, itemCount = 10 })
    check("Priced in a currency and an item: the scarcer one limits the most", b.max == 5, b.max)
    c, e, b = open({ items = { pricedIn({ itemCost }, 3) }, itemCount = 10 })
    check("Priced in an item, bundle of 3: counted in items", b.max == 15, b.max)
    c, e, b = open({ items = { pricedIn({ itemCost }) }, itemCount = 1 })
    check("Priced in an item, too few owned: nothing is bought", b.max == 0 and c.onClick == 0, b.max)

    local currencyLink = "|cff|Hcurrency:55:0|h[C]|h|r"
    local function currencyForCurrency()
        local i = altItem(1, 1)
        i.link = currencyLink
        return i
    end
    c, e, b = open({ items = { currencyForCurrency() } })
    check("Currency for a currency, no cap: the cost limits the most", b.max == 50000 and e.BuyEmAllFrame.shown, b.max)
    b:DoPurchase(300)
    check("Currency for a currency: bought all at once", c:quantities() == "300" and c.loopFrame:GetScript("OnUpdate") == nil, c:quantities())

    c, e, b = open({ items = { item(1, { link = currencyLink }) }, money = 1000 })
    check("Currency for gold, no cap: money limits the most", b.max == 10, b.max)
    c, e, b = open({ items = { item(1, { link = currencyLink }) }, currency = { quantity = 95, maxQuantity = 100 } })
    check("Currency for gold: limited to the room under the cap", b.max == 5, b.max)
    b:DoPurchase(5)
    check("Currency for gold: bought all at once", c:quantities() == "5", c:quantities())

    c = startRun()
    c.buys = {}
    c.env.BuyEmAll:DoPurchase(40)
    c:tick(4)
    check("An exact number of stacks leaves nothing over", c:quantities() == "20,20", c:quantities())
end

print("--- #11 globals")
do
    local c = newClient({ locale = "deDE" })
    check("#11 no BUYEMALL_MAX global", rawget(c.env, "BUYEMALL_MAX") == nil)
    check("#11 no BUYEMALL_STACK global", rawget(c.env, "BUYEMALL_STACK") == nil)
    check("#11 no BEAFrame global", rawget(c.env, "BEAFrame") == nil)
    check("#11 Stack button is labelled from the locale", c.env.BuyEmAllStackButton.text == c.env.BuyEmAll.L.STACK, c.env.BuyEmAllStackButton.text)
    check("#11 Max button is labelled from the locale", c.env.BuyEmAllMaxButton.text == c.env.BuyEmAll.L.MAX, c.env.BuyEmAllMaxButton.text)
end

print("--- Characterisation, not pass/fail")
do
    local c = newClient({ items = { altItem(1, 1, 3) }, stackSize = 200 })
    c:click(1)
    c.env.BuyEmAll:DoPurchase(300)
    c:tick(4)
    note("DoPurchase of 300, bundle 3, stack 200 sends", c:quantities())

    local cost = altItem(1, 1).costs[1]
    local capped = altItem(1, 1)
    capped.link = "|cff|Hcurrency:55:0|h[C]|h|r"
    local _, _, b = open({ items = { capped }, currencies ={ [capped.link] = { quantity = 95, maxQuantity = 100 }, [cost.link] = { quantity = 1000, maxQuantity = 0 } } })
    note("Currency for a currency, holding 95 of a cap of 100: the most is", b.max)
end

T.finish()
