import { assertEquals } from 'https://deno.land/std@0.168.0/testing/asserts.ts'
import { processStorePurchase } from './process_store_purchase.ts'
import type { AppleVerifyDeps } from './apple_transaction.ts'
import type { GoogleVerifyDeps } from './google_purchase.ts'
import type { ExistingStorePlan, StorePlanInsertRow, StorePlanWriter } from './grant_store_plan.ts'
import type { PendingReferral, ReferralStore } from './apply_store_referral.ts'

const NOW = new Date('2026-11-08T15:00:00.000Z')

function jws(payload: Record<string, unknown>): string {
  const bytes = new TextEncoder().encode(JSON.stringify(payload))
  let binary = ''
  for (const byte of bytes) binary += String.fromCharCode(byte)
  const body = btoa(binary).replaceAll('+', '-').replaceAll('/', '_').replaceAll('=', '')
  return `e30.${body}.sig`
}

function pemFromPkcs8(pkcs8: ArrayBuffer, label: string): string {
  const bytes = new Uint8Array(pkcs8)
  let binary = ''
  for (const byte of bytes) binary += String.fromCharCode(byte)
  const b64 = btoa(binary).match(/.{1,64}/g)?.join('\n') ?? ''
  return `-----BEGIN ${label}-----\n${b64}\n-----END ${label}-----`
}

async function es256Pem(): Promise<string> {
  const key = await crypto.subtle.generateKey({ name: 'ECDSA', namedCurve: 'P-256' }, true, ['sign'])
  const pkcs8 = await crypto.subtle.exportKey('pkcs8', key.privateKey)
  return pemFromPkcs8(pkcs8, 'PRIVATE KEY')
}

async function rs256Pem(): Promise<string> {
  const key = await crypto.subtle.generateKey(
    { name: 'RSASSA-PKCS1-v1_5', modulusLength: 2048, publicExponent: new Uint8Array([1, 0, 1]), hash: 'SHA-256' },
    true,
    ['sign'],
  )
  const pkcs8 = await crypto.subtle.exportKey('pkcs8', key.privateKey)
  return pemFromPkcs8(pkcs8, 'PRIVATE KEY')
}

class MemoryWriter implements StorePlanWriter {
  rows: StorePlanInsertRow[] = []
  deactivated: string[] = []
  failInsert = false

  findByPaymentId(paymentId: string): Promise<ExistingStorePlan | null> {
    const row = this.rows.find((item) => item.payment_id === paymentId)
    return Promise.resolve(row
      ? { plano: row.plano, expira_em: row.expira_em, user_id: row.user_id }
      : null)
  }

  deactivateActivePlans(userId: string): Promise<void> {
    this.deactivated.push(userId)
    return Promise.resolve()
  }

  insertPlan(row: StorePlanInsertRow): Promise<{ error: unknown | null }> {
    if (this.failInsert) return Promise.resolve({ error: 'db' })
    this.rows.push(row)
    return Promise.resolve({ error: null })
  }
}

class MemoryReferrals implements ReferralStore {
  pending: PendingReferral | null = null
  count = 0
  plan: string | null = 'bronze'
  upgraded: { plano: string; expiraEmIso: string } | null = null
  validated = false

  findPending(): Promise<PendingReferral | null> {
    return Promise.resolve(this.pending)
  }

  markValidated(): Promise<void> {
    this.validated = true
    return Promise.resolve()
  }

  readCount(): Promise<number | null> {
    return Promise.resolve(this.count)
  }

  writeCount(_referrerId: string, count: number): Promise<void> {
    this.count = count
    return Promise.resolve()
  }

  activePlan(): Promise<{ plano: string } | null> {
    return Promise.resolve(this.plan ? { plano: this.plan } : null)
  }

  upgrade(_referrerId: string, plano: 'prata' | 'ouro', expiraEmIso: string): Promise<void> {
    this.upgraded = { plano, expiraEmIso }
    this.plan = plano
    return Promise.resolve()
  }

  resetCount(): Promise<void> {
    this.count = 0
    return Promise.resolve()
  }
}

function appleDeps(pem: string, fetchImpl: AppleVerifyDeps['fetch']): AppleVerifyDeps {
  return {
    fetch: fetchImpl,
    issuerId: 'issuer',
    keyId: 'key',
    privateKeyPem: pem,
    now: () => NOW,
  }
}

Deno.test('Apple sem segredo não grava plano', async () => {
  const writer = new MemoryWriter()
  let called = false
  const result = await processStorePurchase({
    now: () => NOW,
    writer,
    referrals: new MemoryReferrals(),
    apple: { fetch: () => { called = true; return Promise.reject(new Error('no')) }, issuerId: '', keyId: '', privateKeyPem: '', now: () => NOW },
    google: { fetch, serviceAccount: null, now: () => NOW },
  }, {
    userId: 'user-1',
    platform: 'ios',
    productId: 'soloforte_plano_bronze',
    transactionId: 'tx-1',
    verificationData: '',
  })
  assertEquals(result.kind, 'rejected')
  if (result.kind === 'rejected') assertEquals(result.reason, 'apple_not_configured')
  assertEquals(called, false)
  assertEquals(writer.rows.length, 0)
})

