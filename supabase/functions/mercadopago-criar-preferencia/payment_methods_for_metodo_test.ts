import {
  assertEquals,
  assert,
} from 'https://deno.land/std@0.168.0/testing/asserts.ts'
import {
  paymentMethodsForMetodo,
  resolveMetodoPagamento,
} from './payment_methods_for_metodo.ts'

Deno.test('resolveMetodoPagamento — ausente → todos', () => {
  assertEquals(resolveMetodoPagamento(undefined), { metodo: 'todos' })
  assertEquals(resolveMetodoPagamento(null), { metodo: 'todos' })
  assertEquals(resolveMetodoPagamento(''), { metodo: 'todos' })
})

Deno.test('resolveMetodoPagamento — pix e cartao normalizados', () => {
  assertEquals(resolveMetodoPagamento('pix'), { metodo: 'pix' })
  assertEquals(resolveMetodoPagamento(' cartao '), { metodo: 'cartao' })
})

Deno.test('resolveMetodoPagamento — inválido retorna erro explícito', () => {
  const result = resolveMetodoPagamento('bitcoin')
  assert('error' in result)
  assertEquals(result.error, 'Método de pagamento inválido. Use pix ou cartao.')
})

Deno.test('paymentMethodsForMetodo — pix restringe a PIX', () => {
  const pm = paymentMethodsForMetodo('pix')!
  assertEquals(pm.default_payment_method_id, 'pix')
  const types = pm.excluded_payment_types as Array<{ id: string }>
  assert(types.some((t) => t.id === 'credit_card'))
})

Deno.test('paymentMethodsForMetodo — cartao exclui pix', () => {
  const pm = paymentMethodsForMetodo('cartao')!
  const methods = pm.excluded_payment_methods as Array<{ id: string }>
  assert(methods.some((m) => m.id === 'pix'))
})

Deno.test('paymentMethodsForMetodo — todos não envia restrição', () => {
  assertEquals(paymentMethodsForMetodo('todos'), undefined)
})
