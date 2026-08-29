AdminStore = AdminStore or {}

-- In-memory permission matrix: [group_name] = { [perm] = true }
AdminStore.perms = {}
AdminStore.ready = false

----------------------------------------------------------------
-- JSON helpers
----------------------------------------------------------------
local function jdecode(s)
    if type(s) ~= 'string' then return false end
    local ok, v = pcall(json.decode, s)
    if not ok then return false end
    return true, v
end
AdminStore.Decode = jdecode

local function isEnabled(v)
    return tonumber(v) ~= 0
end

----------------------------------------------------------------
-- Load definitions from the DB into Config.* / Stations.*, which is what the
-- rest of the runtime reads. Nothing outside this file talks to the tables.
----------------------------------------------------------------
function AdminStore.LoadStations()
    Config.Stations = {}

    local rows = MySQL.query.await(
        'SELECT `id`, `label`, `owner`, `balance`, `data`, `enabled` FROM `msk_fuel_stations`') or {}

    for _, row in ipairs(rows) do
        if isEnabled(row.enabled) then
            local ok, def = jdecode(row.data)

            if ok and type(def) == 'table' then
                def.id = row.id
                def.label = row.label or def.label or row.id
                -- owner and balance live in columns rather than inside `data`:
                -- they change far more often than the definition and are looked
                -- up per player, while `data` is what gets shipped to clients.
                def.owner = (row.owner ~= '' and row.owner) or nil
                def.balance = tonumber(row.balance) or 0.0
                Config.Stations[row.id] = def
            end
        end
    end
end

function AdminStore.LoadStock()
    Stations.stock = {}

    local rows = MySQL.query.await(
        'SELECT `station_id`, `fuel_type`, `stock`, `capacity`, `price_mode`, `fixed_price` FROM `msk_fuel_stock`') or {}

    for _, row in ipairs(rows) do
        Stations.stock[row.station_id] = Stations.stock[row.station_id] or {}
        Stations.stock[row.station_id][row.fuel_type] = {
            stock = tonumber(row.stock) or 0.0,
            capacity = math.floor(tonumber(row.capacity) or 0),
            price_mode = (row.price_mode == 'fixed') and 'fixed' or 'dynamic',
            fixed_price = tonumber(row.fixed_price) or 0.0,
        }
    end
end

function AdminStore.LoadRanks()
    Employees.ranks = {}

    local rows = MySQL.query.await(
        'SELECT `station_id`, `rank_id`, `label`, `salary`, `delivery_bonus`, `perms` FROM `msk_fuel_ranks`') or {}

    for _, row in ipairs(rows) do
        local ok, perms = jdecode(row.perms)

        Employees.ranks[row.station_id] = Employees.ranks[row.station_id] or {}
        Employees.ranks[row.station_id][row.rank_id] = {
            label = row.label or row.rank_id,
            salary = math.floor(tonumber(row.salary) or 0),
            delivery_bonus = math.floor(tonumber(row.delivery_bonus) or 0),
            perms = (ok and type(perms) == 'table') and perms or {},
        }
    end
end

function AdminStore.LoadEmployees()
    Employees.list = {}

    local rows = MySQL.query.await(
        'SELECT `station_id`, `identifier`, `rank_id`, `hired_at`, `stats` FROM `msk_fuel_employees`') or {}

    for _, row in ipairs(rows) do
        local ok, stats = jdecode(row.stats)

        Employees.list[row.station_id] = Employees.list[row.station_id] or {}
        Employees.list[row.station_id][row.identifier] = {
            rank_id = row.rank_id,
            hired_at = tostring(row.hired_at),
            stats = (ok and type(stats) == 'table') and stats or Employees.EmptyStats(),
        }
    end
end

function AdminStore.LoadPumps()
    Maintenance.pumps = {}

    local rows = MySQL.query.await(
        'SELECT `station_id`, `pump_key`, `coords`, `health` FROM `msk_fuel_pumps`') or {}

    for _, row in ipairs(rows) do
        local ok, coords = jdecode(row.coords)

        Maintenance.pumps[row.station_id] = Maintenance.pumps[row.station_id] or {}
        Maintenance.pumps[row.station_id][row.pump_key] = {
            coords = (ok and type(coords) == 'table') and coords or { x = 0.0, y = 0.0, z = 0.0 },
            health = math.max(0, math.min(math.floor(tonumber(row.health) or 100), 100)),
        }
    end
end

function AdminStore.LoadSettings()
    local rows = MySQL.query.await('SELECT `skey`, `svalue` FROM `msk_fuel_settings`') or {}

    for _, row in ipairs(rows) do
        if row.skey ~= '__seeded__' then
            local ok, v = jdecode(row.svalue)
            if ok then Config[row.skey] = v end
        end
    end
end

function AdminStore.LoadPermissions()
    AdminStore.perms = {}

    local rows = MySQL.query.await('SELECT `group_name`, `perms` FROM `msk_fuel_permissions`') or {}

    for _, row in ipairs(rows) do
        local ok, p = jdecode(row.perms)
        AdminStore.perms[row.group_name] = (ok and type(p) == 'table') and p or {}
    end
end

function AdminStore.LoadAll()
    -- Settings first: the station and stock loaders read price limits and
    -- default capacities out of Config while building their payloads.
    AdminStore.LoadSettings()
    AdminStore.LoadStations()
    AdminStore.LoadStock()
    AdminStore.LoadRanks()
    AdminStore.LoadEmployees()
    AdminStore.LoadPumps()
    AdminStore.LoadPermissions()
    AdminStore.ready = true
end
