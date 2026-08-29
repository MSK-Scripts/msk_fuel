----------------------------------------------------------------
-- Fuel stations as manageable entities.
--
-- Up to v1.1.1 a fuel station was nothing but a blip coordinate. From here on
-- every station has an ID, a name, a ZONE (center + radius), its own stock and
-- (once bought) an owner. The pumps themselves are not touched: every pump prop
-- standing inside a zone belongs to that station, which is why the existing
-- coordinates could be reused as zone centers without re-mapping anything.
--
-- This file is a SEED. On the first start it is imported into
-- `msk_fuel_stations` / `msk_fuel_stock`, and from then on the DATABASE is the
-- source of truth. Edit stations in the admin dashboard, not here.
--
-- Fields per station (only `coords` is required):
--   label         string   name shown on the blip and in the dashboard
--   coords        vector3  zone center
--   radius        number   zone radius in units          (default 60.0)
--   blip          boolean  show a blip for this station   (default true)
--   fuelTypes     table    what can be tanked here        (default gas/diesel/kerosin)
--   capacity      table    per fuel type, overrides Config.DefaultCapacity
--   purchasable   boolean  may players buy this station   (default true)
--   purchasePrice number   overrides Config.DefaultPurchasePrice
--
-- The labels below are generic on purpose. Renaming a station in the dashboard
-- writes through to its blip, so name them however your server calls them.
----------------------------------------------------------------
Config.Stations = {
    ----------------------------------------------------------------
    -- Los Santos
    ----------------------------------------------------------------
    ['ls_01'] = { label = 'Tankstelle Los Santos 1',  coords = vector3(-71.28, -1761.16, 29.48) },
    ['ls_02'] = { label = 'Tankstelle Los Santos 2',  coords = vector3(264.74, -1260.98, 29.18) },
    ['ls_03'] = { label = 'Tankstelle Los Santos 3',  coords = vector3(1208.66, -1402.64, 35.22) },
    ['ls_04'] = { label = 'Tankstelle Los Santos 4',  coords = vector3(818.83, -1029.89, 26.17) },
    ['ls_05'] = { label = 'Tankstelle Los Santos 5',  coords = vector3(1181.27, -329.57, 69.18) },
    ['ls_06'] = { label = 'Tankstelle Los Santos 6',  coords = vector3(621.07, 269.52, 103.0) },
    ['ls_07'] = { label = 'Tankstelle Los Santos 7',  coords = vector3(-1437.58, -276.38, 46.21) },
    ['ls_08'] = { label = 'Tankstelle Los Santos 8',  coords = vector3(-2096.6, -318.15, 13.02) },
    ['ls_09'] = { label = 'Tankstelle Los Santos 9',  coords = vector3(-1799.03, 803.11, 138.4) },
    ['ls_10'] = { label = 'Tankstelle Los Santos 10', coords = vector3(-524.84, -1211.02, 18.18) },
    ['ls_11'] = { label = 'Tankstelle Los Santos 11', coords = vector3(2581.56, 361.65, 108.46) },
    ['ls_12'] = { label = 'Tankstelle Los Santos 12', coords = vector3(-319.84, -1471.77, 30.55) },
    ['ls_13'] = { label = 'Tankstelle Los Santos 13', coords = vector3(175.31, -1561.73, 29.26) },
    ['ls_14'] = { label = 'Tankstelle Los Santos 14', coords = vector3(-723.72, -935.51, 19.21) },

    ----------------------------------------------------------------
    -- Blaine County
    ----------------------------------------------------------------
    ['bc_01'] = { label = 'Tankstelle Blaine County 1',  coords = vector3(-2555.31, 2334.01, 33.06) },
    ['bc_02'] = { label = 'Tankstelle Blaine County 2',  coords = vector3(49.69, 2778.33, 57.88) },
    ['bc_03'] = { label = 'Tankstelle Blaine County 3',  coords = vector3(264.15, 2607.05, 44.95) },
    ['bc_04'] = { label = 'Tankstelle Blaine County 4',  coords = vector3(1207.56, 2660.2, 37.81) },
    ['bc_05'] = { label = 'Tankstelle Blaine County 5',  coords = vector3(2538.0, 2593.83, 37.94) },
    ['bc_06'] = { label = 'Tankstelle Blaine County 6',  coords = vector3(2680.01, 3265.0, 55.24) },
    ['bc_07'] = { label = 'Tankstelle Blaine County 7',  coords = vector3(2005.07, 3774.33, 32.18) },
    ['bc_08'] = { label = 'Tankstelle Blaine County 8',  coords = vector3(1688.42, 4930.85, 42.08) },
    ['bc_09'] = { label = 'Tankstelle Blaine County 9',  coords = vector3(1039.34, 2671.78, 39.55) },

    -- Grand Senora Desert. The generator prop from Config.CustomFuelStations
    -- stands inside this zone, so this station also sells electricity.
    ['bc_10'] = {
        label = 'Tankstelle Grand Senora Desert',
        coords = vector3(1785.58, 3330.47, 41.38),
        fuelTypes = { 'gas', 'diesel', 'kerosin', 'electric' },
    },

    -- The diesel tank spawned by Config.CustomFuelStations, roughly 100 units
    -- away from bc_10 and therefore its own station.
    ['bc_11'] = {
        label = 'Dieseldepot Grand Senora',
        coords = vector3(1761.61, 3228.0, 42.52),
        radius = 40.0,
        fuelTypes = { 'kerosin' },
        purchasable = false,
    },

    ----------------------------------------------------------------
    -- Paleto Bay
    ----------------------------------------------------------------
    ['pb_01'] = { label = 'Tankstelle Paleto Bay 1', coords = vector3(1702.79, 6416.86, 33.64) },
    ['pb_02'] = { label = 'Tankstelle Paleto Bay 2', coords = vector3(179.94, 6602.6, 31.85) },
    ['pb_03'] = { label = 'Tankstelle Paleto Bay 3', coords = vector3(-93.98, 6420.1, 31.48) },

    -- The extra pump spawned by Config.CustomFuelStations near 3021 Paleto Bay.
    ['pb_04'] = {
        label = 'Tankstelle Paleto Bay 4',
        coords = vector3(166.44, 6461.82, 31.2),
        radius = 40.0,
    },

    ----------------------------------------------------------------
    -- Airports
    ----------------------------------------------------------------
    -- Covers both diesel tanks spawned by Config.CustomFuelStations; they are
    -- about 50 units apart and share one zone.
    ['lsia'] = {
        label = 'LS International Airport',
        coords = vector3(-995.06, -3398.36, 13.84),
        radius = 70.0,
        fuelTypes = { 'kerosin' },
        purchasable = false,
    },
}

----------------------------------------------------------------
-- Fuel depots. Delivery jobs (phase 4) load here. Seeded now so the station
-- table does not have to change shape later.
----------------------------------------------------------------
Config.FuelDepots = {
    { label = 'Raffinerie Elysian Island', coords = vector4(2739.61, 1516.55, 24.5, 15.0) },
    { label = 'Raffinerie Port of LS',     coords = vector4(1204.94, -2967.09, 5.9, 87.0) },
}
