export const APPLE_BUNDLE_ID = 'com.soloforte.soloforteApp'
export const ANDROID_PACKAGE = 'com.soloforte.app'

export const STORE_PLAN_CATALOG = {
  soloforte_plano_bronze: { plano: 'bronze', months: 3 },
  soloforte_plano_prata: { plano: 'prata', months: 6 },
  soloforte_plano_ouro: { plano: 'ouro', months: 12 },
} as const

export type StoreProductId = keyof typeof STORE_PLAN_CATALOG

export function storePlanForProduct(productId: string) {
  if (productId in STORE_PLAN_CATALOG) {
    return STORE_PLAN_CATALOG[productId as StoreProductId]
  }
  return null
}

export function addMonths(from: Date, months: number): Date {
  const next = new Date(from.getTime())
  next.setUTCMonth(next.getUTCMonth() + months)
  return next
}
