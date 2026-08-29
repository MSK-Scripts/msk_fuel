AdminCommand = AdminCommand or {}
AdminCommand.registered = {}

-- The command itself is NOT ACE-restricted; access control lives entirely in the
-- callback (AdminPerms.CanOpen) so it respects dashboardGroups and the
-- group.user hard blacklist. Registering a new name leaves any previously
-- registered name pointing at the same gated handler (harmless) until the next
-- restart.
function AdminCommand.Register(name)
    name = name or Config.adminCommand or 'fueladmin'
    if AdminCommand.registered[name] then return end
    AdminCommand.registered[name] = true

    MSK.RegisterCommand(name, function(source)
        local src = source

        if src == 0 then
            print('^3[msk_fuel]^0 The admin dashboard can only be opened in-game.')
            return
        end

        if not AdminPerms.CanOpen(src) then
            Config.Notification(src, Translate('no_dashboard_permission'), 'error')
            return
        end

        TriggerClientEvent('msk_fuel:admin:open', src, AdminApi.BuildBootstrap(src))
    end, {
        help = 'Open the MSK Fuel admin dashboard',
        restricted = false,
    })
end
