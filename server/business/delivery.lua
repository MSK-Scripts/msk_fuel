----------------------------------------------------------------
-- Delivery runs.
--
-- The server owns the order: what was bought, for whom, how far along it is.
-- The client drives the truck and reports arrival, but every report is checked
-- against where the player actually is, and the cargo can only ever shrink on
-- the way (crash leak), never grow.
--
-- Two flavours share the whole flow:
--   * a station order, paid up front out of the company account. The fuel lands
--     in that station's tank, and an employee earns their rank's bonus.
--   * a public job at an unowned station, which costs the player nothing and
--     pays a reward out of the system. That is what keeps unowned stations
--     supplied without an admin doing it by hand.
----------------------------------------------------------------
Delivery = Delivery or {}

-- [playerId] = order. One run per player: the truck is theirs, and two orders
-- at once would mean two trucks and no way to tell which one is being unloaded.
Delivery.active = Delivery.active or {}

local STAGE_TO_DEPOT = 'to_depot'
local STAGE_TO_STATION = 'to_station'

local function depots()
    return Config.FuelDepots or {}
end

local function pickDepot()
    local list = depots()
    if #list == 0 then return nil end

    return list[math.random(#list)]
end

local function vehicleSpec(vehicleType)
    return (Config.DeliveryVehicles or {})[vehicleType]
end

---Everything the client needs to run the job, and nothing it could abuse.
local function clientPayload(order)
    local def = Stations.Get(order.stationId)
    local station = Stations.Coords(def)

    -- The depot coords come from the config as a vector4; sent as a plain table
    -- so both sides read the same fields regardless of how the wire treats
    -- FiveM vector types.
    local depot = order.depot and {
        label = order.depot.label,
        coords = {
            x = (order.depot.coords.x or 0.0) + 0.0,
            y = (order.depot.coords.y or 0.0) + 0.0,
            z = (order.depot.coords.z or 0.0) + 0.0,
            w = (order.depot.coords.w or 0.0) + 0.0,
        },
    } or nil

    return {
        stationId = order.stationId,
        stationLabel = def and def.label or order.stationId,
        stationCoords = station and { x = station.x, y = station.y, z = station.z } or nil,
        fuelType = order.fuelType,
        amount = order.amount,
        vehicleType = order.vehicleType,
        vehicle = vehicleSpec(order.vehicleType),
        depot = depot,
        stage = order.stage,
        public = order.public == true,
        maxLeak = math.max(0.0, math.min(tonumber((Config.Delivery or {}).maxLeak) or 0.3, 1.0)),
    }
end

function Delivery.Get(playerId)
    return Delivery.active[playerId]
end

function Delivery.Has(playerId)
    return Delivery.active[playerId] ~= nil
end

---Ends a run without delivering. `refund` decides whether the paid order cost
---is partly given back.
function Delivery.Cancel(playerId, refund, reason)
    local order = Delivery.active[playerId]
    if not order then return end

    Delivery.active[playerId] = nil

    if refund and order.cost and order.cost > 0 then
        local share = math.max(0.0, math.min(tonumber((Config.Delivery or {}).abortRefund) or 0.0, 1.0))
        local back = math.floor(order.cost * share)

        if back > 0 then
            Account.Book(order.stationId, back, 'delivery_refund', { reason = reason, liters = 0 })
        end
    end

    TriggerClientEvent('msk_fuel:delivery:cancel', playerId, reason)
end

----------------------------------------------------------------
-- Starting a run
----------------------------------------------------------------

---Order for a station the player manages. Paid up front out of its account.
---@return boolean ok, string|nil err
function Delivery.StartOrder(playerId, stationId, fuelType, amount, vehicleType)
    if Delivery.Has(playerId) then return false, 'delivery_running' end

    local def = Stations.Get(stationId)
    if not def then return false, 'not_found' end
    if not Stations.SellsFuelType(def, fuelType) then return false, 'no_tank' end

    local spec = vehicleSpec(vehicleType)
    if not spec then return false, 'bad_vehicle' end

    amount = math.max(1, math.floor(tonumber(amount) or 0))
    amount = math.min(amount, math.floor(tonumber(spec.capacity) or 0))

    -- Ordering more than fits would burn the money on fuel that gets thrown
    -- away at the unload.
    amount = math.min(amount, Supply.FreeSpace(stationId, fuelType))
    if amount <= 0 then return false, 'tank_full' end

    local depot = pickDepot()
    if not depot then return false, 'no_depot' end

    local cost = Supply.CostOf(fuelType, amount, vehicleType)

    if Account.Get(stationId) < cost then return false, 'not_enough_balance' end
    if not Account.Book(stationId, -cost, 'delivery_order', { fuelType = fuelType, liters = amount }) then
        return false, 'not_enough_balance'
    end

    Delivery.active[playerId] = {
        stationId = stationId,
        fuelType = fuelType,
        amount = amount,
        vehicleType = vehicleType,
        cost = cost,
        depot = depot,
        stage = STAGE_TO_DEPOT,
        public = false,
        startedAt = os.time(),
        identifier = Ownership.IdentifierOf(playerId),
    }

    TriggerClientEvent('msk_fuel:delivery:start', playerId, clientPayload(Delivery.active[playerId]))

    return true
end

---Public job at an unowned station. Costs the player nothing, pays a reward.
---@return boolean ok, string|nil err
function Delivery.StartPublic(playerId, stationId, fuelType)
    if Delivery.Has(playerId) then return false, 'delivery_running' end

    local def = Stations.Get(stationId)
    if not def then return false, 'not_found' end
    if Stations.IsOwned(def) then return false, 'station_owned' end

    local cfg = def.publicDelivery
    if type(cfg) ~= 'table' or cfg.enable ~= true then return false, 'no_public_job' end
    if not Stations.SellsFuelType(def, fuelType) then return false, 'no_tank' end

    -- Fixed size: a public job is a trucker run, not something the player gets
    -- to scale for a bigger payout.
    local amount = math.max(1, math.floor(tonumber(cfg.amount) or 1000))
    amount = math.min(amount, Supply.FreeSpace(stationId, fuelType))
    if amount <= 0 then return false, 'tank_full' end

    -- The rig follows from the amount rather than from the player, so nobody
    -- takes a tanker to move 200 liters: the smallest one that fits the load,
    -- or the biggest there is when nothing fits.
    local vehicleType, chosen, biggest, biggestKey

    for key, spec in pairs(Config.DeliveryVehicles or {}) do
        local capacity = tonumber(spec.capacity) or 0

        if capacity >= amount and (not chosen or capacity < chosen) then
            vehicleType, chosen = key, capacity
        end

        if not biggest or capacity > biggest then
            biggestKey, biggest = key, capacity
        end
    end

    if not vehicleType then
        vehicleType = biggestKey
        amount = math.min(amount, math.floor(biggest or 0))
    end

    if not vehicleType or amount <= 0 then return false, 'bad_vehicle' end

    local depot = pickDepot()
    if not depot then return false, 'no_depot' end

    Delivery.active[playerId] = {
        stationId = stationId,
        fuelType = fuelType,
        amount = amount,
        vehicleType = vehicleType,
        cost = 0,
        depot = depot,
        stage = STAGE_TO_DEPOT,
        public = true,
        rewardPerLiter = math.max(0.0, tonumber(cfg.rewardPerLiter) or 0.0),
        startedAt = os.time(),
        identifier = Ownership.IdentifierOf(playerId),
    }

    TriggerClientEvent('msk_fuel:delivery:start', playerId, clientPayload(Delivery.active[playerId]))

    return true
end

----------------------------------------------------------------
-- Progress
----------------------------------------------------------------

-- Loaded at the depot. Checked against the depot coordinates so the stage
-- cannot simply be skipped from anywhere on the map.
RegisterNetEvent('msk_fuel:delivery:loaded', function()
    local playerId = source
    local order = Delivery.active[playerId]

    if not order or order.stage ~= STAGE_TO_DEPOT then return end

    local ped = GetPlayerPed(playerId)
    if not ped or ped == 0 then return end

    local depot = order.depot and order.depot.coords
    if not depot then return end

    local maxDist = tonumber((Config.Delivery or {}).depotDistance) or 25.0
    local coords = vector3((depot.x or 0.0) + 0.0, (depot.y or 0.0) + 0.0, (depot.z or 0.0) + 0.0)

    if #(GetEntityCoords(ped) - coords) > maxDist then return end

    order.stage = STAGE_TO_STATION
    TriggerClientEvent('msk_fuel:delivery:stage', playerId, clientPayload(order))
end)

-- Unloaded at the station. `leak` is the share the client says was lost to
-- crash damage; it is clamped, so the worst a manipulated client can do is
-- deliver LESS than it bought.
RegisterNetEvent('msk_fuel:delivery:deliver', function(leak)
    local playerId = source
    local order = Delivery.active[playerId]

    if not order or order.stage ~= STAGE_TO_STATION then return end
    if not CheckRateLimit(playerId, 'deliveryDeliver', 1000) then return end

    local def = Stations.Get(order.stationId)
    if not def then
        Delivery.Cancel(playerId, false, 'not_found')
        return
    end

    local ped = GetPlayerPed(playerId)
    if not ped or ped == 0 then return end

    local station = Stations.Coords(def)
    local maxDist = tonumber((Config.Delivery or {}).unloadDistance) or 30.0

    if not station or #(GetEntityCoords(ped) - station) > maxDist then return end

    local maxLeak = math.max(0.0, math.min(tonumber((Config.Delivery or {}).maxLeak) or 0.3, 1.0))
    leak = math.max(0.0, math.min(tonumber(leak) or 0.0, maxLeak))

    local delivered = math.floor(order.amount * (1.0 - leak))
    local added = math.floor(Stock.Add(order.stationId, order.fuelType, delivered))

    Delivery.active[playerId] = nil
    Stations.MarkDirty()

    local label = def.label or order.stationId

    if order.public then
        local reward = math.floor(added * (order.rewardPerLiter or 0.0))

        AddMoney(playerId, reward)
        Account.Log(order.stationId, 'delivery_public', 0.0, { liters = added, reward = reward })
        Config.Notification(playerId, Translate('delivery_done_public', added, reward), 'success')
    else
        Account.Log(order.stationId, 'delivery_done', 0.0, { fuelType = order.fuelType, liters = added })

        -- An employee earns their rank's bonus on top of their salary; the
        -- owner driving their own truck is just moving their own money around.
        local bonus = 0

        if order.identifier and def.owner ~= order.identifier then
            local employee = Employees.Get(order.stationId, order.identifier)
            local rank = employee and Employees.Rank(order.stationId, employee.rank_id)

            bonus = math.max(0, math.floor(tonumber(rank and rank.delivery_bonus) or 0))

            if bonus > 0 and Account.Get(order.stationId) >= bonus then
                Account.Book(order.stationId, -bonus, 'delivery_bonus', { to = order.identifier })
                AddMoney(playerId, bonus)
            else
                bonus = 0
            end
        end

        if order.identifier then
            Employees.AddStats(order.stationId, order.identifier, {
                deliveries = 1,
                earnings = bonus,
                last_active = os.time(),
            })
        end

        Config.Notification(playerId, Translate('delivery_done', added, label), 'success')
    end

    TriggerClientEvent('msk_fuel:delivery:finish', playerId)
end)

-- The client gives up: truck destroyed, trailer gone, or the player walked away
-- from the whole thing.
RegisterNetEvent('msk_fuel:delivery:abort', function(reason)
    local playerId = source
    if not Delivery.active[playerId] then return end

    Delivery.Cancel(playerId, true, type(reason) == 'string' and reason:sub(1, 40) or 'aborted')
    Config.Notification(playerId, Translate('delivery_aborted'), 'error')
end)

AddEventHandler('playerDropped', function()
    if source and Delivery.active[source] then
        Delivery.Cancel(source, true, 'disconnected')
    end
end)

-- An order nobody finishes would block that player forever and hold fuel the
-- station already paid for.
CreateThread(function()
    while true do
        Wait(60000)

        local limit = math.max(1, tonumber((Config.Delivery or {}).timeoutMinutes) or 30) * 60
        local now = os.time()

        for playerId, order in pairs(Delivery.active) do
            if (now - (order.startedAt or now)) > limit then
                Delivery.Cancel(playerId, true, 'timeout')
                Config.Notification(playerId, Translate('delivery_timeout'), 'error')
            end
        end
    end
end)
