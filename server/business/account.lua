----------------------------------------------------------------
-- Station company account.
--
-- Every station carries its own `balance` column. It is deliberately NOT an
-- ESX/QBCore society account: stations are bought and staffed independently of
-- framework jobs, so tying the money to a job would make a station unusable for
-- anyone whose job does not exist on that server.
--
-- Money paid at a station nobody owns has no account to land in. What happens
-- to it is a server decision (Config.NeutralIncome): it either disappears or
-- goes into a society account.
----------------------------------------------------------------
Account = Account or {}

local function persistBalance(stationId, balance)
    MySQL.update('UPDATE `msk_fuel_stations` SET `balance` = ? WHERE `id` = ?', { balance, stationId })
end

function Account.Get(stationId)
    local def = Stations.Get(stationId)
    if not def then return 0.0 end

    return tonumber(def.balance) or 0.0
end

---Books an amount onto a station's account and logs the transaction.
---Negative amounts are withdrawals; the balance may not go below zero.
---@param stationId string
---@param amount number
---@param kind string       transaction type, e.g. 'sale', 'purchase', 'restock'
---@param meta table|nil    free-form payload for the finance log
---@return boolean ok, number balance
function Account.Book(stationId, amount, kind, meta)
    local def = Stations.Get(stationId)
    if not def then return false, 0.0 end

    amount = tonumber(amount) or 0.0
    local balance = (tonumber(def.balance) or 0.0) + amount

    if balance < 0 then return false, tonumber(def.balance) or 0.0 end

    -- Optional ceiling, so a station cannot become an unbounded money store.
    -- Income above the cap is dropped rather than refused: refusing would mean
    -- silently blocking sales at a full station.
    local cap = tonumber(Config.MaxStationBalance) or 0

    if cap > 0 and balance > cap then
        balance = cap
    end

    def.balance = balance
    persistBalance(stationId, balance)
    Account.Log(stationId, kind, amount, meta)

    return true, balance
end

-- `meta.liters` is lifted into its own column: the owner statistics sum it up,
-- and a SUM over a column beats decoding one JSON blob per transaction.
function Account.Log(stationId, kind, amount, meta)
    meta = meta or {}

    MySQL.insert(
        'INSERT INTO `msk_fuel_transactions` (`station_id`, `type`, `amount`, `liters`, `meta`) VALUES (?, ?, ?, ?, ?)',
        {
            stationId,
            tostring(kind or 'unknown'):sub(1, 40),
            tonumber(amount) or 0.0,
            tonumber(meta.liters) or 0.0,
            json.encode(meta),
        }
    )
end

---Where the revenue of a sale goes. Owned stations credit their own account,
---unowned ones follow Config.NeutralIncome.
function Account.BookSale(stationId, amount, meta)
    if amount <= 0 then return end

    if Stations.IsOwned(stationId) then
        Account.Book(stationId, amount, 'sale', meta)
        return
    end

    local cfg = Config.NeutralIncome or {}

    if cfg.mode == 'society' and MSK.Society and MSK.Society.AddMoney then
        local ok = pcall(MSK.Society.AddMoney, cfg.societyName or 'society_fuel', amount)
        if not ok then
            logging('error', 'Could not pay neutral station income into the society account', cfg.societyName)
        end
    end

    -- 'void' (and any failed society booking) simply drops the money, but the
    -- sale is still logged so the statistics of a neutral station stay honest.
    Account.Log(stationId, 'sale_neutral', amount, meta)
end
