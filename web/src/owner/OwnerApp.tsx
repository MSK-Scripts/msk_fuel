import { useCallback, useEffect, useMemo, useState } from 'react'
import { Banknote, Fuel, LayoutDashboard, Shield, Tag, Truck, Users, Wrench, X } from 'lucide-react'
import { fetchNui } from '../lib/nui'
import { errorText, makeT, type TranslationKey } from '../lib/i18n'
import { StatusText } from '../admin/ui'
import OverviewTab from './OverviewTab'
import FinanceTab from './FinanceTab'
import PricesTab from './PricesTab'
import StockTab from './StockTab'
import StaffTab from './StaffTab'
import RanksTab from './RanksTab'
import SupplyTab from './SupplyTab'
import PumpsTab from './PumpsTab'
import type { OwnerBootstrap, OwnerResponse } from './types'

export type Toast = { msg: string; ok: boolean } | null

export interface OwnerTabProps {
  boot: OwnerBootstrap
  t: (key: TranslationKey) => string
  can: (perm: string) => boolean
  call: (endpoint: string, data?: unknown) => Promise<boolean>
}

type TabId = 'overview' | 'finance' | 'prices' | 'stock' | 'supply' | 'pumps' | 'staff' | 'ranks'

// A tab with no permissions listed is visible to anyone who got this far, which
// only ever happens for someone who holds at least one right at this station.
const TABS: { id: TabId; icon: typeof Fuel; label: TranslationKey; perms: string[] }[] = [
  { id: 'overview', icon: LayoutDashboard, label: 'tab_overview', perms: [] },
  { id: 'finance', icon: Banknote, label: 'tab_finance', perms: ['deposit', 'withdraw'] },
  { id: 'prices', icon: Tag, label: 'tab_prices', perms: ['set_prices'] },
  { id: 'stock', icon: Fuel, label: 'tab_stock', perms: [] },
  { id: 'supply', icon: Truck, label: 'tab_supply', perms: ['order_fuel'] },
  { id: 'pumps', icon: Wrench, label: 'tab_pumps', perms: ['repair'] },
  { id: 'staff', icon: Users, label: 'tab_staff', perms: ['hire'] },
  { id: 'ranks', icon: Shield, label: 'tab_ranks', perms: ['hire'] },
]

export default function OwnerApp({
  boot,
  onBootChange,
  onClose,
}: {
  boot: OwnerBootstrap
  onBootChange: (boot: OwnerBootstrap) => void
  onClose: () => void
}) {
  const t = useMemo(() => makeT(boot.locale), [boot.locale])
  const can = useCallback((perm: string) => boot.perms[perm] === true, [boot.perms])

  const visibleTabs = useMemo(
    () => TABS.filter((tab) => tab.perms.length === 0 || tab.perms.some(can)),
    [can],
  )

  const [tab, setTab] = useState<TabId>('overview')
  const [toast, setToast] = useState<Toast>(null)

  useEffect(() => {
    if (!visibleTabs.some((v) => v.id === tab) && visibleTabs[0]) {
      setTab(visibleTabs[0].id)
    }
  }, [visibleTabs, tab])

  const close = useCallback(() => {
    void fetchNui('owner:close')
    onClose()
  }, [onClose])

  useEffect(() => {
    const onKey = (e: KeyboardEvent) => {
      if (e.key === 'Escape') close()
    }

    window.addEventListener('keydown', onKey)
    return () => window.removeEventListener('keydown', onKey)
  }, [close])

  const call = useCallback(
    async (endpoint: string, data: unknown = {}): Promise<boolean> => {
      const res = await fetchNui<OwnerResponse>(endpoint, data)

      if (!res || !res.ok) {
        setToast({ msg: errorText(t, res?.err), ok: false })
        return false
      }

      // Selling ends the business; the Lua side already dropped NUI focus.
      if (res.closed) {
        onClose()
        return true
      }

      if (res.data) onBootChange(res.data)

      setToast({ msg: t('saved'), ok: true })
      return true
    },
    [onBootChange, onClose, t],
  )

  useEffect(() => {
    if (!toast) return

    const id = window.setTimeout(() => setToast(null), 4000)
    return () => window.clearTimeout(id)
  }, [toast])

  const tabProps: OwnerTabProps = { boot, t, can, call }

  return (
    <div className="flex h-full w-full items-center justify-center bg-black/50 font-sans">
      <div className="msk-panel flex h-[86vh] w-[1080px] max-w-[96vw] overflow-hidden animate-scale-in">
        <aside className="flex w-[220px] shrink-0 flex-col border-r border-border bg-panel-raised">
          <div className="border-b border-border px-5 py-5">
            <h1 className="truncate font-display text-[17px] font-bold text-accent">
              {boot.station.label}
            </h1>
            <p className="msk-label mt-1 text-[10px]">{t('owner_subtitle')}</p>
          </div>

          <nav className="flex flex-1 flex-col gap-1 p-3">
            {visibleTabs.map(({ id, icon: Icon, label }) => (
              <button
                key={id}
                type="button"
                onClick={() => setTab(id)}
                className={`flex items-center gap-3 rounded-sm px-3 py-2.5 text-left font-mono text-[11px] uppercase tracking-[0.08em] transition-colors ${
                  tab === id
                    ? 'bg-accent/15 text-accent'
                    : 'text-text-secondary hover:bg-input hover:text-text-primary'
                }`}
              >
                <Icon size={15} />
                {t(label)}
              </button>
            ))}
          </nav>

          <div className="border-t border-border px-5 py-4">
            <span className="msk-label block text-[10px]">{t('finance_balance')}</span>
            <span className="font-display text-[18px] font-bold text-accent">
              ${Math.round(boot.station.balance).toLocaleString('en-US')}
            </span>
          </div>
        </aside>

        <main className="flex min-w-0 flex-1 flex-col">
          <header className="flex items-center justify-between gap-4 border-b border-border px-6 py-4">
            <h2 className="font-display text-[16px] font-semibold text-text-primary">
              {t(TABS.find((x) => x.id === tab)?.label ?? 'tab_overview')}
            </h2>

            <div className="flex items-center gap-4">
              <StatusText toast={toast} />
              <button
                type="button"
                onClick={close}
                className="flex h-8 w-8 items-center justify-center rounded-sm text-text-muted transition-colors hover:bg-input hover:text-text-primary"
                aria-label={t('close')}
              >
                <X size={18} />
              </button>
            </div>
          </header>

          <div className="msk-scroll flex-1 overflow-y-auto p-6">
            {tab === 'overview' && <OverviewTab {...tabProps} />}
            {tab === 'finance' && <FinanceTab {...tabProps} />}
            {tab === 'prices' && <PricesTab {...tabProps} />}
            {tab === 'stock' && <StockTab {...tabProps} />}
            {tab === 'supply' && <SupplyTab {...tabProps} />}
            {tab === 'pumps' && <PumpsTab {...tabProps} />}
            {tab === 'staff' && <StaffTab {...tabProps} />}
            {tab === 'ranks' && <RanksTab {...tabProps} />}
          </div>
        </main>
      </div>
    </div>
  )
}
