if Config.FuelStationBlips.enable then
	AddTextEntry('msk_fuel_station', Config.FuelStationBlips.label)

	CreateThread(function()
		for i = 1, #Config.FuelStations do
			local blip = AddBlipForCoord(Config.FuelStations[i])
	
			SetBlipSprite(blip, Config.FuelStationBlips.id)
			SetBlipDisplay(blip, 4)
			SetBlipScale(blip, Config.FuelStationBlips.scale)
			SetBlipColour(blip, Config.FuelStationBlips.color)
			SetBlipAsShortRange(blip, true)
			BeginTextCommandSetBlipName('msk_fuel_station')
			EndTextCommandSetBlipName(blip)
		end

		for k, v in pairs(Config.CustomFuelStations) do
			if v.showBlip then
				local blip = AddBlipForCoord(v.coords.x, v.coords.y, v.coords.z)
	
				SetBlipSprite(blip, Config.FuelStationBlips.id)
				SetBlipDisplay(blip, 4)
				SetBlipScale(blip, Config.FuelStationBlips.scale)
				SetBlipColour(blip, Config.FuelStationBlips.color)
				SetBlipAsShortRange(blip, true)
				BeginTextCommandSetBlipName('msk_fuel_station')
				EndTextCommandSetBlipName(blip)
			end
		end
	end)

	CreateThread(function()
		while not State?.FuelStation?.Add do
			Wait(10)
		end

		for k, v in pairs(Config.CustomFuelStations) do
			local object = CreateObject(v.model, v.coords.x, v.coords.y, v.coords.z - 1.0, true, true, true)
			SetEntityHeading(object, v.coords.w)
			State.FuelStation.Add(object)
		end
	end)
end

RegisterCommand('tankVolume', function(source, args, raw)
	if not MSK.Player.vehicle then return end
	local tankVolume = GetVehicleMaxFuel(MSK.Player.vehicle)
	print(('PetrolTankVolume of %s: %s Liters'):format(MSK.GetVehicleLabel(MSK.Player.vehicle), tankVolume))
end)

SetFuelConsumptionState(true)
SetFuelConsumptionRateMultiplier(Config.FuelConsumptionRateMultiplier)

CalculateVehicleFuel = function(vehicle)
	if not DoesVehicleUseFuel(vehicle) then return end
	local vehState = Entity(vehicle).state
	local model = GetEntityModel(vehicle)

	if not vehState.fuel then
		SetVehicleFuel(vehicle, GetVehicleFuelLevel(vehicle))
	end

	if not vehState.fuelType then
		CalculateFuelType(vehicle)
	end

	if not vehState.maxFuel then
		SetVehicleMaxFuel(vehicle, Config.PetrolTankVolume[model] or GetVehicleHandlingFloat(vehicle, "CHandlingData", "fPetrolTankVolume"))
	end

	while MSK.Player.seat == -1 do
		if not DoesEntityExist(vehicle) then return end

		if GetIsVehicleEngineRunning(vehicle) and not State.Vehicle.Get(vehicle, 'consumFuel') then
			State.Vehicle.Set(vehicle, 'consumFuel', true)
			SetVehicleHandlingFloat(vehicle, 'CHandlingData', 'fPetrolConsumptionRate', Config.FuelConsumptionRateMultiplier)
		elseif not GetIsVehicleEngineRunning(vehicle) and State.Vehicle.Get(vehicle, 'consumFuel') then
			State.Vehicle.Set(vehicle, 'consumFuel', nil)
			SetVehicleHandlingFloat(vehicle, 'CHandlingData', 'fPetrolConsumptionRate', 0)
		end

		local fuelLevel = vehState.fuel
		local currFuelLevel = GetVehicleFuelLevel(vehicle)

		if fuelLevel > 0 then
			if GetVehiclePetrolTankHealth(vehicle) < 700 then
				currFuelLevel -= math.random(10, 20) * 0.01
			end

			if fuelLevel ~= currFuelLevel then
				logging('debug', 'CalculateVehicleFuel', currFuelLevel)
				SetVehicleFuel(vehicle, currFuelLevel)
			end
		end

		if not State.Vehicle.Get(vehicle, 'engineFailure') and State.Vehicle.Get(vehicle, 'isFuelingType') and GetIsVehicleEngineRunning(vehicle) then
			CreateThread(function()
				SetEngineFailure(vehicle)
			end)
		elseif State.Vehicle.Get(vehicle, 'engineFailure') and State.Vehicle.Get(vehicle, 'isFuelingType') and GetIsVehicleEngineRunning(vehicle) then
			CreateThread(function()
				OverrideEngine(vehicle)
			end)
		end

		Wait(1000)
	end

	if DoesEntityExist(vehicle) then
		SetVehicleFuel(vehicle, vehState.fuel)
	end
