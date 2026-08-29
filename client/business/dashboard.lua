----------------------------------------------------------------
-- Owner dashboard: opening it, and forwarding its NUI callbacks.
--
-- Every callback carries the station id AND the pump coordinates. The server
-- uses the coordinates to verify the player is really standing there, so a
-- dashboard cannot be driven from across the map.
----------------------------------------------------------------
OwnerNui = OwnerNui or { open = false, stationId = nil, coords = nil }

-- Stations this player can manage: the ones they own plus the ones they are
-- employed at with at least one permission. Pushed by the server on join, on
-- purchase, on sale, when hired or fired, on a rank change, and when an admin
-- takes a station away.
Station.manageable = Station.manageable or {}

function Station.CanManage(stationId)
    return stationId ~= nil and Station.manageable[stationId] == true
end

RegisterNetEvent('msk_fuel:setOwnedStations', function(list)
    local manageable = {}

    for _, id in ipairs(type(list) == 'table' and list or {}) do
        manageable[id] = true
    end

    Station.manageable = manageable
end)

local function closeNui()
    SetNuiFocus(false, false)
    OwnerNui.open = false
    OwnerNui.stationId = nil
    OwnerNui.coords = nil
end

---Opens the dashboard for the station the given pump belongs to.
function OwnerNui.Open(pumpCoords)
    if OwnerNui.open then return end

    local stationId = Station.From(pumpCoords)
    if not stationId then return end

    local coords = GetEntityCoords(PlayerPedId())
    local payload = MSK.Trigger('msk_fuel:owner:bootstrap', { id = stationId, coords = coords })

    if not payload or not payload.ok then
        return Config.Notification(nil, Translate('station_no_access'), 'error')
    end

    OwnerNui.open = true
    OwnerNui.stationId = stationId
    OwnerNui.coords = coords

    SetNuiFocus(true, true)
    SendNUIMessage({ action = 'openOwner', data = payload.data })
end

---Buys the station the given pump belongs to.
function OwnerNui.Buy(pumpCoords)
    local stationId = Station.From(pumpCoords)
    if not stationId then return end

    local coords = GetEntityCoords(PlayerPedId())
    local res = MSK.Trigger('msk_fuel:owner:buy', { id = stationId, coords = coords })

    if not res or not res.ok then
        -- The server already notified about the money; anything else is a state
        -- the client could not know about.
        if res and res.err ~= 'not_enough_money' then
            Config.Notification(nil, Translate('station_buy_failed'), 'error')
        end
        return
    end

    -- Straight into the dashboard of the station just bought.
    OwnerNui.open = true
    OwnerNui.stationId = stationId
    OwnerNui.coords = coords

    SetNuiFocus(true, true)
    SendNUIMessage({ action = 'openOwner', data = res.data })
end

----------------------------------------------------------------
-- NUI callbacks. The station id and coordinates are added here rather than in
-- the UI, so the browser has no say in which station it is talking about.
----------------------------------------------------------------
local function forward(event)
    return function(data, cb)
        if not OwnerNui.stationId then
            cb({ ok = false, err = 'not_found' })
            return
        end

        local payload = type(data) == 'table' and data or {}
        payload.id = OwnerNui.stationId
        payload.coords = GetEntityCoords(PlayerPedId())

        local res = MSK.Trigger(event, payload)

        -- Selling closes the business, so it closes the dashboard with it.
        if res and res.ok and res.closed then
            closeNui()
        end

        cb(res or { ok = false, err = 'no_response' })
    end
end

RegisterNUICallback('owner:close', function(_data, cb)
    closeNui()
    cb('ok')
end)

RegisterNUICallback('owner:refresh', forward('msk_fuel:owner:bootstrap'))
RegisterNUICallback('owner:rename', forward('msk_fuel:owner:rename'))
RegisterNUICallback('owner:sell', forward('msk_fuel:owner:sell'))
RegisterNUICallback('owner:deposit', forward('msk_fuel:owner:deposit'))
RegisterNUICallback('owner:withdraw', forward('msk_fuel:owner:withdraw'))
RegisterNUICallback('owner:pricing', forward('msk_fuel:owner:pricing'))
RegisterNUICallback('owner:onlinePlayers', forward('msk_fuel:owner:onlinePlayers'))
RegisterNUICallback('owner:hire', forward('msk_fuel:owner:hire'))
RegisterNUICallback('owner:fire', forward('msk_fuel:owner:fire'))
RegisterNUICallback('owner:setRank', forward('msk_fuel:owner:setRank'))
RegisterNUICallback('owner:rank:save', forward('msk_fuel:owner:rank:save'))
RegisterNUICallback('owner:rank:delete', forward('msk_fuel:owner:rank:delete'))
RegisterNUICallback('owner:npc:unlock', forward('msk_fuel:owner:npc:unlock'))
RegisterNUICallback('owner:autoRestock', forward('msk_fuel:owner:autoRestock'))
RegisterNUICallback('owner:restock', forward('msk_fuel:owner:restock'))
RegisterNUICallback('owner:delivery:start', forward('msk_fuel:owner:delivery:start'))
RegisterNUICallback('owner:pump:repair', forward('msk_fuel:owner:pump:repair'))
RegisterNUICallback('owner:mechanic:unlock', forward('msk_fuel:owner:mechanic:unlock'))

-- Pull what this player owns once the framework is up. Without it the "manage
-- this station" option would be missing until the next purchase or sync.
CreateThread(function()
    while not MSK?.Player?.playerId do Wait(250) end
    Wait(1500)

    local list = MSK.Trigger('msk_fuel:owner:myStations')
    local manageable = {}

    for _, id in ipairs(type(list) == 'table' and list or {}) do
        manageable[id] = true
    end

    Station.manageable = manageable
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    SetNuiFocus(false, false)
end)
