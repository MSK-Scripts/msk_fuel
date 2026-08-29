import { useCallback, useEffect, useMemo, useState } from 'react'
import { Fuel, LineChart, Settings2, ShieldCheck, Truck, X } from 'lucide-react'
import { fetchNui } from '../lib/nui'
import { applyTheme } from '../lib/theme'
import { errorText, makeT, type TranslationKey } from '../lib/i18n'
import { StatusText } from './ui'
import StationsTab from './StationsTab'
import MarketTab from './MarketTab'
import SettingsTab from './SettingsTab'
import PermissionsTab from './PermissionsTab'
import NeutralTab from './NeutralTab'
import type { ApiResponse, Bootstrap } from './types'

export type Toast = { msg: string; ok: boolean } | null

/** What every tab needs: data, translations, and a way to talk to the server. */
export interface TabProps {
  boot: Bootstrap
  t: (key: TranslationKey) => string
  can: (perm: string) => boolean
  call: (endpoint: string, data?: unknown) => Promise<boolean>
  toast: Toast
}

type TabId = 'stations' | 'market' | 'neutral' | 'settings' | 'permissions'

const TABS: { id: TabId; icon: typeof Fuel; label: TranslationKey; perms: string[] }[] = [
  { id: 'stations', icon: Fuel, label: 'tab_stations', perms: ['station.view', 'station.create', 'station.edit', 'station.delete', 'stock.manage'] },
  { id: 'market', icon: LineChart, label: 'tab_market', perms: ['market.manage'] },
  { id: 'neutral', icon: Truck, label: 'tab_neutral', perms: ['station.edit'] },
  { id: 'settings', icon: Settings2, label: 'tab_settings', perms: ['settings.manage'] },
  { id: 'permissions', icon: ShieldCheck, label: 'tab_permissions', perms: ['permissions.manage'] },
]

export default function AdminApp({
  boot,
  onBootChange,
  onClose,
}: {
  boot: Bootstrap
  onBootChange: (boot: Bootstrap) => void
  onClose: () => void
}) {
  const t = useMemo(() => makeT(boot.locale), [boot.locale])
  const can = useCallback((perm: string) => boot.perms[perm] === true, [boot.perms])

  const visibleTabs = useMemo(() => TABS.filter((tab) => tab.perms.some(can)), [can])
  const [tab, setTab] = useState<TabId>(() => visibleTabs[0]?.id ?? 'stations')
  const [toast, setToast] = useState<Toast>(null)

  // A permission change can take the current tab away mid-session.
  useEffect(() => {
    if (!visibleTabs.some((v) => v.id === tab) && visibleTabs[0]) {
      setTab(visibleTabs[0].id)
    }
  }, [visibleTabs, tab])

  const close = useCallback(() => {
    void fetchNui('admin:close')
    onClose()
  }, [onClose])

  useEffect(() => {
    const onKey = (e: KeyboardEvent) => {
      if (e.key === 'Escape') close()
    }

    window.addEventListener('keydown', onKey)
    return () => window.removeEventListener('keydown', onKey)
  }, [close])

  // Every mutation goes through here: the server answers with a fresh bootstrap
  // on success, so the UI always shows what the database actually holds rather
  // than what it optimistically assumed.
  const call = useCallback(
    async (endpoint: string, data: unknown = {}): Promise<boolean> => {
      const res = await fetchNui<ApiResponse>(endpoint, data)

      if (!res || !res.ok) {
        setToast({ msg: errorText(t, res?.err), ok: false })
        return false
      }

      if (res.data) {
        onBootChange(res.data)
        applyTheme(res.data.settings?.Theme)
      }

      setToast({ msg: t('saved'), ok: true })
      return true
    },
    [onBootChange, t],
  )

  // Let a status line fade instead of piling up.
  useEffect(() => {
    if (!toast) return

    const id = window.setTimeout(() => setToast(null), 4000)
    return () => window.clearTimeout(id)
  }, [toast])

  const tabProps: TabProps = { boot, t, can, call, toast }

  return (
    <div className="flex h-full w-full items-center justify-center bg-black/50 font-sans">
      <div className="msk-panel flex h-[86vh] w-[1180px] max-w-[96vw] overflow-hidden animate-scale-in">
        <aside className="flex w-[220px] shrink-0 flex-col border-r border-border bg-panel-raised">
          <div className="border-b border-border px-5 py-5">
            <h1 className="font-display text-[18px] font-bold text-accent">{t('title')}</h1>
            <p className="msk-label mt-1 text-[10px]">{t('subtitle')}</p>
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
        </aside>

        <main className="flex min-w-0 flex-1 flex-col">
          <header className="flex items-center justify-between gap-4 border-b border-border px-6 py-4">
            <h2 className="font-display text-[16px] font-semibold text-text-primary">
              {t(TABS.find((x) => x.id === tab)?.label ?? 'tab_stations')}
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
            {tab === 'stations' && <StationsTab {...tabProps} />}
            {tab === 'market' && <MarketTab {...tabProps} />}
            {tab === 'neutral' && <NeutralTab {...tabProps} />}
            {tab === 'settings' && <SettingsTab {...tabProps} />}
            {tab === 'permissions' && <PermissionsTab {...tabProps} />}
          </div>
        </main>
      </div>
    </div>
  )
}
