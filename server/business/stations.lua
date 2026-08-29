----------------------------------------------------------------
-- Station registry.
--
-- `Config.Stations` is the runtime truth and is filled from the database by
-- AdminStore.LoadStations(). Everything a station owns beyond its definition
-- (stock, demand counters) lives here, keyed by station id.
--
-- The whole point of this module is the zone lookup: a pump prop has no idea
-- which station it belongs to, so the server resolves the station from a
-- coordinate. Every pump standing inside a station's radius belongs to it.
----------------------------------------------------------------
Stations = Stations or {}

-- [stationId][fuelType] = { stock, capacity, price_mode, fixed_price }
Stations.stock = Stations.stock or {}

-- [stationId][fuelType] = liters sold since the last market tick. Feeds the
-- demand factor of the price model, decayed by the market cron (phase 5).
Stations.demand = Stations.demand or {}

local DEFAULT_RADIUS = 60.0

function Stations.Get(id)
    if type(id) ~= 'string' then return nil end
    return Config.Stations[id]
end

function Stations.Radius(def)
    return tonumber(def and def.radius) or DEFAULT_RADIUS
end

-- Coordinates of a station definition as a vector3, regardless of whether the
-- definition came from the config (vector3) or from the DB (plain table).
function Stations.Coords(def)
    local c = def and def.coords
    if not c then return nil end
    return vector3((tonumber(c.x) or 0.0) + 0.0, (tonumber(c.y) or 0.0) + 0.0, (tonumber(c.z) or 0.0) + 0.0)
end

-- Resolves the station a coordinate belongs to: the NEAREST station whose zone
-- contains the point. Nearest rather than first, so overlapping zones resolve
-- deterministically instead of depending on table order.
---@return string|nil id, table|nil def
function Stations.Find(coords)
    if type(coords) ~= 'vector3' then
        if type(coords) ~= 'table' then return nil end
        local x, y, z = tonumber(coords.x), tonumber(coords.y), tonumber(coords.z)
        if not (x and y and z) then return nil end
        coords = vector3(x + 0.0, y + 0.0, z + 0.0)
    end

    local bestId, bestDef, bestDist

    for id, def in pairs(Config.Stations or {}) do
        local center = Stations.Coords(def)

        if center then
            local dist = #(coords - center)

            if dist <= Stations.Radius(def) and (not bestDist or dist < bestDist) then
                bestId, bestDef, bestDist = id, def, dist
            end
        end
    end

    return bestId, bestDef
end

-- Which fuel types does this station sell?
function Stations.FuelTypes(def)
    if type(def) == 'string' then def = Stations.Get(def) end
    if type(def) ~= 'table' then return {} end

    if type(def.fuelTypes) == 'table' and #def.fuelTypes > 0 then
        return def.fuelTypes
    end

    return { 'gas', 'diesel', 'kerosin' }
end

function Stations.SellsFuelType(def, fuelType)
    for _, t in ipairs(Stations.FuelTypes(def)) do
        if t == fuelType then return true end
    end
    return false
end

function Stations.IsOwned(def)
    if type(def) == 'string' then def = Stations.Get(def) end
    return type(def) == 'table' and type(def.owner) == 'string' and def.owner ~= ''
end

-- Default capacity for a fuel type, used when a station carries none of its own.
function Stations.DefaultCapacity(def, fuelType)
    if type(def) == 'table' and type(def.capacity) == 'table' then
        local own = tonumber(def.capacity[fuelType])
        if own then return math.floor(own) end
    end

    return math.floor(tonumber((Config.DefaultCapacity or {})[fuelType]) or 10000)
end

function Stations.PurchasePrice(def)
    if type(def) == 'string' then def = Stations.Get(def) end
    if type(def) ~= 'table' then return 0 end

    return math.floor(tonumber(def.purchasePrice) or tonumber(Config.DefaultPurchasePrice) or 250000)
end

----------------------------------------------------------------
-- Payload for the client. Only what the client actually needs to draw blips,
-- label pumps and grey out sold-out fuel types — never balances or owners.
----------------------------------------------------------------
function Stations.ClientPayload()
    local out = {}

    for id, def in pairs(Config.Stations or {}) do
        local center = Stations.Coords(def)

        if center then
            local prices, stock = {}, {}

            for _, fuelType in ipairs(Stations.FuelTypes(def)) do
                prices[fuelType] = Pricing.Get(id, fuelType)
                stock[fuelType] = math.floor(Stock.Get(id, fuelType))
            end

            out[id] = {
                id = id,
                label = def.label or id,
                coords = { x = center.x, y = center.y, z = center.z },
                radius = Stations.Radius(def),
                blip = def.blip ~= false,
                fuelTypes = Stations.FuelTypes(def),
                owned = Stations.IsOwned(def),
                purchasable = def.purchasable ~= false and not Stations.IsOwned(def),
                purchasePrice = Stations.PurchasePrice(def),
                prices = prices,
                stock = stock,
                -- Public jobs only exist at unowned stations, so the client can
                -- decide on its own whether to offer the option at the pump.
                publicDelivery = (not Stations.IsOwned(def))
                    and type(def.publicDelivery) == 'table'
                    and def.publicDelivery.enable == true,
                -- Only the worn ones: a healthy pump behaves as it always did.
                pumps = Maintenance.ClientPayload(id),
            }
        end
    end

    return out
end

----------------------------------------------------------------
-- Selling fuel changes stock and price, and the client needs to see that (a
-- sold-out pump has to grey out). Broadcasting on every single refuel would put
-- a full station payload on the wire dozens of times a minute, so changes are
-- collected and flushed at most once per interval.
----------------------------------------------------------------
local BROADCAST_INTERVAL = 5000
local dirty = false

function Stations.Broadcast()
    dirty = false
    TriggerClientEvent('msk_fuel:syncStations', -1, Stations.ClientPayload())
end

function Stations.MarkDirty()
    dirty = true
end

CreateThread(function()
    while true do
        Wait(BROADCAST_INTERVAL)
        if dirty then Stations.Broadcast() end
    end
end)
