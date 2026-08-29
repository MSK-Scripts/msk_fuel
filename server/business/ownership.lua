----------------------------------------------------------------
-- Who owns a station, and who may do what with it.
--
-- Ownership is stored as the framework identifier in the `owner` column, not as
-- a job: a station is bought by a person, and it has to keep working when that
-- person changes job or when the server has no matching job at all.
--
-- Every permission question goes through Ownership.Has(). Right now that is
-- "the owner may everything, everyone else nothing"; phase 3 adds employees and
-- ranks behind the same function, so no call site has to change.
----------------------------------------------------------------
Ownership = Ownership or {}

---The identifier a station is stored under. Prefers the framework identifier
---(ESX `identifier`, QBCore `citizenid`) so the value matches what the rest of
---the server uses, and falls back to the raw license on standalone setups.
---@param playerId number
---@return string|nil
function Ownership.IdentifierOf(playerId)
    local ok, player = pcall(MSK.GetPlayer, { source = playerId })

    if ok and type(player) == 'table' and type(player.identifier) == 'string' and player.identifier ~= '' then
        return player.identifier
    end

    local identifier = MSK.GetPlayerIdentifier(playerId)

    return (type(identifier) == 'string' and identifier ~= '') and identifier or nil
end

function Ownership.IsOwner(playerId, stationId)
    local def = Stations.Get(stationId)
    if not def or not def.owner then return false end

    return def.owner == Ownership.IdentifierOf(playerId)
end

---Does this player hold `perm` at this station?
---@param playerId number
---@param stationId string
---@param perm string   one of OwnerPerms.PERMS
function Ownership.Has(playerId, stationId, perm)
    if not OwnerPerms.IsPerm(perm) then return false end

    -- The owner is never locked out of their own business.
    if Ownership.IsOwner(playerId, stationId) then return true end

    local identifier = Ownership.IdentifierOf(playerId)
    if not identifier then return false end

    return Employees.PermsOf(stationId, identifier)[perm] == true
end

---Every permission the player holds at a station, for the dashboard to hide
---what it must not offer. The server checks each action again regardless.
function Ownership.PermsOf(playerId, stationId)
    if Ownership.IsOwner(playerId, stationId) then return OwnerPerms.All() end

    local identifier = Ownership.IdentifierOf(playerId)
    if not identifier then return {} end

    return Employees.PermsOf(stationId, identifier)
end

---Is this player allowed to open the dashboard of this station at all? Owner
---always, everyone else only with at least one permission from their rank.
function Ownership.CanOpen(playerId, stationId)
    if Ownership.IsOwner(playerId, stationId) then return true end

    return next(Ownership.PermsOf(playerId, stationId)) ~= nil
end

---Stations this player owns, for a future "my businesses" overview.
---Stations this player can manage: the ones they own plus the ones they are
---employed at with at least one permission. The client hangs its "manage this
---station" target option off this list.
function Ownership.StationsOf(playerId)
    local identifier = Ownership.IdentifierOf(playerId)
    if not identifier then return {} end

    local seen = {}

    for id, def in pairs(Config.Stations or {}) do
        if def.owner == identifier then seen[id] = true end
    end

    for _, id in ipairs(Employees.StationsOf(identifier)) do
        if next(Employees.PermsOf(id, identifier)) ~= nil then seen[id] = true end
    end

    local out = {}
    for id in pairs(seen) do out[#out + 1] = id end

    table.sort(out)
    return out
end

---Pushes the list of stations a player owns to their client. The target
---options ("manage this station") hang off it, and the client has no way to
---know an identifier, so it has to be told.
function Ownership.PushTo(playerId)
    if not playerId or playerId <= 0 then return end

    TriggerClientEvent('msk_fuel:setOwnedStations', playerId, Ownership.StationsOf(playerId))
end

---Same, for a player addressed by identifier rather than by source. Does
---nothing when that player is not online.
function Ownership.PushToIdentifier(identifier)
    if type(identifier) ~= 'string' or identifier == '' then return end

    local ok, player = pcall(MSK.GetPlayerFromIdentifier, identifier)
    if not ok or type(player) ~= 'table' then return end

    local src = tonumber(player.source)
    if src then Ownership.PushTo(src) end
end

local function setOwner(stationId, identifier)
    MySQL.update.await('UPDATE `msk_fuel_stations` SET `owner` = ? WHERE `id` = ?', { identifier, stationId })

    local def = Stations.Get(stationId)
    if def then def.owner = identifier end
end

----------------------------------------------------------------
-- Buying and selling
----------------------------------------------------------------

---@return boolean ok, string|nil err
function Ownership.Buy(playerId, stationId)
    local def = Stations.Get(stationId)
    if not def then return false, 'not_found' end
    if Stations.IsOwned(def) then return false, 'already_owned' end
    if def.purchasable == false then return false, 'not_purchasable' end

    local identifier = Ownership.IdentifierOf(playerId)
    if not identifier then return false, 'no_identifier' end

    local price = Stations.PurchasePrice(def)

    -- PayPrice removes the money and notifies on insufficient funds.
    if not PayPrice(playerId, price) then return false, 'not_enough_money' end

    setOwner(stationId, identifier)
    Employees.SeedRanks(stationId)
    Account.Log(stationId, 'purchase', -price, { by = identifier })

    logging('info', ('Station %s bought by %s for $%s'):format(stationId, identifier, price))
    Ownership.PushTo(playerId)
    Stations.Broadcast()

    return true
end

---Sells the station back to the system. The refund is a share of the purchase
---price; whatever sits on the company account is paid out on top, because it is
---the owner's money and would otherwise vanish with the station.
---@return boolean ok, string|nil err, number|nil payout
function Ownership.Sell(playerId, stationId)
    local def = Stations.Get(stationId)
    if not def then return false, 'not_found' end

    -- Deliberately NOT a rank permission: a manager may rename and run the
    -- station, but selling the business belongs to whoever bought it.
    if not Ownership.IsOwner(playerId, stationId) then return false, 'owner_only' end

    -- Held on to before the owner column is cleared, so the log says who sold.
    local seller = def.owner

    local ratio = tonumber(Config.SellRefundRatio) or 0.6
    local refund = math.floor(Stations.PurchasePrice(def) * math.max(0.0, math.min(ratio, 1.0)))
    local balance = math.floor(Account.Get(stationId))
    local payout = refund + math.max(0, balance)

    -- Empty the account first: the station keeps existing, and a leftover
    -- balance would otherwise be handed to whoever buys it next.
    if balance > 0 then
        Account.Book(stationId, -balance, 'sell_payout', { to = seller })
    end

    setOwner(stationId, nil)

    -- The staff goes with the owner. Ranks stay, so the structure survives for
    -- whoever buys the station next.
    for identifier in pairs(Employees.ListOf(stationId)) do
        Employees.Fire(stationId, identifier)
        Ownership.PushToIdentifier(identifier)
    end

    Account.Log(stationId, 'sold', refund, { to = seller })

    AddMoney(playerId, payout)

    logging('info', ('Station %s sold by %s for $%s'):format(stationId, tostring(seller), payout))
    Ownership.PushTo(playerId)
    Stations.Broadcast()

    return true, nil, payout
end

-- A player who reconnects has to learn what they own before their first pump
-- interaction, and the client cannot ask for it before the framework is ready.
MSK.Register('msk_fuel:owner:myStations', function(src)
    return Ownership.StationsOf(src)
end)
