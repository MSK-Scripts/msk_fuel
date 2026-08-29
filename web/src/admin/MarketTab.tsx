import { useState } from 'react'
import { Btn, Field, NumInput, Section } from './ui'
import type { TabProps } from './AdminApp'
import type { Settings } from './types'
import type { TranslationKey } from '../lib/i18n'

const fuelLabel = (t: (k: TranslationKey) => string, fuelType: string) =>
  t(`fuel_${fuelType}` as TranslationKey)

export default function MarketTab({ boot, t, can, call }: TabProps) {
  const [draft, setDraft] = useState<Settings>(boot.settings)
  const readOnly = !can('market.manage')

  const patch = (next: Partial<Settings>) => setDraft({ ...draft, ...next })

  const save = () =>
    call('admin:settings:save', {
      settings: {
        BasePrices: draft.BasePrices,
        PriceLimits: draft.PriceLimits,
        Market: draft.Market,
        DefaultCapacity: draft.DefaultCapacity,
      },
    })

  return (
    <div className="flex flex-col gap-4">
      <Section title={t('market_base')}>
        <p className="font-sans text-[11px] text-text-muted">{t('market_base_hint')}</p>

        <div className="grid grid-cols-2 gap-3 md:grid-cols-4">
          {boot.fuelTypes.map((fuelType) => (
            <Field key={fuelType} label={fuelLabel(t, fuelType)}>
              <NumInput
                value={draft.BasePrices?.[fuelType] ?? 0}
                step={0.05}
                disabled={readOnly}
                onChange={(v) => patch({ BasePrices: { ...draft.BasePrices, [fuelType]: v } })}
              />
            </Field>
          ))}
        </div>
      </Section>

      <Section title={t('market_limits')}>
        <p className="font-sans text-[11px] text-text-muted">{t('market_limits_hint')}</p>

        {boot.fuelTypes.map((fuelType) => {
          const limit = draft.PriceLimits?.[fuelType] ?? { min: 0, max: 0 }

          return (
            <div key={fuelType} className="grid grid-cols-3 items-end gap-3">
              <span className="font-display text-[13px] text-text-primary">{fuelLabel(t, fuelType)}</span>

              <Field label={t('market_min')}>
                <NumInput
                  value={limit.min}
                  step={0.05}
                  disabled={readOnly}
                  onChange={(v) =>
                    patch({ PriceLimits: { ...draft.PriceLimits, [fuelType]: { ...limit, min: v } } })
                  }
                />
              </Field>

              <Field label={t('market_max')}>
                <NumInput
                  value={limit.max}
                  step={0.05}
                  disabled={readOnly}
                  onChange={(v) =>
                    patch({ PriceLimits: { ...draft.PriceLimits, [fuelType]: { ...limit, max: v } } })
                  }
                />
              </Field>
            </div>
          )
        })}
      </Section>

      <Section title={t('market_params')}>
        <div className="grid grid-cols-2 gap-3 md:grid-cols-3">
          <Field label={t('market_kStock')}>
            <NumInput
              value={draft.Market?.kStock ?? 0}
              step={0.05}
              disabled={readOnly}
              onChange={(v) => patch({ Market: { ...draft.Market, kStock: v } })}
            />
          </Field>

          <Field label={t('market_kDemand')}>
            <NumInput
              value={draft.Market?.kDemand ?? 0}
              step={0.05}
              disabled={readOnly}
              onChange={(v) => patch({ Market: { ...draft.Market, kDemand: v } })}
            />
          </Field>

          <Field label={t('market_demandNorm')}>
            <NumInput
              value={draft.Market?.demandNorm ?? 0}
              step={100}
              disabled={readOnly}
              onChange={(v) => patch({ Market: { ...draft.Market, demandNorm: v } })}
            />
          </Field>

          <Field label={t('market_drift')}>
            <NumInput
              value={draft.Market?.drift ?? 0}
              step={0.01}
              disabled={readOnly}
              onChange={(v) => patch({ Market: { ...draft.Market, drift: v } })}
            />
          </Field>

          <Field label={t('market_decay')}>
            <NumInput
              value={draft.Market?.decay ?? 0}
              step={0.05}
              disabled={readOnly}
              onChange={(v) => patch({ Market: { ...draft.Market, decay: v } })}
            />
          </Field>

          <Field label={t('market_tick')}>
            <NumInput
              value={draft.Market?.tickMinutes ?? 60}
              step={5}
              disabled={readOnly}
              onChange={(v) => patch({ Market: { ...draft.Market, tickMinutes: v } })}
            />
          </Field>
        </div>
      </Section>

      <Section title={t('market_capacity')}>
        <p className="font-sans text-[11px] text-text-muted">{t('market_capacity_hint')}</p>

        <div className="grid grid-cols-2 gap-3 md:grid-cols-4">
          {boot.fuelTypes.map((fuelType) => (
            <Field key={fuelType} label={fuelLabel(t, fuelType)}>
              <NumInput
                value={draft.DefaultCapacity?.[fuelType] ?? 0}
                step={1000}
                disabled={readOnly}
                onChange={(v) => patch({ DefaultCapacity: { ...draft.DefaultCapacity, [fuelType]: v } })}
              />
            </Field>
          ))}
        </div>
      </Section>

      {!readOnly && (
        <div className="flex justify-end">
          <Btn variant="accent" onClick={save}>{t('save')}</Btn>
        </div>
      )}
    </div>
  )
}
