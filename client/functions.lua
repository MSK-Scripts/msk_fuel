GetPlayerMoney = function()
    return exports.ox_inventory:GetItemCount('money')
end

IsFuelTypeAtFuelStation = function(entity, fuelType)
    local pumpModel = GetEntityModel(entity)

    if not Config.FuelStationTypes[pumpModel] then
        return false
    end

    if not MSK.Table.Contains(Config.FuelStationTypes[pumpModel], fuelType) then
        return false
    end

    return true
end
exports('IsFuelTypeAtFuelStation', IsFuelTypeAtFuelStation)

GetFuelTypesFromModel = function(entity)
    local pumpModel = GetEntityModel(entity)

    if not Config.FuelStationTypes[pumpModel] then
        return false
    end

    return Config.FuelStationTypes[pumpModel]
end
exports('GetFuelTypesFromModel', GetFuelTypesFromModel)

GetVehicleFuelTankBoneIndex = function(vehicle)
    local class = GetVehicleClass(vehicle)
    local position = {x = 0.0, y = 0.0, z = 0.0}
    local tankBoneIndex, tankBoneName = -1, 'petrolcap'
    local tankBones = {
        "petrolcap",
        "petroltank_l",
        "hub_lr",
        "handle_dside_r",
        "engine",
    }

    if class == 13 then
        return tankBoneIndex, position
    end

    if class == 8 then -- Motorcycles
        tankBones = {
            "petrolcap",
            "petroltank",
            "engine",
        }
    elseif class == 15 then -- Helicopters
        tankBones = {
            "petrolcap",
            "petroltank",
            "petroltank_l",
            "hub_lr",
            "handle_dside_r",
            "engine",
        }

        position = {x = 0.0, y = 0.0, z = -0.3}

    elseif class == 16 then -- Planes
        tankBones = {
            "petrolcap",
            "petroltank",
            "petroltank_l",
            "hub_lr",
            "handle_dside_r",
            "engine",
        }
    end

    for i=1, #tankBones do
        local boneIndex = GetEntityBoneIndexByName(vehicle, tankBones[i])

        if boneIndex ~= -1 then
            tankBoneIndex = boneIndex
            tankBoneName = tankBones[i]

            if tankBoneName == "handle_dside_r" then
                position = {x = 0.1, y = -0.5, z = -0.6}
            end

            break
        end
    end

    if AdjustBonePosition then
        local newPos = AdjustBonePosition(vehicle, tankBoneIndex, tankBoneName)

        if newPos then
            position = newPos
        end
    end

    return tankBoneIndex, position
end
exports('GetVehicleFuelTankBoneIndex', GetVehicleFuelTankBoneIndex)

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

    return typeOfFuel
end
exports('IsVehicleGas', IsVehicleGas)

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

    return typeOfFuel
end
exports('IsVehicleDiesel', IsVehicleDiesel)

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

    return typeOfFuel
end
exports('IsVehicleKerosin', IsVehicleKerosin)

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

    return typeOfFuel
end
exports('IsVehicleElectric', IsVehicleElectric)

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

SetVehicleMaxFuel = function(vehicle, maxFuel)
    assert(vehicle and DoesEntityExist(vehicle), 'Parameter "vehicle" is nil or the Vehicle does not exist')

    Entity(vehicle).state:set('maxFuel', maxFuel, true)
    SetVehicleHandlingFloat(vehicle, 'CHandlingData', 'fPetrolTankVolume', maxFuel)
end
exports('SetVehicleMaxFuel', SetVehicleMaxFuel)

GetVehicleMaxFuel = function(vehicle)
    assert(vehicle and DoesEntityExist(vehicle), 'Parameter "vehicle" is nil or the Vehicle does not exist')

    if not Entity(vehicle).state.maxFuel then
        local maxFuel = GetVehicleHandlingFloat(vehicle, "CHandlingData", "fPetrolTankVolume")

        Entity(vehicle).state:set('maxFuel', maxFuel, true)
    end

    return Entity(vehicle).state.maxFuel
end
exports('GetVehicleMaxFuel', GetVehicleMaxFuel)

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
exports('OverrideEngine', OverrideEngine)

logging = function(code, ...)
    if not Config.Debug and code == 'debug' then return end
    MSK.Logging(code, ...)
end