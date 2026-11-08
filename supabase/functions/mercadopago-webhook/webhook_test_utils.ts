import type { PagamentoPlanInsertRow } from './build_user_plan_payment_insert.ts'
import type { UserPlansWriter } from './webhook_process_payment.ts'

export function createRecordingUserPlansWriter(): UserPlansWriter & {
  inserts: PagamentoPlanInsertRow[]
  deactivateCalls: string[]
} {
  const inserts: PagamentoPlanInsertRow[] = []
  const deactivateCalls: string[] = []

  return {
    inserts,
    deactivateCalls,
    async deactivateActivePlans(userId: string) {
      deactivateCalls.push(userId)
    },
    async insertPlan(row: PagamentoPlanInsertRow) {
      inserts.push(row)
      return { error: null }
    },
  }
}

export async function hmacV1ForManifest(
  secret: string,
  manifest: string,
): Promise<string> {
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
  return Array.from(new Uint8Array(signatureBuffer))
    .map((b) => b.toString(16).padStart(2, '0'))
    .join('')
}
