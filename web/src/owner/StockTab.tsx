import { Section } from '../admin/ui'
import type { OwnerTabProps } from './OwnerApp'
import type { TranslationKey } from '../lib/i18n'

const fuelLabel = (t: (k: TranslationKey) => string, fuelType: string) =>
  t(`fuel_${fuelType}` as TranslationKey)

const number = (n: number) => Math.round(n).toLocaleString('en-US')

export default function StockTab({ boot, t }: OwnerTabProps) {
  return (
    <div className="flex flex-col gap-4">
      <p className="rounded-sm border border-border bg-panel-raised px-4 py-3 font-sans text-[12px] text-text-secondary">
        {t('stock_hint_owner')}
      </p>

      {boot.stock.map((row) => {
        const fillRatio = row.capacity > 0 ? Math.min(1, row.stock / row.capacity) : 0
        const low = fillRatio <= 0.2

        return (
          <Section key={row.fuelType} title={fuelLabel(t, row.fuelType)}>
            <div className="flex items-baseline justify-between">
              <span className="font-display text-[20px] font-bold text-text-primary">
                {number(row.stock)}
                <span className="ml-1 font-sans text-[12px] font-normal text-text-muted">
                  / {number(row.capacity)} L
                </span>
              </span>

              <span className={`font-mono text-[12px] ${row.stock > 0 ? 'text-accent' : 'text-red-400'}`}>
                {row.stock > 0 ? `$${row.price.toFixed(2)} / L` : t('stock_sold_out')}
              </span>
            </div>

            <div className="h-2 w-full overflow-hidden rounded-full bg-white/10">
              <div
                className={`h-full rounded-full ${low ? 'bg-red-400' : 'bg-accent'}`}
                style={{ width: `${fillRatio * 100}%` }}
              />
            </div>
          </Section>
        )
      })}
    </div>
  )
}
