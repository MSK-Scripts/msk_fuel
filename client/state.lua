State = {}
State.Player = {}
State.Vehicle = {}
State.FuelStation = {}

State.Vehicle.Set = function(vehicle, stateName, value)
    assert(vehicle and DoesEntityExist(vehicle), 'Parameter "vehicle" is nil or the Vehicle does not exist')
    Entity(vehicle).state:set(stateName, value, false)

    if stateName == 'fuel' then
        SetVehicleFuelLevel(vehicle, value)
    end

    if stateName == 'maxFuel' then
        SetVehicleHandlingFloat(vehicle, 'CHandlingData', 'fPetrolTankVolume', value)
    end

    if NetworkGetEntityIsNetworked(vehicle) then
        TriggerServerEvent('msk_fuel:setVehicleState', NetworkGetNetworkIdFromEntity(vehicle), stateName, value)
    end
end

RegisterNetEvent('msk_fuel:syncVehicleState', function(netId)
    local vehicle = NetworkGetEntityFromNetworkId(netId)
    if not DoesEntityExist(vehicle) or not NetworkHasControlOfEntity(vehicle) then return end

    local state = Entity(vehicle).state
    for _, key in ipairs({'fuel', 'maxFuel', 'fuelType', 'consumFuel', 'engineFailure',
        'isFueling', 'nozzleAttached', 'isFuelingType', 'isFuelingTypeValue'}) do
        local value = state[key]
        if value ~= nil then
            if key == 'fuel' then value = math.min(value, GetVehicleFuelLevel(vehicle)) end
            TriggerServerEvent('msk_fuel:setVehicleState', netId, key, value)
        end
    end
end)

State.Vehicle.Get = function(vehicle, stateName)
    assert(vehicle and DoesEntityExist(vehicle), 'Parameter "vehicle" is nil or the Vehicle does not exist')

    if not stateName then
        return Entity(vehicle).state
    end

    return Entity(vehicle).state[stateName]
end

State.Player.Set = function(stateName, value)
    Player(MSK.Player.playerId).state:set(stateName, value)
end

State.Player.Get = function(stateName)
    if not stateName then
        return Player(MSK.Player.playerId).state
    end

    return Player(MSK.Player.playerId).state[stateName]
end

local setPlayerWeapon = function(data)
    State.Player.Set('petrolcan', data and data.name == 'WEAPON_PETROLCAN' and data or nil)
end
AddEventHandler('ox_inventory:currentWeapon', setPlayerWeapon)
setPlayerWeapon(exports.ox_inventory:getCurrentWeapon())

local FuelStations = {}

State.FuelStation.Add = function(object)
    FuelStations[#FuelStations + 1] = object
end

State.FuelStation.Remove = function(object)
    assert(object and DoesEntityExist(object), 'Parameter "vehicle" is nil or the Vehicle does not exist')
    DeleteEntity(object)

    for i, obj in ipairs(FuelStations) do
        if obj == object then
            table.remove(FuelStations, i)
            break
        end
    end
end

State.FuelStation.RemoveAll = function()
    for i, obj in ipairs(FuelStations) do
        DeleteEntity(obj)
    end

    FuelStations = {}
end

local getStateData = function()
    return State
end
exports('State', getStateData)
