import type { PriceLimit, StockRow } from '../admin/types'

export interface OwnerStats {
  revenue: number
  liters: number
  sales: number
}

export interface Transaction {
  type: string
  amount: number
  liters: number
  /** Server timestamp as a string; rendered as-is, never parsed. */
  at: string
  meta: Record<string, unknown>
}

export interface OwnerStation {
  id: string
  label: string
  balance: number
  purchasePrice: number
  /** What selling the station back to the system pays out, before the account. */
  sellPrice: number
}

export interface EmployeeStats {
  liters_sold: number
  deliveries: number
  earnings: number
  /** Unix timestamp, 0 when the employee has never been paid or seen. */
  last_active: number
}

export interface Rank {
  id: string
  label: string
  salary: number
  deliveryBonus: number
  perms: Record<string, boolean>
}

export interface Employee {
  identifier: string
  /** Only known while the player is online. */
  name?: string
  online: boolean
  rankId: string
  rankLabel: string
  stats: EmployeeStats
}

export interface OnlinePlayer {
  source: number
  identifier: string
  name: string
  employed: boolean
}

export interface OnlinePlayersResponse {
  ok: boolean
  err?: string
  players?: OnlinePlayer[]
}

export interface DeliveryVehicle {
  label: string
  capacity: number
  discount: number
  /** Model hashes, only meaningful to the Lua side. */
  model?: number
  trailer?: number
}

export interface SupplyState {
  npcUnlocked: boolean
  npcUnlockPrice: number
  autoRestock: boolean
  wholesale: Record<string, number>
  npcSurcharge: number
  vehicles: Record<string, DeliveryVehicle>
  /** Liters that still fit, per fuel type. */
  free: Record<string, number>
}

export interface Pump {
  key: string
  coords: { x: number; y: number; z: number }
  health: number
  repairCost: number
  broken: boolean
}

export interface MaintenanceState {
  enabled: boolean
  mechanic: boolean
  mechanicPrice: number
  failThreshold: number
  slowThreshold: number
}

export interface OwnerBootstrap {
  locale: string
  perms: Record<string, boolean>
  permKeys: string[]
  fuelTypes: string[]
  priceModes: ('dynamic' | 'fixed')[]
  station: OwnerStation
  stock: StockRow[]
  basePrices: Record<string, number>
  priceLimits: Record<string, PriceLimit>
  stats: {
    day: OwnerStats
    week: OwnerStats
  }
  transactions: Transaction[]
  ranks: Rank[]
  employees: Employee[]
  /** Handing out permissions and selling are owner-only, whatever a rank says. */
  isOwner: boolean
  supply: SupplyState
  pumps: Pump[]
  maintenance: MaintenanceState
}

export interface OwnerResponse {
  ok: boolean
  err?: string
  /** Set when the action ended the session, e.g. the station was sold. */
  closed?: boolean
  data?: OwnerBootstrap
}
