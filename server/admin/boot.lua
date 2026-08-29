-- Boot of the business layer: create the tables, seed once, load the database
-- into RAM, register the command. This file depends on every other admin file,
-- so it must stay LAST in the server_scripts list of the fxmanifest.

local function createTables()
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS `msk_fuel_stations` (
            `id` varchar(60) NOT NULL,
            `label` varchar(120) DEFAULT NULL,
            `owner` varchar(60) DEFAULT NULL,
            `balance` decimal(14,2) NOT NULL DEFAULT 0.00,
            `data` longtext NOT NULL,
            `enabled` tinyint(1) NOT NULL DEFAULT 1,
            `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
            PRIMARY KEY (`id`),
            KEY `idx_owner` (`owner`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
    ]])

    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS `msk_fuel_stock` (
            `station_id` varchar(60) NOT NULL,
            `fuel_type` varchar(20) NOT NULL,
            `stock` decimal(12,2) NOT NULL DEFAULT 0.00,
            `capacity` int(11) NOT NULL DEFAULT 0,
            `price_mode` varchar(10) NOT NULL DEFAULT 'dynamic',
            `fixed_price` decimal(8,2) NOT NULL DEFAULT 0.00,
            PRIMARY KEY (`station_id`, `fuel_type`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
    ]])

    -- Ranks and employees are filled in phase 3. The tables are created now so
    -- a server that updates later does not need a second migration step.
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS `msk_fuel_ranks` (
            `station_id` varchar(60) NOT NULL,
            `rank_id` varchar(60) NOT NULL,
            `label` varchar(120) DEFAULT NULL,
            `salary` int(11) NOT NULL DEFAULT 0,
            `delivery_bonus` int(11) NOT NULL DEFAULT 0,
            `perms` longtext DEFAULT NULL,
            PRIMARY KEY (`station_id`, `rank_id`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
    ]])

    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS `msk_fuel_employees` (
            `station_id` varchar(60) NOT NULL,
            `identifier` varchar(60) NOT NULL,
            `rank_id` varchar(60) NOT NULL,
            `hired_at` timestamp NOT NULL DEFAULT current_timestamp(),
            `stats` longtext DEFAULT NULL,
            PRIMARY KEY (`station_id`, `identifier`),
            KEY `idx_identifier` (`identifier`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
    ]])

    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS `msk_fuel_settings` (
            `skey` varchar(80) NOT NULL,
            `svalue` longtext DEFAULT NULL,
            PRIMARY KEY (`skey`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
    ]])

    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS `msk_fuel_permissions` (
            `group_name` varchar(80) NOT NULL,
            `perms` longtext DEFAULT NULL,
            PRIMARY KEY (`group_name`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
    ]])

    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS `msk_fuel_transactions` (
            `id` int(11) NOT NULL AUTO_INCREMENT,
            `station_id` varchar(60) NOT NULL,
            `type` varchar(40) NOT NULL,
            `amount` decimal(14,2) NOT NULL DEFAULT 0.00,
            `liters` decimal(12,2) NOT NULL DEFAULT 0.00,
            `meta` longtext DEFAULT NULL,
            `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
            PRIMARY KEY (`id`),
            KEY `idx_station_time` (`station_id`, `created_at`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
    ]])

    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS `msk_fuel_pumps` (
            `station_id` varchar(60) NOT NULL,
            `pump_key` varchar(40) NOT NULL,
            `coords` longtext DEFAULT NULL,
            `health` int(11) NOT NULL DEFAULT 100,
            PRIMARY KEY (`station_id`, `pump_key`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
    ]])

    -- Added in phase 2. Safe to run blindly: our own table, the column is
    -- NOT NULL with a default, so existing rows simply read as 0 liters.
    MySQL.query.await([[
        ALTER TABLE `msk_fuel_transactions`
            ADD COLUMN IF NOT EXISTS `liters` decimal(12,2) NOT NULL DEFAULT 0.00
    ]])
end

AddEventHandler('onResourceStart', function(resource)
    if resource ~= GetCurrentResourceName() then return end

    createTables()
    AdminSeed.Run(false)
    AdminSeed.EnsureSettings()
    AdminStore.LoadAll()

    -- After LoadAll, so a station added to config.stations.lua on an already
    -- seeded server still gets its tanks, and so does one created in the
    -- dashboard before this restart.
    AdminSeed.EnsureStock(true)

    -- Needs the loaded permission matrix, so it has to run after LoadAll().
    AdminPerms.EnsureAces()
    AdminCommand.Register(Config.adminCommand)

    -- On a live restart, push the freshly loaded stations to everyone already
    -- connected so their blips and pump labels match the database.
    AdminApi.Broadcast()

    print(('^2[msk_fuel]^0 Business layer ready - %s stations, admin command: ^5/%s^0')
        :format(MSK.Table.Size(Config.Stations), Config.adminCommand or 'fueladmin'))
end)
