import { useState } from 'react'
import { Btn, ColorInput, Field, NumInput, Section, Select, TextInput, ToggleRow } from './ui'
import { applyTheme, DEFAULT_THEME, THEME_KEYS } from '../lib/theme'
import { LOCALES } from '../lib/i18n'
import type { TabProps } from './AdminApp'
import type { Settings } from './types'

export default function SettingsTab({ boot, t, can, call }: TabProps) {
  const [draft, setDraft] = useState<Settings>(boot.settings)
  const readOnly = !can('settings.manage')

  const patch = (next: Partial<Settings>) => setDraft({ ...draft, ...next })

  // Colours preview live, so an admin sees the result before saving.
  const patchTheme = (key: string, value: string) => {
    const theme = { ...draft.Theme, [key]: value }

    applyTheme(theme)
    patch({ Theme: theme })
  }

  const save = () =>
    call('admin:settings:save', {
      settings: {
        Locale: draft.Locale,
        Debug: draft.Debug,
        VersionChecker: draft.VersionChecker,
        adminCommand: draft.adminCommand,
        Theme: draft.Theme,
        NeutralIncome: draft.NeutralIncome,
        DefaultPurchasePrice: draft.DefaultPurchasePrice,
        SellRefundRatio: draft.SellRefundRatio,
        MaxStationBalance: draft.MaxStationBalance,
      },
    })

  return (
    <div className="flex flex-col gap-4">
      <Section title={t('settings_general')}>
        <div className="grid grid-cols-2 gap-3">
          <Field label={t('settings_locale')}>
            <Select
              value={draft.Locale}
              disabled={readOnly}
              onChange={(v) => patch({ Locale: v })}
              options={LOCALES.map((l) => ({ value: l, label: l.toUpperCase() }))}
            />
          </Field>

          <Field label={t('settings_command')}>
            <TextInput
              value={draft.adminCommand ?? ''}
              disabled={readOnly}
              onChange={(v) => patch({ adminCommand: v })}
            />
          </Field>
        </div>

        <ToggleRow
          label={t('settings_debug')}
          checked={draft.Debug === true}
          disabled={readOnly}
          onChange={(v) => patch({ Debug: v })}
        />

        <ToggleRow
          label={t('settings_versionchecker')}
          checked={draft.VersionChecker === true}
          disabled={readOnly}
          onChange={(v) => patch({ VersionChecker: v })}
        />
      </Section>

      <Section title={t('settings_economy')}>
        <div className="grid grid-cols-3 gap-3">
          <Field label={t('settings_purchase_price')}>
            <NumInput
              value={draft.DefaultPurchasePrice ?? 0}
              step={10000}
              disabled={readOnly}
              onChange={(v) => patch({ DefaultPurchasePrice: v })}
            />
          </Field>

          <Field label={t('settings_refund')}>
            <NumInput
              value={draft.SellRefundRatio ?? 0}
              step={0.05}
              disabled={readOnly}
              onChange={(v) => patch({ SellRefundRatio: v })}
            />
          </Field>

          <Field label={t('settings_max_balance')}>
            <NumInput
              value={draft.MaxStationBalance ?? 0}
              step={10000}
              disabled={readOnly}
              onChange={(v) => patch({ MaxStationBalance: v })}
            />
          </Field>
        </div>

        <p className="font-sans text-[11px] text-text-muted">
          {t('settings_purchase_price_hint')} {t('settings_refund_hint')} {t('settings_max_balance_hint')}
        </p>
      </Section>

      <Section title={t('settings_neutral')}>
        <p className="font-sans text-[11px] text-text-muted">{t('settings_neutral_hint')}</p>

        <div className="grid grid-cols-2 gap-3">
          <Field label={t('settings_neutral_mode')}>
            <Select
              value={draft.NeutralIncome?.mode ?? 'void'}
              disabled={readOnly}
              onChange={(v) =>
                patch({ NeutralIncome: { ...draft.NeutralIncome, mode: v as 'void' | 'society' } })
              }
              options={[
                { value: 'void', label: t('settings_neutral_void') },
                { value: 'society', label: t('settings_neutral_society') },
              ]}
            />
          </Field>

          <Field label={t('settings_neutral_society_name')}>
            <TextInput
              value={draft.NeutralIncome?.societyName ?? ''}
              disabled={readOnly || draft.NeutralIncome?.mode !== 'society'}
              onChange={(v) => patch({ NeutralIncome: { ...draft.NeutralIncome, societyName: v } })}
            />
          </Field>
        </div>
      </Section>

      <Section title={t('settings_theme')}>
        <div className="grid grid-cols-2 gap-3 md:grid-cols-3">
          {THEME_KEYS.map((key) => (
            <ColorInput
              key={key}
              label={key}
              value={draft.Theme?.[key] ?? DEFAULT_THEME[key]}
              onChange={(v) => patchTheme(key, v)}
            />
          ))}
        </div>

        <div className="flex justify-end">
          <Btn
            disabled={readOnly}
            onClick={() => {
              applyTheme(DEFAULT_THEME)
              patch({ Theme: { ...DEFAULT_THEME } })
            }}
          >
            {t('theme_reset')}
          </Btn>
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
