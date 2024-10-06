GetPlayerMoney = function()
    return exports.ox_inventory:GetItemCount('money')
end

GetVehicleFuelTankBoneIndex = function(vehicle)
    local model = GetEntityModel(vehicle)
    local class = GetVehicleClass(vehicle)
    local fuelType = GetVehicleFuelType(vehicle)
    local zPos = State.NozzlePositions[class + 1]
    local modifiedPosition = {
        x = 0.0,
        y = 0.0,
        z = 0.0
    }
    local tankBone

    if class == 8 and class ~= 13 and fuelType ~= 'electric' then
        tankBone = GetEntityBoneIndexByName(vehicle, "petrolcap")

        if tankBone == -1 then
            tankBone = GetEntityBoneIndexByName(vehicle, "petroltank")
        end

        if tankBone == -1 then
            tankBone = GetEntityBoneIndexByName(vehicle, "engine")
        end
    elseif class ~= 13 and fuelType ~= 'electric' then
        tankBone = GetEntityBoneIndexByName(vehicle, "petrolcap")

        if tankBone == -1 then
            tankBone = GetEntityBoneIndexByName(vehicle, "petroltank_l")
        end

        if tankBone == -1 then
            tankBone = GetEntityBoneIndexByName(vehicle, "hub_lr")
        end

        if tankBone == -1 then
            tankBone = GetEntityBoneIndexByName(vehicle, "handle_dside_r")

            modifiedPosition.x = 0.1
            modifiedPosition.y = -0.5
            modifiedPosition.z = -0.6
        end
    end

    return tankBone, modifiedPosition
end

IsVehicleGas = function(vehicle)
    local fuelType = State.Vehicle.Get(vehicle, 'fuelType')

    if fuelType and fuelType == 'gas' then 
        return true 
    end

    local model = GetEntityModel(vehicle)
    local typeOfFuel

    for fuelType, vehModel in pairs(Config.Vehicles.gas) do
        if vehModel == model then
            typeOfFuel = fuelType
            break
        end
    end

    if not typeOfFuel then
        typeOfFuel = Config.DefaultFuelType
    end

    return typeOfFuel
end

IsVehicleDiesel = function(vehicle)
    local fuelType = State.Vehicle.Get(vehicle, 'fuelType')

    if fuelType and fuelType == 'diesel' then 
        return true 
    end

    local model = GetEntityModel(vehicle)
    local typeOfFuel

    for fuelType, vehModel in pairs(Config.Vehicles.diesel) do
        if vehModel == model then
            typeOfFuel = fuelType
            break
        end
    end

    if not typeOfFuel then
        typeOfFuel = Config.DefaultFuelType
    end

    return typeOfFuel
end

IsVehicleKerosin = function(vehicle)
    local fuelType = State.Vehicle.Get(vehicle, 'fuelType')
    
    if fuelType and fuelType == 'kerosin' then 
        return true 
    end

    local model = GetEntityModel(vehicle)
    local typeOfFuel

    for fuelType, vehModel in pairs(Config.Vehicles.kerosin) do
        if vehModel == model then
            typeOfFuel = fuelType
            break
        end
    end

    if not typeOfFuel then
        typeOfFuel = Config.DefaultFuelType
    end

    return typeOfFuel
end

IsVehicleElectric = function(vehicle)
    local fuelType = State.Vehicle.Get(vehicle, 'fuelType')
    
    if fuelType and fuelType == 'electric' then 
        return true 
    end

    local model = GetEntityModel(vehicle)
    local typeOfFuel

    for fuelType, vehModel in pairs(Config.Vehicles.electric) do
        if vehModel == model then
            typeOfFuel = fuelType
            break
        end
    end

    if not typeOfFuel then
        typeOfFuel = Config.DefaultFuelType
    end

    return typeOfFuel
end

CalculateFuelType = function(vehicle)    
    if IsVehicleGas(vehicle) then
        SetVehicleFuelType(vehicle, 'gas')
        return 'gas'
    end

    if IsVehicleDiesel(vehicle) then
        SetVehicleFuelType(vehicle, 'diesel')
        return 'diesel'
    end

    if IsVehicleKerosin(vehicle) then
        SetVehicleFuelType(vehicle, 'kerosin')
        return 'kerosin'
    end

    if IsVehicleElectric(vehicle) then
        SetVehicleFuelType(vehicle, 'electric')
        return 'electric'
    end
end

SetVehicleFuelType = function(vehicle, fuelType)
    assert(vehicle and DoesEntityExist(vehicle), 'Parameter "vehicle" is nil or the Vehicle does not exist')

    if not fuelType then 
        CalculateFuelType(vehicle)
        return
    end

    State.Vehicle.Set(vehicle, 'fuelType', fuelType)
