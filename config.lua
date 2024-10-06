Config = {}
----------------------------------------------------------------
Config.Locale = 'de'
Config.Debug = true
Config.VersionChecker = true
----------------------------------------------------------------
-- !!! This function is clientside AND serverside !!!
Config.Notification = function(source, message, typ)
    if IsDuplicityVersion() then -- serverside
        MSK.Notification(source, 'Fuel Station', message, typ, 5000)
    else -- clientside
        MSK.Notification('Fuel Station', message, typ, 5000)
    end
end
----------------------------------------------------------------
Config.Target = {
    enable = true,

    -- Supported Target: ox_target
    script = 'ox_target',
}

Config.Commands = {
    allowedGroups = {'superadmin', 'admin'},
    setVehicleFuel = 'setFuel', -- /setFuel 50 // You have to sit in a vehicle
}

Config.FuelStationBlips = {
    enable = true, -- Set false to disable blips

    id = 361,
    color = 6,
    scale = 0.8,
    label = Translate('fuel_station_blip'),
}

-- See FiveM Native Reference (SetFuelConsumptionRateMultiplier - https://docs.fivem.net/natives/?_0x845F3E5C)
Config.FuelConsumptionRateMultiplier = 10.0 -- Sets fuel consumption rate multiplier for all vehicles operated by a player.

Config.Refill = {
    tick = 250, -- Fuel Tick Rate (every 250 miliseconds)
    value = 0.50, -- Fuel Refill Value (adds 0.50% every refillTick miliseconds)
    price = 5, -- Price per Tick Rate (costs $5 every 250 miliseconds)
}

Config.Petrolcan = {
    enable = true,
    price = 1000,
    refillPrice = 800,
    refillDuration = 5, -- duration to refill the petrolcan // in seconds
    durabilityTick = 1.3, -- durability loss per Fuel Tick Rate
}
----------------------------------------------------------------
Config.FuelStationModels = {
    -- Use `` and NOT "" and NOT ''

    `prop_gas_pump_old2`,
	`prop_gas_pump_1a`,
	`prop_vintage_pump`,
	`prop_gas_pump_old3`,
	`prop_gas_pump_1c`,
	`prop_gas_pump_1b`,
	`prop_gas_pump_1d`,
}

Config.DefaultFuelType = 'gas'

Config.WrongFuel = {
    allow = true, -- Allow players to fill up with the wrong fuel
    liter = 15, -- Engine Failure if more than 15 liters were refueled
}

Config.FuelStationTypes = {
    -- Use `` and NOT "" and NOT ''

    --[[
        Fuel Types:
        * 'gas'
        * 'diesel'
        * 'kerosin' -> For airplanes and helicopters
        * 'electric' -> For electric vehicles
    ]]

    [`prop_gas_pump_old2`] = {'gas', 'diesel', 'kerosin'},
    [`prop_gas_pump_1a`] = {'gas', 'diesel', 'kerosin'},
    [`prop_vintage_pump`] = {'gas', 'diesel', 'kerosin'},
    [`prop_gas_pump_old3`] = {'gas', 'diesel', 'kerosin'},
    [`prop_gas_pump_1c`] = {'gas', 'diesel', 'kerosin'},
    [`prop_gas_pump_1b`] = {'gas', 'diesel', 'kerosin'},
    [`prop_gas_pump_1d`] = {'gas', 'diesel', 'kerosin'},

    -- If you have a custom fuel station for electric vehicles then add them here
    -- [`model`] = {'electric'}
}

-- Spawns the given Fuel Pump on the given coords
Config.CustomFuelStations = {
    {model = `prop_gas_pump_1c`, coords = vector4(166.44, 6461.82, 31.2, 176.24)},
}
----------------------------------------------------------------
-- This is only for Blips
Config.FuelStations = {
    -- Los Santos
    vector3(-71.28, -1761.16, 29.48),
    vector3(264.74, -1260.98, 29.18),
    vector3(1208.66, -1402.64, 35.22),
    vector3(818.83, -1029.89, 26.17),
    vector3(1181.27, -329.57, 69.18),
    vector3(621.07, 269.52, 103.0),
    vector3(-1437.58, -276.38, 46.21),
    vector3(-2096.6, -318.15, 13.02),
    vector3(-1799.03, 803.11, 138.4),
    vector3(-524.84, -1211.02, 18.18),
    vector3(2581.56, 361.65, 108.46),
    vector3(-319.84, -1471.77, 30.55),
    vector3(175.31, -1561.73, 29.26),
    vector3(-723.72, -935.51, 19.21),

    -- Blaine County
    vector3(-2555.31, 2334.01, 33.06),
    vector3(49.69, 2778.33, 57.88),
    vector3(264.15, 2607.05, 44.95),
    vector3(1207.56, 2660.2, 37.81),
    vector3(2538.0, 2593.83, 37.94),
    vector3(2680.01, 3265.0, 55.24),
    vector3(2005.07, 3774.33, 32.18),
    vector3(1688.42, 4930.85, 42.08),
    vector3(1039.34, 2671.78, 39.55),
    vector3(1785.58, 3330.47, 41.38),

    -- Paleto Bay
    vector3(1702.79, 6416.86, 33.64),
    vector3(179.94, 6602.6, 31.85),
    vector3(-93.98, 6420.1, 31.48),
}