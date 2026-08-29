-- The four fuel options are identical apart from the fuel type, so they are
-- built in a loop. Before v1.2.0 each type was written out by hand at both
-- registration sites, which meant every change to the fueling flow had to be
-- made eight times.
local FUEL_TYPES = { 'gas', 'diesel', 'electric', 'kerosin' }

local buildFuelOptions = function(distance)
    local options = {}

    for _, fuelType in ipairs(FUEL_TYPES) do
        options[#options + 1] = {
            name = 'fuel_' .. fuelType,
            label = Translate('fuel_' .. fuelType),
            distance = distance,
            icon = 'fas fa-gas-pump',
            canInteract = function(entity)
                if State.Player.Get('nozzle') or State.Player.Get('rope') then
                    return false
                end

                if not IsFuelTypeAtFuelStation(entity, fuelType) then
                    return false
                end

                -- An empty tank blocks that fuel type at that station. The
                -- server refuses the sale as well, this only saves the player
                -- from grabbing a nozzle that cannot deliver anything.
                if not Station.HasStock(entity, fuelType) then
                    return false
                end

                -- Same for a pump that is worn out: it has to be repaired first.
                if Station.IsPumpBroken(entity) then
                    return false
                end

                return true
            end,
            onSelect = function(data)
                local pricePerLiter = Station.PricePerLiter(data.entity, fuelType)

                -- Enough for at least one tick, otherwise fueling would stop
                -- before it started.
                if GetPlayerMoney() < math.ceil(pricePerLiter * Config.Refill.value) then
                    return Config.Notification(nil, Translate('not_enough_money'), 'error')
                end

                local _, station = Station.From(data.entity)

                Config.Notification(nil, Translate('fuel_price_info',
                    Translate(fuelType), MSK.Round(pricePerLiter, 2), station and station.label or Translate('fuel_station_blip')), 'info')

                Fuel.GrabNozzle(data, fuelType)
            end
        }
    end

    return options
end

-- Buying and managing a station. Both hang off the pump, because the pump is
-- what tells the server which station the player is standing at.
local buildBusinessOptions = function(distance)
    return {
        {
            name = 'station_buy',
            label = Translate('station_buy'),
            distance = distance,
            icon = 'fas fa-file-signature',
            canInteract = function(entity)
                local id, station = Station.From(entity)
                if not id or not station then return false end

                return station.purchasable == true and not station.owned
            end,
            onSelect = function(data)
                OwnerNui.Buy(data.entity)
            end
        },
        {
            name = 'station_public_delivery',
            label = Translate('delivery_public_take'),
            distance = distance,
            icon = 'fas fa-truck',
            canInteract = function(entity)
                if DeliveryRun.active then return false end

                local _, station = Station.From(entity)

                return station ~= nil and station.publicDelivery == true
            end,
            onSelect = function(data)
                DeliveryRun.TakePublicJob(data.entity)
            end
        },
        {
            name = 'station_manage',
            label = Translate('station_manage'),
            distance = distance,
            icon = 'fas fa-briefcase',
            canInteract = function(entity)
                return Station.CanManage((Station.From(entity)))
            end,
            onSelect = function(data)
                OwnerNui.Open(data.entity)
            end
        },
    }
end

registerTargetFuelStations = function()
    local options = buildFuelOptions(2.0)

    for _, option in ipairs(buildBusinessOptions(2.0)) do
        options[#options + 1] = option
    end

    if Config.Petrolcan.enable then
        options[#options + 1] = {
            name = 'fuel_petrolcan',
            label = Translate('petrolcan_buy'),
            distance = 2.0,
            icon = 'fas fa-faucet',
            canInteract = function(entity)
                -- Petrolcans are filled with petrol, so a station that sells no
                -- petrol (or has run out of it) cannot hand one over.
                return Station.HasStock(entity, 'gas') and not Station.IsPumpBroken(entity)
            end,
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
                if GetSelectedPedWeapon(PlayerPedId()) ~= `WEAPON_PETROLCAN` then
                    return false
                end

                return Station.HasStock(entity, 'gas') and not Station.IsPumpBroken(entity)
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
                Fuel.Vehicle(data.entity, fuelType)
			end
		})
    end

    -- If the nozzle is attached to a player to return it to fuel station
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

    -- If the nozzle is attached to a player
    exports.ox_target:addGlobalVehicle({
        name = 'nozzle_fuel_vehicle',
        label = Translate('fuel_vehicle'),
        icon = 'fas fa-faucet',
        distance = 2.5,
        -- bones = {'petrolcap', 'petroltank', 'petroltank_l', 'engine', 'hub_lr', 'handle_dside_r', 'wing_l', 'wing_r'},
        canInteract = function(entity)
            if not State.Player.Get('nozzle') or not State.Player.Get('rope') then
                return false
            end

            if not State.Player.Get('nozzleAttached') then
                return false
            end

            if State.Vehicle.Get(entity, 'nozzleAttached') then
                return false
            end

            return true
        end,
        onSelect = function(data)
            Fuel.AttachRopeToVehicle(data.entity)
        end
    })

    -- If the nozzle is attached to a vehicle
    exports.ox_target:addGlobalVehicle({
        name = 'return_nozzle_fuel_vehicle',
        label = Translate('take_nozzle'),
        icon = 'fas fa-faucet',
        distance = 2.5,
        -- bones = {'petrolcap', 'petroltank', 'petroltank_l', 'engine', 'hub_lr', 'handle_dside_r', 'wing_l', 'wing_r'},
        canInteract = function(entity)
            if not State.Player.Get('nozzle') or not State.Player.Get('rope') then
                return false
            end

            if State.Player.Get('nozzleAttached') then
                return false
            end

            if not State.Vehicle.Get(entity, 'nozzleAttached') then
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
        distance = 2.5,
        bones = {'petrolcap', 'petroltank', 'petroltank_l', 'engine', 'hub_lr', 'handle_dside_r', 'wing_l', 'wing_r'},
        onSelect = function(data)
            local fuelType = GetVehicleFuelType(data.entity)
            Config.Notification(nil, Translate('vehicle_fuel_type', Translate(fuelType)), 'info')
        end
    })
end
registerTargetFuelStations()

registerModelFuelStations = function()
    local options = buildFuelOptions(3.0)

    for _, option in ipairs(buildBusinessOptions(3.0)) do
        options[#options + 1] = option
    end

    -- If the nozzle is attached to a player to return it to fuel station
    options[#options + 1] = {
        name = 'cancel_fueling',
        label = Translate('return_nozzle'),
        distance = 3.0,
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
