----------------------------------------------------------------
-- Owner dashboard API.
--
-- Same contract as the admin API: sanitize, check the right AT THIS STATION,
-- write, reload, answer with a fresh payload. The client never decides whether
-- something was allowed, it only decides what to offer.
--
-- Everything here is reachable only while the player is standing at the station
-- in question. Without that check a player could manage their business from the
-- other side of the map, or worse, poke at a station id they do not own.
----------------------------------------------------------------
OwnerApi = OwnerApi or {}

local function fail(err) return { ok = false, err = err } end

----------------------------------------------------------------
-- Statistics straight out of the transaction log. `liters` has its own column,
-- so both figures are a plain SUM over an indexed range.
----------------------------------------------------------------
local function statsFor(stationId, hours)
    local row = MySQL.single.await(
        'SELECT COALESCE(SUM(`amount`), 0) AS revenue, COALESCE(SUM(`liters`), 0) AS liters, COUNT(*) AS sales ' ..
        'FROM `msk_fuel_transactions` ' ..
        "WHERE `station_id` = ? AND `type` IN ('sale', 'sale_neutral') " ..
        'AND `created_at` >= (NOW() - INTERVAL ? HOUR)',
        { stationId, hours }
    ) or {}

    return {
        revenue = tonumber(row.revenue) or 0.0,
        liters = tonumber(row.liters) or 0.0,
        sales = tonumber(row.sales) or 0,
    }
end

local function transactionsFor(stationId, limit)
    local rows = MySQL.query.await(
        'SELECT `type`, `amount`, `liters`, `meta`, `created_at` FROM `msk_fuel_transactions` ' ..
        'WHERE `station_id` = ? ORDER BY `id` DESC LIMIT ?',
        { stationId, limit or 50 }
    ) or {}

    local out = {}

    for _, row in ipairs(rows) do
        local ok, meta = AdminStore.Decode(row.meta)

        out[#out + 1] = {
            type = row.type,
            amount = tonumber(row.amount) or 0.0,
            liters = tonumber(row.liters) or 0.0,
            at = tostring(row.created_at),
            meta = (ok and type(meta) == 'table') and meta or {},
        }
    end

    return out
end

---Payload behind the owner dashboard. Only ever built for a station the player
---actually holds a permission at.
function OwnerApi.BuildBootstrap(src, stationId)
    local def = Stations.Get(stationId)
    if not def then return nil end

    local ratio = math.max(0.0, math.min(tonumber(Config.SellRefundRatio) or 0.6, 1.0))

    return {
        locale = Config.Locale,
        perms = Ownership.PermsOf(src, stationId),
        permKeys = OwnerPerms.PERMS,
        fuelTypes = Stations.FuelTypes(def),
        priceModes = AdminPerms.PRICE_MODES,
        station = {
            id = stationId,
            label = def.label or stationId,
            balance = Account.Get(stationId),
            purchasePrice = Stations.PurchasePrice(def),
            sellPrice = math.floor(Stations.PurchasePrice(def) * ratio),
        },
        stock = Stock.Payload(stationId),
        basePrices = Config.BasePrices or {},
        priceLimits = Config.PriceLimits or {},
        stats = {
            day = statsFor(stationId, 24),
            week = statsFor(stationId, 24 * 7),
        },
        transactions = transactionsFor(stationId, 50),
        ranks = Employees.RanksPayload(stationId),
        employees = Employees.ListPayload(stationId),
        pumps = Maintenance.Payload(stationId),
        maintenance = {
            enabled = Maintenance.IsEnabled(),
            mechanic = Maintenance.HasMechanic(stationId),
            mechanicPrice = math.max(0, math.floor(tonumber((Config.Maintenance or {}).mechanicUnlockPrice) or 0)),
            failThreshold = tonumber((Config.Maintenance or {}).failThreshold) or 15,
            slowThreshold = tonumber((Config.Maintenance or {}).slowThreshold) or 50,
        },
        supply = {
            npcUnlocked = Supply.IsNpcUnlocked(stationId),
            npcUnlockPrice = math.max(0, math.floor(tonumber(Config.NpcUnlockPrice) or 0)),
            autoRestock = def.autoRestock == true,
            wholesale = Config.Wholesale or {},
            npcSurcharge = tonumber(Config.NpcSurcharge) or 1.0,
            vehicles = Config.DeliveryVehicles or {},
            free = (function()
                local out = {}
                for _, fuelType in ipairs(Stations.FuelTypes(def)) do
                    out[fuelType] = Supply.FreeSpace(stationId, fuelType)
                end
                return out
            end)(),
        },
        -- Only the owner may sell, and only the owner may hire someone into a
        -- rank that would outrank them.
        isOwner = Ownership.IsOwner(src, stationId),
    }
