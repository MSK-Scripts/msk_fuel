----------------------------------------------------------------
-- Restocking a station.
--
-- Two ways in, and they are meant to feel different:
--   * the NPC driver delivers instantly but charges a surcharge. It has to be
--     unlocked once per station, which is what stops a brand new station from
--     skipping the delivery job entirely.
--   * an actual delivery run (delivery.lua) is cheaper, but somebody has to
--     drive it.
--
-- Both buy at the same wholesale price; only the surcharge and the bulk
-- discount of the rig differ.
----------------------------------------------------------------
Supply = Supply or {}

---Wholesale price per liter, before any surcharge or discount.
function Supply.WholesalePrice(fuelType)
    return tonumber((Config.Wholesale or {})[fuelType]) or 1.0
end

---What `liters` of `fuelType` cost.
---@param mode string|nil  'npc' adds the surcharge, a vehicle key applies its
---                        bulk discount, nil is the plain wholesale price.
function Supply.CostOf(fuelType, liters, mode)
    liters = math.max(0, math.floor(tonumber(liters) or 0))

    local perLiter = Supply.WholesalePrice(fuelType)

    if mode == 'npc' then
        perLiter = perLiter * (tonumber(Config.NpcSurcharge) or 1.0)
    elseif mode then
        local vehicle = (Config.DeliveryVehicles or {})[mode]
        local discount = math.max(0.0, math.min(tonumber(vehicle and vehicle.discount) or 0.0, 0.9))

        perLiter = perLiter * (1.0 - discount)
    end

    return math.ceil(liters * perLiter)
end

---How many liters fit into a station's tank right now.
function Supply.FreeSpace(stationId, fuelType)
    return math.max(0, Stock.Capacity(stationId, fuelType) - math.floor(Stock.Get(stationId, fuelType)))
end

function Supply.IsNpcUnlocked(stationId)
    local def = Stations.Get(stationId)
    return type(def) == 'table' and def.npcUnlocked == true
end

local function setStationFlag(stationId, key, value)
    local def = Stations.Get(stationId)
    if not def then return false end

    def[key] = value

    -- The flags live inside the `data` JSON, so the whole definition is written
    -- back. Owner and balance have their own columns and are not in there.
    local clean = {}
    for k, v in pairs(def) do clean[k] = v end
    clean.owner, clean.balance, clean.id = nil, nil, nil

    MySQL.update('UPDATE `msk_fuel_stations` SET `data` = ? WHERE `id` = ?', { json.encode(clean), stationId })

    return true
end

Supply.SetStationFlag = setStationFlag

---Unlocks the NPC driver for a station, paid out of the company account.
---@return boolean ok, string|nil err
function Supply.UnlockNpc(stationId)
    if Supply.IsNpcUnlocked(stationId) then return false, 'already_unlocked' end

    local price = math.max(0, math.floor(tonumber(Config.NpcUnlockPrice) or 0))

    if Account.Get(stationId) < price then return false, 'not_enough_balance' end
    if not Account.Book(stationId, -price, 'npc_unlock', {}) then return false, 'not_enough_balance' end

    setStationFlag(stationId, 'npcUnlocked', true)

    return true
end

---Instant restock through the NPC driver.
---@return boolean ok, string|nil err, number|nil liters, number|nil cost
function Supply.OrderInstant(stationId, fuelType, liters)
    if not Supply.IsNpcUnlocked(stationId) then return false, 'npc_locked' end

    local def = Stations.Get(stationId)
    if not def or not Stations.SellsFuelType(def, fuelType) then return false, 'no_tank' end

    liters = math.max(0, math.floor(tonumber(liters) or 0))
    if liters <= 0 then return false, 'bad_amount' end

    -- Never order more than fits: the money would be gone and the fuel with it.
    liters = math.min(liters, Supply.FreeSpace(stationId, fuelType))
    if liters <= 0 then return false, 'tank_full' end

    local cost = Supply.CostOf(fuelType, liters, 'npc')

    if Account.Get(stationId) < cost then return false, 'not_enough_balance' end
    if not Account.Book(stationId, -cost, 'restock_npc', { fuelType = fuelType, liters = liters }) then
        return false, 'not_enough_balance'
    end

    Stock.Add(stationId, fuelType, liters)
    Stations.MarkDirty()

    return true, nil, liters, cost
end

----------------------------------------------------------------
-- Automatic restocking
--
-- Runs for owned stations whose owner switched it on (and that have the NPC
-- unlocked) and for unowned stations the admin switched it on. An unowned
-- station has no account to pay from, so its refill is free: it exists to keep
-- the map supplied, not to make anyone money.
----------------------------------------------------------------
local function shouldAutoRestock(stationId, def)
    if def.autoRestock ~= true then return false end
    if Stations.IsOwned(def) then return Supply.IsNpcUnlocked(stationId) end

    return true
end

function Supply.RunAutoRestock()
    local cfg = Config.AutoRestock or {}
    local threshold = math.max(0.0, math.min(tonumber(cfg.threshold) or 0.35, 1.0))
    local target = math.max(threshold, math.min(tonumber(cfg.target) or 0.9, 1.0))

    for stationId, def in pairs(Config.Stations or {}) do
        if shouldAutoRestock(stationId, def) then
            for _, fuelType in ipairs(Stations.FuelTypes(def)) do
                local capacity = Stock.Capacity(stationId, fuelType)
                local stock = Stock.Get(stationId, fuelType)

                if capacity > 0 and (stock / capacity) < threshold then
                    local wanted = math.floor(capacity * target - stock)

                    if wanted > 0 then
                        if Stations.IsOwned(def) then
                            -- Paid for; a station that cannot afford it simply
                            -- does not get refilled.
                            Supply.OrderInstant(stationId, fuelType, wanted)
                        else
                            Stock.Add(stationId, fuelType, wanted)
                            Account.Log(stationId, 'restock_auto', 0.0, { fuelType = fuelType, liters = wanted })
                            Stations.MarkDirty()
                        end
                    end
                end
            end
        end
    end
end

CreateThread(function()
    while not AdminStore.ready do Wait(1000) end

    while true do
        local minutes = math.max(1, tonumber((Config.AutoRestock or {}).intervalMinutes) or 30)
        Wait(minutes * 60000)

        Supply.RunAutoRestock()
    end
end)
