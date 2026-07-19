RegisterNetEvent('msk_fuel:refillCan', function(isRefill, coords)
    local playerId = source

    if not CheckRateLimit(playerId, 'refillCan', 500) then return end

    -- Make sure the player is actually at a fuel station (anti-exploit)
    if not IsPlayerNearFuelStation(playerId, coords) then return end

    if isRefill then
        local item = exports.ox_inventory:GetCurrentWeapon(playerId)

        if not item or item.name ~= 'WEAPON_PETROLCAN' then return end

        -- Price is determined serverside, never trust the client
        local price = Config.Petrolcan.refillPrice

        -- PayPrice removes the money and notifies on insufficient funds
        if not PayPrice(playerId, price) then return end

        item.metadata.durability = 100
        item.metadata.ammo = 100

        exports.ox_inventory:SetMetadata(playerId, item.slot, item.metadata)

        Config.Notification(playerId, Translate('refilled_petrolcan', price), 'success')
    else
        -- Price is determined serverside, never trust the client
        local price = Config.Petrolcan.price
        local canCarry = exports.ox_inventory:CanCarryItem(playerId, 'WEAPON_PETROLCAN', 1)

        if not canCarry then
            return Config.Notification(playerId, Translate('cannot_carry_petrolcan'), 'error')
        end

        -- PayPrice removes the money and notifies on insufficient funds
        if not PayPrice(playerId, price) then return end

        exports.ox_inventory:AddItem(playerId, 'WEAPON_PETROLCAN', 1)

        Config.Notification(playerId, Translate('bought_petrolcan', price), 'success')
    end
end)

RegisterNetEvent('msk_fuel:payFuelPrice', function(fuel, netId)
    local playerId = source

    if not CheckRateLimit(playerId, 'payFuelPrice', 500) then return end

    local vehicle = GetVehicleFromNetId(netId)
    if not vehicle then return end

    -- Make sure the player is actually near the vehicle (anti-exploit)
    if not IsPlayerNearVehicle(playerId, vehicle) then return end

    fuel = tonumber(fuel)
    if not fuel then return end

    local currentFuel = GetVehicleFuel(netId)
    local maxFuel = Entity(vehicle).state.maxFuel or 100.0

    -- Clamp the requested fuel to a valid range, never trust the client value
    fuel = math.min(fuel, maxFuel)

    local addedFuel = fuel - currentFuel
    if addedFuel <= 0 then return end

    -- Recalculate the price serverside based on the actually added fuel
    local price = math.ceil(addedFuel / Config.Refill.value) * Config.Refill.price

    -- PayPrice removes the money and notifies on insufficient funds
    if not PayPrice(playerId, price) then return end

    SetVehicleFuel(netId, fuel)

    Config.Notification(playerId, Translate('vehicle_fuel_success', MSK.Round(fuel), price), 'success')
end)

RegisterNetEvent('msk_fuel:updateFuelCan', function(durability, fuel, netId)
    local playerId = source

    if not CheckRateLimit(playerId, 'updateFuelCan', 500) then return end

    local item = exports.ox_inventory:GetCurrentWeapon(playerId)

    if not item or item.name ~= 'WEAPON_PETROLCAN' then return end

    durability = tonumber(durability)
    fuel = tonumber(fuel)
    if not durability or not fuel or durability <= 0 then return end

    local vehicle = GetVehicleFromNetId(netId)
    if not vehicle then return end

    -- Make sure the player is actually near the vehicle (anti-exploit)
    if not IsPlayerNearVehicle(playerId, vehicle) then return end

    -- Clamp the consumed durability to what the can actually has
    local available = item.metadata.ammo or item.metadata.durability or 0
    durability = math.min(durability, available)
    if durability <= 0 then return end

    -- Max fuel that could have been added with the consumed durability
    local maxAddable = (durability / Config.Petrolcan.durabilityTick) * Config.Refill.value
    local currentFuel = GetVehicleFuel(netId)
    local maxFuel = Entity(vehicle).state.maxFuel or 100.0

    fuel = math.min(fuel, currentFuel + maxAddable, maxFuel)
    if fuel <= currentFuel then return end

    -- Round to nearest integer to avoid float drift losing can durability over time
    local newDurability = math.floor((available - durability) + 0.5)
    item.metadata.durability = newDurability
    item.metadata.ammo = newDurability

    exports.ox_inventory:SetMetadata(playerId, item.slot, item.metadata)
    SetVehicleFuel(netId, fuel)
end)
