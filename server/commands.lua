for i = 1, #Config.Commands.allowedGroups do
    ExecuteCommand(('add_ace group.%s command.%s allow'):format(Config.Commands.allowedGroups[i], Config.Commands.setVehicleFuel))
    ExecuteCommand(('add_ace group.%s command.%s allow'):format(Config.Commands.allowedGroups[i], Config.Commands.repairVehicle))
end

local isPlayerAllowed = function(source, command)
    return IsPlayerAceAllowed(source, ('command.%s'):format(command))
end

RegisterCommand(Config.Commands.setVehicleFuel, function(source, args)
    local playerId = source
    if not playerId or playerId == 0 then return end

    if not isPlayerAllowed(playerId, Config.Commands.setVehicleFuel) then
        return Config.Notification(playerId, Translate('no_permission'), 'error')
    end

    local vehicle = GetVehiclePedIsIn(GetPlayerPed(playerId), false)

    if not vehicle or not DoesEntityExist(vehicle) then
        return Config.Notification(playerId, Translate('not_inside_vehicle'), 'error')
    end

    local netId = NetworkGetNetworkIdFromEntity(vehicle)
    local fuel = args[1] or 100

	SetVehicleFuel(netId, fuel)
    TriggerClientEvent('msk_fuel:setVehicleFuel', playerId, netId, fuel)
end)

RegisterCommand(Config.Commands.repairVehicle, function(source, args)
    local playerId = source
    if not playerId or playerId == 0 then return end

    if not isPlayerAllowed(playerId, Config.Commands.repairVehicle) then
        return Config.Notification(playerId, Translate('no_permission'), 'error')
    end

    local vehicle = GetVehiclePedIsIn(GetPlayerPed(playerId), false)

    if not vehicle or not DoesEntityExist(vehicle) then
        return Config.Notification(playerId, Translate('not_inside_vehicle'), 'error')
    end

    local netId = NetworkGetNetworkIdFromEntity(vehicle)

    TriggerClientEvent('msk_fuel:setVehicleRepaired', playerId, netId)
end)