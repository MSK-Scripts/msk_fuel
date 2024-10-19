Fuel = {}

Fuel.GrabNozzle = function(data, fuelType)
    TriggerEvent('ox_inventory:disarm') -- Disarm Playe
    local playerPed = MSK.Player.playerPed

    MSK.Request.AnimDict("anim@am_hold_up@male")
    TaskPlayAnim(playerPed, "anim@am_hold_up@male", "shoplift_high", 2.0, 8.0, -1, 50, 0, 0, 0, 0)
    Wait(300)
    ClearPedTasks(playerPed)

    local nozzle = CreateObject(`prop_cs_fuel_nozle`, 0, 0, 0, true, true, true)
    AttachEntityToEntity(nozzle, playerPed, GetPedBoneIndex(playerPed, 0x49D9), 0.11, 0.02, 0.02, -80.0, -90.0, 15.0, true, true, false, true, 1, true)
    State.Player.Set('nozzle', nozzle)

    RopeLoadTextures()
    while not RopeAreTexturesLoaded() do
        Wait(0)
    end

    local rope = AddRope(data.coords.x, data.coords.y, data.coords.z, 0.0, 0.0, 0.0, 3.0, 1, 1000.0, 0.0, 1.0, false, false, false, 1.0, true)
    while not rope do
        Wait(0)
    end

    ActivatePhysics(rope)
    Wait(50)
    State.Player.Set('rope', rope)

    local nozzlePos = GetEntityCoords(nozzle)
    nozzlePos = GetOffsetFromEntityInWorldCoords(nozzle, 0.0, -0.033, -0.195)
    AttachEntitiesToRope(rope, data.entity, nozzle, data.coords.x, data.coords.y, data.coords.z + 1.45, nozzlePos.x, nozzlePos.y, nozzlePos.z, 5.0, false, false, nil, nil)

    State.Player.Set('nozzleAttached', true)
    State.Player.Set('nozzleCoords', data.coords)
    State.Player.Set('isFuelingType', fuelType)
end

-- Refill vehicle with Petrolcan
Fuel.Vehicle = function(vehicle, fuelType)
    if State.Vehicle.Get(vehicle, 'isFueling') then return end
    State.Player.Set('isFuelingType', fuelType)

    local fuelAmount, maxFuel = GetVehicleFuel(vehicle), GetVehicleMaxFuel(vehicle)
    local duration = math.ceil((maxFuel - fuelAmount) / Config.Refill.value) * Config.Refill.tick

    if fuelAmount > fuelAmount + Config.Refill.value then
        return Config.Notification(nil, Translate('vehicle_tank_full'), 'info')
    end

    local weapon = State.Player.Get('petrolcan')

    if not weapon or GetSelectedPedWeapon(MSK.Player.playerPed) ~= `WEAPON_PETROLCAN` then
        return Config.Notification(nil, Translate('petrolcan_not_equipped'), 'error')
    end

    if weapon and weapon.metadata.ammo <= Config.Petrolcan.durabilityTick then
        return Config.Notification(nil, Translate('petrolcan_not_enough_fuel'), 'error')
    end

    TaskTurnPedToFaceEntity(MSK.Player.playerPed, vehicle, duration)
	Wait(500)

    Fuel.StartFueling(vehicle, duration, true)
end

-- Refill/Buy Petrolcan
Fuel.Petrolcan = function(coords, refill)
    local playerPed = MSK.Player.playerPed
    local duration = Config.Petrolcan.refillDuration * 1000

    TaskTurnPedToFaceCoord(playerPed, coords.x, coords.y, coords.z, duration)
	Wait(500)

    MSK.Progress.Start({
        duration = duration,
        text = Translate('petrolcan_refill') .. '...',
        canCancel = true,
        animation = {
            dict = 'timetable@gardener@filling_can',
			anim = 'gar_ig_5_filling_can',
			flags = 49,
        },
        disable = {
            move = true,
            vehicle = true,
            combat = true,
        }
    })

    if refill then
        TriggerServerEvent('msk_fuel:refillCan', Config.Petrolcan.refillPrice, true)
    else
        TriggerServerEvent('msk_fuel:refillCan', Config.Petrolcan.price)
    end

    ClearPedTasks(playerPed)
end

