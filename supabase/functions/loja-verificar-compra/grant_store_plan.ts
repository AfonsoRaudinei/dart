import { addMonths, storePlanForProduct } from './store_plan_catalog.ts'

export type StorePlanInsertRow = {
  user_id: string
  plano: string
  origem: 'pagamento'
  expira_em: string
  ativo: true
  payment_id: string
}

export type ExistingStorePlan = {
  plano: string
  expira_em: string
  user_id: string
}

export type StorePlanWriter = {
  findByPaymentId(paymentId: string): Promise<ExistingStorePlan | null>
  deactivateActivePlans(userId: string): Promise<void>
  insertPlan(row: StorePlanInsertRow): Promise<{ error: unknown | null }>
}

export type GrantStorePlanResult =
  | { kind: 'granted'; row: StorePlanInsertRow }
  | { kind: 'already_granted'; existing: ExistingStorePlan }
  | { kind: 'other_account' }
  | { kind: 'rejected'; reason: string }

export async function grantStorePlan(
  writer: StorePlanWriter,
  input: { userId: string; productId: string; transactionId: string; now: Date },
): Promise<GrantStorePlanResult> {
  const plan = storePlanForProduct(input.productId)
  if (!plan || !input.transactionId) {
    return { kind: 'rejected', reason: 'unknown_product' }
  }

  const existing = await writer.findByPaymentId(input.transactionId)
  if (existing) {
    if (existing.user_id !== input.userId) return { kind: 'other_account' }
    return { kind: 'already_granted', existing }
  }

  const expiraEm = addMonths(input.now, plan.months)
  await writer.deactivateActivePlans(input.userId)
  const row: StorePlanInsertRow = {
    user_id: input.userId,
    plano: plan.plano,
    origem: 'pagamento',
    expira_em: expiraEm.toISOString(),
    ativo: true,
    payment_id: input.transactionId,
  }
  const { error } = await writer.insertPlan(row)
  if (error) return { kind: 'rejected', reason: 'insert_failed' }
  return { kind: 'granted', row }
}
