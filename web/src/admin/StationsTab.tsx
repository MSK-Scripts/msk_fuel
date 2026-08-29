import { useMemo, useState } from 'react'
import { ChevronDown, ChevronRight, MapPin, Pencil, Plus, Trash2, UserMinus } from 'lucide-react'
import {
  Btn,
  Chip,
  ConfirmDialog,
  CoordInput,
  Field,
  Modal,
  NumInput,
  Section,
  Select,
  TextInput,
  ToggleRow,
} from './ui'
import type { TabProps } from './AdminApp'
import type { Coord, Station, StockRow } from './types'
import type { TranslationKey } from '../lib/i18n'

const emptyStation = (defaultPrice: number): Station => ({
  id: '',
  label: '',
  coords: { x: 0, y: 0, z: 0 },
  radius: 60,
  blip: true,
  fuelTypes: ['gas', 'diesel', 'kerosin'],
  purchasable: true,
  purchasePrice: defaultPrice,
  balance: 0,
  stock: [],
})

const fuelLabel = (t: (k: TranslationKey) => string, fuelType: string) =>
  t(`fuel_${fuelType}` as TranslationKey)

const money = (n: number) => `$${Math.round(n).toLocaleString('en-US')}`

export default function StationsTab({ boot, t, can, call }: TabProps) {
  const [editing, setEditing] = useState<Station | null>(null)
  const [isNew, setIsNew] = useState(false)
  const [expanded, setExpanded] = useState<string | null>(null)
  const [confirm, setConfirm] = useState<{ station: Station; kind: 'delete' | 'clearOwner' } | null>(null)

  const stations = boot.stations
  const defaultPrice = useMemo(
    () => stations[0]?.purchasePrice ?? 250000,
    [stations],
  )

  const openNew = () => {
    setEditing(emptyStation(defaultPrice))
    setIsNew(true)
  }

  const openEdit = (station: Station) => {
    setEditing({ ...station })
    setIsNew(false)
  }

  const save = async () => {
    if (!editing) return

    const ok = await call('admin:station:save', { station: editing })
    if (ok) setEditing(null)
  }

  const runConfirm = async () => {
    if (!confirm) return

    const endpoint = confirm.kind === 'delete' ? 'admin:station:delete' : 'admin:station:clearOwner'
    await call(endpoint, { id: confirm.station.id })
    setConfirm(null)
  }

  return (
    <div className="flex flex-col gap-4">
      <div className="flex items-center justify-between">
        <span className="msk-label text-[10px] font-bold">
          {stations.length} {t('tab_stations')}
        </span>

        {can('station.create') && (
          <Btn variant="accent" onClick={openNew}>
            <Plus size={13} /> {t('station_new')}
          </Btn>
        )}
      </div>

      {stations.length === 0 && (
        <p className="rounded-sm border border-border bg-panel-raised px-4 py-6 text-center font-sans text-[13px] text-text-muted">
          {t('stations_empty')}
        </p>
      )}

      <div className="flex flex-col gap-2">
        {stations.map((station) => (
          <StationCard
            key={station.id}
            station={station}
            expanded={expanded === station.id}
            onToggle={() => setExpanded(expanded === station.id ? null : station.id)}
            onEdit={() => openEdit(station)}
            onDelete={() => setConfirm({ station, kind: 'delete' })}
            onClearOwner={() => setConfirm({ station, kind: 'clearOwner' })}
            t={t}
            can={can}
            call={call}
          />
        ))}
      </div>

      {editing && (
        <StationEditor
          station={editing}
          isNew={isNew}
          fuelTypes={boot.fuelTypes}
          t={t}
          onChange={setEditing}
          onCancel={() => setEditing(null)}
          onSave={save}
        />
      )}

      {confirm && (
        <ConfirmDialog
          title={confirm.station.label || confirm.station.id}
          message={t(confirm.kind === 'delete' ? 'station_delete_confirm' : 'station_clear_owner_confirm')}
          confirmLabel={t(confirm.kind === 'delete' ? 'delete' : 'station_clear_owner')}
          cancelLabel={t('cancel')}
          onConfirm={runConfirm}
          onCancel={() => setConfirm(null)}
        />
      )}
    </div>
  )
}

