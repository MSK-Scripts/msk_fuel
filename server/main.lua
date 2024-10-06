RegisterNetEvent('msk_fuel:refillCan', function(price, hasPetrolcan)
    local playerId = source

    if hasPetrolcan then
        local item = exports.ox_inventory:GetCurrentWeapon(playerId)

        if not item or item.name ~= 'WEAPON_PETROLCAN' then return end

        if GetPlayerMoney(playerId) < price then 
            return Config.Notification(playerId, Translate('not_enough_money'), 'error')
        end

        PayPrice(playerId, price)

        item.metadata.durability = 100
		item.metadata.ammo = 100

        exports.ox_inventory:SetMetadata(playerId, item.slot, item.metadata)
        
        Config.Notification(playerId, Translate('refilled_petrolcan', price), 'success')
    else
        local canCarry = exports.ox_inventory:CanCarryItem(playerId, 'WEAPON_PETROLCAN', 1)

        if not canCarry then 
            return Config.Notification(playerId, Translate('cannot_carry_petrolcan'), 'error')
        end

        PayPrice(playerId, price)

        exports.ox_inventory:AddItem(playerId, 'WEAPON_PETROLCAN', 1)
        
        Config.Notification(playerId, Translate('bought_petrolcan', price), 'success')
    end
end)

RegisterNetEvent('msk_fuel:payFuelPrice', function(price, fuel, netId)
    local playerId = source

    if GetPlayerMoney(playerId) < price then 
        return Config.Notification(playerId, Translate('not_enough_money'), 'error')
    end

    PayPrice(playerId, price)
    SetVehicleFuel(netId, fuel)

    Config.Notification(playerId, Translate('vehicle_fuel_success', MSK.Round(fuel), price), 'success')
end)

RegisterNetEvent('msk_fuel:updateFuelCan', function(durability, fuel, netId)
    local playerId = source
    local item = exports.ox_inventory:GetCurrentWeapon(playerId)

    if item and durability > 0 then
		durability = math.floor(item.metadata.durability - durability)
		item.metadata.durability = durability
		item.metadata.ammo = durability

		exports.ox_inventory:SetMetadata(playerId, item.slot, item.metadata)
		SetVehicleFuel(netId, fuel)
	end
end)