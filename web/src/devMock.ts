// Browser-only stand-in for the game. Lets the dashboard be clicked through
// with `npm run dev` before it is ever loaded in FiveM. Never bundled into the
// production build (see main.tsx: DEV + browser only).
import type { Bootstrap, Station } from './admin/types'
import type { OwnerBootstrap } from './owner/types'

const FUEL_TYPES = ['gas', 'diesel', 'kerosin', 'electric']

const station = (id: string, label: string, owner?: string): Station => ({
  id,
  label,
  coords: { x: -71.28, y: -1761.16, z: 29.48 },
  radius: 60,
  blip: true,
  fuelTypes: ['gas', 'diesel', 'kerosin'],
  purchasable: !owner,
  purchasePrice: 250000,
  npcUnlocked: false,
  autoRestock: false,
  publicDelivery: { enable: false, rewardPerLiter: 0.35, amount: 1000 },
  owner,
  balance: owner ? 48250 : 0,
  stock: [
    { fuelType: 'gas', stock: 14200, capacity: 20000, priceMode: 'dynamic', fixedPrice: 1.7, price: 1.81 },
    { fuelType: 'diesel', stock: 0, capacity: 20000, priceMode: 'dynamic', fixedPrice: 1.5, price: 2.02 },
    { fuelType: 'kerosin', stock: 9100, capacity: 10000, priceMode: 'fixed', fixedPrice: 2.1, price: 2.1 },
  ],
})

const bootstrap: Bootstrap = {
  locale: 'de',
  perms: {
    'station.view': true,
    'station.create': true,
    'station.edit': true,
    'station.delete': true,
    'station.owner': true,
    'stock.manage': true,
    'market.manage': true,
    'settings.manage': true,
    'permissions.manage': true,
  },
  permKeys: [
    'station.view', 'station.create', 'station.edit', 'station.delete',
    'station.owner', 'stock.manage', 'market.manage', 'settings.manage', 'permissions.manage',
  ],
  fuelTypes: FUEL_TYPES,
  priceModes: ['dynamic', 'fixed'],
  stations: [
    station('ls_01', 'Tankstelle Los Santos 1'),
    station('ls_02', 'Tankstelle Los Santos 2', 'license:deadbeef'),
    station('pb_01', 'Tankstelle Paleto Bay 1'),
  ],
  settings: {
    Locale: 'de',
    Debug: false,
    VersionChecker: true,
    adminCommand: 'fueladmin',
    Theme: {
      accent: '#00E676',
      bg: '#0a0b0d',
      panel: '#131317',
      textPrimary: '#f0ede8',
      textSecondary: '#b0adb8',
    },
    BasePrices: { gas: 1.7, diesel: 1.5, kerosin: 1.9, electric: 0.5 },
    PriceLimits: {
      gas: { min: 0.8, max: 4 },
      diesel: { min: 0.7, max: 3.5 },
      kerosin: { min: 0.9, max: 5 },
      electric: { min: 0.2, max: 2 },
    },
    Market: { kStock: 0.35, kDemand: 0.25, demandNorm: 5000, drift: 0.02, decay: 0.5, tickMinutes: 60 },
    DefaultCapacity: { gas: 20000, diesel: 20000, kerosin: 10000, electric: 5000 },
    NeutralIncome: { mode: 'void', societyName: 'society_fuel' },
    DefaultPurchasePrice: 250000,
    SellRefundRatio: 0.6,
    MaxStationBalance: 0,
    dashboardGroups: ['admin', 'mod'],
  },
  groups: [
    { name: 'admin', perms: {}, protected: true },
    { name: 'mod', perms: { 'station.view': true }, protected: false },
  ],
  suggestedGroups: ['admin', 'mod', 'dev'],
}

