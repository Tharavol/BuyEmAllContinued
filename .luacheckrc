std = "lua51"
max_line_length = 120

-- The luarocks CI action installs into .luarocks/ inside the workspace, so
-- `luacheck .` would otherwise lint the toolchain along with the addon.
exclude_files = {".luarocks/**", ".luarocks", "lua_modules/**"}

-- WoW event handlers always receive (self, event, ...); ignore unused args entirely
-- since callbacks must match Blizzard's fixed signatures.
ignore = {
    "212", -- unused argument
}

globals = {
    "BuyEmAll",

    -- SavedVariables declared in the .toc
    "BEAConfirmToggle",

    "SLASH_BUYEMALL1",
    "SlashCmdList",
    "StaticPopupDialogs", -- mutated in place (new dialog keys added)

    -- Replaced with the addon's own click handler.
    "MerchantItemButton_OnModifiedClick",

    -- Button labels; BuyEmAll.xml reads them by name.
    "BUYEMALL_MAX",
    "BUYEMALL_STACK",
}

read_globals = {
    -- Lua extensions exposed by WoW
    "bit", "ceil", "floor", "format", "max", "min", "strmatch",

    -- Frames defined in BuyEmAll.xml
    "BuyEmAllCancelButton", "BuyEmAllCurrency1", "BuyEmAllCurrency2", "BuyEmAllCurrency3",
    "BuyEmAllCurrencyAmt1", "BuyEmAllCurrencyAmt2", "BuyEmAllCurrencyAmt3",
    "BuyEmAllFrame", "BuyEmAllLeftButton", "BuyEmAllMaxButton", "BuyEmAllOkayButton",
    "BuyEmAllRightButton", "BuyEmAllStackButton", "BuyEmAllText",

    -- Frame / UI globals
    "ChatFrame1EditBox", "CreateFrame", "GameTooltip", "MerchantFrame",
    "MerchantItemButton_OnClick", "StaticPopup_Hide", "StaticPopup_Show",

    -- Strings and colors
    "GREEN_FONT_COLOR", "GREEN_FONT_COLOR_CODE", "HIGHLIGHT_FONT_COLOR",
    "ITEM_UNIQUE", "ITEM_UNIQUE_MULTIPLE", "NO", "YES",

    -- Namespaces / enums
    "C_AzeriteEmpoweredItem", "C_Container", "C_CurrencyInfo", "C_Item",
    "C_MerchantFrame", "C_PaperDollInfo", "C_TooltipInfo", "Enum",

    -- Client, merchant and input API
    "BuyMerchantItem", "GetInventoryItemID", "GetLocale", "GetMerchantItemCostInfo",
    "GetMerchantItemCostItem", "GetMerchantItemLink", "GetMoney",
    "IsControlKeyDown", "IsShiftKeyDown", "Screenshot", "UnitName",
}

-- Mostly lines inherited from upstream; rewrapping them would only add churn before
-- the purchase math is extracted.
files["BuyEmAll.lua"] = {
    max_line_length = false,
}

-- The translations are single long strings.
files["localisation/**"] = {
    max_line_length = false,
}

-- The cases hold their expected values on one line, so a failure reads as one check.
files["tests/**"] = {
    max_line_length = false,
    read_globals = {"arg"},
}
