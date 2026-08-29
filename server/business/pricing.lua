----------------------------------------------------------------
-- Price model.
--
--   price = base[fuelType] * stockFactor * demandFactor,  clamped to the limits
--     stockFactor  = 1 + kStock  * (1 - stock/capacity)   -- a dry tank is expensive
--     demandFactor = 1 + kDemand * (recentDemand / demandNorm)
--
-- A station can opt out per fuel type by setting `price_mode = 'fixed'`, in
-- which case the owner's price applies. The admin limits still bind, so nobody
-- can price a station at zero or at a million.
--
-- The base price itself drifts server-wide with total demand. That cron lives
-- in phase 5; until then `base` is whatever the admin dashboard says.
----------------------------------------------------------------
Pricing = Pricing or {}

local function limits(fuelType)
    local l = (Config.PriceLimits or {})[fuelType]

    if type(l) ~= 'table' then
        return 0.01, 1000.0
    end

    return tonumber(l.min) or 0.01, tonumber(l.max) or 1000.0
end

function Pricing.Clamp(fuelType, price)
    local min, max = limits(fuelType)
    price = tonumber(price) or min

    return math.max(min, math.min(price, max))
end

function Pricing.Base(fuelType)
    return tonumber((Config.BasePrices or {})[fuelType]) or 1.0
end

-- Rounded to cents. Everything downstream (client label, payment) uses this
-- exact value, so rounding has to happen here and only here.
local function round2(n)
    return math.floor(n * 100 + 0.5) / 100
end

---Price per liter (per kWh for electric) at a station.
---@param stationId string
---@param fuelType string
---@return number
function Pricing.Get(stationId, fuelType)
    local entry = (Stations.stock[stationId] or {})[fuelType]

    if entry and entry.price_mode == 'fixed' then
        return round2(Pricing.Clamp(fuelType, entry.fixed_price))
    end

    local market = Config.Market or {}
    local price = Pricing.Base(fuelType)

    if entry then
        local capacity = math.max(1, tonumber(entry.capacity) or 1)
        local stock = math.max(0, tonumber(entry.stock) or 0)
        local fillRatio = math.min(1.0, stock / capacity)

        price = price * (1 + (tonumber(market.kStock) or 0.0) * (1 - fillRatio))
    end

    local demand = ((Stations.demand[stationId] or {})[fuelType]) or 0
    local demandNorm = math.max(1, tonumber(market.demandNorm) or 1)

    price = price * (1 + (tonumber(market.kDemand) or 0.0) * (demand / demandNorm))

    return round2(Pricing.Clamp(fuelType, price))
end

-- Fallback for pumps that belong to no station at all: the legacy per-tick
-- price from config.lua, converted to a price per liter so both paths speak the
-- same unit.
function Pricing.Fallback()
    local perTick = tonumber(Config.Refill.price) or 5
    local litersPerTick = tonumber(Config.Refill.value) or 0.5

    if litersPerTick <= 0 then return perTick end

    return round2(perTick / litersPerTick)
end

----------------------------------------------------------------
-- The global market
--
-- Every station's dynamic price is derived from a server-wide base price, and
-- that base price moves with how much the whole map is buying. Heavy demand
-- pushes it up, quiet hours pull it back toward the anchor. That is what makes
-- one busy station raise prices everywhere, which is the point of having a
-- market rather than 30 independent stations.
--
-- The anchor is whatever the base price was set to (config seed, or the admin
-- dashboard). Without it a quiet server would drift to the price floor and stay
-- there forever.
----------------------------------------------------------------
Pricing.anchor = Pricing.anchor or {}

---Takes the current base prices as the value the market drifts around. Called
---at boot (before the DB overwrites Config) and after an admin edits them.
function Pricing.SetAnchor()
    Pricing.anchor = {}

    for fuelType, price in pairs(Config.BasePrices or {}) do
        Pricing.anchor[fuelType] = tonumber(price) or 1.0
    end
end

-- Runs at load time, so the anchor is the config seed until the store replaces
-- the settings and boot.lua sets it again from the DB values.
Pricing.SetAnchor()

---Total liters sold across every station since the last tick, per fuel type.
local function totalDemand()
    local out, stations = {}, 0

    for stationId in pairs(Config.Stations or {}) do
        stations = stations + 1

        for fuelType, liters in pairs(Stations.demand[stationId] or {}) do
            out[fuelType] = (out[fuelType] or 0) + liters
        end
    end

    return out, math.max(1, stations)
end

---One market tick: move the base prices, then let the demand counters decay so
---the next tick measures fresh demand rather than the whole session.
function Pricing.MarketTick()
    local market = Config.Market or {}
    local drift = math.max(0.0, math.min(tonumber(market.drift) or 0.0, 1.0))
    local decay = math.max(0.0, math.min(tonumber(market.decay) or 0.5, 1.0))
    local pull = math.max(0.0, math.min(tonumber(market.anchorPull) or 0.5, 1.0))
    local norm = math.max(1, tonumber(market.demandNorm) or 5000)

    local demand, stations = totalDemand()
    local changed = false

    for fuelType, base in pairs(Config.BasePrices or {}) do
        local anchor = Pricing.anchor[fuelType] or base
        local sold = demand[fuelType] or 0

        -- 1.0 means "the whole map bought exactly what counts as normal".
        local pressure = sold / (norm * stations)
        local target

        if pressure > 1.0 then
            -- Above normal demand pushes the price up, capped at the drift.
            target = base * (1.0 + drift * math.min(pressure - 1.0, 1.0))
        else
            -- At or below normal, the price eases back toward the anchor
            -- instead of falling forever.
            target = base + (anchor - base) * pull
        end

        target = Pricing.Clamp(fuelType, target)

        if math.abs(target - base) > 0.001 then
            Config.BasePrices[fuelType] = target
            changed = true
        end
    end

    if changed then
        MySQL.insert(
            'INSERT INTO `msk_fuel_settings` (`skey`, `svalue`) VALUES (?, ?) ' ..
            'ON DUPLICATE KEY UPDATE `svalue` = VALUES(`svalue`)',
            { 'BasePrices', json.encode(Config.BasePrices) }
        )
    end

    for stationId, perType in pairs(Stations.demand) do
        for fuelType, liters in pairs(perType) do
            perType[fuelType] = liters * decay
        end

        -- Keep the table from growing with stations that no longer exist.
        if not Config.Stations[stationId] then Stations.demand[stationId] = nil end
    end

    -- Every station price is derived from the base price, so they all moved.
    Stations.MarkDirty()

    logging('debug', 'Market tick', json.encode(Config.BasePrices))
end

CreateThread(function()
    while not AdminStore.ready do Wait(1000) end

    -- The anchor has to come from what the database says, not from the config
    -- seed the store just replaced.
    Pricing.SetAnchor()

    while true do
        local minutes = math.max(1, tonumber((Config.Market or {}).tickMinutes) or 60)
        Wait(minutes * 60000)

        Pricing.MarketTick()
    end
end)
