// Shapes of what the server sends. Kept in one place so a change to a Lua
// payload has exactly one place to be mirrored.

export interface Coord {
  x: number
  y: number
  z: number
  w: number
}

export type FuelType = 'gas' | 'diesel' | 'kerosin' | 'electric'
export type PriceMode = 'dynamic' | 'fixed'

export interface StockRow {
  fuelType: string
  stock: number
  capacity: number
  priceMode: PriceMode
  fixedPrice: number
  /** Effective price per liter right now, already clamped by the limits. */
  price: number
}

export interface Station {
  id: string
  label: string
  coords?: { x: number; y: number; z: number }
  radius: number
  blip: boolean
  fuelTypes: string[]
  capacity?: Partial<Record<FuelType, number>>
  purchasable: boolean
  purchasePrice: number
  /** Identifier of the owning player, absent while the station is unowned. */
  owner?: string
  balance: number
  stock: StockRow[]
  npcUnlocked?: boolean
  autoRestock?: boolean
  publicDelivery?: { enable: boolean; rewardPerLiter: number; amount: number }
}

export interface PriceLimit {
  min: number
  max: number
}

export interface MarketSettings {
  kStock: number
  kDemand: number
  demandNorm: number
  drift: number
  decay: number
  tickMinutes: number
}

export interface Theme {
  accent: string
  bg: string
  panel: string
  textPrimary: string
  textSecondary: string
}

export interface Settings {
  Locale: string
  Debug: boolean
  VersionChecker: boolean
  adminCommand: string
  Theme: Theme
  BasePrices: Record<string, number>
  PriceLimits: Record<string, PriceLimit>
  Market: MarketSettings
  DefaultCapacity: Record<string, number>
  NeutralIncome: { mode: 'void' | 'society'; societyName: string }
  DefaultPurchasePrice: number
  SellRefundRatio: number
  MaxStationBalance: number
  dashboardGroups: string[]
}

export interface Group {
  name: string
  perms: Record<string, boolean>
  protected: boolean
}

export interface Bootstrap {
  locale: string
  perms: Record<string, boolean>
  permKeys: string[]
  fuelTypes: string[]
  priceModes: PriceMode[]
  stations: Station[]
  settings: Settings
  groups: Group[]
  suggestedGroups: string[]
}

export interface ApiResponse {
  ok: boolean
  err?: string
  data?: Bootstrap
}

export interface IncomingMessage {
  action: string
  data?: unknown
}
