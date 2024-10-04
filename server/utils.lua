AddEventHandler('onResourceStart', function(resource)
    if resource ~= 'msk_enginetoggle' then return end

    if not EngineToggle then 
        EngineToggle = {name = 'msk_enginetoggle', label = ("^3[%s]^0"):format('msk_enginetoggle')}
    end

    EngineToggle.state = "started"
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= 'msk_enginetoggle' then return end
    EngineToggle.state = "stopped"
end)