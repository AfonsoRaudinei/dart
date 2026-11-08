import { addMonths } from './store_plan_catalog.ts'

export type PendingReferral = { id: string; referrerId: string }

export type ReferralStore = {
  findPending(userId: string, nowIso: string): Promise<PendingReferral | null>
  markValidated(id: string, nowIso: string): Promise<void>
  readCount(referrerId: string): Promise<number | null>
  writeCount(referrerId: string, count: number): Promise<void>
  activePlan(referrerId: string): Promise<{ plano: string } | null>
  upgrade(referrerId: string, plano: 'prata' | 'ouro', expiraEmIso: string): Promise<void>
  resetCount(referrerId: string): Promise<void>
}

export async function applyStoreReferral(
  store: ReferralStore,
  input: { userId: string; now: Date },
): Promise<void> {
  const nowIso = input.now.toISOString()
  const pending = await store.findPending(input.userId, nowIso)
  if (!pending) return

  await store.markValidated(pending.id, nowIso)
  const current = await store.readCount(pending.referrerId)
  if (current == null) return
  const novaContagem = current + 1
  await store.writeCount(pending.referrerId, novaContagem)

  const plan = await store.activePlan(pending.referrerId)
  if (!plan) return

  if (plan.plano === 'bronze' && novaContagem >= 5) {
    await store.upgrade(pending.referrerId, 'prata', addMonths(input.now, 6).toISOString())
    await store.resetCount(pending.referrerId)
  } else if (plan.plano === 'prata' && novaContagem >= 10) {
    await store.upgrade(pending.referrerId, 'ouro', addMonths(input.now, 12).toISOString())
    await store.resetCount(pending.referrerId)
  }
}
