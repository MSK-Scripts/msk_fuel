GetPlayerMoney = function(playerId)
    return exports.ox_inventory:GetItemCount(playerId, 'money')
end

PayPrice = function(playerId, price)
    local success = exports.ox_inventory:RemoveItem(playerId, 'money', price)
    if success then return true end
    Config.Notification(playerId, Translate('not_enough_money'), 'error')
end

GetVehicleFromNetId = function(netId)
    local vehicle = NetworkGetEntityFromNetworkId(netId)

    if not DoesEntityExist(vehicle) or GetEntityType(vehicle) ~= 2 then
        return false
    end

    return vehicle
end

----------------------------------------------------------------
-- Server-authoritative fuel (S1)
--
-- The fuel level lives in a replicated StateBag. Clients (entity owners) compute
-- consumption locally, which means they may only ever DECREASE the fuel value.
-- Every legit INCREASE (refueling, admin, petrolcan) goes through SetVehicleFuel
-- below, which raises the authorized value BEFORE writing the StateBag. Any state
-- change that pushes the value above the authorized amount was therefore not
-- initiated by the server and gets rolled back. This does not require identifying
-- the setter, we only ever compare the direction of the change.
----------------------------------------------------------------
local AuthorizedFuel = {} -- keyed by server entity handle

-- Tiny upward tolerance to absorb float jitter without allowing meaningful gain.
local FUEL_JITTER = 0.5

-- NOTE: The serverside SetVehicleFuel takes a NETWORK ID, the clientside one
-- (client/functions.lua) takes an ENTITY handle. Same export name, different context.
SetVehicleFuel = function(netId, fuel)
    local vehicle = GetVehicleFromNetId(netId)
    assert(vehicle, 'Parameter "vehicle" is nil or the Vehicle does not exist')

    fuel = tonumber(fuel) + 0.0

    -- Authorize this value first, so the StateBag handler treats it as legit.
    AuthorizedFuel[vehicle] = fuel
    Entity(vehicle).state:set('fuel', fuel, true)

    local entityOwner = NetworkGetEntityOwner(vehicle)

    if entityOwner and entityOwner > 0 then
        TriggerClientEvent('msk_fuel:setVehicleFuel', entityOwner, netId, fuel)
    end
end
exports('SetVehicleFuel', SetVehicleFuel)

GetVehicleFuel = function(netId)
    local vehicle = GetVehicleFromNetId(netId)
    assert(vehicle, 'Parameter "vehicle" is nil or the Vehicle does not exist')

    -- Prefer the authoritative value, fall back to the current state, and only as a
    -- last resort to 0.0 (conservative: never grant free fuel like the old 50.0 did).
    return AuthorizedFuel[vehicle] or Entity(vehicle).state.fuel or 0.0
end
exports('GetVehicleFuel', GetVehicleFuel)

AddStateBagChangeHandler('fuel', nil, function(bagName, key, value, reserved, replicated)
    local vehicle = GetEntityFromStateBagName(bagName)
    if vehicle == 0 or GetEntityType(vehicle) ~= 2 then return end

    local authorized = AuthorizedFuel[vehicle]

    -- Reject non-numeric values, reset to the last known good value if we have one.
    if type(value) ~= 'number' then
        if authorized then
            Entity(vehicle).state:set('fuel', authorized, true)
        end
        return
    end

    -- First time we see this vehicle: take the value as the baseline.
    if authorized == nil then
        AuthorizedFuel[vehicle] = value
        return
    end

    -- Decrease (consumption) or negligible jitter is fine.
    if value <= authorized + FUEL_JITTER then
        if value < authorized then
            AuthorizedFuel[vehicle] = value -- let the authorized value follow consumption down
        end
        return
    end

    -- Illegitimate increase: roll the StateBag back to the authorized value.
    local netId = NetworkGetNetworkIdFromEntity(vehicle)
    Entity(vehicle).state:set('fuel', authorized, true)

    local owner = NetworkGetEntityOwner(vehicle)
    if owner and owner > 0 then
        TriggerClientEvent('msk_fuel:setVehicleFuel', owner, netId, authorized)
    end

    logging('debug', 'Fuel manipulation rejected', netId, ('client=%.2f authorized=%.2f'):format(value, authorized))
end)

AddEventHandler('entityRemoved', function(entity)
    AuthorizedFuel[entity] = nil
end)

----------------------------------------------------------------
-- Distance / station checks
----------------------------------------------------------------

-- Per vehicle type max fueling distance (S3). Mirrors the clientside logic.
GetMaxFuelingDistance = function(vehicle)
    local vehType = GetVehicleType(vehicle)

    if vehType == 'heli' then
        return Config.MaxFuelingDistance.heli
    elseif vehType == 'plane' then
        return Config.MaxFuelingDistance.plane
    end

    return Config.MaxFuelingDistance.default
end

-- Serverside anti-exploit check: is the player close enough to the vehicle to interact with it?
IsPlayerNearVehicle = function(playerId, vehicle, maxDist)
    local ped = GetPlayerPed(playerId)
    if not ped or ped == 0 then return false end
    if not vehicle or not DoesEntityExist(vehicle) then return false end

    local dist = #(GetEntityCoords(ped) - GetEntityCoords(vehicle))
    return dist <= (maxDist or GetMaxFuelingDistance(vehicle))
end
exports('IsPlayerNearVehicle', IsPlayerNearVehicle)

-- Serverside anti-exploit check (S2): is the player actually standing at a fuel station?
-- 1. The player must be at the reported pump coords (blocks remote triggering).
-- 2. The reported coords must be near a known station zone (blocks fake coords).
IsPlayerNearFuelStation = function(playerId, coords)
    local ped = GetPlayerPed(playerId)
    if not ped or ped == 0 then return false end

    if type(coords) ~= 'vector3' and type(coords) ~= 'table' then return false end
    local x, y, z = tonumber(coords.x), tonumber(coords.y), tonumber(coords.z)
    if not x or not y or not z then return false end
    coords = vector3(x, y, z)

    local pedCoords = GetEntityCoords(ped)
    if #(pedCoords - coords) > Config.MaxStationDistance then return false end

    for i = 1, #Config.FuelStations do
        if #(coords - Config.FuelStations[i]) <= Config.FuelStationZoneDistance then
            return true
        end
    end

    for _, v in pairs(Config.CustomFuelStations) do
        if #(coords - vector3(v.coords.x, v.coords.y, v.coords.z)) <= Config.FuelStationZoneDistance then
            return true
        end
    end

    return false
end
exports('IsPlayerNearFuelStation', IsPlayerNearFuelStation)

----------------------------------------------------------------
-- Rate limiting (S4)
----------------------------------------------------------------
local RateLimits = {}

-- Returns false if the player triggered the same key within the cooldown window.
CheckRateLimit = function(playerId, key, cooldown)
    local now = GetGameTimer()
    RateLimits[playerId] = RateLimits[playerId] or {}

    local last = RateLimits[playerId][key]
    if last and (now - last) < cooldown then
        return false
    end

    RateLimits[playerId][key] = now
    return true
end

AddEventHandler('playerDropped', function()
    RateLimits[source] = nil
end)

logging = function(code, ...)
    if not Config.Debug and code == 'debug' then return end
    MSK.Logging(code, ...)
end
