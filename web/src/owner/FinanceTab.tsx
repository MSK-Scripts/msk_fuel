import { useState } from 'react'
import { ArrowDownLeft, ArrowUpRight } from 'lucide-react'
import { Btn, Field, NumInput, Section } from '../admin/ui'
import type { OwnerTabProps } from './OwnerApp'
import type { TranslationKey } from '../lib/i18n'

const money = (n: number) => `$${Math.round(n).toLocaleString('en-US')}`

/** Transaction types have their own labels; an unknown one falls back to its raw code. */
const txLabel = (t: (k: TranslationKey) => string, type: string) => {
  const key = `tx_${type}` as TranslationKey
  const text = t(key)

  return text === key ? type : text
}

export default function FinanceTab({ boot, t, can, call }: OwnerTabProps) {
  const [amount, setAmount] = useState(0)

  const mayDeposit = can('deposit')
  const mayWithdraw = can('withdraw')
  const valid = amount > 0

  return (
    <div className="flex flex-col gap-4">
      <Section title={t('finance_balance')}>
        <span className="font-display text-[28px] font-bold text-accent">
          {money(boot.station.balance)}
        </span>

        <div className="flex items-end gap-3">
          <div className="flex-1">
            <Field label={t('finance_amount')}>
              <NumInput value={amount} step={100} onChange={setAmount} />
            </Field>
          </div>

          <Btn
            variant="accent"
            disabled={!valid || !mayDeposit}
            onClick={() => call('owner:deposit', { amount })}
          >
            <ArrowDownLeft size={13} /> {t('finance_deposit')}
          </Btn>

          <Btn
            disabled={!valid || !mayWithdraw || amount > boot.station.balance}
            onClick={() => call('owner:withdraw', { amount })}
          >
            <ArrowUpRight size={13} /> {t('finance_withdraw')}
          </Btn>
        </div>
      </Section>

      <Section title={t('finance_history')}>
        {boot.transactions.length === 0 ? (
          <p className="font-sans text-[12px] text-text-muted">{t('finance_history_empty')}</p>
        ) : (
          <div className="flex flex-col gap-1">
            {boot.transactions.map((tx, i) => (
              <div
                key={`${tx.at}-${i}`}
                className="flex items-center justify-between gap-3 rounded-sm border border-border bg-input px-3 py-2"
              >
                <span className="min-w-0">
                  <span className="block truncate font-sans text-[12px] text-text-primary">
                    {txLabel(t, tx.type)}
                  </span>
                  <span className="msk-label block text-[10px]">{tx.at}</span>
                </span>

                <span className="flex shrink-0 items-center gap-3">
                  {tx.liters > 0 && (
                    <span className="font-mono text-[11px] text-text-muted">
                      {Math.round(tx.liters).toLocaleString('en-US')} L
                    </span>
                  )}

                  <span
                    className={`font-mono text-[12px] ${tx.amount < 0 ? 'text-red-400' : 'text-accent'}`}
                  >
                    {tx.amount < 0 ? '-' : '+'}
                    {money(Math.abs(tx.amount))}
                  </span>
                </span>
              </div>
            ))}
          </div>
        )}
      </Section>
    </div>
  )
}