function StationCard({
  station,
  expanded,
  onToggle,
  onEdit,
  onDelete,
  onClearOwner,
  t,
  can,
  call,
}: {
  station: Station
  expanded: boolean
  onToggle: () => void
  onEdit: () => void
  onDelete: () => void
  onClearOwner: () => void
} & Pick<TabProps, 't' | 'can' | 'call'>) {
  return (
    <div className="rounded-sm border border-border bg-panel-raised">
      <div className="flex items-center gap-3 px-4 py-3">
        <button
          type="button"
          onClick={onToggle}
          className="flex min-w-0 flex-1 items-center gap-3 text-left"
        >
          {expanded ? <ChevronDown size={15} className="shrink-0 text-accent" /> : <ChevronRight size={15} className="shrink-0 text-text-muted" />}

          <span className="min-w-0">
            <span className="block truncate font-display text-[14px] font-semibold text-text-primary">
              {station.label || station.id}
            </span>
            <span className="msk-label block text-[10px]">{station.id}</span>
          </span>
        </button>

        <div className="flex shrink-0 items-center gap-2">
          {station.owner ? (
            <Chip active>{money(station.balance)}</Chip>
          ) : (
            <Chip>{t('station_no_owner')}</Chip>
          )}

          {station.owner && can('station.owner') && (
            <button
              type="button"
              onClick={onClearOwner}
              title={t('station_clear_owner')}
              className="rounded-sm border border-border p-1.5 text-text-muted transition-colors hover:text-red-400"
            >
              <UserMinus size={14} />
            </button>
          )}

          {can('station.edit') && (
            <button
              type="button"
              onClick={onEdit}
              title={t('edit')}
              className="rounded-sm border border-border p-1.5 text-text-muted transition-colors hover:text-text-primary"
            >
              <Pencil size={14} />
            </button>
          )}

          {can('station.delete') && (
            <button
              type="button"
              onClick={onDelete}
              title={t('delete')}
              className="rounded-sm border border-border p-1.5 text-text-muted transition-colors hover:text-red-400"
            >
              <Trash2 size={14} />
            </button>
          )}
        </div>
      </div>

      {expanded && (
        <div className="flex flex-col gap-2 border-t border-border px-4 py-4">
          {station.stock.length === 0 && (
            <p className="font-sans text-[12px] text-text-muted">{t('err_no_tank')}</p>
          )}

          {station.stock.map((row) => (
            <StockRowEditor key={row.fuelType} stationId={station.id} row={row} t={t} can={can} call={call} />
          ))}
        </div>
      )}
    </div>
  )
}

function StockRowEditor({
  stationId,
  row,
  t,
  can,
  call,
}: {
  stationId: string
  row: StockRow
} & Pick<TabProps, 't' | 'can' | 'call'>) {
  const [stock, setStock] = useState(row.stock)
  const [capacity, setCapacity] = useState(row.capacity)
  const [mode, setMode] = useState(row.priceMode)
  const [fixedPrice, setFixedPrice] = useState(row.fixedPrice)

  const fillRatio = capacity > 0 ? Math.min(1, stock / capacity) : 0
  const dirtyStock = stock !== row.stock || capacity !== row.capacity
  const dirtyPrice = mode !== row.priceMode || fixedPrice !== row.fixedPrice

  return (
    <div className="rounded-sm border border-border bg-input px-3 py-3">
      <div className="mb-3 flex items-center justify-between gap-3">
        <span className="font-display text-[13px] font-semibold text-text-primary">
          {fuelLabel(t, row.fuelType)}
        </span>

        <span className={`font-mono text-[12px] ${row.stock > 0 ? 'text-accent' : 'text-red-400'}`}>
          {row.stock > 0 ? `$${row.price.toFixed(2)} / L` : t('stock_sold_out')}
        </span>
      </div>

      <div className="mb-3 h-1.5 w-full overflow-hidden rounded-full bg-white/10">
        <div
          className={`h-full rounded-full ${fillRatio > 0.2 ? 'bg-accent' : 'bg-red-400'}`}
          style={{ width: `${fillRatio * 100}%` }}
        />
      </div>

      <div className="grid grid-cols-2 gap-3 md:grid-cols-4">
        <Field label={t('stock_level')}>
          <NumInput value={stock} onChange={setStock} disabled={!can('stock.manage')} />
        </Field>

        <Field label={t('stock_capacity')}>
          <NumInput value={capacity} onChange={setCapacity} disabled={!can('stock.manage')} />
        </Field>

        <Field label={t('stock_price_mode')}>
          <Select
            value={mode}
            onChange={(v) => setMode(v as StockRow['priceMode'])}
            disabled={!can('market.manage')}
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
            onChange={setFixedPrice}
            disabled={!can('market.manage') || mode !== 'fixed'}
          />
        </Field>
      </div>

      <div className="mt-3 flex flex-wrap items-center gap-2">
        {can('stock.manage') && (
          <>
            <Btn onClick={() => setStock(capacity)}>{t('stock_fill')}</Btn>
            <Btn onClick={() => setStock(0)}>{t('stock_empty')}</Btn>
            <Btn
              variant="accent"
              disabled={!dirtyStock}
              onClick={() => call('admin:stock:set', { id: stationId, fuelType: row.fuelType, stock, capacity })}
            >
              {t('stock_save')}
            </Btn>
          </>
        )}

        {can('market.manage') && (
          <Btn
            variant="accent"
            disabled={!dirtyPrice}
            onClick={() => call('admin:stock:pricing', { id: stationId, fuelType: row.fuelType, mode, fixedPrice })}
          >
            {t('stock_save_price')}
          </Btn>
        )}
      </div>
    </div>
  )
}