end

local function ok(src, stationId)
    return { ok = true, data = OwnerApi.BuildBootstrap(src, stationId) }
end

----------------------------------------------------------------
-- Shared entry check for every owner callback: the payload has to name a real
-- station, the player has to be standing at it, and they have to hold the right.
----------------------------------------------------------------
local function gate(src, data, perm)
    if type(data) ~= 'table' then return nil, 'bad_input' end

    local stationId = data.id
    if type(stationId) ~= 'string' or not Stations.Get(stationId) then return nil, 'not_found' end

    -- Standing at the station, not just claiming to be. `coords` is the pump the
    -- player interacted with; ResolveStation checks the player is really there
    -- and resolves which zone it belongs to.
    local atStation = ResolveStation(src, data.coords, Config.MaxStationDistance)
    if atStation ~= stationId then return nil, 'too_far_away' end

    if perm and not Ownership.Has(src, stationId, perm) then return nil, 'no_permission' end

    return stationId
end

----------------------------------------------------------------
-- Callbacks
----------------------------------------------------------------

-- Buying a station. No owner permission to check (nobody owns it yet), but the
-- player still has to be at the pump and the station has to be for sale.
MSK.Register('msk_fuel:owner:buy', function(src, data)
    if not CheckRateLimit(src, 'stationTrade', 2000) then return fail('too_fast') end

    local stationId, err = gate(src, data, nil)
    if not stationId then return fail(err) end

    local bought, buyErr = Ownership.Buy(src, stationId)
    if not bought then return fail(buyErr) end

    local def = Stations.Get(stationId)
    Config.Notification(src, Translate('station_bought', def.label or stationId), 'success')

    return ok(src, stationId)
end)

-- Opening the dashboard does not need a specific permission, it needs ANY: an
-- employee who may only order fuel still has a dashboard, it just shows less.
MSK.Register('msk_fuel:owner:bootstrap', function(src, data)
    local stationId, err = gate(src, data, nil)
    if not stationId then return fail(err) end

    if not Ownership.CanOpen(src, stationId) then return fail('no_permission') end

    return ok(src, stationId)
end)

MSK.Register('msk_fuel:owner:rename', function(src, data)
    local stationId, err = gate(src, data, 'manage')
    if not stationId then return fail(err) end

    -- Trimmed by hand on purpose: MSK.Trim without its second argument strips
    -- EVERY space, inner ones included, which would eat station names.
    local label = type(data.label) == 'string' and data.label:match('^%s*(.-)%s*$') or nil
    if not label or #label == 0 or #label > 60 then return fail('bad_label') end

    MySQL.update.await('UPDATE `msk_fuel_stations` SET `label` = ? WHERE `id` = ?', { label, stationId })
    Stations.Get(stationId).label = label

    -- The name lives on the blip, so everyone has to see the change.
    Stations.Broadcast()

    return ok(src, stationId)
end)

MSK.Register('msk_fuel:owner:sell', function(src, data)
    if not CheckRateLimit(src, 'stationTrade', 2000) then return fail('too_fast') end

    local stationId, err = gate(src, data, 'manage')
    if not stationId then return fail(err) end

    local label = Stations.Get(stationId).label or stationId
    local sold, sellErr, payout = Ownership.Sell(src, stationId)
    if not sold then return fail(sellErr) end

    Config.Notification(src, Translate('station_sold', label, payout), 'success')

    -- Nothing left to show: the dashboard closes on a payload-less answer.
    return { ok = true, closed = true }
end)