Deno.test('Apple aprovado grava bronze por 3 meses e não duplica', async () => {
  const pem = await es256Pem()
  const writer = new MemoryWriter()
  const referrals = new MemoryReferrals()
  referrals.pending = { id: 'ref-1', referrerId: 'owner' }
  referrals.count = 4
  const fetchImpl: AppleVerifyDeps['fetch'] = (input) => {
    const url = String(input)
    const payload = jws({
      bundleId: 'com.soloforte.soloforteApp',
      productId: 'soloforte_plano_bronze',
      transactionId: 'tx-1',
      appAccountToken: 'user-1',
    })
    if (url.includes('sandbox')) {
      return Promise.resolve(new Response(JSON.stringify({ signedTransactionInfo: payload }), { status: 200 }))
    }
    return Promise.resolve(new Response('missing', { status: 404 }))
  }
  const deps = {
    now: () => NOW,
    writer,
    referrals,
    apple: appleDeps(pem, fetchImpl),
    google: { fetch, serviceAccount: null, now: () => NOW } satisfies GoogleVerifyDeps,
  }
  const input = {
    userId: 'user-1',
    platform: 'ios',
    productId: 'soloforte_plano_bronze',
    transactionId: 'tx-1',
    verificationData: 'ignored',
  }
  const first = await processStorePurchase(deps, input)
  assertEquals(first.kind, 'granted')
  if (first.kind === 'granted') {
    assertEquals(first.row.plano, 'bronze')
    assertEquals(first.row.payment_id, 'tx-1')
    assertEquals(first.row.expira_em, '2027-02-08T15:00:00.000Z')
  }
  assertEquals(referrals.validated, true)
  assertEquals(referrals.upgraded?.plano, 'prata')
  assertEquals(referrals.upgraded?.expiraEmIso, '2027-05-08T15:00:00.000Z')

  const second = await processStorePurchase(deps, input)
  assertEquals(second.kind, 'already_granted')
  assertEquals(writer.rows.length, 1)
  assertEquals(writer.deactivated.length, 1)
})

Deno.test('Google cancelado não grava; comprado grava o orderId', async () => {
  const pem = await rs256Pem()
  const writer = new MemoryWriter()
  const fetchImpl: GoogleVerifyDeps['fetch'] = (_input, init) => {
    if (init?.method === 'POST') {
      return Promise.resolve(new Response(JSON.stringify({ access_token: 'tok' }), { status: 200 }))
    }
    const url = String(_input)
    const state = url.includes('token-cancelado') ? 1 : 0
    return Promise.resolve(new Response(JSON.stringify({
      purchaseState: state,
      orderId: 'GPA.1',
      obfuscatedExternalAccountId: 'user-1',
    }), { status: 200 }))
  }
  const deps = {
    now: () => NOW,
    writer,
    referrals: new MemoryReferrals(),
    apple: appleDeps(await es256Pem(), () => Promise.resolve(new Response('', { status: 500 }))),
    google: {
      fetch: fetchImpl,
      serviceAccount: { client_email: 'sa@soloforte.iam.gserviceaccount.com', private_key: pem },
      now: () => NOW,
    } satisfies GoogleVerifyDeps,
  }
  const canceled = await processStorePurchase(deps, {
    userId: 'user-1',
    platform: 'android',
    productId: 'soloforte_plano_ouro',
    transactionId: 'local',
    verificationData: 'token-cancelado',
  })
  assertEquals(canceled.kind, 'rejected')
  if (canceled.kind === 'rejected') assertEquals(canceled.reason, 'not_purchased')

  const bought = await processStorePurchase(deps, {
    userId: 'user-1',
    platform: 'android',
    productId: 'soloforte_plano_ouro',
    transactionId: 'local',
    verificationData: 'token-ok',
  })
  assertEquals(bought.kind, 'granted')
  if (bought.kind === 'granted') {
    assertEquals(bought.row.plano, 'ouro')
    assertEquals(bought.row.payment_id, 'GPA.1')
    assertEquals(bought.row.expira_em, '2027-11-08T15:00:00.000Z')
  }
})

Deno.test('recibo de outra conta não concede o plano', async () => {
  const writer = new MemoryWriter()
  writer.rows.push({
    user_id: 'outra-conta',
    plano: 'bronze',
    origem: 'pagamento',
    expira_em: '2027-02-08T15:00:00.000Z',
    ativo: true,
    payment_id: 'tx-1',
  })
  const pem = await es256Pem()
  const fetchImpl: AppleVerifyDeps['fetch'] = () => Promise.resolve(new Response(JSON.stringify({
    signedTransactionInfo: jws({
      bundleId: 'com.soloforte.soloforteApp',
      productId: 'soloforte_plano_bronze',
      transactionId: 'tx-1',
      appAccountToken: 'user-1',
    }),
  }), { status: 200 }))
  const result = await processStorePurchase({
    now: () => NOW,
    writer,
    referrals: new MemoryReferrals(),
    apple: appleDeps(pem, fetchImpl),
    google: { fetch, serviceAccount: null, now: () => NOW },
  }, {
    userId: 'user-1',
    platform: 'ios',
    productId: 'soloforte_plano_bronze',
    transactionId: 'tx-1',
    verificationData: '',
  })
  assertEquals(result.kind, 'other_account')
  assertEquals(writer.rows.length, 1)
  assertEquals(writer.deactivated.length, 0)
})
