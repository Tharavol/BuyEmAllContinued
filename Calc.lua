-- Purchase math. Each function takes plain values and returns a result, with no game API calls, so it runs outside
-- the client (see tests/). BuyEmAll.lua reads the values from the game and passes them in.

local floor, ceil, min, max = math.floor, math.ceil, math.min, math.max;

local Calc = {};
BuyEmAll.Calc = Calc;

-- Room for an item in the bags that can hold it: a full stack per free slot, plus the room left in each partial
-- stack of it. bags = list of { freeSlots = n, counts = { stack counts of the item already in that bag } }.
function Calc.FreeSpace(bags, stackSize)
    local fit = 0;
    for _, bag in ipairs(bags) do
        fit = fit + bag.freeSlots * stackSize;
        for _, count in ipairs(bag.counts) do
            fit = fit + (stackSize - count);
        end
    end
    return fit;
end

-- Room under a currency's cap: the cap less the amount held. A cap of 0 or less means none.
function Calc.CurrencyFit(maxQuantity, quantity)
    return (maxQuantity <= 0) and 10000000 or (maxQuantity - quantity);
end

-- How many items gold pays for, when a bundle of preset costs price copper. Free items are limited by fit alone.
function Calc.GoldAfford(money, price, preset, fit)
    if (price == nil) or (price <= 0) then
        return fit;
    end
    return floor(money / ceil(price / preset));
end

-- How many items alternate currencies pay for, in whole bundles of preset. costs = list of { owned = n, price = n },
-- the price being per bundle. With no costs, items are limited by fit alone.
function Calc.AltAfford(costs, preset, fit)
    local afford;
    for _, cost in ipairs(costs) do
        local bundles = floor(cost.owned / cost.price) * preset;
        afford = afford and min(afford, bundles) or bundles;
    end
    return afford or fit;
end

-- The most that can be chosen for a gold-priced item. available is the vendor's stock, -1 for unlimited.
function Calc.GoldMax(fit, afford, available)
    local most = min(fit, afford);
    if (available > -1) then
        most = min(most, available);
    end
    return most;
end

-- The most that can be chosen for an item priced in alternate currencies, in whole bundles of preset. This path
-- counts vendor stock in bundles, while GoldMax counts it in items (#26).
function Calc.AltMax(fit, afford, available, preset)
    local most = min(fit, afford);
    if (available > -1) then
        most = min(most, available * preset);
    end
    -- Bag space need not be a whole number of bundles.
    if (preset > 1) then
        most = most - (most % preset);
    end
    return most;
end

-- Rounds an amount up to a whole bundle of preset. Alternate-currency items, like Blizzard's own stack split frame,
-- are bought in whole bundles only; AltMax keeps the most a whole number of them, so this can't go past it.
function Calc.RoundToBundle(amount, preset)
    preset = preset or 1;
    if (preset <= 1) or (amount % preset == 0) then
        return amount;
    end
    return amount + (preset - (amount % preset));
end

-- The amount the Stack button enters: the next amount that fills a stack, counting partialFit of room in
-- existing partial stacks first.
function Calc.StackClick(split, partialFit, stack)
    local increase = (partialFit - split) % stack;
    return split + ((increase == 0) and stack or increase);
end

-- Whether buying amount asks for confirmation first: more than a stack and more than one bundle.
function Calc.NeedsConfirmation(amount, stack, bundle)
    return (amount > stack) and (amount > bundle);
end

-- Gold cost in copper of amount items, when a bundle of preset costs price copper.
function Calc.GoldCost(amount, price, preset)
    return ceil(amount * (price / preset));
end

-- Splits copper into gold, silver and copper.
function Calc.Coins(copper)
    return floor(copper / 10000), floor((copper / 100) % 100), floor(copper % 100);
end

-- Splits a purchase into the purchase loop's buys: numBuys of perBuy, then leftover (0 for none). With a bundle
-- size, each buy is the largest whole number of bundles that fits in a stack (at least one bundle), so no buy asks
-- for part of a bundle; amount is then a whole number of bundles too.
function Calc.PurchaseRuns(amount, stack, bundle)
    if (bundle ~= nil) and (bundle > 1) then
        stack = max(stack - (stack % bundle), bundle);
    end
    if (amount <= stack) then
        return amount, 1, 0;
    end
    return stack, floor(amount / stack), amount % stack;
end
