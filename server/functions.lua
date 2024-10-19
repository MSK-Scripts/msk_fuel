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

SetVehicleFuel = function(netId, fuel)
    local vehicle = GetVehicleFromNetId(netId)
    assert(vehicle, 'Parameter "vehicle" is nil or the Vehicle does not exist')

    fuel = tonumber(fuel) + 0.0

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

    return Entity(vehicle).state.fuel or 50.0
end
exports('GetVehicleFuel', GetVehicleFuel)

logging = function(code, ...)
    if not Config.Debug and code == 'debug' then return end
    MSK.Logging(code, ...)
end