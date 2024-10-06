State = {}
State.Player = {}
State.Vehicle = {}
State.FuelStation = {}

-- Nozzle Z position based on vehicle class.
State.NozzlePositions = {
    0.65, -- Compacts
    0.65, -- Sedans
    0.85, -- SUVs
    0.6, -- Coupes
    0.55, -- Muscle
    0.6, -- Sports Classics
    0.6, -- Sports
    0.55, -- Super
    0.12, -- Motorcycles
    0.8, -- Off-road
    0.7, -- Industrial
    0.6, -- Utility
    0.7, -- Vans
    0.0, -- Cycles
    0.0, -- Boats
    0.0, -- Helicopters
    0.0, -- Planes
    0.6, -- Service
    0.65, -- Emergency
    0.65, -- Military
    0.75, -- Commercial
    0.0 -- Trains
}

State.Vehicle.Set = function(vehicle, stateName, value)
    assert(vehicle and DoesEntityExist(vehicle), 'Parameter "vehicle" is nil or the Vehicle does not exist')
    Entity(vehicle).state:set(stateName, value, true)

    if stateName == 'fuel' then
        SetVehicleFuel(vehicle, value)
    end
end

State.Vehicle.Get = function(vehicle, stateName)
    assert(vehicle and DoesEntityExist(vehicle), 'Parameter "vehicle" is nil or the Vehicle does not exist')
    return Entity(vehicle).state[stateName]
end

State.Player.Set = function(stateName, value)
    Player(MSK.Player.playerId).state:set(stateName, value)
end

State.Player.Get = function(stateName)
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
        end
    end
end

State.FuelStation.RemoveAll = function()
    for i, obj in ipairs(FuelStations) do
        DeleteEntity(obj)
    end
end