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

print("--- Characterisation, not pass/fail")
do
    local c = newClient({ items = { altItem(1, 1, 3) }, stackSize = 200 })
    c:click(1)
    c.env.BuyEmAll:DoPurchase(300)
    c:tick(4)
    note("DoPurchase of 300, bundle 3, stack 200 sends", c:quantities())
end

T.finish()