end

CreateThread(function()
	while true do
		local sleep = 500
		local fuelingCoords = State.Player.Get('fuelingCoords')
		
		if fuelingCoords then
			local playerDist = #(fuelingCoords - GetEntityCoords(MSK.Player.playerPed))
			local maxDist = 20.0

			local fuelingVehicle = State.Player.Get('vehicle')

			if fuelingVehicle and DoesEntityExist(fuelingVehicle) then
				local model = GetEntityModel(fuelingVehicle)

				if IsThisModelAHeli(model) then
					maxDist = 30.0
				end

				if IsThisModelAPlane(model) then
					maxDist = 50.0
				end
			end

			if playerDist >= maxDist then
				Config.Notification(nil, Translate('too_far_away_from_vehicle'), 'error')
				Fuel.StopFueling()
				Fuel.DetachRopeFromPlayer()
			end
		end

		local nozzleCoords = State.Player.Get('nozzleCoords')

		if nozzleCoords then
			local playerDist = #(nozzleCoords - GetEntityCoords(MSK.Player.playerPed))
			local maxDist = 20.0

			local fuelingVehicle = State.Player.Get('vehicle')
			
			if fuelingVehicle and DoesEntityExist(fuelingVehicle) then
				local model = GetEntityModel(fuelingVehicle)

				if IsThisModelAHeli(model) then
					maxDist = 30.0
				end

				if IsThisModelAPlane(model) then
					maxDist = 50.0
				end
			end

			if playerDist >= maxDist then
				Config.Notification(nil, Translate('too_far_away_from_station'), 'error')
				Fuel.StopFueling()
				Fuel.DetachRopeFromPlayer()
			end
		end

		local fuelingVehicle = State.Player.Get('vehicle')

		if fuelingVehicle then
			if DoesEntityExist(fuelingVehicle) then
				local model = GetEntityModel(fuelingVehicle)
				local vehicleDist = #(fuelingCoords - GetEntityCoords(fuelingVehicle))
				local maxDist = 20.0

				if IsThisModelAHeli(model) then
					maxDist = 30.0
				end

				if IsThisModelAPlane(model) then
					maxDist = 50.0
				end

				if vehicleDist >= maxDist then
					Config.Notification(nil, Translate('vehicle_too_far_away_from_station'), 'error')
					Fuel.StopFueling()
					Fuel.DetachRopeFromPlayer()
				end
			else
				Config.Notification(nil, Translate('vehicle_does_not_exist'), 'error')
				Fuel.StopFueling()
				Fuel.DetachRopeFromPlayer()
			end
		end

		Wait(500)
	end
end)

if MSK.Player.seat == -1 then
	CreateThread(function()
		CalculateVehicleFuel(MSK.Player.vehicle)
	end)
end

AddEventHandler('msk_core:onPlayer', function(key, value)
	if key ~= 'seat' then return end
    if value ~= -1 then return end
	CalculateVehicleFuel(MSK.Player.vehicle)
end)

RegisterNetEvent('msk_fuel:setVehicleFuel', function(netId, fuel)
    local vehicle = NetworkGetEntityFromNetworkId(netId)
    if not DoesEntityExist(vehicle) then return end

    SetVehicleFuel(vehicle, fuel)
end)

RegisterNetEvent('msk_fuel:setVehicleRepaired', function(netId, fuel)
    local vehicle = NetworkGetEntityFromNetworkId(netId)
    if not DoesEntityExist(vehicle) then return end

    SetEngineRepaired(vehicle)
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    Fuel.DetachRopeFromPlayer()
	State.FuelStation.RemoveAll()
end)

AddStateBagChangeHandler("fuel", nil, function(bagName, key, value, reserved, replicated) 
    local entity = GetEntityFromStateBagName(bagName)
    if not IsEntityAVehicle(entity) then return end

	local invoke = GetInvokingResource()
	if not invoke or invoke == 'msk_fuel' then return end

	SetVehicleFuel(entity, value + 0.0)
end)

AddStateBagChangeHandler("maxFuel", nil, function(bagName, key, value, reserved, replicated) 
    local entity = GetEntityFromStateBagName(bagName)
    if not IsEntityAVehicle(entity) then return end

	local invoke = GetInvokingResource()
	if not invoke or invoke == 'msk_fuel' then return end

	SetVehicleMaxFuel(entity, value)
end)