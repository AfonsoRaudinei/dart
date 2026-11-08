import {
  paymentMethodsForMetodo,
  type MetodoPagamento,
} from './payment_methods_for_metodo.ts'

export const PLANOS_CATALOG = {
  bronze: { title: 'Plano Bronze SoloForte', price: 49.90, months: 3 },
  prata: { title: 'Plano Prata SoloForte', price: 79.90, months: 5 },
  ouro: { title: 'Plano Ouro SoloForte', price: 119.90, months: 8 },
} as const

export type PlanoKey = keyof typeof PLANOS_CATALOG

export function buildMercadoPagoPreferencePayload(input: {
  userId: string
  plano: PlanoKey
  metodoAplicado: MetodoPagamento
  supabaseUrl: string
}) {
  const planoData = PLANOS_CATALOG[input.plano]
  const payment_methods = paymentMethodsForMetodo(input.metodoAplicado)

  return {
    items: [{
      title: planoData.title,
      quantity: 1,
      currency_id: 'BRL',
      unit_price: planoData.price,
    }],
    ...(payment_methods ? { payment_methods } : {}),
    external_reference: `${input.userId}:${input.plano}`,
    notification_url: `${input.supabaseUrl}/functions/v1/mercadopago-webhook`,
    back_urls: {
      success: 'soloforte://planos/confirmacao',
      failure: 'soloforte://planos/pagamento',
      pending: 'soloforte://planos/pagamento',
    },
    auto_return: 'approved',
  }
}