const ownerBootstrap: OwnerBootstrap = {
  locale: 'de',
  perms: {
    manage: true,
    hire: true,
    set_prices: true,
    order_fuel: true,
    withdraw: true,
    deposit: true,
    repair: true,
  },
  permKeys: ['manage', 'hire', 'set_prices', 'order_fuel', 'withdraw', 'deposit', 'repair'],
  fuelTypes: ['gas', 'diesel', 'kerosin'],
  priceModes: ['dynamic', 'fixed'],
  station: {
    id: 'ls_02',
    label: 'Tankstelle Los Santos 2',
    balance: 48250,
    purchasePrice: 250000,
    sellPrice: 150000,
  },
  stock: station('ls_02', 'Tankstelle Los Santos 2', 'license:deadbeef').stock,
  basePrices: { gas: 1.7, diesel: 1.5, kerosin: 1.9, electric: 0.5 },
  priceLimits: {
    gas: { min: 0.8, max: 4 },
    diesel: { min: 0.7, max: 3.5 },
    kerosin: { min: 0.9, max: 5 },
    electric: { min: 0.2, max: 2 },
  },
  stats: {
    day: { revenue: 8420, liters: 4780, sales: 63 },
    week: { revenue: 51230, liters: 29100, sales: 412 },
  },
  transactions: [
    { type: 'sale', amount: 142, liters: 78, at: '2026-08-29 14:12:03', meta: {} },
    { type: 'withdraw', amount: -5000, liters: 0, at: '2026-08-29 12:44:51', meta: {} },
    { type: 'petrolcan_refill', amount: 800, liters: 38, at: '2026-08-29 11:02:19', meta: {} },
    { type: 'sale', amount: 96, liters: 53, at: '2026-08-29 10:58:07', meta: {} },
  ],
  ranks: [
    {
      id: 'manager',
      label: 'Geschäftsführer',
      salary: 1000,
      deliveryBonus: 250,
      perms: { manage: true, hire: true, set_prices: true, order_fuel: true, withdraw: true, deposit: true, repair: true },
    },
    {
      id: 'employee',
      label: 'Mitarbeiter',
      salary: 500,
      deliveryBonus: 150,
      perms: { order_fuel: true, deposit: true, repair: true },
    },
  ],
  employees: [
    {
      identifier: 'license:aaa111',
      name: 'Tom Weber',
      online: true,
      rankId: 'manager',
      rankLabel: 'Geschäftsführer',
      stats: { liters_sold: 0, deliveries: 0, earnings: 4000, last_active: 1756468800 },
    },
    {
      identifier: 'license:bbb222',
      online: false,
      rankId: 'employee',
      rankLabel: 'Mitarbeiter',
      stats: { liters_sold: 0, deliveries: 0, earnings: 1500, last_active: 0 },
    },
  ],
  isOwner: true,
  supply: {
    npcUnlocked: true,
    npcUnlockPrice: 50000,
    autoRestock: false,
    wholesale: { gas: 1.05, diesel: 0.9, kerosin: 1.2, electric: 0.3 },
    npcSurcharge: 1.35,
    vehicles: {
      van: { label: 'Van', capacity: 500, discount: 0 },
      truck: { label: 'LKW', capacity: 1500, discount: 0.05 },
      tanker: { label: 'Tanklaster', capacity: 3000, discount: 0.1 },
    },
    free: { gas: 5800, diesel: 20000, kerosin: 900 },
  },
  pumps: [
    { key: '265_-1261', coords: { x: 264.7, y: -1261, z: 29.2 }, health: 100, repairCost: 0, broken: false },
    { key: '271_-1258', coords: { x: 270.6, y: -1258.4, z: 29.2 }, health: 42, repairCost: 1450, broken: false },
    { key: '277_-1255', coords: { x: 276.9, y: -1254.8, z: 29.2 }, health: 8, repairCost: 2300, broken: true },
  ],
  maintenance: {
    enabled: true,
    mechanic: false,
    mechanicPrice: 35000,
    failThreshold: 15,
    slowThreshold: 50,
  },
}

// Which dashboard the browser opens: append ?view=owner to the dev URL. In game
// the Lua side decides, this is only for looking at them side by side.
const showOwner = new URLSearchParams(window.location.search).get('view') === 'owner'

// Mutations just echo the current bootstrap back: this mock is for looking at
// the UI, not for simulating the server.
;(window as unknown as { __mskDevRespond?: (endpoint: string) => unknown }).__mskDevRespond = (
  endpoint: string,
) => {
  if (endpoint === 'admin:getCurrentCoords') {
    return { x: 123.45, y: -678.9, z: 30.12, w: 90 }
  }

  if (endpoint === 'admin:close' || endpoint === 'owner:close') return 'ok'

  if (endpoint === 'owner:onlinePlayers') {
    return {
      ok: true,
      players: [
        { source: 1, identifier: 'license:aaa111', name: 'Tom Weber', employed: true },
        { source: 4, identifier: 'license:ccc333', name: 'Lena Fischer', employed: false },
        { source: 7, identifier: 'license:ddd444', name: 'Jonas Krause', employed: false },
      ],
    }
  }

  if (endpoint.startsWith('owner:')) return { ok: true, data: ownerBootstrap }

  return { ok: true, data: bootstrap }
}

window.setTimeout(() => {
  window.postMessage(
    showOwner
      ? { action: 'openOwner', data: ownerBootstrap }
      : { action: 'openAdmin', data: bootstrap },
    '*',
  )
}, 50)
