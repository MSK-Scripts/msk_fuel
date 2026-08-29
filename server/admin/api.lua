AdminApi = AdminApi or {}

----------------------------------------------------------------
-- Input sanitisation. NEVER trust client structures: every field is coerced and
-- whitelisted before it goes anywhere near the database.
----------------------------------------------------------------
local ID_PATTERN = '^[%w_%-]+$'

local function num(v, default)
    local n = tonumber(v)
    if n == nil then return default end
    return n + 0.0
end

local function int(v, default)
    local n = tonumber(v)
    if n == nil then return default end
    return math.floor(n)
end

local function bool(v) return v == true end

local function str(v, max)
    if type(v) ~= 'string' then return nil end
    max = max or 120
    if #v > max then v = v:sub(1, max) end
    return v
end

local function oneOf(value, list, fallback)
    if type(value) == 'string' then
        for _, v in ipairs(list) do
            if v == value then return value end
        end
    end
    return fallback
end

local function coord(c)
    if type(c) ~= 'table' then return nil end

    local x, y, z = tonumber(c.x), tonumber(c.y), tonumber(c.z)
    if not (x and y and z) then return nil end
    if math.abs(x) > 30000 or math.abs(y) > 30000 or z < -2000 or z > 20000 then return nil end

    return { x = x + 0.0, y = y + 0.0, z = z + 0.0, w = num(c.w, 0.0) }
end

