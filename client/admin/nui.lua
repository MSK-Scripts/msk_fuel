-- NUI callbacks for the admin dashboard. Every mutating callback forwards to
-- the gated server callback and returns its response verbatim, so the UI never
-- decides whether something was allowed.

local function round(n, dp)
    local m = 10 ^ (dp or 2)
    return math.floor(n * m + 0.5) / m
end

local function forward(event)
    return function(data, cb)
        local res = MSK.Trigger(event, data)
        cb(res or { ok = false, err = 'no_response' })
    end
end

-- Capture the player's current position for a coordinate field.
RegisterNUICallback('admin:getCurrentCoords', function(_data, cb)
    local ped = PlayerPedId()
    local c = GetEntityCoords(ped)
    local h = GetEntityHeading(ped)

    cb({ x = round(c.x, 2), y = round(c.y, 2), z = round(c.z, 2), w = round(h, 2) })
end)

RegisterNUICallback('admin:close', function(_data, cb)
    SetNuiFocus(false, false)
    AdminNui.open = false
    cb('ok')
end)

RegisterNUICallback('admin:bootstrap', forward('msk_fuel:admin:bootstrap'))
RegisterNUICallback('admin:station:save', forward('msk_fuel:admin:station:save'))
RegisterNUICallback('admin:station:delete', forward('msk_fuel:admin:station:delete'))
RegisterNUICallback('admin:station:clearOwner', forward('msk_fuel:admin:station:clearOwner'))
RegisterNUICallback('admin:stock:set', forward('msk_fuel:admin:stock:set'))
RegisterNUICallback('admin:stock:pricing', forward('msk_fuel:admin:stock:pricing'))
RegisterNUICallback('admin:station:neutral', forward('msk_fuel:admin:station:neutral'))
RegisterNUICallback('admin:settings:save', forward('msk_fuel:admin:settings:save'))
RegisterNUICallback('admin:perms:saveGroup', forward('msk_fuel:admin:perms:saveGroup'))
RegisterNUICallback('admin:perms:deleteGroup', forward('msk_fuel:admin:perms:deleteGroup'))
RegisterNUICallback('admin:perms:dashboardGroups', forward('msk_fuel:admin:perms:dashboardGroups'))
