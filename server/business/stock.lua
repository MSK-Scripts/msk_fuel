----------------------------------------------------------------
-- Station stock.
--
-- RAM is the working copy, the DB is written through on every change. A refuel
-- is not frequent enough to need batching, and a crashed server that loses the
-- last few liters of a tank is a much smaller problem than a station whose
-- stock silently resets on restart.
--
-- An empty tank blocks that fuel type at that station: the client greys the
-- option out, and the server refuses the sale even if the client lies.
----------------------------------------------------------------
Stock = Stock or {}

local function entry(stationId, fuelType)
    local perStation = Stations.stock[stationId]
    if not perStation then return nil end

    return perStation[fuelType]
end

function Stock.Get(stationId, fuelType)
    local e = entry(stationId, fuelType)
    if not e then return 0.0 end

    return math.max(0.0, tonumber(e.stock) or 0.0)
end

function Stock.Capacity(stationId, fuelType)
    local e = entry(stationId, fuelType)
    if not e then return 0 end

    return math.max(0, math.floor(tonumber(e.capacity) or 0))
end

function Stock.Has(stationId, fuelType, liters)
    return Stock.Get(stationId, fuelType) >= (tonumber(liters) or 0)
end

local function persist(stationId, fuelType, e)
    MySQL.update(
        'UPDATE `msk_fuel_stock` SET `stock` = ? WHERE `station_id` = ? AND `fuel_type` = ?',
        { e.stock, stationId, fuelType }
    )
end

---Takes liters out of a station's tank.
---@return number consumed  how much was actually available and taken
function Stock.Consume(stationId, fuelType, liters)
    local e = entry(stationId, fuelType)
    if not e then return 0.0 end

    liters = math.max(0.0, tonumber(liters) or 0.0)
    local available = math.max(0.0, tonumber(e.stock) or 0.0)
    local consumed = math.min(liters, available)

    if consumed <= 0 then return 0.0 end

    e.stock = available - consumed
    persist(stationId, fuelType, e)

    -- Demand feeds the price model: the more a station sells, the pricier it gets.
    Stations.demand[stationId] = Stations.demand[stationId] or {}
    Stations.demand[stationId][fuelType] = (Stations.demand[stationId][fuelType] or 0) + consumed

    return consumed
end

---Puts liters into a station's tank, never above its capacity.
---@return number added
function Stock.Add(stationId, fuelType, liters)
    local e = entry(stationId, fuelType)
    if not e then return 0.0 end

    liters = math.max(0.0, tonumber(liters) or 0.0)
    local capacity = math.max(0, tonumber(e.capacity) or 0)
    local current = math.max(0.0, tonumber(e.stock) or 0.0)
    local added = math.min(liters, math.max(0.0, capacity - current))

    if added <= 0 then return 0.0 end

    e.stock = current + added
    persist(stationId, fuelType, e)

    return added
end

---Admin override: sets stock and/or capacity directly.
function Stock.Set(stationId, fuelType, stock, capacity)
    local e = entry(stationId, fuelType)
    if not e then return false end

    if capacity ~= nil then
        e.capacity = math.max(0, math.floor(tonumber(capacity) or e.capacity))
    end

    if stock ~= nil then
        e.stock = math.max(0.0, math.min(tonumber(stock) or 0.0, e.capacity))
    else
        e.stock = math.min(e.stock, e.capacity)
    end

    MySQL.update(
        'UPDATE `msk_fuel_stock` SET `stock` = ?, `capacity` = ? WHERE `station_id` = ? AND `fuel_type` = ?',
        { e.stock, e.capacity, stationId, fuelType }
    )

    return true
end

---Sets the price mode for one fuel type at one station.
function Stock.SetPricing(stationId, fuelType, mode, fixedPrice)
    local e = entry(stationId, fuelType)
    if not e then return false end

    e.price_mode = (mode == 'fixed') and 'fixed' or 'dynamic'

    if fixedPrice ~= nil then
        e.fixed_price = Pricing.Clamp(fuelType, fixedPrice)
    end

    MySQL.update(
        'UPDATE `msk_fuel_stock` SET `price_mode` = ?, `fixed_price` = ? WHERE `station_id` = ? AND `fuel_type` = ?',
        { e.price_mode, e.fixed_price, stationId, fuelType }
    )

    return true
end

---Creates the stock rows a station is missing (a brand new station, or a fuel
---type added to an existing one). Existing rows are left untouched.
function Stock.EnsureRows(stationId, def, fill)
    Stations.stock[stationId] = Stations.stock[stationId] or {}
    local perStation = Stations.stock[stationId]

    for _, fuelType in ipairs(Stations.FuelTypes(def)) do
        if not perStation[fuelType] then
            local capacity = Stations.DefaultCapacity(def, fuelType)
            local start = fill and capacity or 0.0
            local base = Pricing.Base(fuelType)

            perStation[fuelType] = {
                stock = start + 0.0,
                capacity = capacity,
                price_mode = 'dynamic',
                fixed_price = base,
            }

            MySQL.insert.await(
                'INSERT INTO `msk_fuel_stock` (`station_id`, `fuel_type`, `stock`, `capacity`, `price_mode`, `fixed_price`) ' ..
                'VALUES (?, ?, ?, ?, ?, ?) ON DUPLICATE KEY UPDATE `capacity` = VALUES(`capacity`)',
                { stationId, fuelType, start + 0.0, capacity, 'dynamic', base }
            )
        end
    end

    -- A fuel type the station no longer sells keeps its row, so re-adding it
    -- later restores the tank instead of starting from an empty one.
    return perStation
end

---Stock and price overview of a station, used by the dashboards.
function Stock.Payload(stationId)
    local def = Stations.Get(stationId)
    if not def then return {} end

    local out = {}

    for _, fuelType in ipairs(Stations.FuelTypes(def)) do
        local e = entry(stationId, fuelType) or {}

        out[#out + 1] = {
            fuelType = fuelType,
            stock = math.floor(tonumber(e.stock) or 0),
            capacity = math.floor(tonumber(e.capacity) or 0),
            priceMode = e.price_mode or 'dynamic',
            fixedPrice = tonumber(e.fixed_price) or Pricing.Base(fuelType),
            price = Pricing.Get(stationId, fuelType),
        }
    end

    return out
end
