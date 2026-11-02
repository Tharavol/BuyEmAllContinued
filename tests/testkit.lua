-- Test support for BuyEmAll: a check counter and a stand-in WoW client that loads the real addon files.
-- All WoW APIs are hand-written stand-ins, and undefined globals raise an error so that a
-- call to an API the stand-ins lack (like a removed global) is caught rather than ignored.

assert(setfenv and loadstring, "run with LuaJIT or Lua 5.1, the client's Lua semantics")

local ROOT = arg[1] or (((arg[0] or ""):match("^(.*)[/\\][^/\\]*$") or ".") .. "/..")
local pass, fail, notes = 0, 0, {}

local function check(name, cond, detail)
    if cond then
        pass = pass + 1
        print("PASS  " .. name)
    else
        fail = fail + 1
        print("FAIL  " .. name .. (detail and ("  -> " .. tostring(detail)) or ""))
    end
end

local function note(name, detail)
    notes[#notes + 1] = name
    print("NOTE  " .. name .. (detail and ("  -> " .. tostring(detail)) or ""))
end

local function readFile(path)
    local f = assert(io.open(path, "rb"))
    local s = f:read("*a")
    f:close()
    return s
end

local function widget()
    local w = { text = nil, enabled = true, shown = false, texture = nil, scripts = {} }
    function w:SetText(v) self.text = v end
    function w:GetText() return self.text ~= nil and tostring(self.text) or nil end
    function w:SetTexture(v) self.texture = v end
    function w:Enable() self.enabled = true end
    function w:Disable() self.enabled = false end
    function w:IsEnabled() return self.enabled end
    function w:Show() self.shown = true end
    function w:Hide()
        self.shown = false
        if self.scripts.OnHide then self.scripts.OnHide(self) end
    end
    function w:ClearAllPoints() end
    function w:SetPoint() end
    function w:SetScript(k, f) self.scripts[k] = f end
    function w:GetScript(k) return self.scripts[k] end
    function w:RegisterEvent() end
    return w
end

local ALLOWED_NIL = { BEAConfirmToggle = true, BuyEmAll = true }

-- Builds a fresh client: locale, merchant list, bag space, money, currency balances.
local function newClient(opts)
    opts = opts or {}
    local c = {
        locale = opts.locale or "enUS",
        items = opts.items or {},
        freeSlots = opts.freeSlots or 10,
        stackSize = opts.stackSize or 20,
        money = opts.money or 100000000,
        itemCount = opts.itemCount or 100000,
        currency = opts.currency or { quantity = 100000, maxQuantity = 0 },
        buys = {}, printed = {}, popups = {}, frames = {}, onClick = 0,
    }
    local env = {}
    c.env = env
    setmetatable(env, { __index = function(_, k)
        local v = rawget(_G, k)
        if v ~= nil then return v end
        if ALLOWED_NIL[k] then return nil end
        error("undefined global: " .. tostring(k), 2)
    end })
    env._G = env
    env.GetLocale = function() return c.locale end
    env.print = function(s) c.printed[#c.printed + 1] = s end
    env.strmatch, env.format = string.match, string.format
    env.floor, env.ceil, env.min, env.max = math.floor, math.ceil, math.min, math.max
    env.bit = require("bit")
    env.YES, env.NO = "Yes", "No"
    env.GREEN_FONT_COLOR_CODE = ""
    env.GREEN_FONT_COLOR = { r = 0, g = 1, b = 0 }
    env.HIGHLIGHT_FONT_COLOR = { r = 1, g = 1, b = 1 }
    env.StaticPopupDialogs = {}
    env.SlashCmdList = {}
    env.StaticPopup_Show = function(name, a, b)
        local d = { name = name, a = a, b = b }
        c.popups[#c.popups + 1] = d
        return d
    end
    env.StaticPopup_Hide = function() end
    env.CreateFrame = function(_, name)
        local f = widget()
        c.frames[#c.frames + 1] = f
        if name then env[name] = f end
        return f
    end
    for _, n in ipairs({ "Currency1", "Currency2", "Currency3", "CurrencyAmt1", "CurrencyAmt2", "CurrencyAmt3",
        "LeftButton", "RightButton", "MaxButton", "StackButton", "OkayButton", "CancelButton", "Text", "Frame" }) do
        env["BuyEmAll" .. n] = widget()
    end
    env.GameTooltip = setmetatable({}, { __index = function() return function() end end })
    env.MerchantFrame = widget()
    env.MerchantFrame.selectedTab = 1
    env.MerchantFrame:SetScript("OnHide", function() end)
    env.ChatFrame1EditBox = { HasFocus = function() return false end }
    env.MerchantItemButton_OnModifiedClick = function() end
    env.MerchantItemButton_OnClick = function() c.onClick = c.onClick + 1 end
    env.IsShiftKeyDown = function() return true end
    env.IsControlKeyDown = function() return false end
    env.GetMoney = function() return c.money end
    env.GetMerchantItemLink = function(i) return c.items[i] and c.items[i].link end
    env.BuyMerchantItem = function(i, q) c.buys[#c.buys + 1] = { i, q, c.items[i] and c.items[i].link } end
    env.GetMerchantItemCostInfo = function(i) return #(c.items[i].costs or {}) end
    env.GetMerchantItemCostItem = function(i, n)
        local k = c.items[i].costs[n]
        return k.tex, k.price, k.link
    end
    env.C_MerchantFrame = { GetItemInfo = function(i) return c.items[i] end }
    env.C_AzeriteEmpoweredItem = { IsAzeriteEmpoweredItemByID = function() return false end }
    env.C_Item = {
        GetItemFamily = function() return 0 end,
        GetItemMaxStackSizeByID = function()
            if c.stackUnknown then return nil end
            return c.stackSize
        end,
        GetItemCount = function() return c.itemCount end,
    }
    c.stackUnknown = opts.stackUnknown
    c.bagFree, c.bagSlots, c.bagItems, c.isReagent, c.uncached = opts.bagFree, opts.bagSlots or {}, opts.bagItems or {}, opts.isReagent or false, opts.uncached
    env.Enum = { BagIndex = { Backpack = 0, Bag_1 = 1, Bag_2 = 2, Bag_3 = 3, Bag_4 = 4, ReagentBag = 5 } }
    env.C_Item.GetItemInfo = function()
        if c.uncached then return end
        return "n", "l", 1, 1, 1, "t", "s", c.stackSize, "", 1, 1, 1, 1, 0, 0, nil, c.isReagent, ""
    end
    env.C_Container = {
        GetContainerNumFreeSlots = function(bag)
            local family = opts.bagFamily and opts.bagFamily[bag] or 0
            if c.bagFree then return c.bagFree[bag] or 0, family end
            return bag == 0 and c.freeSlots or 0, family
        end,
        GetContainerNumSlots = function(bag) return c.bagSlots[bag] or 0 end,
        GetContainerItemInfo = function(bag, slot) return c.bagItems[bag .. ":" .. slot] end,
    }
    -- The global GetInventorySlotInfo is deliberately absent: it exists only through a deprecation shim.
    env.C_PaperDollInfo = { GetInventorySlotInfo = function(name)
        c.slotNames = c.slotNames or {}
        c.slotNames[#c.slotNames + 1] = name
        local n = name:match("^Bag(%d)Slot$")
        return n and (31 + tonumber(n)) or nil
    end }
    env.GetInventoryItemID = function(_, slot) return opts.equippedSlots and opts.equippedSlots[slot] or nil end
    if opts.itemFamily then env.C_Item.GetItemFamily = function() return opts.itemFamily end end
    env.C_AzeriteEmpoweredItem = { IsAzeriteEmpoweredItemByID = function(link)
        c.azeriteCalls = (c.azeriteCalls or 0) + 1
        if link == nil then error("bad argument to IsAzeriteEmpoweredItemByID: nil") end
        return opts.isAzerite or false
    end }
    env.MerchantItemButton_OnModifiedClick = function() c.origClicks = (c.origClicks or 0) + 1 end
    env.ITEM_UNIQUE = opts.itemUnique or "Unique"
    env.ITEM_UNIQUE_MULTIPLE = opts.itemUniqueMultiple or "Unique (%d)"
    env.C_TooltipInfo = { GetItemByID = function(id)
        c.tooltipArgs = c.tooltipArgs or {}
        c.tooltipArgs[#c.tooltipArgs + 1] = id
        if opts.noTooltip then return nil end
        local lines = {}
        for i, text in ipairs(opts.tooltip or {}) do lines[i] = { leftText = text } end
        lines[#lines + 1] = {} -- A line with no left text, as tooltips can have.
        return { lines = lines }
    end }
    if opts.owned then env.C_Item.GetItemCount = function() return opts.owned end end
    env.C_CurrencyInfo = { GetCurrencyInfoFromLink = function(link) return opts.currencies and opts.currencies[link] or c.currency end }

    local function load(rel)
        local chunk = assert(loadstring(readFile(ROOT .. "/" .. rel), "@" .. rel))
        setfenv(chunk, env)
        chunk()
    end
    -- Follows the real load order: TOC, then the files localisation/index.xml names.
    load("init.lua")
    for file in readFile(ROOT .. "/localisation/index.xml"):gmatch('file="([^"]+)"') do
        load("localisation/" .. file:gsub("\\", "/"))
    end
    load("BuyEmAll.lua")
    env.BuyEmAll:OnLoad()
    env.BuyEmAllFrame:SetScript("OnHide", function() env.BuyEmAll:OnHide() end)
    c.eventFrame = c.frames[1]
    c.loopFrame = c.frames[2]

    function c:click(index, button)
        env.MerchantItemButton_OnModifiedClick({ GetID = function() return index or 1 end }, button or "LeftButton")
    end
    function c:tick(n)
        for _ = 1, n or 1 do
            local f = self.loopFrame:GetScript("OnUpdate")
            if f then f(self.loopFrame, 0.5) end
        end
    end
    function c:event(name, ...) self.eventFrame:GetScript("OnEvent")(self.eventFrame, name, ...) end
    function c:quantities()
        local t = {}
        for _, b in ipairs(self.buys) do t[#t + 1] = b[2] end
        return table.concat(t, ",")
    end
    return c
end

local function item(id, extra)
    local t = {
        link = "|cffffffff|Hitem:" .. id .. "::::::::80:::::|h[Item" .. id .. "]|h|r",
        name = "Item" .. id, texture = 1, price = 100, stackCount = 1, numAvailable = -1, hasExtendedCost = false,
    }
    for k, v in pairs(extra or {}) do t[k] = v end
    return t
end

local function costs(n)
    local t = {}
    for i = 1, n do
        t[i] = { tex = "tex" .. i, price = i * 2, link = "|cff|Hcurrency:" .. (100 + i) .. ":0|h[C]|h|r" }
    end
    return t
end

local function altItem(id, n, preset)
    return item(id, { price = 0, stackCount = preset or 1, hasExtendedCost = true, costs = costs(n) })
end

-- Prints the totals and exits non-zero if anything failed.
local function finish()
    print(("\n%d passed, %d failed, %d notes"):format(pass, fail, #notes))
    os.exit(fail == 0 and 0 or 1)
end

return { check = check, note = note, newClient = newClient, item = item, altItem = altItem, finish = finish }
