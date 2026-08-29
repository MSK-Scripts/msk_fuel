AdminPerms = AdminPerms or {}

----------------------------------------------------------------
-- Permission keys for the msk_fuel admin dashboard.
-- Order matters: the NUI renders the matrix in exactly this order.
----------------------------------------------------------------
AdminPerms.PERMS = {
    'station.view', 'station.create', 'station.edit', 'station.delete',
    'station.owner',    -- force-remove an owner / reset a station
    'stock.manage',     -- set stock and capacity from the admin dashboard
    'market.manage',    -- base prices, price limits, market parameters
    'settings.manage',
    'permissions.manage',
}

-- Settings that may be edited from the dashboard (requires `settings.manage`).
-- These are the DB-managed keys. Everything the code hooks into (notification
-- function, target models, fuel type tables) stays in the static config and is
-- deliberately NOT listed here.
AdminPerms.SETTINGS_KEYS = {
    'Locale', 'Debug', 'VersionChecker',
    'adminCommand', 'Theme',
    'BasePrices', 'PriceLimits', 'Market',
    'DefaultCapacity', 'NeutralIncome',
    'DefaultPurchasePrice', 'SellRefundRatio', 'MaxStationBalance',
    'Payroll', 'Wholesale', 'NpcSurcharge', 'NpcUnlockPrice',
    'Delivery', 'PublicDelivery', 'AutoRestock', 'Maintenance',
}

-- Fuel types a station can stock. Keep in sync with Config.FuelStationTypes.
AdminPerms.FUEL_TYPES = { 'gas', 'diesel', 'kerosin', 'electric' }

----------------------------------------------------------------
-- Permissions INSIDE a station, held by a rank rather than by a server group.
-- These gate the owner dashboard, and they are per station: being a manager at
-- one station says nothing about any other.
--
-- The owner themself always holds all of them and can never be locked out of
-- their own business. Ranks that hand a subset to employees arrive in phase 3.
----------------------------------------------------------------
OwnerPerms = OwnerPerms or {}

OwnerPerms.PERMS = {
    'manage',      -- rename the station, sell it
    'hire',        -- hire and fire, edit ranks
    'set_prices',  -- price mode and price per fuel type
    'order_fuel',  -- restock and delivery orders
    'withdraw',    -- take money out of the company account
    'deposit',     -- pay money into it
    'repair',      -- pump maintenance
}

function OwnerPerms.All()
    local t = {}
    for _, p in ipairs(OwnerPerms.PERMS) do t[p] = true end
    return t
end

function OwnerPerms.IsPerm(perm)
    for _, p in ipairs(OwnerPerms.PERMS) do
        if p == perm then return true end
    end
    return false
end

-- Price modes a station can run per fuel type.
AdminPerms.PRICE_MODES = { 'dynamic', 'fixed' }

-- Editable UI colour keys (hex strings) managed via the Settings tab.
-- Keep in sync with web/src/lib/theme.ts (DEFAULT_THEME / THEME_KEYS).
AdminPerms.THEME_KEYS = { 'accent', 'bg', 'panel', 'textPrimary', 'textSecondary' }
AdminPerms.DEFAULT_THEME = {
    accent = '#00E676',
    bg = '#0a0b0d',
    panel = '#131317',
    textPrimary = '#f0ede8',
    textSecondary = '#b0adb8',
}

-- Suggested group names shown in the UI when adding a new group.
AdminPerms.SUGGESTED_GROUPS = { 'admin', 'mod', 'dev' }

-- group.admin always has every right and can never be edited.
AdminPerms.PROTECTED_GROUPS = { admin = true }

-- group.user may NEVER open the dashboard and can never be granted rights.
AdminPerms.BLACKLIST_GROUPS = { user = true }

----------------------------------------------------------------
-- Helpers
----------------------------------------------------------------
function AdminPerms.AllPerms()
    local t = {}
    for _, p in ipairs(AdminPerms.PERMS) do t[p] = true end
    return t
end

function AdminPerms.IsProtected(group)
    return AdminPerms.PROTECTED_GROUPS[tostring(group):lower()] == true
end

function AdminPerms.IsBlacklisted(group)
    return AdminPerms.BLACKLIST_GROUPS[tostring(group):lower()] == true
end

function AdminPerms.IsFuelType(fuelType)
    for _, t in ipairs(AdminPerms.FUEL_TYPES) do
        if t == fuelType then return true end
    end
    return false
end
