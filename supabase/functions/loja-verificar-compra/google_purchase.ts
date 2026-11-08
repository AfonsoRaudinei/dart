import { ANDROID_PACKAGE } from './store_plan_catalog.ts'
import { signRs256Jwt } from './jwt_sign.ts'

export type GoogleVerifyResult =
  | { ok: true; productId: string; orderId: string }
  | { ok: false; reason: string }

export type GoogleServiceAccount = {
  client_email: string
  private_key: string
}

export type GoogleVerifyDeps = {
  fetch: (input: RequestInfo | URL, init?: RequestInit) => Promise<Response>
  serviceAccount: GoogleServiceAccount | null
  packageName?: string
  now: () => Date
}

export async function verifyGooglePurchase(
  deps: GoogleVerifyDeps,
  input: { productId: string; purchaseToken: string },
): Promise<GoogleVerifyResult> {
  if (!deps.serviceAccount?.client_email || !deps.serviceAccount.private_key) {
    return { ok: false, reason: 'google_not_configured' }
  }
  if (!input.purchaseToken) return { ok: false, reason: 'invalid_body' }

  const packageName = deps.packageName || ANDROID_PACKAGE
  const nowSec = Math.floor(deps.now().getTime() / 1000)
  const assertion = await signRs256Jwt(deps.serviceAccount.private_key, {
    iss: deps.serviceAccount.client_email,
    scope: 'https://www.googleapis.com/auth/androidpublisher',
    aud: 'https://oauth2.googleapis.com/token',
    iat: nowSec,
    exp: nowSec + 3600,
  })

  const tokenResponse = await deps.fetch('https://oauth2.googleapis.com/token', {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams({
      grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer',
      assertion,
    }),
  })
  if (!tokenResponse.ok) return { ok: false, reason: 'google_http_error' }
  const tokenBody = await tokenResponse.json()
  const accessToken = tokenBody.access_token as string | undefined
  if (!accessToken) return { ok: false, reason: 'google_http_error' }

  const url =
    `https://androidpublisher.googleapis.com/androidpublisher/v3/applications/${packageName}` +
    `/purchases/products/${encodeURIComponent(input.productId)}/tokens/${encodeURIComponent(input.purchaseToken)}`
  const purchaseResponse = await deps.fetch(url, {
    headers: { Authorization: `Bearer ${accessToken}` },
  })
  if (!purchaseResponse.ok) return { ok: false, reason: 'google_http_error' }
  const purchase = await purchaseResponse.json()
  if (purchase.purchaseState !== 0) return { ok: false, reason: 'not_purchased' }
  const orderId = String(purchase.orderId ?? '')
  if (!orderId) return { ok: false, reason: 'transaction_mismatch' }
  return { ok: true, productId: input.productId, orderId }
}
