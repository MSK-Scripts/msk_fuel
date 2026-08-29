----------------------------------------------------------------
-- Pump maintenance.
--
-- Pumps are never mapped. A pump enters the register the first time somebody
-- fuels at it, keyed by its rounded position, which means this works on any map
-- with any set of props and needs no coordinates maintained anywhere.
--
-- Wear happens per refuel with a small chance. A worn pump fuels slower, a
-- broken one refuses to serve until it is repaired out of the company account.
----------------------------------------------------------------
Maintenance = Maintenance or {}

-- [stationId][pumpKey] = { coords = {x,y,z}, health = 0..100 }
Maintenance.pumps = Maintenance.pumps or {}

local MAX_HEALTH = 100

---A stable key for a pump position. Rounded to a full unit: the same prop
---always reports the same spot, and two pumps are never that close together.
function Maintenance.KeyOf(coords)
    return ('%d_%d'):format(math.floor(coords.x + 0.5), math.floor(coords.y + 0.5))
end

local function cfg()
    return Config.Maintenance or {}
end

function Maintenance.IsEnabled()
    return cfg().enable ~= false
end

function Maintenance.Get(stationId, pumpKey)
    return (Maintenance.pumps[stationId] or {})[pumpKey]
end

local function persist(stationId, pumpKey, pump)
    MySQL.insert(
        'INSERT INTO `msk_fuel_pumps` (`station_id`, `pump_key`, `coords`, `health`) VALUES (?, ?, ?, ?) ' ..
        'ON DUPLICATE KEY UPDATE `health` = VALUES(`health`)',
        { stationId, pumpKey, json.encode(pump.coords), pump.health }
    )
end

---Returns the pump at these coordinates, registering it on first contact.
function Maintenance.Register(stationId, coords)
    if not stationId or not coords then return nil end

    local key = Maintenance.KeyOf(coords)

    Maintenance.pumps[stationId] = Maintenance.pumps[stationId] or {}
    local existing = Maintenance.pumps[stationId][key]

    if existing then return existing, key end

    local pump = {
        coords = { x = coords.x + 0.0, y = coords.y + 0.0, z = coords.z + 0.0 },
        health = MAX_HEALTH,
    }

    Maintenance.pumps[stationId][key] = pump
    persist(stationId, key, pump)

    return pump, key
end

---Health of the pump at these coordinates. An unknown pump counts as healthy:
---it has simply never been used yet.
function Maintenance.HealthAt(stationId, coords)
    if not Maintenance.IsEnabled() then return MAX_HEALTH end

    local pump = Maintenance.Get(stationId, Maintenance.KeyOf(coords))

    return pump and pump.health or MAX_HEALTH
end

function Maintenance.IsBroken(stationId, coords)
    return Maintenance.HealthAt(stationId, coords) < (tonumber(cfg().failThreshold) or 15)
end

---Rolls for wear after a refuel. Called once per completed sale.
function Maintenance.Wear(stationId, coords)
    if not Maintenance.IsEnabled() or not stationId or not coords then return end

    local chance = math.max(0.0, math.min(tonumber(cfg().wearChance) or 0.0, 1.0))
    if chance <= 0 or math.random() > chance then return end

    local pump, key = Maintenance.Register(stationId, coords)
    if not pump then return end

    local amount = math.max(1, math.floor(tonumber(cfg().wearAmount) or 1))

    pump.health = math.max(0, pump.health - amount)
    persist(stationId, key, pump)

    Stations.MarkDirty()
end

---Cost of bringing one pump back to full.
function Maintenance.RepairCost(pump)
    local perPoint = math.max(0, math.floor(tonumber(cfg().costPerPoint) or 0))

    return math.floor((MAX_HEALTH - (pump and pump.health or MAX_HEALTH)) * perPoint)
end

---@return boolean ok, string|nil err, number|nil cost
function Maintenance.Repair(stationId, pumpKey, chargeAccount)
    local pump = Maintenance.Get(stationId, pumpKey)
    if not pump then return false, 'not_found' end
    if pump.health >= MAX_HEALTH then return false, 'not_damaged' end

    local cost = Maintenance.RepairCost(pump)

    if chargeAccount ~= false and cost > 0 then
        if Account.Get(stationId) < cost then return false, 'not_enough_balance' end
        if not Account.Book(stationId, -cost, 'pump_repair', { pump = pumpKey }) then
            return false, 'not_enough_balance'
        end
    end

    pump.health = MAX_HEALTH
    persist(stationId, pumpKey, pump)
    Stations.MarkDirty()

    return true, nil, cost
end

----------------------------------------------------------------
-- Mechanic on staff
--
-- Unlocked once per station, then repairs anything below the threshold on its
-- own and charges the station for it. A station that cannot pay simply keeps
-- its worn pumps.
----------------------------------------------------------------
function Maintenance.HasMechanic(stationId)
    local def = Stations.Get(stationId)
    return type(def) == 'table' and def.mechanic == true
end

---@return boolean ok, string|nil err
function Maintenance.UnlockMechanic(stationId)
    if Maintenance.HasMechanic(stationId) then return false, 'already_unlocked' end

    local price = math.max(0, math.floor(tonumber(cfg().mechanicUnlockPrice) or 0))

    if Account.Get(stationId) < price then return false, 'not_enough_balance' end
    if not Account.Book(stationId, -price, 'mechanic_unlock', {}) then return false, 'not_enough_balance' end

    Supply.SetStationFlag(stationId, 'mechanic', true)

    return true
end

function Maintenance.RunMechanics()
    if not Maintenance.IsEnabled() then return end

    local threshold = tonumber(cfg().mechanicThreshold) or 40

    for stationId, def in pairs(Config.Stations or {}) do
        if Stations.IsOwned(def) and Maintenance.HasMechanic(stationId) then
            for pumpKey, pump in pairs(Maintenance.pumps[stationId] or {}) do
                if pump.health < threshold then
                    -- A station that cannot afford it keeps the worn pump; the
                    -- repair simply does not happen this round.
                    Maintenance.Repair(stationId, pumpKey, true)
                end
            end
        end
    end
end

---Pumps of a station, for the dashboard.
function Maintenance.Payload(stationId)
    local out = {}

    for pumpKey, pump in pairs(Maintenance.pumps[stationId] or {}) do
        out[#out + 1] = {
            key = pumpKey,
            coords = pump.coords,
            health = pump.health,
            repairCost = Maintenance.RepairCost(pump),
            broken = pump.health < (tonumber(cfg().failThreshold) or 15),
        }
    end

    table.sort(out, function(a, b) return a.key < b.key end)
    return out
end

---Health per pump for the client, so a worn pump can fuel slower and a broken
---one can grey itself out without asking the server first.
function Maintenance.ClientPayload(stationId)
    if not Maintenance.IsEnabled() then return nil end

    local out = {}

    for pumpKey, pump in pairs(Maintenance.pumps[stationId] or {}) do
        -- Only pumps that are actually worn: a healthy pump behaves like it
        -- always did, and sending all of them would put the whole register on
        -- the wire on every sync.
        if pump.health < MAX_HEALTH then out[pumpKey] = pump.health end
    end

    if next(out) == nil then return nil end
    return out
end

CreateThread(function()
    while not AdminStore.ready do Wait(1000) end

    while true do
        local minutes = math.max(1, tonumber(cfg().mechanicIntervalMinutes) or 20)
        Wait(minutes * 60000)

        Maintenance.RunMechanics()
    end
end)
