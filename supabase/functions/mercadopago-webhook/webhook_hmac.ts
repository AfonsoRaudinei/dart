export type WebhookHmacResult = 'skip' | 'invalid' | 'valid'

export async function verifyMercadoPagoWebhookSignature(input: {
  secret: string | undefined
  xSignature: string
  xRequestId: string
  notificationPaymentId: string
}): Promise<WebhookHmacResult> {
  const { secret, xSignature, xRequestId, notificationPaymentId } = input
  if (!secret) {
    return 'skip'
  }

  const parts = Object.fromEntries(
    xSignature.split(',').map((p) => p.split('=')),
  )
  const ts = parts['ts']
  const v1 = parts['v1']

  const manifest =
    `id:${notificationPaymentId};request-id:${xRequestId};ts:${ts};`

  const encoder = new TextEncoder()
  const key = await crypto.subtle.importKey(
    'raw',
    encoder.encode(secret),
    { name: 'HMAC', hash: 'SHA-256' },
    false,
    ['sign'],
  )
  const signatureBuffer = await crypto.subtle.sign(
    'HMAC',
    key,
    encoder.encode(manifest),
  )
  const expectedSignature = Array.from(new Uint8Array(signatureBuffer))
    .map((b) => b.toString(16).padStart(2, '0'))
    .join('')

  if (expectedSignature !== v1 && v1) {
    return 'invalid'
  }
  return 'valid'
}
