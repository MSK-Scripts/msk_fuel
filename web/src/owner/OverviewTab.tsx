import { useState } from 'react'
import { Btn, ConfirmDialog, Field, Section, TextInput } from '../admin/ui'
import type { OwnerTabProps } from './OwnerApp'
import type { OwnerStats } from './types'
import type { TranslationKey } from '../lib/i18n'

const money = (n: number) => `$${Math.round(n).toLocaleString('en-US')}`
const liters = (n: number) => `${Math.round(n).toLocaleString('en-US')} L`

function StatBlock({
  title,
  stats,
  t,
}: {
  title: string
  stats: OwnerStats
  t: (k: TranslationKey) => string
}) {
  const rows: [string, string][] = [
    [t('overview_revenue'), money(stats.revenue)],
    [t('overview_liters'), liters(stats.liters)],
    [t('overview_sales'), String(stats.sales)],
  ]

  return (
    <Section title={title}>
      <div className="grid grid-cols-3 gap-3">
        {rows.map(([label, value]) => (
          <div key={label} className="rounded-sm border border-border bg-input px-3 py-3">
            <span className="msk-label block text-[10px]">{label}</span>
            <span className="mt-1 block font-display text-[18px] font-bold text-text-primary">
              {value}
            </span>
          </div>
        ))}
      </div>
    </Section>
  )
}

export default function OverviewTab({ boot, t, can, call }: OwnerTabProps) {
  const [label, setLabel] = useState(boot.station.label)
  const [confirmSell, setConfirmSell] = useState(false)

  const mayManage = can('manage')
  const renamed = label.trim() !== boot.station.label && label.trim().length > 0

  return (
    <div className="flex flex-col gap-4">
      <StatBlock title={t('overview_today')} stats={boot.stats.day} t={t} />
      <StatBlock title={t('overview_week')} stats={boot.stats.week} t={t} />

      <Section title={t('overview_rename')} disabled={!mayManage} hint={t('err_no_permission')}>
        <p className="font-sans text-[11px] text-text-muted">{t('overview_rename_hint')}</p>

        <div className="flex items-end gap-3">
          <div className="flex-1">
            <Field label={t('station_label')}>
              <TextInput value={label} onChange={setLabel} />
            </Field>
          </div>

          <Btn variant="accent" disabled={!renamed} onClick={() => call('owner:rename', { label: label.trim() })}>
            {t('save')}
          </Btn>
        </div>
      </Section>

      {mayManage && (
        <Section title={t('overview_sell')}>
          <p className="font-sans text-[12px] text-text-secondary">
            {t('overview_sell_confirm').replace('%s', money(boot.station.sellPrice))}
          </p>

          <div className="flex justify-end">
            <Btn variant="danger" onClick={() => setConfirmSell(true)}>
              {t('overview_sell')}
            </Btn>
          </div>
        </Section>
      )}

      {confirmSell && (
        <ConfirmDialog
          title={boot.station.label}
          message={t('overview_sell_confirm').replace('%s', money(boot.station.sellPrice))}
          confirmLabel={t('overview_sell')}
          cancelLabel={t('cancel')}
          onConfirm={() => {
            void call('owner:sell')
            setConfirmSell(false)
          }}
          onCancel={() => setConfirmSell(false)}
        />
      )}
    </div>
  )
}
