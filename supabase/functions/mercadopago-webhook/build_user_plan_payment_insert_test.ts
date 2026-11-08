import { assertEquals } from 'https://deno.land/std@0.168.0/testing/asserts.ts'
import {
  buildPagamentoPlanInsertRow,
  resolveMercadoPagoPaymentId,
} from './build_user_plan_payment_insert.ts'

Deno.test('resolveMercadoPagoPaymentId — prefere paymentInfo.id', () => {
  assertEquals(resolveMercadoPagoPaymentId(999001, '888'), '999001')
})

Deno.test('resolveMercadoPagoPaymentId — fallback notificação', () => {
  assertEquals(resolveMercadoPagoPaymentId(null, 777002), '777002')
})

Deno.test('buildPagamentoPlanInsertRow — inclui payment_id e origem pagamento', () => {
  const row = buildPagamentoPlanInsertRow({
    userId: 'user-uuid',
    planoId: 'bronze',
    expiraEmIso: '2026-12-01T00:00:00.000Z',
    paymentId: '12345678',
  })
  assertEquals(row.payment_id, '12345678')
  assertEquals(row.origem, 'pagamento')
  assertEquals(row.plano, 'bronze')
  assertEquals(row.user_id, 'user-uuid')
  assertEquals(row.ativo, true)
})
