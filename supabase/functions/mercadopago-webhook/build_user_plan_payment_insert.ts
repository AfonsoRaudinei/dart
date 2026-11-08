export type PagamentoPlanInsertRow = {
  user_id: string
  plano: string
  origem: 'pagamento'
  expira_em: string
  ativo: true
  payment_id: string
}

export function resolveMercadoPagoPaymentId(
  paymentInfoId: unknown,
  notificationPaymentId: unknown,
): string {
  const fromInfo = paymentInfoId != null && paymentInfoId !== ''
    ? String(paymentInfoId)
    : ''
  if (fromInfo !== '') return fromInfo
  return String(notificationPaymentId ?? '')
}

export function buildPagamentoPlanInsertRow(input: {
  userId: string
  planoId: string
  expiraEmIso: string
  paymentId: string
}): PagamentoPlanInsertRow {
  return {
    user_id: input.userId,
    plano: input.planoId,
    origem: 'pagamento',
    expira_em: input.expiraEmIso,
    ativo: true,
    payment_id: input.paymentId,
  }
}
