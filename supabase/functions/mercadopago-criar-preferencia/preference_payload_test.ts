import { assertEquals } from 'https://deno.land/std@0.168.0/testing/asserts.ts'
import {
  PLANOS_CATALOG,
  buildMercadoPagoPreferencePayload,
} from './preference_payload.ts'

const SUPABASE_URL = 'https://example.supabase.co'
const USER_ID = '550e8400-e29b-41d4-a716-446655440000'

Deno.test('preference — unit_price por plano bronze/prata/ouro', () => {
  for (const [plano, data] of Object.entries(PLANOS_CATALOG)) {
    const payload = buildMercadoPagoPreferencePayload({
      userId: USER_ID,
      plano: plano as keyof typeof PLANOS_CATALOG,
      metodoAplicado: 'todos',
      supabaseUrl: SUPABASE_URL,
    })
    assertEquals(payload.items[0].unit_price, data.price)
    assertEquals(payload.external_reference, `${USER_ID}:${plano}`)
  }
})

Deno.test('preference — notification_url e back_urls', () => {
  const payload = buildMercadoPagoPreferencePayload({
    userId: USER_ID,
    plano: 'bronze',
    metodoAplicado: 'todos',
    supabaseUrl: SUPABASE_URL,
  })

  assertEquals(
    payload.notification_url,
    `${SUPABASE_URL}/functions/v1/mercadopago-webhook`,
  )
  assertEquals(payload.back_urls.success, 'soloforte://planos/confirmacao')
  assertEquals(payload.back_urls.failure, 'soloforte://planos/pagamento')
  assertEquals(payload.back_urls.pending, 'soloforte://planos/pagamento')
})

Deno.test('preference — metodo pix inclui payment_methods', () => {
  const payload = buildMercadoPagoPreferencePayload({
    userId: USER_ID,
    plano: 'ouro',
    metodoAplicado: 'pix',
    supabaseUrl: SUPABASE_URL,
  })

  const pm = payload.payment_methods as Record<string, unknown>
  assertEquals(pm.default_payment_method_id, 'pix')
})
