import { useMemo, useState } from 'react'
import { Truck, Zap } from 'lucide-react'
import { Btn, Field, NumInput, Section, Select, ToggleRow } from '../admin/ui'
import type { OwnerTabProps } from './OwnerApp'
import type { TranslationKey } from '../lib/i18n'

const money = (n: number) => `$${Math.round(n).toLocaleString('en-US')}`

const fuelLabel = (t: (k: TranslationKey) => string, fuelType: string) =>
  t(`fuel_${fuelType}` as TranslationKey)

export default function SupplyTab({ boot, t, can, call }: OwnerTabProps) {
  const supply = boot.supply
  const mayOrder = can('order_fuel')

  const [fuelType, setFuelType] = useState(boot.fuelTypes[0] ?? 'gas')
  const [instantAmount, setInstantAmount] = useState(1000)
  const [vehicleType, setVehicleType] = useState(Object.keys(supply.vehicles)[0] ?? 'van')
  const [orderAmount, setOrderAmount] = useState(500)

  const free = supply.free[fuelType] ?? 0
  const wholesale = supply.wholesale[fuelType] ?? 1

  // Mirrors Supply.CostOf on the server. The server recalculates and is the one
  // that charges; this is only so the player sees the price before committing.
  const instantCost = Math.ceil(instantAmount * wholesale * supply.npcSurcharge)

  const vehicle = supply.vehicles[vehicleType]
  const orderCost = useMemo(
    () => Math.ceil(orderAmount * wholesale * (1 - (vehicle?.discount ?? 0))),
    [orderAmount, wholesale, vehicle],
  )

  const fuelOptions = boot.fuelTypes.map((f) => ({ value: f, label: fuelLabel(t, f) }))

  return (
    <div className="flex flex-col gap-4">
      <Section title={t('supply_npc')}>
        {supply.npcUnlocked ? (
          <>
            <p className="font-sans text-[12px] text-accent">{t('supply_npc_unlocked')}</p>

            <ToggleRow
              label={t('supply_auto')}
              checked={supply.autoRestock}
              disabled={!mayOrder}
              onChange={(v) => void call('owner:autoRestock', { enable: v })}
            />

            <p className="font-sans text-[11px] text-text-muted">{t('supply_auto_hint')}</p>
          </>
        ) : (
          <>
            <p className="font-sans text-[12px] text-text-secondary">{t('supply_npc_locked')}</p>

            <div className="flex justify-end">
              <Btn variant="accent" disabled={!mayOrder} onClick={() => void call('owner:npc:unlock')}>
                {t('supply_npc_unlock').replace('%s', money(supply.npcUnlockPrice))}
              </Btn>
            </div>
          </>
        )}
      </Section>

      <Section title={t('supply_instant')} disabled={!supply.npcUnlocked} hint={t('err_npc_locked')}>
        <p className="font-sans text-[11px] text-text-muted">{t('supply_instant_hint')}</p>

        <div className="grid grid-cols-3 gap-3">
          <Field label={t('supply_fuel')}>
            <Select value={fuelType} onChange={setFuelType} options={fuelOptions} />
          </Field>

          <Field label={t('supply_amount')}>
            <NumInput value={instantAmount} step={100} onChange={setInstantAmount} />
          </Field>

          <Field label={t('supply_free')}>
            <div className="rounded-sm border border-border bg-input px-3 py-2 font-mono text-[13px] text-text-secondary">
              {free.toLocaleString('en-US')} L
            </div>
          </Field>
        </div>

        <div className="flex items-center justify-between gap-3">
          <span className="font-sans text-[13px] text-text-secondary">
            {t('supply_cost')}: <span className="font-mono text-accent">{money(instantCost)}</span>
          </span>

          <Btn
            variant="accent"
            disabled={!mayOrder || instantAmount <= 0 || free <= 0}
            onClick={() => void call('owner:restock', { fuelType, amount: Math.min(instantAmount, free) })}
          >
            <Zap size={13} /> {t('supply_instant')}
          </Btn>
        </div>
      </Section>

      <Section title={t('supply_order')}>
        <p className="font-sans text-[11px] text-text-muted">{t('supply_order_hint')}</p>

        <div className="grid grid-cols-3 gap-3">
          <Field label={t('supply_fuel')}>
            <Select value={fuelType} onChange={setFuelType} options={fuelOptions} />
          </Field>

          <Field label={t('supply_vehicle')}>
            <Select
              value={vehicleType}
              onChange={(v) => {
                setVehicleType(v)

                // Never leave an amount standing that the new rig cannot carry.
                const capacity = supply.vehicles[v]?.capacity ?? 0
                setOrderAmount((current) => Math.min(current, capacity))
              }}
              options={Object.entries(supply.vehicles).map(([key, spec]) => ({
                value: key,
                label: `${spec.label} (${spec.capacity} L)`,
              }))}
            />
          </Field>

          <Field label={t('supply_amount')}>
            <NumInput value={orderAmount} step={100} onChange={setOrderAmount} />
          </Field>
        </div>

        <div className="flex items-center justify-between gap-3">
          <span className="font-sans text-[13px] text-text-secondary">
            {t('supply_capacity')}: {vehicle?.capacity ?? 0} L · {t('supply_cost')}:{' '}
            <span className="font-mono text-accent">{money(orderCost)}</span>
          </span>

          <Btn
            variant="accent"
            disabled={!mayOrder || orderAmount <= 0 || free <= 0}
            onClick={() =>
              void call('owner:delivery:start', {
                fuelType,
                amount: Math.min(orderAmount, vehicle?.capacity ?? 0, free),
                vehicleType,
              })
            }
          >
            <Truck size={13} /> {t('supply_start_order')}
          </Btn>
        </div>
      </Section>
    </div>
  )
}
