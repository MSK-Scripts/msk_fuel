registerTargetFuelStations = function()
    local options = {}

    options[#options + 1] = {
        name = 'fuel_gas',
        label = Translate('fuel_gas'),
        distance = 2.0,
        icon = 'fas fa-gas-pump',
        canInteract = function(entity)
            local vehicle, distance = MSK.GetClosestVehicle()

            if not DoesEntityExist(vehicle) or distance > 2.5 then
                return false
            end

            if State.Player.Get('nozzle') or State.Player.Get('rope') then
                return false
            end

            local fuelType = GetVehicleFuelType(vehicle)

            if not IsFuelTypeAtFuelStation(entity, fuelType) then
                return false
            end

            if not IsFuelTypeAtFuelStation(entity, 'gas') then
                return false
            end

            return true
        end,
        onSelect = function(data)
            if GetPlayerMoney() >= Config.Refill.price then
                local vehicle, distance = MSK.GetClosestVehicle()
                local fuelType = GetVehicleFuelType(vehicle)

                if not Config.WrongFuel.allow and fuelType ~= 'gas' then
                    return Config.Notification(nil, Translate('wrong_fuel', Translate(fuelType)), 'error')
                end

                Fuel.Vehicle(vehicle, 'gas', false, data)
            else
                Config.Notification(nil, Translate('not_enough_money'), 'error')
            end
        end
    }

    options[#options + 1] = {
        name = 'fuel_diesel',
        label = Translate('fuel_diesel'),
        distance = 2.0,
        icon = 'fas fa-gas-pump',
        canInteract = function(entity)
            local vehicle, distance = MSK.GetClosestVehicle()

            if not DoesEntityExist(vehicle) or distance > 2.5 then
                return false
            end

            if State.Player.Get('nozzle') or State.Player.Get('rope') then
                return false
            end

            local fuelType = GetVehicleFuelType(vehicle)

            if not IsFuelTypeAtFuelStation(entity, fuelType) then
                return false
            end

            if not IsFuelTypeAtFuelStation(entity, 'diesel') then
                return false
            end

            return true
        end,
        onSelect = function(data)
            if GetPlayerMoney() >= Config.Refill.price then
                local vehicle, distance = MSK.GetClosestVehicle()
                local fuelType = GetVehicleFuelType(vehicle)

                if not Config.WrongFuel.allow and fuelType ~= 'diesel' then
                    return Config.Notification(nil, Translate('wrong_fuel', Translate(fuelType)), 'error')
                end

                Fuel.Vehicle(vehicle, 'diesel', false, data)
            else
                Config.Notification(nil, Translate('not_enough_money'), 'error')
            end
        end
    }

    options[#options + 1] = {
        name = 'fuel_electric',
        label = Translate('fuel_electric'),
        distance = 2.0,
        icon = 'fas fa-gas-pump',
        canInteract = function(entity)
            local vehicle, distance = MSK.GetClosestVehicle()

            if not DoesEntityExist(vehicle) or distance > 2.5 then
                return false
            end

            if State.Player.Get('nozzle') or State.Player.Get('rope') then
                return false
            end

            local fuelType = GetVehicleFuelType(vehicle)

            if not IsFuelTypeAtFuelStation(entity, fuelType) then
                return false
            end

            if not IsFuelTypeAtFuelStation(entity, 'electric') then
                return false
            end

            return true
        end,
        onSelect = function(data)
            if GetPlayerMoney() >= Config.Refill.price then
                local vehicle, distance = MSK.GetClosestVehicle()
                local fuelType = GetVehicleFuelType(vehicle)

                if not Config.WrongFuel.allow and fuelType ~= 'electric' then
                    return Config.Notification(nil, Translate('wrong_fuel', Translate(fuelType)), 'error')
                end

                Fuel.Vehicle(vehicle, 'electric', false, data)
            else
                Config.Notification(nil, Translate('not_enough_money'), 'error')
            end
        end
    }

    options[#options + 1] = {
        name = 'fuel_kerosin',
        label = Translate('fuel_kerosin'),
        distance = 2.0,
        icon = 'fas fa-gas-pump',
        canInteract = function(entity)
            local vehicle, distance = MSK.GetClosestVehicle()

            if not DoesEntityExist(vehicle) or distance > 2.5 then
                return false
            end

            if State.Player.Get('nozzle') or State.Player.Get('rope') then
                return false
            end

            local fuelType = GetVehicleFuelType(vehicle)

            if not IsFuelTypeAtFuelStation(entity, fuelType) then
                return false
            end

            if not IsFuelTypeAtFuelStation(entity, 'kerosin') then
                return false
            end

            return true
        end,
        onSelect = function(data)
            if GetPlayerMoney() >= Config.Refill.price then
                local vehicle, distance = MSK.GetClosestVehicle()
                local fuelType = GetVehicleFuelType(vehicle)

                if not Config.WrongFuel.allow and fuelType ~= 'kerosin' then
                    return Config.Notification(nil, Translate('wrong_fuel', Translate(fuelType)), 'error')
                end

                Fuel.Vehicle(vehicle, 'kerosin', false, data)
            else
                Config.Notification(nil, Translate('not_enough_money'), 'error')
            end
        end
    }

    if Config.Petrolcan.enable then
        options[#options + 1] = {
            name = 'fuel_petrolcan',
            label = Translate('petrolcan_buy'),
            distance = 2.0,
            icon = 'fas fa-faucet',
            onSelect = function(data)
                if GetPlayerMoney() >= Config.Petrolcan.price then    
                    Fuel.Petrolcan(data.coords)
                else
                    Config.Notification(nil, Translate('not_enough_money'), 'error')
                end
            end
        }

        options[#options + 1] = {
            name = 'fuel_petrolcan',
            label = Translate('petrolcan_refill'),
            distance = 2.0,
            icon = 'fas fa-faucet',
            canInteract = function(entity)    
                return GetSelectedPedWeapon(PlayerPedId()) == `WEAPON_PETROLCAN`
            end,
            onSelect = function(data)
                if GetPlayerMoney() >= Config.Petrolcan.refillPrice then    
                    Fuel.Petrolcan(data.coords, true)
                else
                    Config.Notification(nil, Translate('not_enough_money'), 'error')
                end
            end
        }

        exports.ox_target:addGlobalVehicle({
			name = 'petrolcan_fuel_vehicle',
			label = Translate('fuel_vehicle'),
			icon = 'fas fa-faucet',
			distance = 2.0,
            canInteract = function(entity)
                if not DoesVehicleUseFuel(entity) or State.Vehicle.Get(entity, 'isFueling') then
                    return false
                end

                return GetSelectedPedWeapon(PlayerPedId()) == `WEAPON_PETROLCAN`
            end,
			onSelect = function(data)
                local fuelType = GetVehicleFuelType(data.entity)
                Fuel.Vehicle(data.entity, fuelType, true)
			end
		})
    end

    options[#options + 1] = {
        name = 'cancel_fueling',
        label = Translate('return_nozzle'),
        distance = 2.0,
        icon = 'fas fa-gas-pump',
        canInteract = function(entity)
            if not State.Player.Get('nozzle') or not State.Player.Get('rope') then
                return false
            end

            if not State.Player.Get('nozzleAttached') then
                return false
            end

            return true
        end,
        onSelect = function(data)
            Fuel.DetachRopeFromPlayer()
        end
    }

    exports.ox_target:addModel(Config.FuelStationModels, options)

    -- If player has a nozzle in his hand
    exports.ox_target:addGlobalVehicle({
        name = 'nozzle_fuel_vehicle',
        label = Translate('fuel_vehicle'),
        icon = 'fas fa-faucet',
        distance = 2.0,
        bones = {'petrolcap', 'petroltank', 'petroltank_l', 'engine', 'hub_lr', 'handle_dside_r'},
        canInteract = function(entity)
            if not State.Player.Get('nozzle') or not State.Player.Get('rope') then
                return false
            end

            if not State.Player.Get('nozzleAttached') then
                return false
            end

            return true
        end,
        onSelect = function(data)
            Fuel.AttachRopeToVehicle(data.entity)
        end
    })

    -- If player has a nozzle in his hand
    exports.ox_target:addGlobalVehicle({
        name = 'return_nozzle_fuel_vehicle',
        label = Translate('take_nozzle'),
        icon = 'fas fa-faucet',
        distance = 2.0,
        bones = {'petrolcap', 'petroltank', 'petroltank_l', 'engine', 'hub_lr', 'handle_dside_r'},
        canInteract = function(entity)
            if not State.Player.Get('nozzle') or not State.Player.Get('rope') then
                return false
            end

            if State.Player.Get('nozzleAttached') and not State.Vehicle.Get(entity, 'nozzleAttached') then
                return false
            end

            return true
        end,
        onSelect = function(data)
            Fuel.AttachRopeToPlayer(data.entity)
        end
    })

    -- Lookup for Vehicle Fuel Type
    exports.ox_target:addGlobalVehicle({
        name = 'lookup_vehicle_fuel_type',
        label = Translate('vehicle_get_fuel_type'),
        icon = 'fa-solid fa-fire-flame-simple',
        distance = 2.0,
        bones = {'petrolcap', 'petroltank', 'petroltank_l', 'engine', 'hub_lr', 'handle_dside_r'},
        onSelect = function(data)
            local fuelType = GetVehicleFuelType(data.entity)
            Config.Notification(nil, Translate('vehicle_fuel_type', Translate(fuelType)), 'info')
        end
    })
