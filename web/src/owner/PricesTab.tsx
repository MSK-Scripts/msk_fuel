import { useState } from 'react'
import { Btn, Field, NumInput, Section, Select } from '../admin/ui'
import type { OwnerTabProps } from './OwnerApp'
import type { StockRow } from '../admin/types'
import type { TranslationKey } from '../lib/i18n'

const fuelLabel = (t: (k: TranslationKey) => string, fuelType: string) =>
  t(`fuel_${fuelType}` as TranslationKey)

export default function PricesTab({ boot, t, can, call }: OwnerTabProps) {
  const readOnly = !can('set_prices')

  return (
    <div className="flex flex-col gap-4">
      <p className="rounded-sm border border-border bg-panel-raised px-4 py-3 font-sans text-[12px] text-text-secondary">
        {t('prices_hint')}
      </p>

      {boot.stock.map((row) => (
        <PriceRow
          key={row.fuelType}
          row={row}
          basePrice={boot.basePrices[row.fuelType] ?? 0}
          limit={boot.priceLimits[row.fuelType] ?? { min: 0, max: 0 }}
          readOnly={readOnly}
          t={t}
          call={call}
        />
      ))}
    </div>
  )
}

function PriceRow({
  row,
  basePrice,
  limit,
  readOnly,
  t,
  call,
}: {
  row: StockRow
  basePrice: number
  limit: { min: number; max: number }
  readOnly: boolean
  t: (k: TranslationKey) => string
  call: OwnerTabProps['call']
}) {
  const [mode, setMode] = useState(row.priceMode)
  const [fixedPrice, setFixedPrice] = useState(row.fixedPrice)

  const dirty = mode !== row.priceMode || fixedPrice !== row.fixedPrice

  return (
    <Section title={fuelLabel(t, row.fuelType)}>
      <div className="grid grid-cols-3 gap-3">
        <div className="rounded-sm border border-border bg-input px-3 py-2">
          <span className="msk-label block text-[10px]">{t('prices_current')}</span>
          <span className="font-mono text-[15px] text-accent">${row.price.toFixed(2)}</span>
        </div>

        <div className="rounded-sm border border-border bg-input px-3 py-2">
          <span className="msk-label block text-[10px]">{t('prices_base')}</span>
          <span className="font-mono text-[15px] text-text-secondary">${basePrice.toFixed(2)}</span>
        </div>

        <div className="rounded-sm border border-border bg-input px-3 py-2">
          <span className="msk-label block text-[10px]">{t('prices_range')}</span>
          <span className="font-mono text-[15px] text-text-secondary">
            ${limit.min.toFixed(2)} - ${limit.max.toFixed(2)}
          </span>
        </div>
      </div>

      <div className="grid grid-cols-2 gap-3">
        <Field label={t('stock_price_mode')}>
          <Select
            value={mode}
            disabled={readOnly}
            onChange={(v) => setMode(v as StockRow['priceMode'])}
            options={[
              { value: 'dynamic', label: t('stock_mode_dynamic') },
              { value: 'fixed', label: t('stock_mode_fixed') },
            ]}
          />
        </Field>

        <Field label={t('stock_fixed_price')}>
          <NumInput
            value={fixedPrice}
            step={0.01}
            disabled={readOnly || mode !== 'fixed'}
            onChange={setFixedPrice}
          />
        </Field>
      </div>

      {!readOnly && (
        <div className="flex justify-end">
          <Btn
            variant="accent"
            disabled={!dirty}
            onClick={() => call('owner:pricing', { fuelType: row.fuelType, mode, fixedPrice })}
          >
            {t('save')}
          </Btn>
        </div>
      )}
    </Section>
  )
}
