----------------------------------------------------------------
-- Economy configuration for the fuel business.
--
-- Everything in this file is a SEED. On the first start the values are written
-- into `msk_fuel_settings` and from then on the DATABASE is the source of truth
-- (edit them in the admin dashboard). Changing a value here after the first
-- start has no effect until the table is re-seeded.
--
-- The static config (config.lua) keeps everything the code hooks into and is
-- never DB-managed.
----------------------------------------------------------------

-- Command that opens the admin dashboard.
Config.adminCommand = 'fueladmin'

-- Groups allowed to open the admin dashboard. `group.admin` always may,
-- `group.user` never may, regardless of what is listed here.
Config.dashboardGroups = { 'admin', 'mod' }

-- Dashboard colours (live editable in the Settings tab).
Config.Theme = {
    accent = '#00E676',
    bg = '#0a0b0d',
    panel = '#131317',
    textPrimary = '#f0ede8',
    textSecondary = '#b0adb8',
}

----------------------------------------------------------------
-- Prices
----------------------------------------------------------------

-- Server-wide base price per liter (per kWh for electric). Every station's
-- dynamic price is derived from these, so this is the knob that moves the
-- whole map at once.
Config.BasePrices = {
    gas = 1.70,
    diesel = 1.50,
    kerosin = 1.90,
    electric = 0.50,
}

-- Hard bounds. A station price can never leave this range, no matter what the
-- market does or what an owner sets manually.
Config.PriceLimits = {
    gas = { min = 0.80, max = 4.00 },
    diesel = { min = 0.70, max = 3.50 },
    kerosin = { min = 0.90, max = 5.00 },
    electric = { min = 0.20, max = 2.00 },
}

-- Market parameters for the dynamic price model:
--   price = base * stockFactor * demandFactor,  clamped to PriceLimits
--   stockFactor  = 1 + kStock  * (1 - stock/capacity)
--   demandFactor = 1 + kDemand * (recentDemand / demandNorm)
--
-- `drift` and `decay` are used by the market cron in phase 5. They are seeded
-- now so the settings row does not have to change shape later.
Config.Market = {
    kStock = 0.35,      -- how much an empty tank raises the price
    kDemand = 0.25,     -- how much recent demand raises the price
    demandNorm = 5000,  -- liters that count as "normal" demand per station
    drift = 0.02,       -- max relative base price move per market tick
    decay = 0.5,        -- share of the demand counter that survives a tick
    tickMinutes = 60,   -- market tick interval

    -- The base price drifts around the value set here (or in the dashboard),
    -- not away from it: heavy server-wide demand pushes it up, quiet hours pull
    -- it back. Without an anchor a quiet server would drift to the floor and
    -- stay there.
    anchorPull = 0.5,   -- share of the gap to the anchor closed per quiet tick
}

----------------------------------------------------------------
-- Stock
----------------------------------------------------------------

-- Default tank capacity per fuel type, in liters (kWh for electric). Used when
-- a station definition does not carry its own capacity.
Config.DefaultCapacity = {
    gas = 20000,
    diesel = 20000,
    kerosin = 10000,
    electric = 5000,
}

----------------------------------------------------------------
-- Neutral (unowned) stations
----------------------------------------------------------------

-- What happens to the money a player pays at a station nobody owns.
--   'void'    -> the money simply disappears (default, keeps the economy tight)
--   'society' -> paid into the society account named in `societyName`
Config.NeutralIncome = {
    mode = 'void',
    societyName = 'society_fuel',
}

-- Default purchase price for a station that is flagged purchasable and does not
-- define its own price.
Config.DefaultPurchasePrice = 250000

-- Share of the purchase price an owner gets back when selling the station to
-- the system. 0.6 means 60 percent, so buying and reselling is a loss rather
-- than a way to park money.
Config.SellRefundRatio = 0.6

----------------------------------------------------------------
-- Pump maintenance
----------------------------------------------------------------

