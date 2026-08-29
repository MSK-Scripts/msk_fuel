----------------------------------------------------------------
-- Ranks and employees.
--
-- Both are per station and live in msk_fuel's own tables, deliberately not in
-- the framework's job system: a station is a side business, and tying it to a
-- job would mean a player can only work at one and only on a server that has
-- that job configured. A player can be employed at several stations at once.
--
-- A rank carries a salary, a delivery bonus and a set of OwnerPerms. The owner
-- holds every permission by virtue of the `owner` column and has no rank.
----------------------------------------------------------------
Employees = Employees or {}

-- [stationId][rankId] = { label, salary, delivery_bonus, perms }
Employees.ranks = Employees.ranks or {}

-- [stationId][identifier] = { rank_id, hired_at, stats }
Employees.list = Employees.list or {}

-- Ranks every freshly bought station starts with. A manager can run the place,
-- an employee can do the day-to-day work. Both are editable afterwards.
Employees.DEFAULT_RANKS = {
    {
        id = 'manager',
        label = 'Geschäftsführer',
        salary = 1000,
        delivery_bonus = 250,
        perms = { manage = true, hire = true, set_prices = true, order_fuel = true, withdraw = true, deposit = true, repair = true },
    },
    {
        id = 'employee',
        label = 'Mitarbeiter',
        salary = 500,
        delivery_bonus = 150,
        perms = { order_fuel = true, deposit = true, repair = true },
    },
}

local function emptyStats()
    return { liters_sold = 0, deliveries = 0, earnings = 0, last_active = 0 }
end

Employees.EmptyStats = emptyStats

----------------------------------------------------------------
-- Reading
----------------------------------------------------------------
function Employees.RanksOf(stationId)
    return Employees.ranks[stationId] or {}
end

function Employees.Rank(stationId, rankId)
    return (Employees.ranks[stationId] or {})[rankId]
end

function Employees.ListOf(stationId)
    return Employees.list[stationId] or {}
end

function Employees.Get(stationId, identifier)
    return (Employees.list[stationId] or {})[identifier]
end

---Permissions an employee holds at a station, from their rank. Returns an empty
---table for anyone who does not work there.
function Employees.PermsOf(stationId, identifier)
    local employee = Employees.Get(stationId, identifier)
    if not employee then return {} end

    local rank = Employees.Rank(stationId, employee.rank_id)
    if not rank or type(rank.perms) ~= 'table' then return {} end

    local out = {}

    for _, perm in ipairs(OwnerPerms.PERMS) do
        if rank.perms[perm] == true then out[perm] = true end
    end

    return out
end

