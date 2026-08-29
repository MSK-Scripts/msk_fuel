import type { ReactNode } from 'react'
import { Crosshair, X } from 'lucide-react'
import { fetchNui } from '../lib/nui'
import type { Coord } from './types'

export function Btn({
  children,
  onClick,
  variant = 'default',
  disabled,
  type = 'button',
}: {
  children: ReactNode
  onClick?: () => void
  variant?: 'default' | 'accent' | 'danger' | 'ghost'
  disabled?: boolean
  type?: 'button' | 'submit'
}) {
  const base =
    'inline-flex items-center justify-center gap-2 rounded-sm px-3 py-2 font-mono text-[11px] uppercase tracking-[0.08em] transition-colors disabled:cursor-not-allowed disabled:opacity-40'
  const styles = {
    default: 'bg-input text-text-primary hover:bg-white/10 border border-border',
    accent: 'bg-accent text-black hover:bg-accent-dim',
    danger: 'bg-red-500/15 text-red-400 hover:bg-red-500/25 border border-red-500/30',
    ghost: 'text-text-secondary hover:text-text-primary',
  }[variant]
  return (
    <button type={type} onClick={onClick} disabled={disabled} className={`${base} ${styles}`}>
      {children}
    </button>
  )
}

export function Switch({
  checked,
  onChange,
  disabled,
}: {
  checked: boolean
  onChange: (v: boolean) => void
  disabled?: boolean
}) {
  return (
    <button
      type="button"
      disabled={disabled}
      onClick={() => onChange(!checked)}
      className={`relative h-5 w-9 shrink-0 rounded-full transition-colors disabled:opacity-40 ${
        checked ? 'bg-accent' : 'bg-white/15'
      }`}
    >
      <span
        className={`absolute top-0.5 h-4 w-4 rounded-full bg-black transition-transform ${
          checked ? 'left-0.5 translate-x-4' : 'left-0.5'
        }`}
      />
    </button>
  )
}

export function Field({ label, children }: { label: string; children: ReactNode }) {
  return (
    <label className="flex flex-col gap-1.5">
      <span className="msk-label text-[10px] font-bold">{label}</span>
      {children}
    </label>
  )
}

const inputCls =
  'w-full rounded-sm border border-border bg-input px-3 py-2 font-sans text-[13px] text-text-primary outline-none focus:border-border-accent'

export function TextInput({
  value,
  onChange,
  placeholder,
  disabled,
}: {
  value: string
  onChange: (v: string) => void
  placeholder?: string
  disabled?: boolean
}) {
  return (
    <input
      className={inputCls}
      value={value}
      placeholder={placeholder}
      disabled={disabled}
      onChange={(e) => onChange(e.target.value)}
    />
  )
}

export function ColorInput({
  label,
  value,
  onChange,
}: {
  label: string
  value: string
  onChange: (v: string) => void
}) {
  const safe = /^#[0-9a-fA-F]{6}$/.test(value) ? value : '#000000'
  return (
    <label className="flex flex-col gap-1.5">
      <span className="msk-label text-[10px] font-bold">{label}</span>
      <div className="flex items-center gap-2 rounded-sm border border-border bg-input px-2 py-1.5 focus-within:border-border-accent">
        <input
          type="color"
          value={safe}
          onChange={(e) => onChange(e.target.value)}
          className="h-7 w-9 shrink-0 cursor-pointer rounded-sm border-0 bg-transparent p-0"
        />
        <input
          value={value}
          onChange={(e) => onChange(e.target.value)}
          spellCheck={false}
          className="w-full bg-transparent font-mono text-[12px] uppercase text-text-primary outline-none"
        />
      </div>
    </label>
  )
}

export function NumInput({
  value,
  onChange,
  step = 1,
  disabled,
}: {
  value: number
  onChange: (v: number) => void
  step?: number
  disabled?: boolean
}) {
  return (
    <input
      type="number"
      step={step}
      className={inputCls}
      value={Number.isFinite(value) ? value : 0}
      disabled={disabled}
      onChange={(e) => onChange(e.target.value === '' ? 0 : Number(e.target.value))}
    />
  )
}

export function Select({
  value,
  onChange,
  options,
  disabled,
}: {
  value: string
  onChange: (v: string) => void
  options: { value: string; label: string }[]
  disabled?: boolean
}) {
  return (
    <select
      className={`${inputCls} cursor-pointer`}
      value={value}
      disabled={disabled}
      onChange={(e) => onChange(e.target.value)}
    >
      {options.map((o) => (
        <option key={o.value} value={o.value} className="bg-panel">
          {o.label}
        </option>
      ))}
    </select>
  )
}

export function ToggleRow({
  label,
  checked,
  onChange,
  disabled,
}: {
  label: string
  checked: boolean
  onChange: (v: boolean) => void
  disabled?: boolean
}) {
  return (
    <div className="flex items-center justify-between rounded-sm border border-border bg-input px-3 py-2">
      <span className="font-sans text-[13px] text-text-secondary">{label}</span>
      <Switch checked={checked} onChange={onChange} disabled={disabled} />
    </div>
  )
}

