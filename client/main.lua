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
	end)

	CreateThread(function()
		while not State?.FuelStation?.Add do
			print('Waiting for State.FuelStation.Add')
			Wait(10)
		end

		for k, v in pairs(Config.CustomFuelStations) do
			local object = CreateObject(v.model, v.coords.x, v.coords.y, v.coords.z - 1.0, true, true, true)
			SetEntityHeading(object, v.coords.w)
			State.FuelStation.Add(object)
		end
	end)
end

SetFuelConsumptionState(true)
SetFuelConsumptionRateMultiplier(Config.FuelConsumptionRateMultiplier)

CalculateVehicleFuel = function(vehicle)
	if not DoesVehicleUseFuel(vehicle) then return end
	local vehState = Entity(vehicle).state

	if not vehState.fuel then
		SetVehicleFuel(vehicle, GetVehicleFuelLevel(vehicle))
	end

	if not vehState.fuelType then
		CalculateFuelType(vehicle)
	end

	while MSK.Player.seat == -1 do
		if not DoesEntityExist(vehicle) then return end
		local fuelLevel = vehState.fuel
		local currFuelLevel = GetVehicleFuelLevel(vehicle)

		if fuelLevel > 0 then
			if GetVehiclePetrolTankHealth(vehicle) < 700 then
				currFuelLevel -= math.random(10, 20) * 0.01
			end

			if fuelLevel ~= currFuelLevel then
				SetVehicleFuel(vehicle, currFuelLevel)
			end
		end

		if not State.Vehicle.Get(vehicle, 'engineFailure') and State.Vehicle.Get(vehicle, 'isFuelingType') and GetIsVehicleEngineRunning(vehicle) then
			CreateThread(function()
				SetEngineFailure(vehicle)
			end)
		end

		Wait(1000)
	end

	SetVehicleFuel(vehicle, vehState.fuel)
end

if MSK.Player.seat == -1 then
	CreateThread(function()
		CalculateVehicleFuel(MSK.Player.vehicle)
	end)
end

AddEventHandler('msk_core:onSeatChange', function(vehicle, seat)
    if not seat or seat ~= -1 then return end
	CalculateVehicleFuel(vehicle)
end)

RegisterNetEvent('msk_fuel:setVehicleFuel', function(netId, fuel)
    local vehicle = NetworkGetEntityFromNetworkId(netId)
    if not DoesEntityExist(vehicle) then return end

    SetVehicleFuel(vehicle, fuel)
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    Fuel.DetachRopeFromPlayer()
	State.FuelStation.RemoveAll()
end)