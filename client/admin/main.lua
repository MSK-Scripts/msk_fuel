-- Opens the admin dashboard NUI when the server grants access.
AdminNui = AdminNui or { open = false }

RegisterNetEvent('msk_fuel:admin:open', function(payload)
    if AdminNui.open then return end

    AdminNui.open = true
    SetNuiFocus(true, true)
    SendNUIMessage({ action = 'openAdmin', data = payload })
end)

-- Safety net: on (re)start, force-release any NUI focus left stuck from a
-- previous session (e.g. a frozen UI), so a `restart msk_fuel` always frees the
-- cursor instead of leaving it captured on a blank screen.
AddEventHandler('onClientResourceStart', function(resource)
    if resource ~= GetCurrentResourceName() then return end

    SetNuiFocus(false, false)
    AdminNui.open = false
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    SetNuiFocus(false, false)
end)