local function fuelTypeList(t)
    if type(t) ~= 'table' then return nil end

    local out, seen = {}, {}

    for _, v in ipairs(t) do
        local key = tostring(v):lower()
        if AdminPerms.IsFuelType(key) and not seen[key] then
            seen[key] = true
            out[#out + 1] = key
        end
    end

    if #out == 0 then return nil end
    return out
end

local function capacityTable(t)
    if type(t) ~= 'table' then return nil end

    local out = {}

    for _, fuelType in ipairs(AdminPerms.FUEL_TYPES) do
        local v = tonumber(t[fuelType])
        if v then out[fuelType] = math.max(0, math.floor(v)) end
    end

    if next(out) == nil then return nil end
    return out
end

function AdminApi.SanitizeStation(input)
    if type(input) ~= 'table' then return nil, 'bad_input' end

    local id = input.id
    if type(id) ~= 'string' or #id == 0 or #id > 60 or not id:match(ID_PATTERN) then return nil, 'bad_id' end

    local coords = coord(input.coords)
    if not coords then return nil, 'bad_coords' end

    local fuelTypes = fuelTypeList(input.fuelTypes)
    if not fuelTypes then return nil, 'bad_fueltypes' end

    return {
        id = id,
        label = str(input.label, 120) or id,
        coords = coords,
        -- A zone smaller than a few units would never catch a pump, a huge one
        -- would swallow its neighbours.
        radius = math.max(5.0, math.min(num(input.radius, 60.0), 300.0)),
        blip = input.blip ~= false,
        fuelTypes = fuelTypes,
        capacity = capacityTable(input.capacity),
        purchasable = input.purchasable ~= false,
        purchasePrice = math.max(0, int(input.purchasePrice, tonumber(Config.DefaultPurchasePrice) or 250000)),
    }
end

----------------------------------------------------------------
-- Settings
----------------------------------------------------------------
local function themeTable(t)
    local out = {}

    for _, key in ipairs(AdminPerms.THEME_KEYS) do
        local v = type(t) == 'table' and t[key] or nil
        out[key] = (type(v) == 'string' and v:match('^#%x%x%x%x%x%x$')) and v or AdminPerms.DEFAULT_THEME[key]
    end

    return out
end

local function priceMap(t, fallback)
    local out = {}

    for _, fuelType in ipairs(AdminPerms.FUEL_TYPES) do
        local v = tonumber(type(t) == 'table' and t[fuelType] or nil)
        out[fuelType] = v and math.max(0.0, v) or (fallback[fuelType] or 1.0)
    end

    return out
end

local function limitMap(t)
    local out = {}

    for _, fuelType in ipairs(AdminPerms.FUEL_TYPES) do
        local cur = (Config.PriceLimits or {})[fuelType] or {}
        local given = type(t) == 'table' and t[fuelType] or nil
        local min = num(type(given) == 'table' and given.min or nil, tonumber(cur.min) or 0.01)
        local max = num(type(given) == 'table' and given.max or nil, tonumber(cur.max) or 100.0)

        min = math.max(0.01, min)
        max = math.max(min, max)

        out[fuelType] = { min = min, max = max }
    end

    return out
end

function AdminApi.SanitizeSettings(patch)
    local clean = {}

    if patch.Locale ~= nil then clean.Locale = str(patch.Locale, 10) or Config.Locale end
    if patch.Debug ~= nil then clean.Debug = bool(patch.Debug) end
    if patch.VersionChecker ~= nil then clean.VersionChecker = bool(patch.VersionChecker) end

    if patch.adminCommand ~= nil then
        local cmd = str(patch.adminCommand, 40)
        if cmd and cmd:match('^[%w_%-]+$') then clean.adminCommand = cmd end
    end

    if patch.Theme ~= nil then clean.Theme = themeTable(patch.Theme) end
    if patch.BasePrices ~= nil then clean.BasePrices = priceMap(patch.BasePrices, Config.BasePrices or {}) end
    if patch.PriceLimits ~= nil then clean.PriceLimits = limitMap(patch.PriceLimits) end

    if patch.Market ~= nil and type(patch.Market) == 'table' then
        local m = Config.Market or {}
        clean.Market = {
            kStock = math.max(0.0, num(patch.Market.kStock, m.kStock or 0.0)),
            kDemand = math.max(0.0, num(patch.Market.kDemand, m.kDemand or 0.0)),
            demandNorm = math.max(1, int(patch.Market.demandNorm, m.demandNorm or 5000)),
            drift = math.max(0.0, math.min(num(patch.Market.drift, m.drift or 0.0), 1.0)),
            decay = math.max(0.0, math.min(num(patch.Market.decay, m.decay or 0.5), 1.0)),
            tickMinutes = math.max(1, int(patch.Market.tickMinutes, m.tickMinutes or 60)),
        }
    end

    if patch.DefaultCapacity ~= nil and type(patch.DefaultCapacity) == 'table' then
        local out = {}
        for _, fuelType in ipairs(AdminPerms.FUEL_TYPES) do
            out[fuelType] = math.max(0, int(patch.DefaultCapacity[fuelType], (Config.DefaultCapacity or {})[fuelType] or 10000))
        end
        clean.DefaultCapacity = out
    end

    if patch.NeutralIncome ~= nil and type(patch.NeutralIncome) == 'table' then
        clean.NeutralIncome = {
            mode = oneOf(patch.NeutralIncome.mode, { 'void', 'society' }, 'void'),
            societyName = str(patch.NeutralIncome.societyName, 60) or 'society_fuel',
        }
    end

    if patch.DefaultPurchasePrice ~= nil then
        clean.DefaultPurchasePrice = math.max(0, int(patch.DefaultPurchasePrice, Config.DefaultPurchasePrice or 250000))
    end

    -- A refund above 1.0 would turn buying and reselling into a money printer.
    if patch.SellRefundRatio ~= nil then
        clean.SellRefundRatio = math.max(0.0, math.min(num(patch.SellRefundRatio, Config.SellRefundRatio or 0.6), 1.0))
    end

    if patch.MaxStationBalance ~= nil then
        clean.MaxStationBalance = math.max(0, int(patch.MaxStationBalance, Config.MaxStationBalance or 0))
    end

    return clean
end

----------------------------------------------------------------
-- Payloads
----------------------------------------------------------------
function AdminApi.SettingsPayload()
    local out = {}

    for _, key in ipairs(AdminPerms.SETTINGS_KEYS) do
        out[key] = Config[key]
    end

    out.dashboardGroups = Config.dashboardGroups or {}
    return out
end

-- One dashboard row per station: the definition plus everything the admin needs
-- to judge it at a glance (owner, balance, tanks).
function AdminApi.StationsArray()
    local out = {}

    for id, def in pairs(Config.Stations or {}) do
        local coords = Stations.Coords(def)

        out[#out + 1] = {
            id = id,
            label = def.label or id,
            coords = coords and { x = coords.x, y = coords.y, z = coords.z } or nil,
            radius = Stations.Radius(def),
            blip = def.blip ~= false,
            fuelTypes = Stations.FuelTypes(def),
            capacity = def.capacity,
            purchasable = def.purchasable ~= false,
            purchasePrice = Stations.PurchasePrice(def),
            owner = def.owner,
            balance = tonumber(def.balance) or 0.0,
            stock = Stock.Payload(id),
            npcUnlocked = def.npcUnlocked == true,
            autoRestock = def.autoRestock == true,
            publicDelivery = type(def.publicDelivery) == 'table' and def.publicDelivery or {
                enable = false,
                rewardPerLiter = (Config.PublicDelivery or {}).rewardPerLiter or 0.35,
                amount = (Config.PublicDelivery or {}).amount or 1000,
            },
        }
    end

    table.sort(out, function(a, b) return a.id < b.id end)
    return out
end

function AdminApi.GroupsArray()
    local out = {}

    for group, perms in pairs(AdminStore.perms or {}) do
        out[#out + 1] = { name = group, perms = perms, protected = AdminPerms.IsProtected(group) }
    end

    table.sort(out, function(a, b) return a.name < b.name end)
    return out
end

function AdminApi.BuildBootstrap(src)
    return {
        locale = Config.Locale,
        perms = AdminPerms.GetPlayerPerms(src),
        permKeys = AdminPerms.PERMS,
        fuelTypes = AdminPerms.FUEL_TYPES,
        priceModes = AdminPerms.PRICE_MODES,
        stations = AdminApi.StationsArray(),
        settings = AdminApi.SettingsPayload(),
        groups = AdminApi.GroupsArray(),
        suggestedGroups = AdminPerms.SUGGESTED_GROUPS,
    }
end

----------------------------------------------------------------
-- Live sync to the clients. Sent after every mutation so blips, pump labels and
-- sold-out states match the DB without a restart.
----------------------------------------------------------------
function AdminApi.Broadcast()
    TriggerClientEvent('msk_fuel:syncStations', -1, Stations.ClientPayload())
end

function AdminApi.PushTo(src)
    TriggerClientEvent('msk_fuel:syncStations', src, Stations.ClientPayload())
end

local function ok(src) return { ok = true, data = AdminApi.BuildBootstrap(src) } end
local function fail(err) return { ok = false, err = err } end

----------------------------------------------------------------
-- Callbacks (client -> server via MSK.Trigger). Every mutation is gated:
-- sanitize -> check the right -> write -> reload the store -> broadcast.
----------------------------------------------------------------

-- Public: the client pulls the authoritative station list on join. This is the
-- same world-visible data it needs for blips and pump labels, so no right is
-- required.
MSK.Register('msk_fuel:getStations', function(src)
    return Stations.ClientPayload()
end)

MSK.Register('msk_fuel:admin:bootstrap', function(src)
    if not AdminPerms.CanOpen(src) then return fail('no_permission') end
    return ok(src)
end)

-- Stations ------------------------------------------------------
MSK.Register('msk_fuel:admin:station:save', function(src, data)
    local def, err = AdminApi.SanitizeStation(type(data) == 'table' and data.station or nil)
    if not def then return fail(err or 'bad_input') end

    local existing = Config.Stations[def.id] ~= nil
    if not AdminPerms.Has(src, existing and 'station.edit' or 'station.create') then return fail('no_permission') end

    -- Supply flags belong to the owner (NPC driver, auto restock) or to the
    -- neutral-station tab (public jobs). The station editor does not carry
    -- them, so a plain edit must not silently reset them.
    local current = Config.Stations[def.id]

    if current then
        def.npcUnlocked = current.npcUnlocked
        def.autoRestock = current.autoRestock
        def.publicDelivery = current.publicDelivery
    end

    MySQL.insert.await(
        'INSERT INTO `msk_fuel_stations` (`id`, `label`, `data`, `enabled`) VALUES (?, ?, ?, 1) ' ..
        'ON DUPLICATE KEY UPDATE `label` = VALUES(`label`), `data` = VALUES(`data`)',
        { def.id, def.label, json.encode(def) }
    )

    AdminStore.LoadStations()
    -- A fuel type that was just added to the station has no tank yet. A brand
    -- new station starts full, an edited one only gets rows for what is new.
    Stock.EnsureRows(def.id, Config.Stations[def.id], not existing)

    AdminApi.Broadcast()
    return ok(src)
end)

MSK.Register('msk_fuel:admin:station:delete', function(src, data)
    if not AdminPerms.Has(src, 'station.delete') then return fail('no_permission') end

    local id = type(data) == 'table' and data.id or nil
    if type(id) ~= 'string' or not Config.Stations[id] then return fail('not_found') end

    MySQL.query.await('DELETE FROM `msk_fuel_stations` WHERE `id` = ?', { id })
    -- Stock and transactions would otherwise outlive the station and come back
    -- to life if the same id is ever created again.
    MySQL.query.await('DELETE FROM `msk_fuel_stock` WHERE `station_id` = ?', { id })
    MySQL.query.await('DELETE FROM `msk_fuel_transactions` WHERE `station_id` = ?', { id })
    MySQL.query.await('DELETE FROM `msk_fuel_ranks` WHERE `station_id` = ?', { id })
    MySQL.query.await('DELETE FROM `msk_fuel_employees` WHERE `station_id` = ?', { id })
    MySQL.query.await('DELETE FROM `msk_fuel_pumps` WHERE `station_id` = ?', { id })

    Stations.stock[id] = nil
    Stations.demand[id] = nil
    Employees.ranks[id] = nil
    Employees.list[id] = nil
    Maintenance.pumps[id] = nil

    AdminStore.LoadStations()
    AdminApi.Broadcast()
    return ok(src)
end)

-- Force-removes the owner of a station and puts it back on the market. The
-- balance stays with the station on purpose: it is the company's money, and an
-- admin taking a station away should not silently delete it.
MSK.Register('msk_fuel:admin:station:clearOwner', function(src, data)
    if not AdminPerms.Has(src, 'station.owner') then return fail('no_permission') end

    local id = type(data) == 'table' and data.id or nil
    if type(id) ~= 'string' or not Config.Stations[id] then return fail('not_found') end

    local formerOwner = Config.Stations[id].owner

    MySQL.update.await('UPDATE `msk_fuel_stations` SET `owner` = NULL WHERE `id` = ?', { id })
    Account.Log(id, 'owner_cleared', 0.0, { by = src, owner = formerOwner })

    -- The staff loses its employer along with the owner.
    for identifier in pairs(Employees.ListOf(id)) do
        Employees.Fire(id, identifier)
        Ownership.PushToIdentifier(identifier)
    end

    AdminStore.LoadStations()

    -- The former owner keeps their "manage this station" option until their
    -- client is told otherwise.
    Ownership.PushToIdentifier(formerOwner)

    AdminApi.Broadcast()
    return ok(src)
end)

-- Stock ---------------------------------------------------------
MSK.Register('msk_fuel:admin:stock:set', function(src, data)
    if not AdminPerms.Has(src, 'stock.manage') then return fail('no_permission') end
    if type(data) ~= 'table' then return fail('bad_input') end

    local id = data.id
    local fuelType = tostring(data.fuelType or ''):lower()

    if type(id) ~= 'string' or not Config.Stations[id] then return fail('not_found') end
    if not AdminPerms.IsFuelType(fuelType) then return fail('bad_fueltype') end

    if not Stock.Set(id, fuelType, data.stock, data.capacity) then return fail('no_tank') end

    AdminApi.Broadcast()
    return ok(src)
end)

MSK.Register('msk_fuel:admin:stock:pricing', function(src, data)
    if not AdminPerms.Has(src, 'market.manage') then return fail('no_permission') end
    if type(data) ~= 'table' then return fail('bad_input') end

    local id = data.id
    local fuelType = tostring(data.fuelType or ''):lower()

    if type(id) ~= 'string' or not Config.Stations[id] then return fail('not_found') end
    if not AdminPerms.IsFuelType(fuelType) then return fail('bad_fueltype') end

    local mode = oneOf(data.mode, AdminPerms.PRICE_MODES, 'dynamic')
    if not Stock.SetPricing(id, fuelType, mode, data.fixedPrice) then return fail('no_tank') end

    AdminApi.Broadcast()
    return ok(src)
end)

-- Settings ------------------------------------------------------
MSK.Register('msk_fuel:admin:settings:save', function(src, data)
    if not AdminPerms.Has(src, 'settings.manage') then return fail('no_permission') end
    if type(data) ~= 'table' or type(data.settings) ~= 'table' then return fail('bad_input') end

    local clean = AdminApi.SanitizeSettings(data.settings)

    for k, v in pairs(clean) do
        MySQL.insert.await(
            'INSERT INTO `msk_fuel_settings` (`skey`, `svalue`) VALUES (?, ?) ' ..
            'ON DUPLICATE KEY UPDATE `svalue` = VALUES(`svalue`)',
            { k, json.encode(v) }
        )
    end

    local oldCmd = Config.adminCommand
    AdminStore.LoadSettings()
    if Config.adminCommand ~= oldCmd then AdminCommand.Register(Config.adminCommand) end

    -- Base prices set by hand become the value the market drifts around, not
    -- something the next tick pulls straight back off.
    if clean.BasePrices then Pricing.SetAnchor() end

    AdminApi.Broadcast()
    return ok(src)
end)

-- Permissions ---------------------------------------------------
local function normGroup(name)
    if type(name) ~= 'string' then return nil end
    name = name:lower():gsub('^group%.', '')
    if #name == 0 or #name > 60 or not name:match('^[%w_%-]+$') then return nil end
    return name
end

MSK.Register('msk_fuel:admin:perms:saveGroup', function(src, data)
    if not AdminPerms.Has(src, 'permissions.manage') then return fail('no_permission') end

    local group = normGroup(type(data) == 'table' and data.group or nil)
    if not group then return fail('bad_group') end
    if AdminPerms.IsProtected(group) then return fail('protected_group') end
    if AdminPerms.IsBlacklisted(group) then return fail('blacklisted_group') end

    local perms = {}

    if type(data.perms) == 'table' then
        for _, key in ipairs(AdminPerms.PERMS) do
            if data.perms[key] == true then perms[key] = true end
        end
    end

    MySQL.insert.await(
        'INSERT INTO `msk_fuel_permissions` (`group_name`, `perms`) VALUES (?, ?) ' ..
        'ON DUPLICATE KEY UPDATE `perms` = VALUES(`perms`)',
        { group, json.encode(perms) }
    )

    AdminStore.LoadPermissions()
    AdminPerms.EnsureAces()
    AdminPerms.Invalidate()
    return ok(src)
end)

MSK.Register('msk_fuel:admin:perms:deleteGroup', function(src, data)
    if not AdminPerms.Has(src, 'permissions.manage') then return fail('no_permission') end

    local group = normGroup(type(data) == 'table' and data.group or nil)
    if not group then return fail('bad_group') end
    if AdminPerms.IsProtected(group) then return fail('protected_group') end

    MySQL.query.await('DELETE FROM `msk_fuel_permissions` WHERE `group_name` = ?', { group })

    AdminStore.LoadPermissions()
    AdminPerms.Invalidate()
    return ok(src)
end)

MSK.Register('msk_fuel:admin:perms:dashboardGroups', function(src, data)
    if not AdminPerms.Has(src, 'permissions.manage') then return fail('no_permission') end
    if type(data) ~= 'table' or type(data.groups) ~= 'table' then return fail('bad_input') end

    local groups, seen = {}, {}

    for _, raw in ipairs(data.groups) do
        local group = normGroup(raw)
        if group and not seen[group] and not AdminPerms.IsBlacklisted(group) then
            seen[group] = true
            groups[#groups + 1] = group
        end
    end

    MySQL.insert.await(
        'INSERT INTO `msk_fuel_settings` (`skey`, `svalue`) VALUES (?, ?) ' ..
        'ON DUPLICATE KEY UPDATE `svalue` = VALUES(`svalue`)',
        { 'dashboardGroups', json.encode(groups) }
    )

    AdminStore.LoadSettings()
    AdminPerms.EnsureAces()
    AdminPerms.Invalidate()
    return ok(src)
end)

-- Neutral stations ----------------------------------------------
-- Public delivery jobs and automatic restocking for stations nobody owns.
-- Kept apart from the station editor because these are operating decisions, not
-- part of what a station IS.
MSK.Register('msk_fuel:admin:station:neutral', function(src, data)
    if not AdminPerms.Has(src, 'station.edit') then return fail('no_permission') end
    if type(data) ~= 'table' then return fail('bad_input') end

    local id = data.id
    if type(id) ~= 'string' or not Config.Stations[id] then return fail('not_found') end

    local defaults = Config.PublicDelivery or {}

    Supply.SetStationFlag(id, 'publicDelivery', {
        enable = data.enable == true,
        rewardPerLiter = math.max(0.0, num(data.rewardPerLiter, defaults.rewardPerLiter or 0.35)),
        amount = math.max(1, int(data.amount, defaults.amount or 1000)),
    })

    Supply.SetStationFlag(id, 'autoRestock', data.autoRestock == true)

    AdminApi.Broadcast()
    return ok(src)
end)