----------------------------------------------------------------
-- Company account
----------------------------------------------------------------
local function amountOf(value)
    local amount = math.floor(tonumber(value) or 0)
    if amount <= 0 then return nil end

    return amount
end

MSK.Register('msk_fuel:owner:deposit', function(src, data)
    local stationId, err = gate(src, data, 'deposit')
    if not stationId then return fail(err) end

    local amount = amountOf(data.amount)
    if not amount then return fail('bad_amount') end

    -- Money leaves the player first: a failed booking must never create money.
    if not PayPrice(src, amount) then return fail('not_enough_money') end

    local booked = Account.Book(stationId, amount, 'deposit', { by = Ownership.IdentifierOf(src) })

    if not booked then
        AddMoney(src, amount)
        return fail('booking_failed')
    end

    return ok(src, stationId)
end)

MSK.Register('msk_fuel:owner:withdraw', function(src, data)
    local stationId, err = gate(src, data, 'withdraw')
    if not stationId then return fail(err) end

    local amount = amountOf(data.amount)
    if not amount then return fail('bad_amount') end

    if Account.Get(stationId) < amount then return fail('not_enough_balance') end

    -- Book first, pay out second: a booking that fails leaves no money behind.
    local booked = Account.Book(stationId, -amount, 'withdraw', { by = Ownership.IdentifierOf(src) })
    if not booked then return fail('not_enough_balance') end

    AddMoney(src, amount)

    return ok(src, stationId)
end)

----------------------------------------------------------------
-- Prices
----------------------------------------------------------------
MSK.Register('msk_fuel:owner:pricing', function(src, data)
    local stationId, err = gate(src, data, 'set_prices')
    if not stationId then return fail(err) end

    local fuelType = tostring(data.fuelType or ''):lower()
    if not AdminPerms.IsFuelType(fuelType) then return fail('bad_fueltype') end
    if not Stations.SellsFuelType(Stations.Get(stationId), fuelType) then return fail('no_tank') end

    local mode = (data.mode == 'fixed') and 'fixed' or 'dynamic'

    -- Stock.SetPricing clamps the price to the admin limits, so an owner can
    -- never price themselves outside the range the server allows.
    if not Stock.SetPricing(stationId, fuelType, mode, data.fixedPrice) then return fail('no_tank') end

    Stations.MarkDirty()

    return ok(src, stationId)
end)

----------------------------------------------------------------
-- Staff and ranks
----------------------------------------------------------------

-- Players the dashboard can offer for hiring. Only who is online: an offline
-- player has no name to show and could not be told they were hired.
MSK.Register('msk_fuel:owner:onlinePlayers', function(src, data)
    local stationId, err = gate(src, data, 'hire')
    if not stationId then return { ok = false, err = err } end

    local out = {}

    for _, player in pairs(MSK.GetPlayers() or {}) do
        local playerId = tonumber(player.source)
        local identifier = playerId and Ownership.IdentifierOf(playerId) or nil

        if identifier then
            out[#out + 1] = {
                source = playerId,
                identifier = identifier,
                name = player.name or ('ID %s'):format(playerId),
                employed = Employees.Get(stationId, identifier) ~= nil,
            }
        end
    end

    table.sort(out, function(a, b) return a.source < b.source end)

    return { ok = true, players = out }
end)

MSK.Register('msk_fuel:owner:hire', function(src, data)
    local stationId, err = gate(src, data, 'hire')
    if not stationId then return fail(err) end

    -- Addressed by server id, not by identifier: the dashboard shows who is
    -- online, and a raw identifier from the client would let anyone hire anyone.
    local targetId = tonumber(data.target)
    if not targetId or targetId <= 0 then return fail('bad_target') end

    local identifier = Ownership.IdentifierOf(targetId)
    if not identifier then return fail('bad_target') end

    local rankId = type(data.rankId) == 'string' and data.rankId or nil
    if not rankId then return fail('bad_rank') end

    local hired, hireErr = Employees.Hire(stationId, identifier, rankId)
    if not hired then return fail(hireErr) end

    local label = Stations.Get(stationId).label or stationId
    Config.Notification(targetId, Translate('hired_at_station', label), 'success')

    -- The new employee gets their target option right away.
    Ownership.PushTo(targetId)

    return ok(src, stationId)
end)

