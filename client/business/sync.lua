----------------------------------------------------------------
-- Client-side station registry.
--
-- The server owns the stations; this is a read-only mirror so the client can
-- draw blips, name them, and know whether a pump has anything left to sell.
-- Nothing here is trusted by the server: it re-checks price, stock and distance
-- on every sale.
----------------------------------------------------------------
Station = Station or {}

-- [stationId] = payload from Stations.ClientPayload()
Station.list = Station.list or {}

local blips = {}

local function clearBlips()
    for _, blip in ipairs(blips) do
        if DoesBlipExist(blip) then RemoveBlip(blip) end
    end

    blips = {}
end

local function buildBlips()
    clearBlips()
    if not Config.FuelStationBlips.enable then return end

    for _, def in pairs(Station.list) do
        if def.blip ~= false and def.coords then
            local blip = AddBlipForCoord(def.coords.x, def.coords.y, def.coords.z)

            SetBlipSprite(blip, Config.FuelStationBlips.id)
            SetBlipDisplay(blip, 4)
            SetBlipScale(blip, Config.FuelStationBlips.scale)
            SetBlipColour(blip, Config.FuelStationBlips.color)
            SetBlipAsShortRange(blip, true)

            -- The station name goes on the blip, so renaming a station in the
            -- dashboard is visible on the map right away.
            AddTextEntry('msk_fuel_station', def.label or Config.FuelStationBlips.label)
            BeginTextCommandSetBlipName('msk_fuel_station')
            EndTextCommandSetBlipName(blip)

            blips[#blips + 1] = blip
        end
    end
end

---Nearest station whose zone contains the coordinate. Mirrors Stations.Find().
---@return string|nil id, table|nil def
function Station.Find(coords)
    if not coords then return nil end

    local bestId, bestDef, bestDist

    for id, def in pairs(Station.list) do
        if def.coords then
            local dist = #(coords - vector3(def.coords.x, def.coords.y, def.coords.z))

            if dist <= (def.radius or 60.0) and (not bestDist or dist < bestDist) then
                bestId, bestDef, bestDist = id, def, dist
            end
        end
    end

    return bestId, bestDef
end

---The station a pump belongs to. Accepts the pump entity or its coordinates,
---because the fueling loop only keeps the coords around, not the prop.
function Station.From(entityOrCoords)
    local t = type(entityOrCoords)

    if t == 'vector3' then
        return Station.Find(entityOrCoords)
    end

    -- A coordinate that made the round trip through a statebag comes back as a
    -- plain table.
    if t == 'table' then
        local x, y, z = tonumber(entityOrCoords.x), tonumber(entityOrCoords.y), tonumber(entityOrCoords.z)
        if not (x and y and z) then return nil end

        return Station.Find(vector3(x + 0.0, y + 0.0, z + 0.0))
    end

    if t ~= 'number' or not DoesEntityExist(entityOrCoords) then return nil end

    return Station.Find(GetEntityCoords(entityOrCoords))
end

---Is there anything left in that tank? Unknown pumps (no station) always sell,
---they fall back to the legacy flat price on the server.
function Station.HasStock(pump, fuelType)
    local _, def = Station.From(pump)
    if not def then return true end

    if not MSK.Table.Contains(def.fuelTypes or {}, fuelType) then return false end

    return (def.stock and def.stock[fuelType] or 0) > 0
end

---Price per liter at that pump. Pumps outside every zone fall back to the
---legacy flat price from config.lua, converted into the same unit. Mirrors
---Pricing.Fallback() on the server, which is what actually charges the player.
function Station.PricePerLiter(pump, fuelType)
    local _, def = Station.From(pump)

    if def and def.prices and def.prices[fuelType] then
        return def.prices[fuelType]
    end

    local litersPerTick = Config.Refill.value or 0.5
    if litersPerTick <= 0 then return Config.Refill.price end

    return Config.Refill.price / litersPerTick
end

----------------------------------------------------------------
-- Pump condition
--
-- The payload only carries the pumps that are actually worn, keyed the same way
-- the server keys them. Anything not in there is healthy, which is also what an
-- unknown pump is: one nobody has used yet.
----------------------------------------------------------------
local MAX_HEALTH = 100

local function pumpKey(coords)
    return ('%d_%d'):format(math.floor(coords.x + 0.5), math.floor(coords.y + 0.5))
end

---Health of the pump behind this entity, 0 to 100.
function Station.PumpHealth(pump)
    local _, def = Station.From(pump)
    if not def or type(def.pumps) ~= 'table' then return MAX_HEALTH end

    local coords = (type(pump) == 'number' and DoesEntityExist(pump)) and GetEntityCoords(pump) or pump
    if type(coords) ~= 'vector3' then return MAX_HEALTH end

    return def.pumps[pumpKey(coords)] or MAX_HEALTH
end

---A pump worn past the failure threshold serves nobody. The server refuses the
---sale as well; this only keeps the option from showing up at all.
function Station.IsPumpBroken(pump)
    if not Config.Maintenance or Config.Maintenance.enable == false then return false end

    return Station.PumpHealth(pump) < (Config.Maintenance.failThreshold or 15)
end

---How much slower this pump fuels. 1.0 is a healthy pump.
function Station.PumpSlowFactor(pump)
    if not Config.Maintenance or Config.Maintenance.enable == false then return 1.0 end

    if Station.PumpHealth(pump) >= (Config.Maintenance.slowThreshold or 50) then return 1.0 end

    return math.max(1.0, tonumber(Config.Maintenance.slowFactor) or 1.0)
end

function Station.Apply(payload)
    if type(payload) ~= 'table' then return end

    Station.list = payload
    buildBlips()
end

RegisterNetEvent('msk_fuel:syncStations', function(payload)
    Station.Apply(payload)
end)

-- Pull the authoritative stations once on join: the client ships no station
-- list of its own, and edits made before the player connected would otherwise
-- be invisible until the next admin change.
CreateThread(function()
    while not MSK?.Player?.playerId do Wait(250) end
    Wait(1000)

    Station.Apply(MSK.Trigger('msk_fuel:getStations'))
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    clearBlips()
end)
