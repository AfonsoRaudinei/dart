export type MetodoPagamento = 'pix' | 'cartao' | 'todos'

export type MetodoResolveResult =
  | { metodo: MetodoPagamento }
  | { error: string }

const VALID_METODOS = new Set<MetodoPagamento>(['pix', 'cartao'])

export function resolveMetodoPagamento(raw: unknown): MetodoResolveResult {
  if (raw === undefined || raw === null) {
    return { metodo: 'todos' }
  }

  const normalized = String(raw).toLowerCase().trim()
  if (normalized === '') {
    return { metodo: 'todos' }
  }

  if (!VALID_METODOS.has(normalized as MetodoPagamento)) {
    return { error: 'Método de pagamento inválido. Use pix ou cartao.' }
  }

  return { metodo: normalized as MetodoPagamento }
}

/** Fragmento `payment_methods` da preference MP; `todos` → sem restrição (undefined). */
export function paymentMethodsForMetodo(
  metodo: MetodoPagamento,
): Record<string, unknown> | undefined {
  switch (metodo) {
    case 'pix':
      return {
        excluded_payment_types: [
          { id: 'credit_card' },
          { id: 'debit_card' },
          { id: 'ticket' },
          { id: 'atm' },
        ],
        default_payment_method_id: 'pix',
      }
    case 'cartao':
      return {
        excluded_payment_methods: [{ id: 'pix' }],
        excluded_payment_types: [
          { id: 'ticket' },
          { id: 'atm' },
        ],
      }
    case 'todos':
      return undefined
  }
}