MSK.Register('msk_fuel:owner:fire', function(src, data)
    local stationId, err = gate(src, data, 'hire')
    if not stationId then return fail(err) end

    local identifier = type(data.identifier) == 'string' and data.identifier or nil
    if not identifier or not Employees.Get(stationId, identifier) then return fail('not_employed') end

    Employees.Fire(stationId, identifier)

    local label = Stations.Get(stationId).label or stationId
    local found, player = pcall(MSK.GetPlayerFromIdentifier, identifier)

    if found and type(player) == 'table' and tonumber(player.source) then
        Config.Notification(tonumber(player.source), Translate('fired_from_station', label), 'error')
        Ownership.PushTo(tonumber(player.source))
    end

    return ok(src, stationId)
end)

MSK.Register('msk_fuel:owner:rank:save', function(src, data)
    local stationId, err = gate(src, data, 'hire')
    if not stationId then return fail(err) end

    local rankId = type(data.rankId) == 'string' and data.rankId or nil
    if not rankId or #rankId == 0 or #rankId > 60 or not rankId:match('^[%w_%-]+$') then return fail('bad_rank') end

    local label = type(data.label) == 'string' and data.label:match('^%s*(.-)%s*$') or nil
    if not label or #label == 0 or #label > 60 then return fail('bad_label') end

    -- Only the owner hands out permissions, so a manager cannot promote
    -- themselves or a friend past what the owner intended.
    local existing = Employees.Rank(stationId, rankId)
    local perms = existing and existing.perms or {}

    if Ownership.IsOwner(src, stationId) and type(data.perms) == 'table' then
        perms = {}

        for _, perm in ipairs(OwnerPerms.PERMS) do
            if data.perms[perm] == true then perms[perm] = true end
        end
    end

    Employees.SaveRank(stationId, rankId, {
        label = label,
        salary = math.max(0, math.floor(tonumber(data.salary) or 0)),
        delivery_bonus = math.max(0, math.floor(tonumber(data.deliveryBonus) or 0)),
        perms = perms,
    })

    return ok(src, stationId)
end)

MSK.Register('msk_fuel:owner:rank:delete', function(src, data)
    local stationId, err = gate(src, data, 'hire')
    if not stationId then return fail(err) end

    local rankId = type(data.rankId) == 'string' and data.rankId or nil
    if not rankId or not Employees.Rank(stationId, rankId) then return fail('bad_rank') end

    local deleted, delErr = Employees.DeleteRank(stationId, rankId)
    if not deleted then return fail(delErr) end

    return ok(src, stationId)
end)

-- Moving an existing employee to another rank. Separate from hiring because it
-- addresses by identifier: the employee is already on the list, so the
-- identifier is one we put there ourselves, and they may well be offline.
MSK.Register('msk_fuel:owner:setRank', function(src, data)
    local stationId, err = gate(src, data, 'hire')
    if not stationId then return fail(err) end

    local identifier = type(data.identifier) == 'string' and data.identifier or nil
    if not identifier or not Employees.Get(stationId, identifier) then return fail('not_employed') end

    local rankId = type(data.rankId) == 'string' and data.rankId or nil
    if not rankId or not Employees.Rank(stationId, rankId) then return fail('bad_rank') end

    local moved, moveErr = Employees.Hire(stationId, identifier, rankId)
    if not moved then return fail(moveErr) end

    -- A rank change can add or remove every permission, including the one that
    -- puts the "manage this station" option on their pump.
    Ownership.PushToIdentifier(identifier)

    return ok(src, stationId)
end)

