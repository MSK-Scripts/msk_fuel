----------------------------------------------------------------
-- Salaries.
--
-- Every interval each owned station pays its online staff the salary of their
-- rank, out of the company account. A station that cannot afford its payroll
-- skips it and tells the owner, rather than going into debt.
--
-- This is a plain thread rather than MSK.Cron: Cron fires either at a fixed
-- time of day or once at a timestamp, while payroll wants a repeating interval.
-- Rebuilding that on top of Cron would mean re-registering the job on every run.
----------------------------------------------------------------
Payroll = Payroll or {}

---Pays one station's staff.
---@return number paid, number skipped
function Payroll.RunFor(stationId)
    local def = Stations.Get(stationId)
    if not def or not Stations.IsOwned(def) then return 0, 0 end

    local onlineOnly = (Config.Payroll or {}).onlineOnly ~= false
    local paid, skipped = 0, 0

    -- One warning per run, not one per unpaid employee.
    local warned = false

    for identifier, employee in pairs(Employees.ListOf(stationId)) do
        local rank = Employees.Rank(stationId, employee.rank_id)
        local salary = math.floor(tonumber(rank and rank.salary) or 0)

        if salary > 0 then
            local found, player = pcall(MSK.GetPlayerFromIdentifier, identifier)
            local src = (found and type(player) == 'table') and tonumber(player.source) or nil

            if not src and onlineOnly then
                skipped = skipped + 1
            elseif Account.Get(stationId) < salary then
                -- Out of money: stop here rather than paying whoever happens to
                -- come first in the table.
                skipped = skipped + 1

                if not warned then
                    warned = true
                    Payroll.NotifyOwner(stationId, Translate('payroll_no_funds', def.label or stationId))
                end
            else
                Account.Book(stationId, -salary, 'salary', { to = identifier, rank = employee.rank_id })
                Employees.AddStats(stationId, identifier, { earnings = salary, last_active = os.time() })

                if src then
                    AddMoney(src, salary)
                    Config.Notification(src, Translate('payroll_paid', salary, def.label or stationId), 'success')
                end

                paid = paid + 1
            end
        end
    end

    return paid, skipped
end

---Tells the owner something about their station, if they are online.
function Payroll.NotifyOwner(stationId, message)
    local def = Stations.Get(stationId)
    if not def or not def.owner then return end

    local found, player = pcall(MSK.GetPlayerFromIdentifier, def.owner)
    if not found or type(player) ~= 'table' then return end

    local src = tonumber(player.source)
    if src then Config.Notification(src, message, 'error') end
end

function Payroll.RunAll()
    local paid, skipped = 0, 0

    for stationId, def in pairs(Config.Stations or {}) do
        if Stations.IsOwned(def) then
            local p, s = Payroll.RunFor(stationId)
            paid, skipped = paid + p, skipped + s
        end
    end

    if paid > 0 or skipped > 0 then
        logging('debug', ('Payroll: %s salaries paid, %s skipped'):format(paid, skipped))
    end
end

CreateThread(function()
    -- The store has to be loaded before the first run, otherwise there is
    -- nothing to pay out of.
    while not AdminStore.ready do Wait(1000) end

    while true do
        local cfg = Config.Payroll or {}
        local minutes = math.max(1, tonumber(cfg.intervalMinutes) or 60)

        Wait(minutes * 60000)

        -- Read again after the wait: the interval is editable at runtime, and
        -- payroll can be switched off entirely.
        if (Config.Payroll or {}).enable ~= false then
            Payroll.RunAll()
        end
    end
end)
