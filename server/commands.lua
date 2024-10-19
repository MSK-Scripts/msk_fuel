MSK.RegisterCommand(Config.Commands.setVehicleFuel, function(source, args, raw)
    local playerId = source
    local vehicle = MSK.Player[playerId].vehicle

    if not vehicle or not DoesEntityExist(vehicle) then
        return Config.Notification(playerId, Translate('not_inside_vehicle'), 'error')
    end

    local netId = NetworkGetNetworkIdFromEntity(vehicle)
    local fuel = args.fuel or 100

	SetVehicleFuel(netId, fuel)
end, {
    allowConsole = false,
    restricted = Config.Commands.allowedGroups,
    help = 'Set the fuel of the vehicle you are in',
    params = {
        {name = 'fuel', type = 'number', help = 'Fuel Amount', optional = true}
    }
})

MSK.RegisterCommand(Config.Commands.repairVehicle, function(source, args, raw)
    local playerId = source
    local vehicle = MSK.Player[playerId].vehicle

    if not vehicle or not DoesEntityExist(vehicle) then
        return Config.Notification(playerId, Translate('not_inside_vehicle'), 'error')
    end

    local netId = NetworkGetNetworkIdFromEntity(vehicle)

    TriggerClientEvent('msk_fuel:setVehicleRepaired', playerId, netId)
end, {
    allowConsole = false,
    restricted = Config.Commands.allowedGroups,
    help = 'Repair the vehicle you are in'
})