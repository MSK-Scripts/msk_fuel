import { Wrench } from 'lucide-react'
import { Btn, Section } from '../admin/ui'
import type { OwnerTabProps } from './OwnerApp'
import type { Pump } from './types'

const money = (n: number) => `$${Math.round(n).toLocaleString('en-US')}`

export default function PumpsTab({ boot, t, can, call }: OwnerTabProps) {
  const maintenance = boot.maintenance
  const mayRepair = can('repair')

  if (!maintenance.enabled) {
    return (
      <p className="rounded-sm border border-border bg-panel-raised px-4 py-6 text-center font-sans text-[13px] text-text-muted">
        {t('pumps_disabled')}
      </p>
    )
  }

  return (
    <div className="flex flex-col gap-4">
      <Section title={t('pumps_mechanic')}>
        {maintenance.mechanic ? (
          <p className="font-sans text-[12px] text-accent">{t('pumps_mechanic_hired')}</p>
        ) : (
          <>
            <p className="font-sans text-[12px] text-text-secondary">{t('pumps_mechanic_hint')}</p>

            <div className="flex justify-end">
              <Btn
                variant="accent"
                disabled={!mayRepair}
                onClick={() => void call('owner:mechanic:unlock')}
              >
                {t('pumps_mechanic_unlock').replace('%s', money(maintenance.mechanicPrice))}
              </Btn>
            </div>
          </>
        )}
      </Section>

      <p className="rounded-sm border border-border bg-panel-raised px-4 py-3 font-sans text-[12px] text-text-secondary">
        {t('pumps_hint')}
      </p>

      {boot.pumps.length === 0 ? (
        <p className="rounded-sm border border-border bg-panel-raised px-4 py-6 text-center font-sans text-[13px] text-text-muted">
          {t('pumps_empty')}
        </p>
      ) : (
        boot.pumps.map((pump) => (
          <PumpRow
            key={pump.key}
            pump={pump}
            slowThreshold={maintenance.slowThreshold}
            mayRepair={mayRepair}
            t={t}
            call={call}
          />
        ))
      )}
    </div>
  )
}

function PumpRow({
  pump,
  slowThreshold,
  mayRepair,
  t,
  call,
}: {
  pump: Pump
  slowThreshold: number
  mayRepair: boolean
} & Pick<OwnerTabProps, 't' | 'call'>) {
  const worn = pump.health < slowThreshold
  const state = pump.broken ? t('pumps_broken') : worn ? t('pumps_worn') : t('pumps_fine')
  const colour = pump.broken ? 'text-red-400' : worn ? 'text-amber-400' : 'text-accent'
  const bar = pump.broken ? 'bg-red-400' : worn ? 'bg-amber-400' : 'bg-accent'

  return (
    <div className="rounded-sm border border-border bg-panel-raised px-4 py-3">
      <div className="mb-2 flex items-center justify-between gap-3">
        <span className="min-w-0">
          <span className="block font-display text-[14px] font-semibold text-text-primary">
            {t('pumps_health')}: {pump.health}%
          </span>
          <span className="msk-label block text-[10px]">
            {Math.round(pump.coords.x)} / {Math.round(pump.coords.y)}
          </span>
        </span>

        <div className="flex shrink-0 items-center gap-3">
          <span className={`font-mono text-[12px] ${colour}`}>{state}</span>

          {mayRepair && pump.health < 100 && (
            <Btn variant="accent" onClick={() => void call('owner:pump:repair', { pumpKey: pump.key })}>
              <Wrench size={13} /> {t('pumps_repair')} ({money(pump.repairCost)})
            </Btn>
          )}
        </div>
      </div>

      <div className="h-1.5 w-full overflow-hidden rounded-full bg-white/10">
        <div className={`h-full rounded-full ${bar}`} style={{ width: `${pump.health}%` }} />
      </div>
    </div>
  )
}
