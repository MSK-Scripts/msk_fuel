----------------------------------------------------------------
-- How much fuel a full petrolcan holds, derived from the same two config values
-- the fueling loop uses, so the can never carries more liters than it can pour.
----------------------------------------------------------------
local function petrolcanLiters(durability)
    local tick = tonumber(Config.Petrolcan.durabilityTick) or 1.3
    if tick <= 0 then return 0.0 end

    return (math.max(0, tonumber(durability) or 0) / tick) * (tonumber(Config.Refill.value) or 0.5)
end

-- Takes the liters out of the station tank and books the money. A station that
-- cannot deliver the full amount blocks the sale outright: a half-filled can is
-- worse than a refused one, because the player already paid the full price.
---@return boolean ok
local function sellPetrolcanFuel(playerId, stationId, liters, price, kind)
    if not stationId then return true end

    local def = Stations.Get(stationId)

    -- Petrolcans hold petrol. A station selling only kerosene (an airport tank)
    -- has nothing to fill them with.
    if not Stations.SellsFuelType(def, 'gas') then
        Config.Notification(playerId, Translate('station_no_petrolcan'), 'error')
        return false
    end

    if not Stock.Has(stationId, 'gas', liters) then
        Config.Notification(playerId, Translate('station_sold_out', Translate('gas')), 'error')
        return false
    end

    Stock.Consume(stationId, 'gas', liters)
    Account.BookSale(stationId, price, { kind = kind, liters = liters })
    Stations.MarkDirty()

    return true
end

RegisterNetEvent('msk_fuel:refillCan', function(isRefill, coords)
    local playerId = source

    if not CheckRateLimit(playerId, 'refillCan', 500) then return end

    -- Make sure the player is actually at a fuel station (anti-exploit). The
    -- station is resolved from the same check, so the money and the fuel end up
    -- at the station the player is really standing at.
    local stationId = ResolveStation(playerId, coords, Config.MaxStationDistance)
    if not stationId then return end

    if isRefill then
        local item = exports.ox_inventory:GetCurrentWeapon(playerId)

        if not item or item.name ~= 'WEAPON_PETROLCAN' then return end

        -- Price is determined serverside, never trust the client
        local price = Config.Petrolcan.refillPrice
        local missing = 100 - math.max(0, tonumber(item.metadata.ammo) or 0)

        if missing <= 0 then
            return Config.Notification(playerId, Translate('petrolcan_already_full'), 'info')
        end

        if not sellPetrolcanFuel(playerId, stationId, petrolcanLiters(missing), price, 'petrolcan_refill') then return end

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

        -- A bought can comes full, so it costs the station a full can of fuel.
        if not sellPetrolcanFuel(playerId, stationId, petrolcanLiters(100), price, 'petrolcan_buy') then return end

        -- PayPrice removes the money and notifies on insufficient funds
        if not PayPrice(playerId, price) then return end

        exports.ox_inventory:AddItem(playerId, 'WEAPON_PETROLCAN', 1)

        Config.Notification(playerId, Translate('bought_petrolcan', price), 'success')
    end
end)

RegisterNetEvent('msk_fuel:payFuelPrice', function(fuel, netId, fuelType, pumpCoords)
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

    ----------------------------------------------------------------
    -- Which station is this? The pump the player used decides the price and
    -- whose tank the fuel comes out of. The nozzle can be dragged as far as the
    -- vehicle type allows, so that is the distance the pump coords are checked
    -- against, not the much tighter petrolcan radius.
    ----------------------------------------------------------------
    local stationId, def = ResolveStation(playerId, pumpCoords, GetMaxFuelingDistance(vehicle))
    local pumpAt = ToCoords(pumpCoords)
    local pricePerLiter = Pricing.Fallback()

    if type(fuelType) ~= 'string' or not AdminPerms.IsFuelType(fuelType) then
        fuelType = Config.DefaultFuelType
    end

    if stationId then
        -- A station that does not sell this fuel type never had a pump for it.
        if not Stations.SellsFuelType(def, fuelType) then return end

        -- A pump worn down past the failure threshold serves nobody until it is
        -- repaired. The client greys it out as well; this is the check that
        -- counts.
        if pumpAt and Maintenance.IsBroken(stationId, pumpAt) then
            return Config.Notification(playerId, Translate('pump_broken'), 'error')
        end

        local available = Stock.Get(stationId, fuelType)

        if available <= 0 then
            return Config.Notification(playerId, Translate('station_sold_out', Translate(fuelType)), 'error')
        end

        -- Empty tank in the middle of fueling: the player gets (and pays for)
        -- what was left, not what the client asked for.
        if addedFuel > available then
            addedFuel = available
            fuel = currentFuel + addedFuel
        end

        pricePerLiter = Pricing.Get(stationId, fuelType)
    end

    -- Recalculate the price serverside based on the actually added fuel
    local price = math.ceil(addedFuel * pricePerLiter)

    -- PayPrice removes the money and notifies on insufficient funds
    if not PayPrice(playerId, price) then return end

    if stationId then
        Stock.Consume(stationId, fuelType, addedFuel)
        Account.BookSale(stationId, price, { kind = 'refuel', fuelType = fuelType, liters = addedFuel })

        -- Every sale is a chance for the pump to wear a little. This also
        -- registers a pump the first time it is ever used.
        if pumpAt then Maintenance.Wear(stationId, pumpAt) end

        Stations.MarkDirty()
    end

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
