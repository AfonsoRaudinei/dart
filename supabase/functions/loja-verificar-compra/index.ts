import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2"
import { processStorePurchase } from "./process_store_purchase.ts"
import type { GoogleServiceAccount } from "./google_purchase.ts"
import type { StorePlanInsertRow } from "./grant_store_plan.ts"

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
}

function statusForReason(reason: string): number {
  if (reason === "apple_not_configured" || reason === "google_not_configured") return 503
  if (reason === "apple_http_error" || reason === "google_http_error" || reason === "insert_failed") {
    return 502
  }
  return 400
}

function json(body: unknown, status: number) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  })
}

function readServiceAccount(): GoogleServiceAccount | null {
  const raw = Deno.env.get("GOOGLE_PLAY_SERVICE_ACCOUNT_JSON") ?? ""
  if (!raw) return null
  try {
    const parsed = JSON.parse(raw) as GoogleServiceAccount
    if (!parsed.client_email || !parsed.private_key) return null
    return parsed
  } catch {
    return null
  }
}

serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders })
  if (req.method !== "POST") return json({ error: "Método não permitido." }, 405)

  const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? ""
  const anonKey = Deno.env.get("SUPABASE_ANON_KEY") ?? ""
  const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? ""
  const authHeader = req.headers.get("Authorization")
  if (!authHeader) return json({ error: "Authorization header ausente." }, 401)

  const userClient = createClient(supabaseUrl, anonKey)
  const token = authHeader.replace("Bearer ", "")
  const { data: { user }, error: authError } = await userClient.auth.getUser(token)
  if (authError || !user) return json({ error: "Token JWT inválido ou expirado." }, 401)

  const body = await req.json().catch(() => null)
  if (!body || typeof body !== "object") return json({ error: "Corpo inválido." }, 400)

  const admin = createClient(supabaseUrl, serviceKey)
  const result = await processStorePurchase({
    now: () => new Date(),
    writer: {
      async findByPaymentId(paymentId) {
        const { data } = await admin
          .from("user_plans")
          .select("plano, expira_em")
          .eq("payment_id", paymentId)
          .limit(1)
        const row = data?.[0]
        if (!row) return null
        return { plano: String(row.plano), expira_em: String(row.expira_em) }
      },
      async deactivateActivePlans(userId) {
        await admin.from("user_plans").update({ ativo: false }).eq("user_id", userId).eq("ativo", true)
      },
      async insertPlan(row: StorePlanInsertRow) {
        const { error } = await admin.from("user_plans").insert(row)
        return { error }
      },
    },
    referrals: {
      async findPending(userId, nowIso) {
        const { data } = await admin
          .from("referrals")
          .select("id, referrer_id")
          .eq("referred_id", userId)
          .eq("status", "pendente")
          .gt("expira_em", nowIso)
          .limit(1)
        const row = data?.[0]
        if (!row) return null
        return { id: String(row.id), referrerId: String(row.referrer_id) }
      },
      async markValidated(id, nowIso) {
        await admin.from("referrals").update({ status: "validada", validado_em: nowIso }).eq("id", id)
      },
      async readCount(referrerId) {
        const { data } = await admin
          .from("referral_codes")
          .select("indicacoes_validadas")
          .eq("user_id", referrerId)
          .limit(1)
        if (!data?.[0]) return null
        return Number(data[0].indicacoes_validadas)
      },
      async writeCount(referrerId, count) {
        await admin.from("referral_codes").update({ indicacoes_validadas: count }).eq("user_id", referrerId)
      },
      async activePlan(referrerId) {
        const { data } = await admin
          .from("user_plans")
          .select("plano")
          .eq("user_id", referrerId)
          .eq("ativo", true)
          .limit(1)
        if (!data?.[0]) return null
        return { plano: String(data[0].plano) }
      },
      async upgrade(referrerId, plano, expiraEmIso) {
        await admin.from("user_plans").update({ ativo: false }).eq("user_id", referrerId).eq("ativo", true)
        await admin.from("user_plans").insert({
          user_id: referrerId,
          plano,
          origem: "indicacao",
          ativo: true,
          expira_em: expiraEmIso,
        })
      },
      async resetCount(referrerId) {
        await admin.from("referral_codes").update({ indicacoes_validadas: 0 }).eq("user_id", referrerId)
      },
    },
    apple: {
      fetch,
      issuerId: Deno.env.get("APPLE_IAP_ISSUER_ID") ?? "",
      keyId: Deno.env.get("APPLE_IAP_KEY_ID") ?? "",
      privateKeyPem: Deno.env.get("APPLE_IAP_PRIVATE_KEY") ?? "",
      bundleId: Deno.env.get("APPLE_BUNDLE_ID") ?? undefined,
      now: () => new Date(),
    },
    google: {
      fetch,
      serviceAccount: readServiceAccount(),
      packageName: Deno.env.get("GOOGLE_PLAY_PACKAGE_NAME") ?? undefined,
      now: () => new Date(),
    },
  }, {
    userId: user.id,
    platform: String(body.platform ?? ""),
    productId: String(body.productId ?? ""),
    transactionId: String(body.transactionId ?? ""),
    verificationData: String(body.verificationData ?? ""),
  })

  if (result.kind === "rejected") {
    return json({ error: result.reason }, statusForReason(result.reason))
  }
  if (result.kind === "already_granted") {
    return json({
      status: "already_granted",
      plano: result.existing.plano,
      expira_em: result.existing.expira_em,
    }, 200)
  }
  return json({ status: "granted", plano: result.row.plano, expira_em: result.row.expira_em }, 200)
})