export function Section({
  title,
  children,
  disabled,
  hint,
}: {
  title: string
  children: ReactNode
  disabled?: boolean
  hint?: string
}) {
  return (
    <div
      className={`flex flex-col gap-3 rounded-sm border border-border bg-panel-raised p-4 ${
        disabled ? 'pointer-events-none opacity-50' : ''
      }`}
    >
      <div className="flex items-center justify-between gap-2">
        <h3 className="msk-label text-[11px] font-bold text-accent">{title}</h3>
        {disabled && hint && (
          <span className="font-sans text-[10px] normal-case text-text-muted">{hint}</span>
        )}
      </div>
      {children}
    </div>
  )
}

export function Modal({
  title,
  onClose,
  children,
  footer,
}: {
  title: string
  onClose: () => void
  children: ReactNode
  footer?: ReactNode
}) {
  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/60 animate-fade-in">
      <div className="msk-panel flex max-h-[90vh] w-[840px] max-w-[94vw] flex-col animate-scale-in">
        <div className="flex items-center justify-between border-b border-border px-5 py-4">
          <h2 className="font-display text-[16px] font-semibold text-text-primary">{title}</h2>
          <button
            onClick={onClose}
            className="flex h-8 w-8 items-center justify-center rounded-sm text-text-muted transition-colors hover:bg-input hover:text-text-primary"
            aria-label="Close"
          >
            <X size={18} />
          </button>
        </div>
        <div className="msk-scroll flex-1 overflow-y-auto p-5">{children}</div>
        {footer && (
          <div className="flex justify-end gap-2 border-t border-border px-5 py-4">{footer}</div>
        )}
      </div>
    </div>
  )
}

// Inline status message rendered next to an action button (colored text, not an
// overlay) so it can't be missed and never covers the button.
export function StatusText({ toast }: { toast: { msg: string; ok: boolean } | null }) {
  if (!toast) return null
  return (
    <span
      className={`flex items-center gap-2 font-sans text-[12px] animate-fade-in ${
        toast.ok ? 'text-accent' : 'text-red-400'
      }`}
    >
      <span className={`h-1.5 w-1.5 shrink-0 rounded-full ${toast.ok ? 'bg-accent' : 'bg-red-400'}`} />
      {toast.msg}
    </span>
  )
}

// In-UI confirmation dialog. NEVER use window.confirm/alert/prompt in FiveM NUI —
// CEF doesn't render them and the renderer thread freezes permanently.
export function ConfirmDialog({
  title,
  message,
  confirmLabel,
  cancelLabel,
  onConfirm,
  onCancel,
}: {
  title: string
  message: string
  confirmLabel: string
  cancelLabel: string
  onConfirm: () => void
  onCancel: () => void
}) {
  return (
    <div className="fixed inset-0 z-[70] flex items-center justify-center bg-black/60 animate-fade-in">
      <div className="msk-panel w-[440px] max-w-[92vw] p-5 animate-scale-in">
        <h3 className="mb-2 font-display text-[15px] font-semibold text-text-primary">{title}</h3>
        <p className="mb-5 whitespace-pre-line font-sans text-[13px] text-text-secondary">{message}</p>
        <div className="flex justify-end gap-2">
          <Btn variant="ghost" onClick={onCancel}>{cancelLabel}</Btn>
          <Btn variant="danger" onClick={onConfirm}>{confirmLabel}</Btn>
        </div>
      </div>
    </div>
  )
}

// A single world coordinate with a "use my position" capture button. Stations
// have one zone center, so there is no list to manage here.
export function CoordInput({
  label,
  useLabel,
  value,
  onChange,
}: {
  label: string
  useLabel: string
  value: Coord
  onChange: (next: Coord) => void
}) {
  const update = (key: keyof Coord, v: number) => onChange({ ...value, [key]: v })

  const capture = async () => {
    const c = await fetchNui<Coord>('admin:getCurrentCoords')
    if (c) onChange({ ...c, w: value.w })
  }

  return (
    <div className="flex flex-col gap-1.5">
      <span className="msk-label text-[10px] font-bold">{label}</span>
      <div className="flex items-center gap-2">
        {(['x', 'y', 'z'] as const).map((k) => (
          <input
            key={k}
            type="number"
            step={0.01}
            value={Number.isFinite(value[k]) ? value[k] : 0}
            onChange={(e) => update(k, e.target.value === '' ? 0 : Number(e.target.value))}
            className="w-full rounded-sm border border-border bg-input px-2 py-1.5 font-mono text-[12px] text-text-primary outline-none focus:border-border-accent"
          />
        ))}
        <button
          type="button"
          onClick={capture}
          title={useLabel}
          className="shrink-0 rounded-sm border border-border-accent p-1.5 text-accent hover:bg-accent/10"
        >
          <Crosshair size={14} />
        </button>
      </div>
    </div>
  )
}

export function Chip({
  children,
  active,
  onClick,
}: {
  children: ReactNode
  active?: boolean
  onClick?: () => void
}) {
  return (
    <button
      type="button"
      onClick={onClick}
      className={`rounded-sm border px-2.5 py-1 font-mono text-[11px] uppercase tracking-[0.06em] transition-colors ${
        active
          ? 'border-border-accent bg-accent/15 text-accent'
          : 'border-border bg-input text-text-secondary hover:text-text-primary'
      }`}
    >
      {children}
    </button>
  )
}