end
exports('SetVehicleFuelType', SetVehicleFuelType)

GetVehicleFuelType = function(vehicle)
    assert(vehicle and DoesEntityExist(vehicle), 'Parameter "vehicle" is nil or the Vehicle does not exist')
    local fuelType = State.Vehicle.Get(vehicle, 'fuelType')

    return fuelType or CalculateFuelType(vehicle)
end
exports('GetVehicleFuelType', GetVehicleFuelType)

SetVehicleFuel = function(vehicle, fuel)
    assert(vehicle and DoesEntityExist(vehicle), 'Parameter "vehicle" is nil or the Vehicle does not exist')
    fuel = tonumber(fuel) + 0.0

    Entity(vehicle).state:set('fuel', fuel, true)
    SetVehicleFuelLevel(vehicle, fuel)
end
exports('SetVehicleFuel', SetVehicleFuel)

GetVehicleFuel = function(vehicle)
    assert(vehicle and DoesEntityExist(vehicle), 'Parameter "vehicle" is nil or the Vehicle does not exist')

    if not Entity(vehicle).state.fuel then
        SetVehicleFuel(vehicle, GetVehicleFuelLevel(vehicle))
    end

    return Entity(vehicle).state.fuel
end
exports('GetVehicleFuel', GetVehicleFuel)

SetEngineFailure = function(vehicle)
    assert(vehicle and DoesEntityExist(vehicle), 'Parameter "vehicle" is nil or the Vehicle does not exist')
    if State.Vehicle.Get(vehicle, 'engineFailure') then return end

    if State.Vehicle.Get(vehicle, 'isFuelingTypeValue') < Config.WrongFuel.liter then 
        State.Vehicle.Set(vehicle, 'isFuelingType', nil)
        State.Vehicle.Set(vehicle, 'isFuelingTypeValue', nil)
        return 
    end

    State.Vehicle.Set(vehicle, 'engineFailure', true)
    local engineHealth = GetVehicleEngineHealth(vehicle)

    while DoesEntityExist(vehicle) and GetIsVehicleEngineRunning(vehicle) do
        if not DoesEntityExist(vehicle) then return end
        engineHealth -= 150

        if engineHealth >= 700 then
            CreateThread(function()
				SetVehicleEngineOn(vehicle, false, true, true)
                Wait(500)
                SetVehicleEngineOn(vehicle, true, false, true)
			end)
        end

        if engineHealth <= 500 and engineHealth > 250 then
            CreateThread(function()
				SetVehicleEngineOn(vehicle, false, true, true)
                Wait(500)
                SetVehicleEngineOn(vehicle, true, false, true)
                Wait(150)
                SetVehicleEngineOn(vehicle, false, true, true)
                Wait(100)
                SetVehicleEngineOn(vehicle, true, false, true)
			end)
        end

        if engineHealth <= 250 then
            SetVehicleEngineOn(vehicle, false, true, true)
        end

        if engineHealth <= 50 then
            engineHealth = 50
            break
        end

        SetVehicleEngineHealth(vehicle, engineHealth)

        Wait(1000)
    end

    if not DoesEntityExist(vehicle) then return end

    SetVehicleEngineHealth(vehicle, engineHealth)
    SetVehicleEngineOn(vehicle, false, true, true)

    if (GetResourceState('msk_enginetoggle') == 'started') then
        exports.msk_enginetoggle:SetVehicleDamaged(vehicle, true)
    end
end
exports('SetEngineFailure', SetEngineFailure)

SetEngineRepaired = function(vehicle)
    assert(vehicle and DoesEntityExist(vehicle), 'Parameter "vehicle" is nil or the Vehicle does not exist')

    State.Vehicle.Set(vehicle, 'isFuelingType', nil)
    State.Vehicle.Set(vehicle, 'isFuelingTypeValue', nil)
    State.Vehicle.Set(vehicle, 'engineFailure', false)

    if (GetResourceState('msk_enginetoggle') == 'started') then
        exports.msk_enginetoggle:SetVehicleDamaged(vehicle, false)
    end
end
exports('SetEngineRepaired', SetEngineRepaired)

OverrideEngine = function(vehicle)
    if not DoesEntityExist(vehicle) then return end
    if not State.Vehicle.Get(vehicle, 'engineFailure') then return end

    SetVehicleEngineHealth(vehicle, 50)
    SetVehicleEngineOn(vehicle, false, true, true)

    if (GetResourceState('msk_enginetoggle') == 'started') then
        exports.msk_enginetoggle:SetVehicleDamaged(vehicle, true)
    end
end

logging = function(code, ...)
    if not Config.Debug and code == 'debug' then return end
    MSK.Logging(code, ...)
end