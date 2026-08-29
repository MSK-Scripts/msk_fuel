import { useState } from 'react'
import { Plus, Trash2 } from 'lucide-react'
import { Btn, Chip, ConfirmDialog, Field, Section, Switch, TextInput } from './ui'
import type { TabProps } from './AdminApp'
import type { Group } from './types'
import type { TranslationKey } from '../lib/i18n'

export default function PermissionsTab({ boot, t, call }: TabProps) {
  const [newGroup, setNewGroup] = useState('')
  const [confirm, setConfirm] = useState<Group | null>(null)
  const [dashboardGroups, setDashboardGroups] = useState<string[]>(boot.settings.dashboardGroups ?? [])

  const addGroup = async () => {
    const name = newGroup.trim().toLowerCase()
    if (!name) return

    const ok = await call('admin:perms:saveGroup', { group: name, perms: {} })
    if (ok) setNewGroup('')
  }

  const togglePerm = (group: Group, perm: string) => {
    const perms = { ...group.perms, [perm]: !group.perms[perm] }

    void call('admin:perms:saveGroup', { group: group.name, perms })
  }

  const toggleDashboardGroup = (name: string) => {
    const next = dashboardGroups.includes(name)
      ? dashboardGroups.filter((g) => g !== name)
      : [...dashboardGroups, name]

    setDashboardGroups(next)
    void call('admin:perms:dashboardGroups', { groups: next })
  }

  // Every group that can be toggled for dashboard access: the ones with a
  // permission matrix plus the suggested defaults that do not exist yet.
  const knownGroups = Array.from(
    new Set([...boot.groups.map((g) => g.name), ...boot.suggestedGroups, ...dashboardGroups]),
  ).sort()

  return (
    <div className="flex flex-col gap-4">
      <Section title={t('perms_dashboard_groups')}>
        <p className="font-sans text-[11px] text-text-muted">{t('perms_dashboard_hint')}</p>

        <div className="flex flex-wrap gap-2">
          {knownGroups.map((name) => (
            <Chip
              key={name}
              active={dashboardGroups.includes(name)}
              onClick={() => toggleDashboardGroup(name)}
            >
              {name}
            </Chip>
          ))}
        </div>
      </Section>

      <Section title={t('perms_add_group')}>
        <div className="flex items-end gap-3">
          <div className="flex-1">
            <Field label={t('perms_group_name')}>
              <TextInput value={newGroup} onChange={setNewGroup} placeholder="mod" />
            </Field>
          </div>

          <Btn variant="accent" onClick={addGroup} disabled={!newGroup.trim()}>
            <Plus size={13} /> {t('create')}
          </Btn>
        </div>
      </Section>

      {boot.groups.map((group) => (
        <Section key={group.name} title={group.name}>
          {group.protected ? (
            <p className="font-sans text-[12px] text-text-muted">{t('perms_protected')}</p>
          ) : (
            <>
              <div className="grid grid-cols-1 gap-2 md:grid-cols-2">
                {boot.permKeys.map((perm) => (
                  <div
                    key={perm}
                    className="flex items-center justify-between gap-3 rounded-sm border border-border bg-input px-3 py-2"
                  >
                    <span className="font-sans text-[12px] text-text-secondary">
                      {t(`perm_${perm}` as TranslationKey)}
                    </span>

                    <Switch
                      checked={group.perms[perm] === true}
                      onChange={() => togglePerm(group, perm)}
                    />
                  </div>
                ))}
              </div>

              <div className="flex justify-end">
                <Btn variant="danger" onClick={() => setConfirm(group)}>
                  <Trash2 size={13} /> {t('delete')}
                </Btn>
              </div>
            </>
          )}
        </Section>
      ))}

      {confirm && (
        <ConfirmDialog
          title={confirm.name}
          message={t('perms_delete_confirm')}
          confirmLabel={t('delete')}
          cancelLabel={t('cancel')}
          onConfirm={() => {
            void call('admin:perms:deleteGroup', { group: confirm.name })
            setConfirm(null)
          }}
          onCancel={() => setConfirm(null)}
        />
      )}
    </div>
  )
}