----------------------------------------------------------------
-- Supply
----------------------------------------------------------------
MSK.Register('msk_fuel:owner:npc:unlock', function(src, data)
    local stationId, err = gate(src, data, 'order_fuel')
    if not stationId then return fail(err) end

    local unlocked, unlockErr = Supply.UnlockNpc(stationId)
    if not unlocked then return fail(unlockErr) end

    return ok(src, stationId)
end)

-- Owner-side switch for the automatic NPC restock. Requires the driver to be
-- unlocked, otherwise the flag would sit there doing nothing.
MSK.Register('msk_fuel:owner:autoRestock', function(src, data)
    local stationId, err = gate(src, data, 'order_fuel')
    if not stationId then return fail(err) end

    local enable = data.enable == true
    if enable and not Supply.IsNpcUnlocked(stationId) then return fail('npc_locked') end

    Supply.SetStationFlag(stationId, 'autoRestock', enable)

    return ok(src, stationId)
end)

MSK.Register('msk_fuel:owner:restock', function(src, data)
    local stationId, err = gate(src, data, 'order_fuel')
    if not stationId then return fail(err) end

    local fuelType = tostring(data.fuelType or ''):lower()
    if not AdminPerms.IsFuelType(fuelType) then return fail('bad_fueltype') end

    local bought, buyErr, liters, cost = Supply.OrderInstant(stationId, fuelType, data.amount)
    if not bought then return fail(buyErr) end

    Config.Notification(src, Translate('restock_done', liters, cost), 'success')

    return ok(src, stationId)
end)

MSK.Register('msk_fuel:owner:delivery:start', function(src, data)
    local stationId, err = gate(src, data, 'order_fuel')
    if not stationId then return fail(err) end

    local fuelType = tostring(data.fuelType or ''):lower()
    if not AdminPerms.IsFuelType(fuelType) then return fail('bad_fueltype') end

    local vehicleType = type(data.vehicleType) == 'string' and data.vehicleType or nil
    if not vehicleType then return fail('bad_vehicle') end

    local started, startErr = Delivery.StartOrder(src, stationId, fuelType, data.amount, vehicleType)
    if not started then return fail(startErr) end

    -- The dashboard closes: the job happens out in the world, not in a menu.
    return { ok = true, closed = true }
end)

-- Public job at an unowned station. Taken at the pump, so there is no dashboard
-- and no permission, only the distance check.
MSK.Register('msk_fuel:delivery:public', function(src, data)
    if type(data) ~= 'table' then return fail('bad_input') end

    local stationId = data.id
    if type(stationId) ~= 'string' or not Stations.Get(stationId) then return fail('not_found') end

    if ResolveStation(src, data.coords, Config.MaxStationDistance) ~= stationId then
        return fail('too_far_away')
    end

    local fuelType = tostring(data.fuelType or ''):lower()
    if not AdminPerms.IsFuelType(fuelType) then return fail('bad_fueltype') end

    local started, err = Delivery.StartPublic(src, stationId, fuelType)
    if not started then return fail(err) end

    return { ok = true }
end)

----------------------------------------------------------------
-- Pump maintenance
----------------------------------------------------------------
MSK.Register('msk_fuel:owner:pump:repair', function(src, data)
    local stationId, err = gate(src, data, 'repair')
    if not stationId then return fail(err) end

    local pumpKey = type(data.pumpKey) == 'string' and data.pumpKey or nil
    if not pumpKey then return fail('not_found') end

    local repaired, repairErr, cost = Maintenance.Repair(stationId, pumpKey, true)
    if not repaired then return fail(repairErr) end

    Config.Notification(src, Translate('pump_repaired', cost), 'success')

    return ok(src, stationId)
end)

MSK.Register('msk_fuel:owner:mechanic:unlock', function(src, data)
    local stationId, err = gate(src, data, 'repair')
    if not stationId then return fail(err) end

    local unlocked, unlockErr = Maintenance.UnlockMechanic(stationId)
    if not unlocked then return fail(unlockErr) end

    return ok(src, stationId)
end)
