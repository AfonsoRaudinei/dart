import { assertEquals } from 'https://deno.land/std@0.168.0/testing/asserts.ts'
import { verifyMercadoPagoWebhookSignature } from './webhook_hmac.ts'
import { hmacV1ForManifest } from './webhook_test_utils.ts'

Deno.test('HMAC — secret ausente → skip (fluxo segue sem validar)', async () => {
  const result = await verifyMercadoPagoWebhookSignature({
    secret: undefined,
    xSignature: 'ts=1,v1=deadbeef',
    xRequestId: 'req-1',
    notificationPaymentId: '123',
  })
  assertEquals(result, 'skip')
})

Deno.test('HMAC — assinatura inválida → invalid', async () => {
  const result = await verifyMercadoPagoWebhookSignature({
    secret: 'test-webhook-secret',
    xSignature: 'ts=1700000000,v1=0000000000000000000000000000000000000000000000000000000000000000',
    xRequestId: 'req-2',
    notificationPaymentId: '456',
  })
  assertEquals(result, 'invalid')
})

Deno.test('HMAC — assinatura válida → valid', async () => {
  const secret = 'test-webhook-secret'
  const notificationPaymentId = '789'
  const xRequestId = 'req-3'
  const ts = '1700000001'
  const manifest = `id:${notificationPaymentId};request-id:${xRequestId};ts:${ts};`
  const v1 = await hmacV1ForManifest(secret, manifest)

  const result = await verifyMercadoPagoWebhookSignature({
    secret,
    xSignature: `ts=${ts},v1=${v1}`,
    xRequestId,
    notificationPaymentId,
  })
  assertEquals(result, 'valid')
})

Deno.test('HMAC — v1 vazio com secret configurado → valid (comportamento atual)', async () => {
  const result = await verifyMercadoPagoWebhookSignature({
    secret: 'test-webhook-secret',
    xSignature: 'ts=1700000002,v1=',
    xRequestId: 'req-4',
    notificationPaymentId: '999',
  })
  assertEquals(result, 'valid')
})
