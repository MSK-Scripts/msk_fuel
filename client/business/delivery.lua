----------------------------------------------------------------
-- Driving a delivery run.
--
-- The server owns the order and checks every step; this side spawns the rig,
-- points the player at the depot and back, and watches the cargo. The one thing
-- only the client can know is how badly the truck was crashed, so it measures
-- the damage and reports the resulting leak. The server clamps it, which means
-- a manipulated client can only ever deliver LESS than it bought.
----------------------------------------------------------------
DeliveryRun = DeliveryRun or { active = nil }

local blip, vehicle, trailer
local watchdog = false

local function clearBlip()
    if blip and DoesBlipExist(blip) then RemoveBlip(blip) end
    blip = nil
end

local function setRouteTo(coords, label)
    clearBlip()

    blip = AddBlipForCoord(coords.x, coords.y, coords.z)
    SetBlipSprite(blip, 361)
    SetBlipColour(blip, 5)
    SetBlipScale(blip, 0.9)
    SetBlipRoute(blip, true)
    SetBlipRouteColour(blip, 5)

    AddTextEntry('msk_fuel_delivery', label)
    BeginTextCommandSetBlipName('msk_fuel_delivery')
    EndTextCommandSetBlipName(blip)
end

local function cleanUp(deleteVehicle)
    clearBlip()
    watchdog = false

    if deleteVehicle then
        if trailer and DoesEntityExist(trailer) then DeleteEntity(trailer) end
        if vehicle and DoesEntityExist(vehicle) then DeleteEntity(vehicle) end
    end

    vehicle, trailer = nil, nil
    DeliveryRun.active = nil
end

----------------------------------------------------------------
-- Cargo damage
--
-- Body health runs from 1000 (pristine) down to 0. The share lost is taken as
-- the share of cargo spilled, capped at what the server allows. The trailer
-- counts too when there is one: that is where the fuel actually rides.
----------------------------------------------------------------
local function currentLeak()
    local order = DeliveryRun.active
    if not order then return 0.0 end

    local worst = 0.0

    for _, entity in ipairs({ vehicle, trailer }) do
        if entity and DoesEntityExist(entity) then
            local health = math.max(0.0, math.min(GetVehicleBodyHealth(entity), 1000.0))
            local damage = (1000.0 - health) / 1000.0

            if damage > worst then worst = damage end
        end
    end

    return math.min(worst, order.maxLeak or 0.3)
end

DeliveryRun.Leak = currentLeak

local function abort(reason)
    if not DeliveryRun.active then return end

    TriggerServerEvent('msk_fuel:delivery:abort', reason)
    cleanUp(true)
end

----------------------------------------------------------------
-- Spawning the rig
----------------------------------------------------------------
-- The rig is handed over where the player is standing, at the station. The run
-- is "go and fetch it", so there is nothing waiting at the depot.
local function spawnRig(spec)
    if not MSK.Request.Model(spec.model) then return false end

    local ped = PlayerPedId()
    local heading = GetEntityHeading(ped)

    -- A truck plus trailer needs room, so it goes a good way in front of the
    -- player rather than on top of them.
    local spawn = GetOffsetFromEntityInWorldCoords(ped, 0.0, 12.0, 0.0)

    if not MSK.IsSpawnPointClear(spawn, 6.0) then
        Config.Notification(nil, Translate('delivery_spawn_blocked'), 'error')
        return false
    end

    vehicle = CreateVehicle(spec.model, spawn.x, spawn.y, spawn.z, heading, true, false)
    SetVehicleOnGroundProperly(vehicle)
    SetVehicleHasBeenOwnedByPlayer(vehicle, true)
    SetEntityAsMissionEntity(vehicle, true, true)
    SetVehicleBodyHealth(vehicle, 1000.0)

    if spec.trailer and MSK.Request.Model(spec.trailer) then
        local behind = GetOffsetFromEntityInWorldCoords(ped, 0.0, 4.0, 0.0)

        trailer = CreateVehicle(spec.trailer, behind.x, behind.y, behind.z, heading, true, false)
        SetVehicleOnGroundProperly(trailer)
        SetEntityAsMissionEntity(trailer, true, true)
        SetVehicleBodyHealth(trailer, 1000.0)
        AttachVehicleToTrailer(vehicle, trailer, 1.0)
    end

    -- The truck comes with keys: it is the station's vehicle, handed over for
    -- the run.
    SetVehicleNeedsToBeHotwired(vehicle, false)
    SetPedIntoVehicle(PlayerPedId(), vehicle, -1)

    return true
end

