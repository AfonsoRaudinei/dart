import { verifyApplePurchase, type AppleVerifyDeps } from './apple_transaction.ts'
import { applyStoreReferral, type ReferralStore } from './apply_store_referral.ts'
import { grantStorePlan, type GrantStorePlanResult, type StorePlanWriter } from './grant_store_plan.ts'
import { verifyGooglePurchase, type GoogleVerifyDeps } from './google_purchase.ts'

export type StorePurchaseInput = {
  userId: string
  platform: string
  productId: string
  transactionId: string
  verificationData: string
}

export type ProcessStorePurchaseDeps = {
  now: () => Date
  writer: StorePlanWriter
  referrals: ReferralStore
  apple: AppleVerifyDeps
  google: GoogleVerifyDeps
}

export async function processStorePurchase(
  deps: ProcessStorePurchaseDeps,
  input: StorePurchaseInput,
): Promise<GrantStorePlanResult | { kind: 'rejected'; reason: string }> {
  if (!input.userId || !input.productId) {
    return { kind: 'rejected', reason: 'invalid_body' }
  }

  if (input.platform === 'ios') {
    const verified = await verifyApplePurchase(deps.apple, {
      productId: input.productId,
      transactionId: input.transactionId,
      userId: input.userId,
    })
    if (!verified.ok) return { kind: 'rejected', reason: verified.reason }
  } else if (input.platform === 'android') {
    const verified = await verifyGooglePurchase(deps.google, {
      productId: input.productId,
      purchaseToken: input.verificationData,
      userId: input.userId,
    })
    if (!verified.ok) return { kind: 'rejected', reason: verified.reason }
    input = { ...input, transactionId: verified.orderId }
  } else {
    return { kind: 'rejected', reason: 'invalid_body' }
  }

  const granted = await grantStorePlan(deps.writer, {
    userId: input.userId,
    productId: input.productId,
    transactionId: input.transactionId,
    now: deps.now(),
  })
  if (granted.kind === 'granted') {
    try {
      await applyStoreReferral(deps.referrals, { userId: input.userId, now: deps.now() })
    } catch (error) {
      console.error('indicação da compra de loja falhou', error)
    }
  }
  return granted
}