end
registerTargetFuelStations()

registerModelFuelStations = function()
    local options = {}

    options[#options + 1] = {
        name = 'fuel_gas',
        label = Translate('fuel_gas'),
        distance = 10.0,
        icon = 'fas fa-gas-pump',
        canInteract = function(entity)
            if State.Player.Get('nozzle') or State.Player.Get('rope') then
                return false
            end

            if not IsFuelTypeAtFuelStation(entity, 'gas') then
                return false
            end

            return true
        end,
        onSelect = function(data)
            if GetPlayerMoney() >= Config.Refill.price then
                Fuel.GrabNozzle(data, 'gas')
            else
                Config.Notification(nil, Translate('not_enough_money'), 'error')
            end
        end
    }

    options[#options + 1] = {
        name = 'fuel_diesel',
        label = Translate('fuel_diesel'),
        distance = 10.0,
        icon = 'fas fa-gas-pump',
        canInteract = function(entity)
            if State.Player.Get('nozzle') or State.Player.Get('rope') then
                return false
            end

            if not IsFuelTypeAtFuelStation(entity, 'diesel') then
                return false
            end

            return true
        end,
        onSelect = function(data)
            if GetPlayerMoney() >= Config.Refill.price then
                Fuel.GrabNozzle(data, 'diesel')
            else
                Config.Notification(nil, Translate('not_enough_money'), 'error')
            end
        end
    }

    options[#options + 1] = {
        name = 'fuel_electric',
        label = Translate('fuel_electric'),
        distance = 10.0,
        icon = 'fas fa-gas-pump',
        canInteract = function(entity)
            if State.Player.Get('nozzle') or State.Player.Get('rope') then
                return false
            end

            if not IsFuelTypeAtFuelStation(entity, 'electric') then
                return false
            end

            return true
        end,
        onSelect = function(data)
            if GetPlayerMoney() >= Config.Refill.price then
                Fuel.GrabNozzle(data, 'electric')
            else
                Config.Notification(nil, Translate('not_enough_money'), 'error')
            end
        end
    }

    options[#options + 1] = {
        name = 'fuel_kerosin',
        label = Translate('fuel_kerosin'),
        distance = 10.0,
        icon = 'fas fa-gas-pump',
        canInteract = function(entity)
            if State.Player.Get('nozzle') or State.Player.Get('rope') then
                return false
            end

            if not IsFuelTypeAtFuelStation(entity, 'kerosin') then
                return false
            end

            return true
        end,
        onSelect = function(data)
            if GetPlayerMoney() >= Config.Refill.price then
                Fuel.GrabNozzle(data, 'kerosin')
            else
                Config.Notification(nil, Translate('not_enough_money'), 'error')
            end
        end
    }

    options[#options + 1] = {
        name = 'cancel_fueling',
        label = Translate('return_nozzle'),
        distance = 10.0,
        icon = 'fas fa-gas-pump',
        canInteract = function(entity)
            if not State.Player.Get('nozzle') or not State.Player.Get('rope') then
                return false
            end

            if not State.Player.Get('nozzleAttached') then
                return false
            end

            return true
        end,
        onSelect = function(data)
            Fuel.DetachRopeFromPlayer()
        end
    }

    exports.ox_target:addModel(Config.FuelVehicles, options)
    exports.ox_target:addModel(Config.FuelModels, options)
end
registerModelFuelStations()