-- Pumps wear out as they are used. A worn pump fuels slower, a broken one stops
-- working until somebody pays to fix it.
--
-- Pumps are not mapped anywhere: a pump enters the register the first time
-- somebody fuels at it, keyed by its position. That way this works on any map,
-- with any set of props, without a single coordinate having to be maintained.
Config.Maintenance = {
    enable = true,

    -- Chance per refuel that the pump takes damage, and how much it loses.
    wearChance = 0.03,
    wearAmount = 4,

    -- Below this health the pump fuels slower (see slowFactor); below
    -- failThreshold it stops working entirely.
    slowThreshold = 50,
    failThreshold = 15,

    -- How much slower a worn pump is. 2.0 means twice the time per liter.
    slowFactor = 2.0,

    -- Repair cost per missing health point, paid out of the company account.
    costPerPoint = 25,

    -- Mechanic on staff: unlocked once, then repairs pumps automatically below
    -- the threshold and charges the station for the parts.
    mechanicUnlockPrice = 35000,
    mechanicThreshold = 40,
    mechanicIntervalMinutes = 20,
}

----------------------------------------------------------------
-- Supply
----------------------------------------------------------------

-- What a station pays per liter when it restocks. The margin between this and
-- the pump price is what a station actually earns, so these two sets of numbers
-- have to be tuned together.
Config.Wholesale = {
    gas = 1.05,
    diesel = 0.90,
    kerosin = 1.20,
    electric = 0.30,
}

-- Ordering through the NPC driver skips the drive entirely, so it costs more.
-- 1.35 means 35 percent on top of the wholesale price. Driving it yourself is
-- meant to be the cheaper option.
Config.NpcSurcharge = 1.35

-- One-off price a station pays to unlock its NPC driver. Until it is unlocked,
-- the only way to restock is an actual delivery run.
Config.NpcUnlockPrice = 50000

-- Vehicles a delivery can be run with. Bigger rigs carry more and get a bulk
-- discount on the wholesale price, so the large orders are worth the hassle.
--   model    spawned vehicle
--   trailer  optional trailer model, attached behind it
--   capacity liters this rig can carry in one run
--   discount share off the wholesale price (0.1 = 10 percent cheaper)
Config.DeliveryVehicles = {
    van = {
        label = 'Van',
        model = `boxville3`,
        capacity = 500,
        discount = 0.0,
    },
    truck = {
        label = 'LKW',
        model = `mule`,
        capacity = 1500,
        discount = 0.05,
    },
    tanker = {
        label = 'Tanklaster',
        model = `phantom`,
        trailer = `tanker`,
        capacity = 3000,
        discount = 0.10,
    },
}

Config.Delivery = {
    -- Crash damage spills cargo. This is the most a run can lose, the client
    -- reports the actual share and the server clamps it to this.
    maxLeak = 0.30,

    -- Share of the order cost refunded when a run is aborted (vehicle
    -- destroyed, player disconnected). 0 means the money is simply gone.
    abortRefund = 0.25,

    -- How long a run may take before the server drops it, in minutes. Stops an
    -- abandoned order from blocking the station forever.
    timeoutMinutes = 30,

    -- Distances that count as "arrived" at the depot and back at the station.
    depotDistance = 25.0,
    unloadDistance = 30.0,
}

-- Public delivery jobs at stations nobody owns. Enabled per station in the
-- admin dashboard; these are the defaults a station starts with.
Config.PublicDelivery = {
    enable = false,

    -- Paid out of the system, not out of a company account.
    rewardPerLiter = 0.35,

    -- Fixed amount a public run always carries. Players do not get to size
    -- their own paycheck.
    amount = 1000,
}

-- Automatic restocking. For an owned station this needs the NPC driver
-- unlocked and is switched on by the owner; for an unowned one the admin
-- decides. Either way it buys at the NPC price and stops when the money or the
-- tank space runs out.
Config.AutoRestock = {
    intervalMinutes = 30,

    -- Refill kicks in below this share of capacity, and fills back up to it.
    threshold = 0.35,
    target = 0.9,
}

----------------------------------------------------------------
-- Payroll
----------------------------------------------------------------

-- Salaries are paid per rank (edit them in the owner dashboard) out of the
-- station's company account.
Config.Payroll = {
    enable = true,
    intervalMinutes = 60,

    -- Only employees who are ONLINE get paid. Paying absent staff would let a
    -- station bleed its account dry for players who are not there, and the
    -- payout goes into the pocket of a player who has to exist to receive it.
    onlineOnly = true,
}

-- Maximum a station can hold on its company account. Keeps a runaway station
-- from turning into an unbounded money store; set to 0 for no limit.
Config.MaxStationBalance = 0
