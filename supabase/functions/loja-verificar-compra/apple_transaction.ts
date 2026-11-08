import { APPLE_BUNDLE_ID } from './store_plan_catalog.ts'
import { signEs256Jwt } from './jwt_sign.ts'

export type AppleVerifyResult =
  | { ok: true; productId: string; transactionId: string }
  | { ok: false; reason: string }

export type AppleVerifyDeps = {
  fetch: (input: RequestInfo | URL, init?: RequestInit) => Promise<Response>
  issuerId: string
  keyId: string
  privateKeyPem: string
  bundleId?: string
  now: () => Date
}

export function decodeJwsPayload(jws: string): Record<string, unknown> {
  const payload = jws.split('.')[1]
  if (!payload) throw new Error('jws sem payload')
  const padded = payload.replaceAll('-', '+').replaceAll('_', '/')
    .padEnd(Math.ceil(payload.length / 4) * 4, '=')
  return JSON.parse(atob(padded))
}

export async function verifyApplePurchase(
  deps: AppleVerifyDeps,
  input: { productId: string; transactionId: string; userId: string },
): Promise<AppleVerifyResult> {
  if (!deps.issuerId || !deps.keyId || !deps.privateKeyPem) {
    return { ok: false, reason: 'apple_not_configured' }
  }

  const bundleId = deps.bundleId || APPLE_BUNDLE_ID
  const nowSec = Math.floor(deps.now().getTime() / 1000)
  const token = await signEs256Jwt(deps.privateKeyPem, deps.keyId, {
    iss: deps.issuerId,
    iat: nowSec,
    exp: nowSec + 1200,
    aud: 'appstoreconnect-v1',
    bid: bundleId,
  })

  const hosts = [
    'https://api.storekit.itunes.apple.com',
    'https://api.storekit-sandbox.itunes.apple.com',
  ]
  let response: Response | null = null
  for (const host of hosts) {
    response = await deps.fetch(
      `${host}/inApps/v1/transactions/${encodeURIComponent(input.transactionId)}`,
      { headers: { Authorization: `Bearer ${token}` } },
    )
    if (response.ok || response.status !== 404) break
  }
  if (!response || !response.ok) {
    return { ok: false, reason: 'apple_http_error' }
  }

  const body = await response.json()
  const claims = decodeJwsPayload(String(body.signedTransactionInfo ?? ''))
  if (claims.bundleId !== bundleId) return { ok: false, reason: 'bundle_mismatch' }
  if (claims.productId !== input.productId) return { ok: false, reason: 'product_mismatch' }
  if (String(claims.transactionId ?? '') !== input.transactionId) {
    return { ok: false, reason: 'transaction_mismatch' }
  }
  if (claims.revocationDate != null) return { ok: false, reason: 'revoked' }
  const account = String(claims.appAccountToken ?? '').toLowerCase()
  if (!account || account !== input.userId.toLowerCase()) {
    return { ok: false, reason: 'account_mismatch' }
  }
  return { ok: true, productId: input.productId, transactionId: input.transactionId }
}
