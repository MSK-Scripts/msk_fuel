Config = {}
----------------------------------------------------------------
Config.Locale = 'de'
Config.Debug = false
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
Config.Commands = {
    allowedGroups = {'superadmin', 'admin'},
    setVehicleFuel = 'setFuel', -- /setFuel 50 // You have to sit in a vehicle
    repairVehicle = 'repairVehicle', -- Repair the vehicle if it was refueled with the wrong fuel // You have to sit in a vehicle
}

Config.FuelStationBlips = {
    enable = true, -- Set false to disable blips

    id = 361,
    color = 6,
    scale = 0.8,
    label = Translate('fuel_station_blip'),
}

-- The two values below are DIFFERENT engine concepts and multiply together in practice.
-- Effective consumption roughly scales with FuelConsumptionRateMultiplier * PetrolConsumptionRate,
-- so if you tune one, remember the other still applies.

-- GLOBAL multiplier for every vehicle the player operates.
-- See FiveM Native Reference (SetFuelConsumptionRateMultiplier - https://docs.fivem.net/natives/?_0x845F3E5C)
Config.FuelConsumptionRateMultiplier = 2.0

-- PER-VEHICLE handling value (fPetrolConsumptionRate), applied only while the engine is running.
Config.PetrolConsumptionRate = 2.0

-- Maximum distance (in units) a player may be away from a vehicle to fuel it.
-- Serverside anti-exploit check. Values are per vehicle type so planes/helicopters
-- (which use long ropes) get more range than regular vehicles.
Config.MaxFuelingDistance = {
    default = 20.0,
    heli = 30.0,
    plane = 50.0,
}

-- Maximum distance (in units) a player may be away from a fuel station to buy/refill a petrolcan.
-- The reported pump coords must also fall inside the zone of a known station
-- (see the per-station `radius` in config.stations.lua).
Config.MaxStationDistance = 5.0

Config.Refill = {
    tick = 250, -- Fuel Tick Rate (every 250 miliseconds)
    value = 0.50, -- Fuel Refill Value (adds 0.50% every refillTick miliseconds)
    -- Fallback price per tick, only used for pumps that do not belong to any
    -- station zone. Everywhere else the station's price per liter applies
    -- (see config.business.lua and the admin dashboard).
    price = 5,
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
    liter = 15, -- Engine Failure if more than 15 liters were refueled with the wrong fuel
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

    -- Fuel Stations
    [`prop_gas_pump_old2`] = {'gas', 'diesel', 'kerosin'},
    [`prop_gas_pump_1a`] = {'gas', 'diesel', 'kerosin'},
    [`prop_vintage_pump`] = {'gas', 'diesel', 'kerosin'},
    [`prop_gas_pump_old3`] = {'gas', 'diesel', 'kerosin'},
    [`prop_gas_pump_1c`] = {'gas', 'diesel', 'kerosin'},
    [`prop_gas_pump_1b`] = {'gas', 'diesel', 'kerosin'},
    [`prop_gas_pump_1d`] = {'gas', 'diesel', 'kerosin'},

    -- If you have a custom fuel station for electric vehicles then add them here
    -- [`model`] = {'electric'}

    -- Vehicles
    [`utillitruck2`] = {'gas', 'diesel', 'kerosin', 'electric'},

    -- Trailer
    [`armytanker`] = {'gas', 'diesel', 'kerosin'},
    [`tanker`] = {'gas', 'diesel', 'kerosin'},
    [`tanker2`] = {'gas', 'diesel', 'kerosin'},

    -- Models: Fuel Tanks
    [`prop_ind_deiseltank`] = {'kerosin'},
    [`prop_tanktrailer_01a`] = {'kerosin'},
    [`prop_air_fueltrail1`] = {'kerosin'},
    [`prop_air_fueltrail2`] = {'kerosin'},

    -- Models: Gas Tanks
    [`prop_gas_tank_01a`] = {'kerosin'},
    [`prop_gas_tank_02a`] = {'kerosin'},
    [`prop_gas_tank_02b`] = {'kerosin'},
    [`prop_gas_tank_04a`] = {'kerosin'},
    [`sf_prop_sf_gas_tank_01a`] = {'kerosin'},

    -- Models: Electric Generator
    [`prop_generator_01a`] = {'electric'},
    [`prop_generator_02a`] = {'electric'},
    [`prop_generator_03a`] = {'electric'},
    [`ch_chint04_tunnelgenerator`] = {'electric'},
    [`xm3_int3_int02_generator_01`] = {'electric'},
    [`gr_int02_generator_01`] = {'electric'},
    [`ch_prop_ch_generator_01a`] = {'electric'},
    [`m23_1_prop_m31_generator_01a`] = {'electric'},
    [`prop_generator_04`] = {'electric'},
    [`prop_air_generator_01`] = {'electric'},
    [`sf_prop_sf_air_generator_01`] = {'electric'},
}

-- Spawns the given Fuel Pump on the given coords.
-- Blips are no longer configured here: every one of these props stands inside a
-- station zone from config.stations.lua and the station carries the blip.
Config.CustomFuelStations = {
    {model = `prop_gas_pump_1c`, coords = vector4(166.44, 6461.82, 31.2, 176.24)}, -- Paleto Bay near 3021 (station pb_04)

    {model = `prop_ind_deiseltank`, coords = vector4(1761.61, 3228.0, 42.52, 232.38)}, -- Grand Senora Desert (station bc_11)
    {model = `prop_generator_01a`, coords = vector4(1787.35, 3327.75, 41.4, 303.47)}, -- Grand Senora Desert (station bc_10)

    {model = `prop_ind_deiseltank`, coords = vector4(-973.09, -3411.08, 13.84, 237.21)}, -- LS International Airport (station lsia)
    {model = `prop_ind_deiseltank`, coords = vector4(-1017.03, -3385.64, 13.84, 237.21)}, -- LS International Airport (station lsia)
}
----------------------------------------------------------------
-- Vehicle that acts as a fuel station
Config.FuelVehicles = {
    -- Vehicles
    `utillitruck2`, -- https://forge.plebmasters.de/vehicles/MjUzNDg2MjEwNg

    -- Trailer
    `armytanker`, -- https://forge.plebmasters.de/vehicles/MjkwNDY4NzUwMQ
    `tanker`, -- https://forge.plebmasters.de/vehicles/MjE2MTI0MjU0OQ
    `tanker2`, -- https://forge.plebmasters.de/vehicles/MzMwOTk1NzIxNg
}

-- Models/Props that acts as a fuel station
Config.FuelModels = {
    -- Use `` and NOT "" and NOT ''

    -- Fuel Tanks
    `prop_ind_deiseltank`, -- https://forge.plebmasters.de/objects/prop_ind_deiseltank
    `prop_tanktrailer_01a`, -- https://forge.plebmasters.de/objects/prop_tanktrailer_01a
    `prop_air_fueltrail1`, -- https://forge.plebmasters.de/objects/prop_air_fueltrail1
    `prop_air_fueltrail2`, -- https://forge.plebmasters.de/objects/prop_air_fueltrail2

    -- Gas Tanks
    `prop_gas_tank_01a`, -- https://forge.plebmasters.de/objects/prop_gas_tank_01a
    `prop_gas_tank_02a`, -- https://forge.plebmasters.de/objects/prop_gas_tank_02a
    `prop_gas_tank_02b`, -- https://forge.plebmasters.de/objects/prop_gas_tank_02b
    `prop_gas_tank_04a`, -- https://forge.plebmasters.de/objects/prop_gas_tank_04a
    `sf_prop_sf_gas_tank_01a`, -- https://forge.plebmasters.de/objects/sf_prop_sf_gas_tank_01a

    -- Electric Generators
    `prop_generator_01a`, -- https://forge.plebmasters.de/objects/prop_generator_01a
    `prop_generator_02a`, -- https://forge.plebmasters.de/objects/prop_generator_02a
    `prop_generator_03a`, -- https://forge.plebmasters.de/objects/prop_generator_03a
    `ch_chint04_tunnelgenerator`, -- https://forge.plebmasters.de/objects/ch_chint04_tunnelgenerator
    `xm3_int3_int02_generator_01`, -- https://forge.plebmasters.de/objects/xm3_int3_int02_generator_01
    `gr_int02_generator_01`, -- https://forge.plebmasters.de/objects/gr_int02_generator_01
    `ch_prop_ch_generator_01a`, -- https://forge.plebmasters.de/objects/ch_prop_ch_generator_01a
    `m23_1_prop_m31_generator_01a`, -- https://forge.plebmasters.de/objects/m23_1_prop_m31_generator_01a
    `prop_generator_04`, -- https://forge.plebmasters.de/objects/prop_generator_04
    `prop_air_generator_01`, -- https://forge.plebmasters.de/objects/prop_air_generator_01
    `sf_prop_sf_air_generator_01`, -- https://forge.plebmasters.de/objects/sf_prop_sf_air_generator_01
}
----------------------------------------------------------------
-- Fuel stations live in `config.stations.lua` now. They are no longer plain
-- blip coordinates but named entities with a zone, a stock and (once bought) an
-- owner, so the list moved out of this file. Add or edit them there, or in the
-- admin dashboard once the server has seeded them into the database.
----------------------------------------------------------------
exports('Config', function()
    return Config
end)