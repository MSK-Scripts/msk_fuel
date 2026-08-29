import { useState } from 'react'
import { Plus, Trash2 } from 'lucide-react'
import { Btn, ConfirmDialog, Field, Modal, NumInput, Section, Switch, TextInput } from '../admin/ui'
import type { OwnerTabProps } from './OwnerApp'
import type { Rank } from './types'
import type { TranslationKey } from '../lib/i18n'

const emptyRank = (): Rank => ({ id: '', label: '', salary: 0, deliveryBonus: 0, perms: {} })

export default function RanksTab({ boot, t, can, call }: OwnerTabProps) {
  const [editing, setEditing] = useState<Rank | null>(null)
  const [isNew, setIsNew] = useState(false)
  const [deleting, setDeleting] = useState<Rank | null>(null)

  const mayEdit = can('hire')

  return (
    <div className="flex flex-col gap-4">
      <div className="flex items-center justify-between">
        <span className="msk-label text-[10px] font-bold">
          {boot.ranks.length} {t('tab_ranks')}
        </span>

        {mayEdit && (
          <Btn
            variant="accent"
            onClick={() => {
              setEditing(emptyRank())
              setIsNew(true)
            }}
          >
            <Plus size={13} /> {t('ranks_new')}
          </Btn>
        )}
      </div>

      {boot.ranks.length === 0 && (
        <p className="rounded-sm border border-border bg-panel-raised px-4 py-6 text-center font-sans text-[13px] text-text-muted">
          {t('ranks_empty')}
        </p>
      )}

      {boot.ranks.map((rank) => (
        <Section key={rank.id} title={rank.label}>
          <div className="flex flex-wrap items-center justify-between gap-3">
            <div className="flex flex-wrap gap-2">
              {boot.permKeys
                .filter((perm) => rank.perms[perm])
                .map((perm) => (
                  <span
                    key={perm}
                    className="rounded-sm border border-border-accent bg-accent/10 px-2 py-1 font-mono text-[10px] uppercase tracking-[0.06em] text-accent"
                  >
                    {t(`perm_${perm}` as TranslationKey)}
                  </span>
                ))}
            </div>

            <div className="flex items-center gap-3">
              <span className="font-mono text-[12px] text-text-secondary">
                ${rank.salary.toLocaleString('en-US')} / ${rank.deliveryBonus.toLocaleString('en-US')}
              </span>

              {mayEdit && (
                <>
                  <Btn
                    onClick={() => {
                      setEditing({ ...rank, perms: { ...rank.perms } })
                      setIsNew(false)
                    }}
                  >
                    {t('edit')}
                  </Btn>

                  <Btn variant="danger" onClick={() => setDeleting(rank)}>
                    <Trash2 size={13} />
                  </Btn>
                </>
              )}
            </div>
          </div>
        </Section>
      ))}

      {editing && (
        <RankEditor
          rank={editing}
          isNew={isNew}
          isOwner={boot.isOwner}
          permKeys={boot.permKeys}
          t={t}
          onChange={setEditing}
          onCancel={() => setEditing(null)}
          onSave={async () => {
            const ok = await call('owner:rank:save', {
              rankId: editing.id,
              label: editing.label,
              salary: editing.salary,
              deliveryBonus: editing.deliveryBonus,
              perms: editing.perms,
            })

            if (ok) setEditing(null)
          }}
        />
      )}

      {deleting && (
        <ConfirmDialog
          title={deleting.label}
          message={t('ranks_delete_confirm')}
          confirmLabel={t('delete')}
          cancelLabel={t('cancel')}
          onConfirm={() => {
            void call('owner:rank:delete', { rankId: deleting.id })
            setDeleting(null)
          }}
          onCancel={() => setDeleting(null)}
        />
      )}
    </div>
  )
}

function RankEditor({
  rank,
  isNew,
  isOwner,
  permKeys,
  t,
  onChange,
  onCancel,
  onSave,
}: {
  rank: Rank
  isNew: boolean
  isOwner: boolean
  permKeys: string[]
  t: (k: TranslationKey) => string
  onChange: (next: Rank) => void
  onCancel: () => void
  onSave: () => void
}) {
  const patch = (next: Partial<Rank>) => onChange({ ...rank, ...next })

  return (
    <Modal
      title={isNew ? t('ranks_new') : rank.label}
      onClose={onCancel}
      footer={
        <>
          <Btn variant="ghost" onClick={onCancel}>{t('cancel')}</Btn>
          <Btn variant="accent" disabled={!rank.id || !rank.label.trim()} onClick={onSave}>
            {isNew ? t('create') : t('save')}
          </Btn>
        </>
      }
    >
      <div className="flex flex-col gap-4">
        <Section title={t('ranks_label')}>
          <div className="grid grid-cols-2 gap-3">
            <Field label={t('ranks_id')}>
              <TextInput
                value={rank.id}
                disabled={!isNew}
                placeholder="employee"
                onChange={(v) => patch({ id: v })}
              />
            </Field>

            <Field label={t('ranks_label')}>
              <TextInput value={rank.label} onChange={(v) => patch({ label: v })} />
            </Field>
          </div>

          {isNew && <p className="font-sans text-[11px] text-text-muted">{t('ranks_id_hint')}</p>}

          <div className="grid grid-cols-2 gap-3">
            <Field label={t('ranks_salary')}>
              <NumInput value={rank.salary} step={100} onChange={(v) => patch({ salary: v })} />
            </Field>

            <Field label={t('ranks_bonus')}>
              <NumInput
                value={rank.deliveryBonus}
                step={50}
                onChange={(v) => patch({ deliveryBonus: v })}
              />
            </Field>
          </div>
        </Section>

        <Section title={t('ranks_perms')}>
          {!isOwner && (
            <p className="font-sans text-[11px] text-text-muted">{t('ranks_perms_owner_only')}</p>
          )}

          <div className="grid grid-cols-1 gap-2 md:grid-cols-2">
            {permKeys.map((perm) => (
              <div
                key={perm}
                className="flex items-center justify-between gap-3 rounded-sm border border-border bg-input px-3 py-2"
              >
                <span className="font-sans text-[12px] text-text-secondary">
                  {t(`perm_${perm}` as TranslationKey)}
                </span>

                <Switch
                  checked={rank.perms[perm] === true}
                  disabled={!isOwner}
                  onChange={(v) => patch({ perms: { ...rank.perms, [perm]: v } })}
                />
              </div>
            ))}
          </div>
        </Section>
      </div>
    </Modal>
  )
}
