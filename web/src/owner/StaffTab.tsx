import { useCallback, useEffect, useState } from 'react'
import { UserMinus, UserPlus } from 'lucide-react'
import { Btn, ConfirmDialog, Field, Modal, Section, Select } from '../admin/ui'
import { fetchNui } from '../lib/nui'
import type { OwnerTabProps } from './OwnerApp'
import type { Employee, OnlinePlayer, OnlinePlayersResponse } from './types'
import type { TranslationKey } from '../lib/i18n'

const money = (n: number) => `$${Math.round(n).toLocaleString('en-US')}`

/** Server timestamps are seconds since epoch; 0 means it never happened. */
const lastActive = (t: (k: TranslationKey) => string, seconds: number) => {
  if (!seconds) return t('staff_never')

  return new Date(seconds * 1000).toLocaleString()
}

export default function StaffTab({ boot, t, can, call }: OwnerTabProps) {
  const [hiring, setHiring] = useState(false)
  const [firing, setFiring] = useState<Employee | null>(null)

  const mayHire = can('hire')

  return (
    <div className="flex flex-col gap-4">
      <div className="flex items-center justify-between">
        <span className="msk-label text-[10px] font-bold">
          {boot.employees.length} {t('tab_staff')}
        </span>

        {mayHire && (
          <Btn variant="accent" onClick={() => setHiring(true)}>
            <UserPlus size={13} /> {t('staff_hire')}
          </Btn>
        )}
      </div>

      {boot.employees.length === 0 && (
        <p className="rounded-sm border border-border bg-panel-raised px-4 py-6 text-center font-sans text-[13px] text-text-muted">
          {t('staff_empty')}
        </p>
      )}

      {boot.employees.map((employee) => (
        <Section key={employee.identifier} title={employee.name || employee.identifier}>
          <div className="flex flex-wrap items-end justify-between gap-3">
            <div className="flex items-center gap-3">
              <span
                className={`flex items-center gap-1.5 font-mono text-[11px] ${
                  employee.online ? 'text-accent' : 'text-text-muted'
                }`}
              >
                <span
                  className={`h-1.5 w-1.5 rounded-full ${employee.online ? 'bg-accent' : 'bg-text-muted'}`}
                />
                {employee.online ? t('staff_online') : t('staff_offline')}
              </span>

              <span className="msk-label text-[10px]">{employee.identifier}</span>
            </div>

            <div className="flex items-end gap-3">
              <div className="w-[220px]">
                <Field label={t('staff_rank')}>
                  <Select
                    value={employee.rankId}
                    disabled={!mayHire}
                    onChange={(rankId) =>
                      void call('owner:setRank', { identifier: employee.identifier, rankId })
                    }
                    options={boot.ranks.map((r) => ({ value: r.id, label: r.label }))}
                  />
                </Field>
              </div>

              {mayHire && (
                <Btn variant="danger" onClick={() => setFiring(employee)}>
                  <UserMinus size={13} /> {t('staff_fire')}
                </Btn>
              )}
            </div>
          </div>

          <div className="grid grid-cols-2 gap-3 md:grid-cols-4">
            {(
              [
                [t('staff_earnings'), money(employee.stats.earnings)],
                [t('staff_deliveries'), String(employee.stats.deliveries)],
                [t('staff_liters'), `${Math.round(employee.stats.liters_sold)} L`],
                [t('staff_last_active'), lastActive(t, employee.stats.last_active)],
              ] as [string, string][]
            ).map(([label, value]) => (
              <div key={label} className="rounded-sm border border-border bg-input px-3 py-2">
                <span className="msk-label block text-[10px]">{label}</span>
                <span className="font-sans text-[13px] text-text-primary">{value}</span>
              </div>
            ))}
          </div>
        </Section>
      ))}

      <p className="font-sans text-[11px] text-text-muted">{t('staff_stats_hint')}</p>

      {hiring && <HireDialog boot={boot} t={t} call={call} onClose={() => setHiring(false)} />}

      {firing && (
        <ConfirmDialog
          title={firing.name || firing.identifier}
          message={t('staff_fire_confirm')}
          confirmLabel={t('staff_fire')}
          cancelLabel={t('cancel')}
          onConfirm={() => {
            void call('owner:fire', { identifier: firing.identifier })
            setFiring(null)
          }}
          onCancel={() => setFiring(null)}
        />
      )}
    </div>
  )
}

function HireDialog({
  boot,
  t,
  call,
  onClose,
}: {
  boot: OwnerTabProps['boot']
  t: OwnerTabProps['t']
  call: OwnerTabProps['call']
  onClose: () => void
}) {
  const [players, setPlayers] = useState<OnlinePlayer[] | null>(null)
  const [target, setTarget] = useState('')
  const [rankId, setRankId] = useState(boot.ranks[0]?.id ?? '')

  // Fetched fresh every time the dialog opens: who is online changes constantly,
  // and the bootstrap would be stale within seconds.
  const load = useCallback(async () => {
    const res = await fetchNui<OnlinePlayersResponse>('owner:onlinePlayers')

    setPlayers(res?.ok ? (res.players ?? []) : [])
  }, [])

  useEffect(() => {
    void load()
  }, [load])

  const hirable = (players ?? []).filter((p) => !p.employed)

  return (
    <Modal
      title={t('staff_hire')}
      onClose={onClose}
      footer={
        <>
          <Btn variant="ghost" onClick={onClose}>{t('cancel')}</Btn>
          <Btn
            variant="accent"
            disabled={!target || !rankId}
            onClick={async () => {
              const ok = await call('owner:hire', { target: Number(target), rankId })
              if (ok) onClose()
            }}
          >
            {t('staff_hire')}
          </Btn>
        </>
      }
    >
      {players === null ? (
        <p className="font-sans text-[13px] text-text-muted">{t('loading')}</p>
      ) : hirable.length === 0 ? (
        <p className="font-sans text-[13px] text-text-muted">{t('staff_no_players')}</p>
      ) : (
        <div className="grid grid-cols-2 gap-3">
          <Field label={t('staff_pick_player')}>
            <Select
              value={target}
              onChange={setTarget}
              options={[
                { value: '', label: '-' },
                ...hirable.map((p) => ({ value: String(p.source), label: `[${p.source}] ${p.name}` })),
              ]}
            />
          </Field>

          <Field label={t('staff_rank')}>
            <Select
              value={rankId}
              onChange={setRankId}
              options={boot.ranks.map((r) => ({ value: r.id, label: r.label }))}
            />
          </Field>
        </div>
      )}
    </Modal>
  )
}
