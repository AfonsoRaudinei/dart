/** Payload de notificação Mercado Pago (webhook payment). */
export function mercadoPagoPaymentNotification(paymentId: string | number) {
  return {
    action: 'payment.updated',
    api_version: 'v1',
    data: { id: paymentId },
    date_created: '2026-11-08T12:00:00.000-03:00',
    id: 999001,
    live_mode: false,
    type: 'payment',
    user_id: '123456',
  }
}

export function mercadoPagoPaymentApiResponse(input: {
  id: string | number
  status: 'approved' | 'rejected' | 'pending'
  externalReference: string
}) {
  return {
    id: input.id,
    status: input.status,
    external_reference: input.externalReference,
  }
}
