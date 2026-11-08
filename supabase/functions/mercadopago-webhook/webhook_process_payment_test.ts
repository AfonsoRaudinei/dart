import { assertEquals } from 'https://deno.land/std@0.168.0/testing/asserts.ts'
import {
  mercadoPagoPaymentApiResponse,
  mercadoPagoPaymentNotification,
} from './webhook_notification_fixtures.ts'
import { processMercadoPagoPaymentWebhook } from './webhook_process_payment.ts'
import { createRecordingUserPlansWriter } from './webhook_test_utils.ts'

const USER_ID = '550e8400-e29b-41d4-a716-446655440000'
const MP_PAYMENT_ID = 1234567890

function mockFetchApproved() {
  return async (input: RequestInfo | URL): Promise<Response> => {
    const url = String(input)
    if (!url.includes('api.mercadopago.com/v1/payments/')) {
      throw new Error(`fetch inesperado: ${url}`)
    }
    return new Response(
      JSON.stringify(
        mercadoPagoPaymentApiResponse({
          id: MP_PAYMENT_ID,
          status: 'approved',
          externalReference: `${USER_ID}:prata`,
        }),
      ),
      { status: 200 },
    )
  }
}

function mockFetchRejected() {
  return async (input: RequestInfo | URL): Promise<Response> => {
    const url = String(input)
    if (!url.includes('api.mercadopago.com/v1/payments/')) {
      throw new Error(`fetch inesperado: ${url}`)
    }
    return new Response(
      JSON.stringify(
        mercadoPagoPaymentApiResponse({
          id: MP_PAYMENT_ID,
          status: 'rejected',
          externalReference: `${USER_ID}:bronze`,
        }),
      ),
      { status: 200 },
    )
  }
}

Deno.test('webhook pagamento aprovado → insert user_plans com payment_id', async () => {
  const writer = createRecordingUserPlansWriter()
  const fixedNow = new Date('2026-11-08T15:00:00.000Z')

  const result = await processMercadoPagoPaymentWebhook(
    {
      fetch: mockFetchApproved(),
      mpAccessToken: 'test-token',
      now: () => new Date(fixedNow.getTime()),
      userPlans: writer,
    },
    mercadoPagoPaymentNotification(MP_PAYMENT_ID),
  )

  assertEquals(result.kind, 'activated')
  if (result.kind !== 'activated') return

  assertEquals(writer.deactivateCalls, [USER_ID])
  assertEquals(writer.inserts.length, 1)
  const row = writer.inserts[0]
  assertEquals(row.origem, 'pagamento')
  assertEquals(row.plano, 'prata')
  assertEquals(row.user_id, USER_ID)
  assertEquals(row.payment_id, String(MP_PAYMENT_ID))
  assertEquals(row.ativo, true)
})

Deno.test('webhook pagamento rejeitado → não grava user_plans', async () => {
  const writer = createRecordingUserPlansWriter()

  const result = await processMercadoPagoPaymentWebhook(
    {
      fetch: mockFetchRejected(),
      mpAccessToken: 'test-token',
      now: () => new Date(),
      userPlans: writer,
    },
    mercadoPagoPaymentNotification(MP_PAYMENT_ID),
  )

  assertEquals(result.kind, 'ignored')
  assertEquals(writer.inserts.length, 0)
  assertEquals(writer.deactivateCalls.length, 0)
})

Deno.test('webhook notificação duplicada → segundo insert (sem idempotência hoje)', async () => {
  const writer = createRecordingUserPlansWriter()

  const deps = {
    fetch: mockFetchApproved(),
    mpAccessToken: 'test-token',
    now: () => new Date('2026-11-08T15:00:00.000Z'),
    userPlans: writer,
  }
  const body = mercadoPagoPaymentNotification(MP_PAYMENT_ID)

  await processMercadoPagoPaymentWebhook(deps, body)
  await processMercadoPagoPaymentWebhook(deps, body)

  assertEquals(writer.inserts.length, 2)
  assertEquals(writer.inserts[0].payment_id, writer.inserts[1].payment_id)
})