Fuel.StartFueling = function(vehicle, duration, isPetrolcan)
    local fuelType = State.Player.Get('isFuelingType')
    local vehFuelType = GetVehicleFuelType(vehicle)

    if not Config.WrongFuel.allow and fuelType ~= vehFuelType then
        return Config.Notification(nil, Translate('wrong_fuel', Translate(vehFuelType)), 'error')
    end

    if vehFuelType ~= fuelType then
        logging('debug', 'Fueling Type does not match')
        local isElectric = vehFuelType == 'electric'
        logging('debug', 'Fueling Type', fuelType, vehFuelType, isElectric)

        if isElectric then
            return Config.Notification(nil, Translate('fuel_electric_not_compatible'), 'error')
        end

        if not isElectric and fuelType == 'electric' then
            return Config.Notification(nil, Translate('fuel_not_compatible'), 'error')
        end

        State.Vehicle.Set(vehicle, 'isFuelingType', fuelType)
        State.Vehicle.Set(vehicle, 'isFuelingTypeValue', 0)
    end

    State.Player.Set('vehicle', vehicle)
    State.Player.Set('fuelingCoords', GetEntityCoords(vehicle))
    State.Vehicle.Set(vehicle, 'isFueling', true)

    local fuelAmount, maxFuel, addedFuelAmount = GetVehicleFuel(vehicle), GetVehicleMaxFuel(vehicle), 0
    local price, moneyAmount = 0, GetPlayerMoney()
    
    if not duration then
        duration = math.ceil((maxFuel - fuelAmount) / Config.Refill.value) * Config.Refill.tick
    end

    if fuelAmount > fuelAmount + Config.Refill.value then
        return Config.Notification(nil, Translate('vehicle_tank_full'), 'info')
    end

    if isPetrolcan then
        CreateThread(function()
            MSK.Progress.Start({
                duration = duration,
                text = Translate('fuel_vehicle_type', Translate(fuelType)),
                canCancel = true,
                useWhileDead = false,
                animation = {
                    dict = 'weapon@w_sp_jerrycan',
                    anim = 'fire',
                },
                disable = {
                    move = true,
                    vehicle = true,
                    combat = true,
                }
            })

            Fuel.StopFueling()
        end)
    else
        CreateThread(function()
            MSK.Progress.Start({
                duration = duration,
                text = Translate('fuel_vehicle_type', Translate(fuelType)),
                canCancel = false,
                useWhileDead = false,
            })

            Fuel.StopFueling()
        end)
    end

    local durability = 0

    while State.Vehicle.Get(vehicle, 'isFueling') do
        if not isPetrolcan then
            price += Config.Refill.price

			if price + Config.Refill.price >= moneyAmount then
				MSK.Progress.Stop()
			end
        elseif isPetrolcan and State.Player.Get('petrolcan') then
            durability += Config.Petrolcan.durabilityTick

			if durability >= State.Player.Get('petrolcan').metadata.ammo then
				MSK.Progress.Stop()
				durability = State.Player.Get('petrolcan').metadata.ammo
				break
			end
        else
            break
        end

        fuelAmount += Config.Refill.value
        addedFuelAmount += Config.Refill.value

        if State.Vehicle.Get(vehicle, 'isFuelingType') then
            State.Vehicle.Set(vehicle, 'isFuelingTypeValue', addedFuelAmount)
        end

		if fuelAmount >= maxFuel then
			fuelAmount = maxFuel
			Fuel.StopFueling()
		end

        Wait(Config.Refill.tick)
    end

    if isPetrolcan then
        ClearPedTasks(MSK.Player.playerPed)
        TriggerServerEvent('msk_fuel:updateFuelCan', durability, fuelAmount, NetworkGetNetworkIdFromEntity(vehicle))
    else
        TriggerServerEvent('msk_fuel:payFuelPrice', price, fuelAmount, NetworkGetNetworkIdFromEntity(vehicle))
    end
end

Fuel.StopFueling = function()
    local vehicle = State.Player.Get('vehicle')

    MSK.Progress.Stop()
    State.Player.Set('vehicle', nil)

    if vehicle then 
        State.Vehicle.Set(vehicle, 'isFueling', false)
    end
end

Fuel.AttachRopeToVehicle = function(vehicle)
    local model = GetEntityModel(vehicle)
    local boneIndex, bonePosition = GetVehicleFuelTankBoneIndex(vehicle)
    -- local bonePosition = GetWorldPositionOfEntityBone(vehicle, boneIndex)
    
    if IsThisModelABike(model) then
        AttachEntityToEntity(State.Player.Get('nozzle'), vehicle, boneIndex, 0.0 + bonePosition.x, -0.2 + bonePosition.y, 0.2 + bonePosition.z, -80.0, 0.0, 0.0, true, true, false, false, 1, true)
    else
        AttachEntityToEntity(State.Player.Get('nozzle'), vehicle, boneIndex, -0.18 + bonePosition.x, 0.0 + bonePosition.y, 0.75 + bonePosition.z, -125.0, -90.0, -90.0, true, true, false, false, 1, true)
    end

    State.Vehicle.Set(vehicle, 'nozzleAttached', true)
    State.Player.Set('nozzleAttached', false)

    local fuelAmount, maxFuel = GetVehicleFuel(vehicle), GetVehicleMaxFuel(vehicle)
    local duration = math.ceil((maxFuel - fuelAmount) / Config.Refill.value) * Config.Refill.tick
    Fuel.StartFueling(vehicle, duration, false)
end

Fuel.AttachRopeToPlayer = function(vehicle)
    if State.Player.Get('nozzleAttached') then return end

    State.Player.Set('nozzleAttached', true)
    State.Vehicle.Set(vehicle, 'nozzleAttached', false)

    Fuel.StopFueling()
    AttachEntityToEntity(State.Player.Get('nozzle'), MSK.Player.playerPed, GetPedBoneIndex(MSK.Player.playerPed, 0x49D9), 0.11, 0.02, 0.02, -80.0, -90.0, 15.0, true, true, false, true, 1, true)
end

Fuel.DetachRopeFromPlayer = function()
    DetachEntity(State.Player.Get('nozzle'), true, true)
    DeleteEntity(State.Player.Get('nozzle'))
    RopeUnloadTextures()
    DeleteRope(State.Player.Get('rope'))

    State.Player.Set('nozzleAttached', false)
    State.Player.Set('nozzle', nil)
    State.Player.Set('rope', nil)
    State.Player.Set('vehicle', nil)
    State.Player.Set('isFuelingType', nil)
    State.Player.Set('fuelingCoords', nil)
    State.Player.Set('nozzleCoords', nil)
end

local getFuelData = function()
    return Fuel
end
exports('Fuel', getFuelData)