---Stations this identifier works at (not the ones they own).
function Employees.StationsOf(identifier)
    local out = {}

    for stationId, staff in pairs(Employees.list) do
        if staff[identifier] then out[#out + 1] = stationId end
    end

    table.sort(out)
    return out
end

----------------------------------------------------------------
-- Writing
----------------------------------------------------------------
local function persistRank(stationId, rankId, rank)
    MySQL.insert.await(
        'INSERT INTO `msk_fuel_ranks` (`station_id`, `rank_id`, `label`, `salary`, `delivery_bonus`, `perms`) ' ..
        'VALUES (?, ?, ?, ?, ?, ?) ON DUPLICATE KEY UPDATE ' ..
        '`label` = VALUES(`label`), `salary` = VALUES(`salary`), ' ..
        '`delivery_bonus` = VALUES(`delivery_bonus`), `perms` = VALUES(`perms`)',
        { stationId, rankId, rank.label, rank.salary, rank.delivery_bonus, json.encode(rank.perms or {}) }
    )
end

function Employees.SaveRank(stationId, rankId, rank)
    Employees.ranks[stationId] = Employees.ranks[stationId] or {}
    Employees.ranks[stationId][rankId] = rank

    persistRank(stationId, rankId, rank)
    return true
end

---Deleting a rank is refused while somebody still holds it: an employee without
---a valid rank would silently lose every permission and every salary.
---@return boolean ok, string|nil err
function Employees.DeleteRank(stationId, rankId)
    for _, employee in pairs(Employees.ListOf(stationId)) do
        if employee.rank_id == rankId then return false, 'rank_in_use' end
    end

    MySQL.query.await('DELETE FROM `msk_fuel_ranks` WHERE `station_id` = ? AND `rank_id` = ?', { stationId, rankId })

    if Employees.ranks[stationId] then Employees.ranks[stationId][rankId] = nil end

    return true
end

---@return boolean ok, string|nil err
function Employees.Hire(stationId, identifier, rankId)
    if not Employees.Rank(stationId, rankId) then return false, 'bad_rank' end

    local def = Stations.Get(stationId)
    if def and def.owner == identifier then return false, 'is_owner' end

    local stats = emptyStats()

    MySQL.insert.await(
        'INSERT INTO `msk_fuel_employees` (`station_id`, `identifier`, `rank_id`, `stats`) VALUES (?, ?, ?, ?) ' ..
        'ON DUPLICATE KEY UPDATE `rank_id` = VALUES(`rank_id`)',
        { stationId, identifier, rankId, json.encode(stats) }
    )

    Employees.list[stationId] = Employees.list[stationId] or {}
    local existing = Employees.list[stationId][identifier]

    if existing then
        existing.rank_id = rankId
    else
        Employees.list[stationId][identifier] = { rank_id = rankId, stats = stats }
    end

    return true
end

function Employees.Fire(stationId, identifier)
    MySQL.query.await(
        'DELETE FROM `msk_fuel_employees` WHERE `station_id` = ? AND `identifier` = ?',
        { stationId, identifier }
    )

    if Employees.list[stationId] then Employees.list[stationId][identifier] = nil end

    return true
end

---Merges values into an employee's statistics and writes them back.
function Employees.AddStats(stationId, identifier, patch)
    local employee = Employees.Get(stationId, identifier)
    if not employee then return false end

    local stats = employee.stats or emptyStats()

    for key, value in pairs(patch or {}) do
        if key == 'last_active' then
            stats.last_active = value
        else
            stats[key] = (tonumber(stats[key]) or 0) + (tonumber(value) or 0)
        end
    end

    employee.stats = stats

    MySQL.update('UPDATE `msk_fuel_employees` SET `stats` = ? WHERE `station_id` = ? AND `identifier` = ?',
        { json.encode(stats), stationId, identifier })

    return true
end

----------------------------------------------------------------
-- Seeding a freshly bought station
----------------------------------------------------------------
function Employees.SeedRanks(stationId)
    -- Never overwrite ranks a previous owner already set up: the station keeps
    -- its structure when it changes hands.
    if next(Employees.RanksOf(stationId)) ~= nil then return end

    for _, rank in ipairs(Employees.DEFAULT_RANKS) do
        Employees.SaveRank(stationId, rank.id, {
            label = rank.label,
            salary = rank.salary,
            delivery_bonus = rank.delivery_bonus,
            perms = rank.perms,
        })
    end
end

----------------------------------------------------------------
-- Payload for the owner dashboard
----------------------------------------------------------------
function Employees.RanksPayload(stationId)
    local out = {}

    for rankId, rank in pairs(Employees.RanksOf(stationId)) do
        out[#out + 1] = {
            id = rankId,
            label = rank.label or rankId,
            salary = math.floor(tonumber(rank.salary) or 0),
            deliveryBonus = math.floor(tonumber(rank.delivery_bonus) or 0),
            perms = rank.perms or {},
        }
    end

    table.sort(out, function(a, b) return a.id < b.id end)
    return out
end

function Employees.ListPayload(stationId)
    local out = {}

    for identifier, employee in pairs(Employees.ListOf(stationId)) do
        local rank = Employees.Rank(stationId, employee.rank_id)

        -- Offline employees stay in the list, they just have no name to show:
        -- the frameworks only keep player names in memory while online.
        local found, player = pcall(MSK.GetPlayerFromIdentifier, identifier)
        local online = (found and type(player) == 'table') and player or nil

        out[#out + 1] = {
            identifier = identifier,
            name = online and online.name or nil,
            online = online ~= nil,
            rankId = employee.rank_id,
            rankLabel = rank and rank.label or employee.rank_id,
            stats = employee.stats or emptyStats(),
        }
    end

    table.sort(out, function(a, b) return a.identifier < b.identifier end)
    return out
end
