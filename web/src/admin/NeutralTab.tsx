import { useState } from 'react'
import { Btn, Field, NumInput, Section, ToggleRow } from './ui'
import type { TabProps } from './AdminApp'
import type { Station } from './types'

export default function NeutralTab({ boot, t, can, call }: TabProps) {
  const neutral = boot.stations.filter((s) => !s.owner)
  const readOnly = !can('station.edit')

  return (
    <div className="flex flex-col gap-4">
      <p className="rounded-sm border border-border bg-panel-raised px-4 py-3 font-sans text-[12px] text-text-secondary">
        {t('neutral_hint')}
      </p>

      {neutral.length === 0 && (
        <p className="rounded-sm border border-border bg-panel-raised px-4 py-6 text-center font-sans text-[13px] text-text-muted">
          {t('neutral_none')}
        </p>
      )}

      {neutral.map((station) => (
        <NeutralRow key={station.id} station={station} readOnly={readOnly} t={t} call={call} />
      ))}
    </div>
  )
}

function NeutralRow({
  station,
  readOnly,
  t,
  call,
}: {
  station: Station
  readOnly: boolean
} & Pick<TabProps, 't' | 'call'>) {
  const initial = station.publicDelivery ?? { enable: false, rewardPerLiter: 0.35, amount: 1000 }

  const [enable, setEnable] = useState(initial.enable)
  const [reward, setReward] = useState(initial.rewardPerLiter)
  const [amount, setAmount] = useState(initial.amount)
  const [auto, setAuto] = useState(station.autoRestock ?? false)

  const dirty =
    enable !== initial.enable ||
    reward !== initial.rewardPerLiter ||
    amount !== initial.amount ||
    auto !== (station.autoRestock ?? false)

  return (
    <Section title={station.label || station.id}>
      <ToggleRow
        label={t('neutral_public')}
        checked={enable}
        disabled={readOnly}
        onChange={setEnable}
      />

      <div className="grid grid-cols-2 gap-3">
        <Field label={t('neutral_reward')}>
          <NumInput value={reward} step={0.05} disabled={readOnly || !enable} onChange={setReward} />
        </Field>

        <Field label={t('neutral_amount')}>
          <NumInput value={amount} step={100} disabled={readOnly || !enable} onChange={setAmount} />
        </Field>
      </div>

      <ToggleRow label={t('neutral_auto')} checked={auto} disabled={readOnly} onChange={setAuto} />

      {!readOnly && (
        <div className="flex justify-end">
          <Btn
            variant="accent"
            disabled={!dirty}
            onClick={() =>
              call('admin:station:neutral', {
                id: station.id,
                enable,
                rewardPerLiter: reward,
                amount,
                autoRestock: auto,
              })
            }
          >
            {t('save')}
          </Btn>
        </div>
      )}
    </Section>
  )
}
