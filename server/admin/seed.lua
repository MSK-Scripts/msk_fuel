AdminSeed = AdminSeed or {}

----------------------------------------------------------------
-- vector3/vector4 -> plain {x,y,z,w}. The configs use FiveM vector types which
-- json.encode cannot serialise; everything downstream reads coords via
-- .x/.y/.z so a plain table is a drop-in replacement.
----------------------------------------------------------------
local function vecToTable(v)
    if type(v) ~= 'table' and type(v) ~= 'vector3' and type(v) ~= 'vector4' then return nil end

    return {
        x = (v.x or 0.0) + 0.0,
        y = (v.y or 0.0) + 0.0,
        z = (v.z or 0.0) + 0.0,
        w = (v.w or 0.0) + 0.0,
    }
end

-- Copy of a station definition with its coordinate converted for storage.
-- The remaining fields (fuelTypes, capacity) hold no vectors, so sharing the
-- references is safe for json.encode.
local function defForStorage(def)
    local copy = {}
    for k, v in pairs(def) do copy[k] = v end

    copy.coords = vecToTable(def.coords)
    -- These live in their own columns, they have no business inside `data`.
    copy.owner = nil
    copy.balance = nil

    return copy
end

local function isSeeded()
    local row = MySQL.single.await("SELECT `skey` FROM `msk_fuel_settings` WHERE `skey` = '__seeded__'")
    return row ~= nil
end

----------------------------------------------------------------
-- One-time import of the static config into the DB.
----------------------------------------------------------------
function AdminSeed.Run(force)
    if not force and isSeeded() then return false end

    -- Stations. Every station starts unowned with a full tank, so a fresh
    -- server behaves exactly like it did before the business layer existed.
    for id, def in pairs(Config.Stations) do
        local clean = defForStorage(def)

        MySQL.insert.await(
            'INSERT INTO `msk_fuel_stations` (`id`, `label`, `data`, `enabled`) VALUES (?, ?, ?, 1) ' ..
            'ON DUPLICATE KEY UPDATE `label` = VALUES(`label`), `data` = VALUES(`data`)',
            { id, def.label or id, json.encode(clean) }
        )
    end

    -- Settings (editable whitelist).
    for _, key in ipairs(AdminPerms.SETTINGS_KEYS) do
        if Config[key] ~= nil then
            MySQL.insert.await(
                'INSERT INTO `msk_fuel_settings` (`skey`, `svalue`) VALUES (?, ?) ' ..
                'ON DUPLICATE KEY UPDATE `svalue` = VALUES(`svalue`)',
                { key, json.encode(Config[key]) }
            )
        end
    end

    -- dashboardGroups is permission-managed but still persisted as a setting.
    MySQL.insert.await(
        'INSERT INTO `msk_fuel_settings` (`skey`, `svalue`) VALUES (?, ?) ' ..
        'ON DUPLICATE KEY UPDATE `svalue` = VALUES(`svalue`)',
        { 'dashboardGroups', json.encode(Config.dashboardGroups or {}) }
    )

    -- Default permission groups: admin = all, mod = view only.
    MySQL.insert.await(
        'INSERT INTO `msk_fuel_permissions` (`group_name`, `perms`) VALUES (?, ?) ' ..
        'ON DUPLICATE KEY UPDATE `perms` = VALUES(`perms`)',
        { 'admin', json.encode(AdminPerms.AllPerms()) }
    )
    MySQL.insert.await(
        'INSERT INTO `msk_fuel_permissions` (`group_name`, `perms`) VALUES (?, ?) ' ..
        'ON DUPLICATE KEY UPDATE `perms` = VALUES(`perms`)',
        { 'mod', json.encode({ ['station.view'] = true }) }
    )

    MySQL.insert.await(
        'INSERT INTO `msk_fuel_settings` (`skey`, `svalue`) VALUES (?, ?) ' ..
        'ON DUPLICATE KEY UPDATE `svalue` = VALUES(`svalue`)',
        { '__seeded__', json.encode(os.time()) }
    )

    print('^2[msk_fuel]^0 Seed complete (stations/settings/permissions imported into the database).')
    return true
end

----------------------------------------------------------------
-- Settings introduced by a later version never reach a server that was already
-- seeded, because AdminSeed.Run() bails out on the marker row. Missing keys are
-- therefore written separately on every start; existing rows are left alone, so
-- nothing an admin changed is ever overwritten.
----------------------------------------------------------------
function AdminSeed.EnsureSettings()
    local rows = MySQL.query.await('SELECT `skey` FROM `msk_fuel_settings`') or {}
    local known = {}

    for _, row in ipairs(rows) do known[row.skey] = true end

    for _, key in ipairs(AdminPerms.SETTINGS_KEYS) do
        if not known[key] and Config[key] ~= nil then
            MySQL.insert.await(
                'INSERT INTO `msk_fuel_settings` (`skey`, `svalue`) VALUES (?, ?) ' ..
                'ON DUPLICATE KEY UPDATE `svalue` = VALUES(`svalue`)',
                { key, json.encode(Config[key]) }
            )
        end
    end
end

----------------------------------------------------------------
-- Stock rows are created separately from the seed marker: a station added later
-- (dashboard, or a new entry in config.stations.lua on an already seeded
-- server) still needs its tanks. Missing rows are filled, existing ones are
-- never touched.
----------------------------------------------------------------
function AdminSeed.EnsureStock(fill)
    for id, def in pairs(Config.Stations) do
        Stock.EnsureRows(id, def, fill ~= false)
    end
end