----------------------------------------------------------------
-- The run itself
----------------------------------------------------------------
local function startWatchdog()
    if watchdog then return end
    watchdog = true

    CreateThread(function()
        while watchdog and DeliveryRun.active do
            Wait(1000)

            -- Losing the rig ends the run. Without this the player could walk
            -- away from a wreck and keep the order open forever.
            if not vehicle or not DoesEntityExist(vehicle) then
                Config.Notification(nil, Translate('delivery_vehicle_lost'), 'error')
                abort('vehicle_lost')
                return
            end

            if IsEntityDead(vehicle) or IsVehicleUndriveable(vehicle) then
                Config.Notification(nil, Translate('delivery_vehicle_destroyed'), 'error')
                abort('vehicle_destroyed')
                return
            end

            if DeliveryRun.active.trailerRequired and (not trailer or not DoesEntityExist(trailer)) then
                Config.Notification(nil, Translate('delivery_trailer_lost'), 'error')
                abort('trailer_lost')
                return
            end
        end
    end)
end

---Waits until the player is inside `distance` of the target, then runs `onArrive`.
local function waitForArrival(getTarget, distance, onArrive)
    CreateThread(function()
        while DeliveryRun.active do
            local target = getTarget()

            if not target then return end

            local dist = #(GetEntityCoords(PlayerPedId()) - target)

            if dist <= distance then
                onArrive()
                return
            end

            -- Far away: a slow tick is enough, the drive takes minutes.
            Wait(dist > 200.0 and 2000 or 500)
        end
    end)
end

local function driveToStation()
    local order = DeliveryRun.active
    if not order or not order.stationCoords then return end

    local coords = vector3(order.stationCoords.x, order.stationCoords.y, order.stationCoords.z)
    setRouteTo(coords, order.stationLabel or Translate('fuel_station_blip'))
    Config.Notification(nil, Translate('delivery_loaded', order.amount, order.stationLabel or ''), 'success')

    waitForArrival(function() return coords end, Config.Delivery.unloadDistance or 30.0, function()
        local leak = currentLeak()

        MSK.Progress.Start({
            duration = 8000,
            text = Translate('delivery_unloading'),
            canCancel = false,
            disable = { move = true, vehicle = true, combat = true },
        })

        if not DeliveryRun.active then return end

        TriggerServerEvent('msk_fuel:delivery:deliver', leak)
    end)
end

local function driveToDepot()
    local order = DeliveryRun.active
    if not order or not order.depot or not order.depot.coords then return end

    local depot = order.depot.coords
    local coords = vector3(depot.x, depot.y, depot.z)

    setRouteTo(coords, order.depot.label or Translate('delivery_depot'))
    Config.Notification(nil, Translate('delivery_started', order.depot.label or ''), 'info')

    waitForArrival(function() return coords end, Config.Delivery.depotDistance or 25.0, function()
        MSK.Progress.Start({
            duration = 10000,
            text = Translate('delivery_loading'),
            canCancel = false,
            disable = { move = true, vehicle = true, combat = true },
        })

        if not DeliveryRun.active then return end

        TriggerServerEvent('msk_fuel:delivery:loaded')
    end)
end

---Takes a public job at the unowned station the given pump belongs to. The
---station decides the fuel type: whichever of its tanks is emptiest is the one
---that needs a run.
function DeliveryRun.TakePublicJob(pump)
    if DeliveryRun.active then
        return Config.Notification(nil, Translate('delivery_already_running'), 'error')
    end

    local stationId, station = Station.From(pump)
    if not stationId or not station then return end

    local fuelType, worst

    for _, candidate in ipairs(station.fuelTypes or {}) do
        local stock = (station.stock and station.stock[candidate]) or 0

        if not worst or stock < worst then
            fuelType, worst = candidate, stock
        end
    end

    if not fuelType then return end

    local res = MSK.Trigger('msk_fuel:delivery:public', {
        id = stationId,
        coords = GetEntityCoords(PlayerPedId()),
        fuelType = fuelType,
    })

    if not res or not res.ok then
        Config.Notification(nil, Translate('delivery_public_failed'), 'error')
    end
end

RegisterNetEvent('msk_fuel:delivery:start', function(order)
    if type(order) ~= 'table' then return end
    if DeliveryRun.active then return end

    local spec = order.vehicle
    if type(spec) ~= 'table' or not spec.model then return end

    DeliveryRun.active = order
    DeliveryRun.active.trailerRequired = spec.trailer ~= nil

    if not spawnRig(spec) then
        TriggerServerEvent('msk_fuel:delivery:abort', 'spawn_failed')
        cleanUp(true)
        return
    end

    startWatchdog()
    driveToDepot()
end)

RegisterNetEvent('msk_fuel:delivery:stage', function(order)
    if not DeliveryRun.active or type(order) ~= 'table' then return end

    DeliveryRun.active.stage = order.stage

    if order.stage == 'to_station' then
        driveToStation()
    end
end)

RegisterNetEvent('msk_fuel:delivery:finish', function()
    cleanUp(true)
end)

RegisterNetEvent('msk_fuel:delivery:cancel', function()
    cleanUp(true)
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    cleanUp(true)
end)
