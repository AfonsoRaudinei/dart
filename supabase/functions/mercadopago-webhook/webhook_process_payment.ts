import {
  buildPagamentoPlanInsertRow,
  resolveMercadoPagoPaymentId,
  type PagamentoPlanInsertRow,
} from './build_user_plan_payment_insert.ts'

export const PLANOS_DURACAO_MESES = {
  bronze: 3,
  prata: 5,
  ouro: 8,
} as const

export type PaymentWebhookBody = {
  type: string
  data: { id: unknown }
}

export type ProcessPaymentOutcome =
  | { kind: 'ignored'; reason: string }
  | { kind: 'activated'; planRow: PagamentoPlanInsertRow }

export type UserPlansWriter = {
  deactivateActivePlans(userId: string): Promise<void>
  insertPlan(row: PagamentoPlanInsertRow): Promise<{ error: unknown | null }>
}

export type ProcessPaymentDeps = {
  fetch: (input: RequestInfo | URL, init?: RequestInit) => Promise<Response>
  mpAccessToken: string
  now: () => Date
  userPlans: UserPlansWriter
}

export async function processMercadoPagoPaymentWebhook(
  deps: ProcessPaymentDeps,
  body: PaymentWebhookBody,
): Promise<ProcessPaymentOutcome> {
  if (body.type !== 'payment') {
    return { kind: 'ignored', reason: 'not_payment_type' }
  }

  const paymentId = body.data.id
  const mpRes = await deps.fetch(
    `https://api.mercadopago.com/v1/payments/${paymentId}`,
    {
      headers: { Authorization: `Bearer ${deps.mpAccessToken}` },
    },
  )

  if (!mpRes.ok) {
    return { kind: 'ignored', reason: 'mp_fetch_failed' }
  }

  const paymentInfo = await mpRes.json()
  if (paymentInfo.status !== 'approved') {
    return { kind: 'ignored', reason: `status_${paymentInfo.status}` }
  }

  const externalRef = paymentInfo.external_reference as string | undefined
  if (!externalRef || !externalRef.includes(':')) {
    return { kind: 'ignored', reason: 'invalid_external_reference' }
  }

  const [userId, planoId] = externalRef.split(':')
  const duracaoMeses =
    PLANOS_DURACAO_MESES[planoId as keyof typeof PLANOS_DURACAO_MESES]
  if (!duracaoMeses) {
    return { kind: 'ignored', reason: 'unknown_plano' }
  }

  const dataExpiracao = deps.now()
  dataExpiracao.setMonth(dataExpiracao.getMonth() + duracaoMeses)

  await deps.userPlans.deactivateActivePlans(userId)

  const mpPaymentId = resolveMercadoPagoPaymentId(paymentInfo.id, paymentId)
  const planRow = buildPagamentoPlanInsertRow({
    userId,
    planoId,
    expiraEmIso: dataExpiracao.toISOString(),
    paymentId: mpPaymentId,
  })

  const { error: planError } = await deps.userPlans.insertPlan(planRow)
  if (planError) {
    return { kind: 'ignored', reason: 'insert_failed' }
  }

  return { kind: 'activated', planRow }
}