function StationEditor({
  station,
  isNew,
  fuelTypes,
  t,
  onChange,
  onCancel,
  onSave,
}: {
  station: Station
  isNew: boolean
  fuelTypes: string[]
  t: (k: TranslationKey) => string
  onChange: (next: Station) => void
  onCancel: () => void
  onSave: () => void
}) {
  const coord: Coord = { x: station.coords?.x ?? 0, y: station.coords?.y ?? 0, z: station.coords?.z ?? 0, w: 0 }

  const patch = (next: Partial<Station>) => onChange({ ...station, ...next })

  const toggleFuelType = (fuelType: string) => {
    const has = station.fuelTypes.includes(fuelType)

    patch({
      fuelTypes: has
        ? station.fuelTypes.filter((f) => f !== fuelType)
        : [...station.fuelTypes, fuelType],
    })
  }

  return (
    <Modal
      title={isNew ? t('station_new') : station.label || station.id}
      onClose={onCancel}
      footer={
        <>
          <Btn variant="ghost" onClick={onCancel}>{t('cancel')}</Btn>
          <Btn variant="accent" onClick={onSave} disabled={!station.id || station.fuelTypes.length === 0}>
            {isNew ? t('create') : t('save')}
          </Btn>
        </>
      }
    >
      <div className="flex flex-col gap-4">
        <Section title={t('station_new')}>
          <div className="grid grid-cols-2 gap-3">
            <Field label={t('station_id')}>
              <TextInput
                value={station.id}
                onChange={(v) => patch({ id: v })}
                disabled={!isNew}
                placeholder="ls_01"
              />
            </Field>

            <Field label={t('station_label')}>
              <TextInput value={station.label} onChange={(v) => patch({ label: v })} />
            </Field>
          </div>

          {isNew && (
            <p className="font-sans text-[11px] text-text-muted">{t('station_id_hint')}</p>
          )}
        </Section>

        <Section title={t('station_coords')}>
          <CoordInput
            label={t('station_coords')}
            useLabel={t('station_use_position')}
            value={coord}
            onChange={(c) => patch({ coords: { x: c.x, y: c.y, z: c.z } })}
          />

          <div className="grid grid-cols-2 gap-3">
            <Field label={t('station_radius')}>
              <NumInput value={station.radius} step={1} onChange={(v) => patch({ radius: v })} />
            </Field>

            <div className="flex items-end">
              <div className="w-full">
                <ToggleRow
                  label={t('station_blip')}
                  checked={station.blip}
                  onChange={(v) => patch({ blip: v })}
                />
              </div>
            </div>
          </div>

          <p className="flex items-center gap-2 font-sans text-[11px] text-text-muted">
            <MapPin size={12} />
            {t('station_coords')}
          </p>
        </Section>

        <Section title={t('station_fuelTypes')}>
          <div className="flex flex-wrap gap-2">
            {fuelTypes.map((fuelType) => (
              <Chip
                key={fuelType}
                active={station.fuelTypes.includes(fuelType)}
                onClick={() => toggleFuelType(fuelType)}
              >
                {fuelLabel(t, fuelType)}
              </Chip>
            ))}
          </div>

          <div className="grid grid-cols-2 gap-3 md:grid-cols-4">
            {station.fuelTypes.map((fuelType) => (
              <Field key={fuelType} label={`${t('station_capacity')} ${fuelLabel(t, fuelType)}`}>
                <NumInput
                  value={station.capacity?.[fuelType as keyof typeof station.capacity] ?? 0}
                  onChange={(v) =>
                    patch({ capacity: { ...(station.capacity ?? {}), [fuelType]: v } })
                  }
                />
              </Field>
            ))}
          </div>
        </Section>

        <Section title={t('station_purchasePrice')}>
          <ToggleRow
            label={t('station_purchasable')}
            checked={station.purchasable}
            onChange={(v) => patch({ purchasable: v })}
          />

          <Field label={t('station_purchasePrice')}>
            <NumInput
              value={station.purchasePrice}
              step={1000}
              onChange={(v) => patch({ purchasePrice: v })}
              disabled={!station.purchasable}
            />
          </Field>
        </Section>
      </div>
    </Modal>
  )
}
