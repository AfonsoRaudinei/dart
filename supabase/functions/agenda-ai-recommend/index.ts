// supabase/functions/agenda-ai-recommend/index.ts
// Runtime: Deno (Edge Function)
// Objetivo Fase 3: endpoint backend para recomendação determinística + explicação IA (OpenRouter)
// @ts-nocheck

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

type GeoPoint = { lat: number; lon: number }

type Opportunity = {
  clientId: string
  clientName: string
  city: string
  location?: GeoPoint | null
  categoryId: string
  categoryProgressPercent: number
  categoryAchievedValue: number
  lastVisitAt?: string | null
}

type Policy = {
  topN: number
  prioritizeSameCity: boolean
  maxDistanceKm: number
  cooldownDays: number
}

type RecommendRequest = {
  consultantId: string
  currentCity?: string | null
  currentLocation?: GeoPoint | null
  targetCategoryId: string
  annualTargetValue: number
  annualAchievedValue: number
  opportunities: Opportunity[]
  policy?: Partial<Policy>
  useAiExplanation?: boolean
  chatMessage?: string
}

type Recommendation = {
  clientId: string
  clientName: string
  city: string
  categoryId: string
  reason: string
}

const DEFAULT_POLICY: Policy = {
  topN: 1,
  prioritizeSameCity: true,
  maxDistanceKm: 50,
  cooldownDays: 7,
}

const FEATURE_KEY = 'agenda_ai_v1'
const MAX_TOP_N = 3
const MAX_OPPORTUNITIES = 300

Deno.serve(async (req: Request) => {
  const requestId = crypto.randomUUID()
  const startedAt = Date.now()

  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  const finish = (
    body: unknown,
    status: number,
    meta: Record<string, unknown> = {},
  ) => {
    logTelemetry({
      requestId,
      status,
      durationMs: Date.now() - startedAt,
      featureKey: FEATURE_KEY,
      ...meta,
    })
    return json(body, status)
  }

  if (req.method !== 'POST') {
    return finish({ error: 'Método não permitido.' }, 405, {
      outcome: 'method_not_allowed',
    })
  }

  try {
    const featureEnabled = envBool('AGENDA_AI_ENABLED', true)
    if (!featureEnabled) {
      return finish(
        {
          recommendations: [],
          ai: { enabled: false, reason: 'Assistente temporariamente desativado.' },
        },
        200,
        { outcome: 'disabled_by_env' },
      )
    }

    const authHeader = req.headers.get('Authorization')
    if (!authHeader?.startsWith('Bearer ')) {
      return finish({ error: 'Não autorizado.' }, 401, {
        outcome: 'unauthorized_missing_bearer',
      })
    }

    const jwt = authHeader.replace('Bearer ', '').trim()

    const supabaseAdmin = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
      { auth: { persistSession: false } },
    )

    const { data: { user }, error: authError } = await supabaseAdmin.auth.getUser(jwt)
    if (authError || !user) {
      return finish({ error: 'Não autorizado.' }, 401, {
        outcome: 'unauthorized_invalid_jwt',
      })
    }

    const body = (await req.json()) as RecommendRequest

    if (!body.consultantId || !body.targetCategoryId) {
      return finish({ error: 'consultantId e targetCategoryId são obrigatórios.' }, 400, {
        outcome: 'invalid_payload',
      })
    }

    // Segurança básica: consultantId precisa bater com usuário autenticado.
    if (body.consultantId !== user.id) {
      return finish({ error: 'consultantId inválido para o token informado.' }, 403, {
        outcome: 'forbidden_consultant_mismatch',
        consultantId: body.consultantId,
        authUserId: user.id,
      })
    }

    const rolloutPercent = envInt('AGENDA_AI_ROLLOUT_PERCENT', 100)
    if (!isUserInRollout(body.consultantId, rolloutPercent)) {
      return finish(
        {
          recommendations: [],
          ai: {
            enabled: false,
            reason: 'Assistente em rollout progressivo para sua conta.',
          },
        },
        200,
        {
          outcome: 'outside_rollout',
          consultantId: body.consultantId,
          rolloutPercent,
        },
      )
    }

    const sanitizedInput = sanitizeRequest(body)

    if (!Array.isArray(sanitizedInput.opportunities) || sanitizedInput.opportunities.length === 0) {
      return finish({ recommendations: [], ai: { enabled: false, reason: 'Sem oportunidades.' } }, 200, {
        outcome: 'no_opportunities',
        consultantId: sanitizedInput.consultantId,
      })
    }

    const policy = sanitizePolicy(sanitizedInput.policy)

    const recommendations = recommendDeterministic(sanitizedInput, policy)

    const useAi = sanitizedInput.useAiExplanation === true
    if (!useAi || recommendations.length === 0) {
      return finish({
        recommendations,
        ai: {
          enabled: false,
          reason: useAi ? 'Sem recomendação elegível para explicar.' : 'Explicação IA desativada.',
        },
      }, 200, {
        outcome: recommendations.length === 0 ? 'no_eligible_recommendation' : 'deterministic_only',
        consultantId: sanitizedInput.consultantId,
        recommendationCount: recommendations.length,
      })
    }

    const aiText = await buildAiExplanation({
      req: sanitizedInput,
      recommendation: recommendations[0],
    })

    if (!aiText) {
      return finish({
        recommendations,
        ai: {
          enabled: false,
          reason: 'OpenRouter indisponível no momento. Recomendação determinística mantida.',
        },
      }, 200, {
        outcome: 'ai_fallback',
        consultantId: sanitizedInput.consultantId,
        recommendationCount: recommendations.length,
      })
    }

    return finish({
      recommendations,
      ai: {
        enabled: true,
        text: aiText,
      },
    }, 200, {
      outcome: 'ai_success',
      consultantId: sanitizedInput.consultantId,
      recommendationCount: recommendations.length,
    })
  } catch (error) {
    console.error('[agenda-ai-recommend] erro:', error)
    logTelemetry({
      requestId,
      status: 500,
      durationMs: Date.now() - startedAt,
      featureKey: FEATURE_KEY,
      outcome: 'internal_error',
      error: String(error),
    })
    return json({ error: 'Erro interno.', requestId }, 500)
  }
})

function recommendDeterministic(input: RecommendRequest, policy: Policy): Recommendation[] {
  const now = new Date()

  const filtered = input.opportunities
    .filter((o) => o.categoryId === input.targetCategoryId)
    .filter((o) => safePercent(o.categoryProgressPercent) < 100)
    .filter((o) => outsideCooldown(o.lastVisitAt, now, policy.cooldownDays))

  if (filtered.length === 0) return []

  const sameCityCandidates = input.currentCity
    ? filtered.filter((o) => normalize(o.city) === normalize(input.currentCity ?? ''))
    : []

  let pool = filtered
  if (policy.prioritizeSameCity && sameCityCandidates.length > 0) {
    pool = sameCityCandidates
  } else if (input.currentLocation) {
    const withinRadius = filtered.filter((o) => {
      if (!o.location) return false
      const km = haversineKm(input.currentLocation as GeoPoint, o.location)
      return km <= policy.maxDistanceKm
    })
    if (withinRadius.length > 0) pool = withinRadius
  }

  pool.sort((a, b) => {
    const p = safePercent(a.categoryProgressPercent) - safePercent(b.categoryProgressPercent)
    if (p !== 0) return p

    const v = safeNumber(a.categoryAchievedValue) - safeNumber(b.categoryAchievedValue)
    if (v !== 0) return v

    const aTs = a.lastVisitAt ? new Date(a.lastVisitAt).getTime() : 0
    const bTs = b.lastVisitAt ? new Date(b.lastVisitAt).getTime() : 0
    return aTs - bTs
  })

  return pool.slice(0, Math.max(1, policy.topN)).map((o) => ({
    clientId: o.clientId,
    clientName: o.clientName,
    city: o.city,
    categoryId: o.categoryId,
    reason: buildReason(input.currentCity ?? null, o),
  }))
}

function buildReason(currentCity: string | null, o: Opportunity): string {
  const pct = safePercent(o.categoryProgressPercent).toFixed(1)
  if (currentCity && normalize(currentCity) === normalize(o.city)) {
    return `Cliente em ${o.city}, com ${pct}% na categoria alvo.`
  }
  return `Melhor oportunidade próxima para avançar a categoria alvo (${pct}%).`
}

function outsideCooldown(lastVisitAt: string | null | undefined, now: Date, cooldownDays: number): boolean {
  if (!lastVisitAt) return true
  const date = new Date(lastVisitAt)
  if (Number.isNaN(date.getTime())) return true
  const diffMs = now.getTime() - date.getTime()
  const requiredMs = cooldownDays * 24 * 60 * 60 * 1000
  return diffMs >= requiredMs
}

function normalize(value: string): string {
  return value.trim().toLowerCase()
}

function safePercent(value: number): number {
  if (!Number.isFinite(value)) return 0
  if (value < 0) return 0
  if (value > 100) return 100
  return value
}

function safeNumber(value: number): number {
  return Number.isFinite(value) ? value : 0
}

function sanitizeRequest(input: RecommendRequest): RecommendRequest {
  const opportunities = (Array.isArray(input.opportunities) ? input.opportunities : [])
    .slice(0, MAX_OPPORTUNITIES)
    .filter((o) => !!o?.clientId && !!o?.categoryId)
    .map((o) => ({
      clientId: String(o.clientId),
      clientName: String(o.clientName ?? 'Cliente'),
      city: String(o.city ?? '').trim(),
      location: sanitizeGeoPoint(o.location),
      categoryId: String(o.categoryId),
      categoryProgressPercent: safePercent(Number(o.categoryProgressPercent ?? 0)),
      categoryAchievedValue: safeNumber(Number(o.categoryAchievedValue ?? 0)),
      lastVisitAt: o.lastVisitAt ?? null,
    }))

  return {
    consultantId: String(input.consultantId),
    currentCity: input.currentCity ? String(input.currentCity).trim() : null,
    currentLocation: sanitizeGeoPoint(input.currentLocation),
    targetCategoryId: String(input.targetCategoryId),
    annualTargetValue: safeNumber(Number(input.annualTargetValue ?? 0)),
    annualAchievedValue: safeNumber(Number(input.annualAchievedValue ?? 0)),
    opportunities,
    policy: input.policy,
    useAiExplanation: input.useAiExplanation === true,
    chatMessage: typeof input.chatMessage === 'string' ? input.chatMessage.trim().slice(0, 400) : undefined,
  }
}

function sanitizePolicy(raw?: Partial<Policy>): Policy {
  const topN = clampInt(Number(raw?.topN ?? DEFAULT_POLICY.topN), 1, MAX_TOP_N)
  const maxDistanceKm = clampInt(Number(raw?.maxDistanceKm ?? DEFAULT_POLICY.maxDistanceKm), 1, 500)
  const cooldownDays = clampInt(Number(raw?.cooldownDays ?? DEFAULT_POLICY.cooldownDays), 0, 90)

  return {
    topN,
    prioritizeSameCity: raw?.prioritizeSameCity !== false,
    maxDistanceKm,
    cooldownDays,
  }
}

function sanitizeGeoPoint(value?: GeoPoint | null): GeoPoint | null {
  if (!value) return null
  const lat = Number(value.lat)
  const lon = Number(value.lon)
  if (!Number.isFinite(lat) || !Number.isFinite(lon)) return null
  if (lat < -90 || lat > 90 || lon < -180 || lon > 180) return null
  return { lat, lon }
}

function clampInt(value: number, min: number, max: number): number {
  if (!Number.isFinite(value)) return min
  const n = Math.trunc(value)
  return Math.min(max, Math.max(min, n))
}

function envBool(name: string, defaultValue: boolean): boolean {
  const raw = (Deno.env.get(name) ?? '').trim().toLowerCase()
  if (!raw) return defaultValue
  return raw === '1' || raw === 'true' || raw === 'yes' || raw === 'on'
}

function envInt(name: string, defaultValue: number): number {
  const raw = (Deno.env.get(name) ?? '').trim()
  if (!raw) return defaultValue
  const parsed = Number(raw)
  if (!Number.isFinite(parsed)) return defaultValue
  return clampInt(parsed, 0, 100)
}

function isUserInRollout(userId: string, rolloutPercentage: number): boolean {
  if (rolloutPercentage >= 100) return true
  if (rolloutPercentage <= 0) return false

  let hash = 0
  for (let i = 0; i < userId.length; i++) {
    hash = (hash * 31 + userId.charCodeAt(i)) | 0
  }
  const bucket = Math.abs(hash) % 100
  return bucket < rolloutPercentage
}

function logTelemetry(payload: Record<string, unknown>): void {
  console.log('[agenda-ai-recommend.telemetry]', JSON.stringify(payload))
}

function haversineKm(a: GeoPoint, b: GeoPoint): number {
  const r = 6371
  const dLat = degToRad(b.lat - a.lat)
  const dLon = degToRad(b.lon - a.lon)
  const lat1 = degToRad(a.lat)
  const lat2 = degToRad(b.lat)

  const h =
    Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos(lat1) * Math.cos(lat2) * Math.sin(dLon / 2) * Math.sin(dLon / 2)

  const c = 2 * Math.atan2(Math.sqrt(h), Math.sqrt(1 - h))
  return r * c
}

function degToRad(value: number): number {
  return (value * Math.PI) / 180
}

async function buildAiExplanation(args: {
  req: RecommendRequest
  recommendation: Recommendation
}): Promise<string | null> {
  const apiKey = Deno.env.get('OPENROUTER_API_KEY') ?? ''
  if (!apiKey) return null

  const model = Deno.env.get('OPENROUTER_MODEL') ?? 'qwen/qwen2.5-7b-instruct:free'

  const input = {
    annualTargetValue: args.req.annualTargetValue,
    annualAchievedValue: args.req.annualAchievedValue,
    gapValue: Math.max(0, args.req.annualTargetValue - args.req.annualAchievedValue),
    targetCategoryId: args.req.targetCategoryId,
    currentCity: args.req.currentCity ?? null,
    recommendation: args.recommendation,
  }

  const systemPrompt =
    'Você é um assistente comercial agrícola. Responda em pt-BR, objetivo e curto. Máximo 2 frases. Sem score numérico. Sem markdown.'

  const userPrompt =
    `Explique por que este cliente foi recomendado para visita agora e sugira uma próxima ação curta. Dados: ${JSON.stringify({
      ...input,
      chatMessage: args.req.chatMessage ?? null,
    })}`

  try {
    const controller = new AbortController()
    const timeout = setTimeout(() => controller.abort(), 7000)

    const response = await fetch('https://openrouter.ai/api/v1/chat/completions', {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${apiKey}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        model,
        messages: [
          { role: 'system', content: systemPrompt },
          { role: 'user', content: userPrompt },
        ],
        temperature: 0.2,
        max_tokens: 120,
      }),
      signal: controller.signal,
    })

    clearTimeout(timeout)

    if (!response.ok) {
      const body = await response.text()
      console.error('[agenda-ai-recommend] openrouter error:', body)
      return null
    }

    const jsonBody = await response.json()
    const text = jsonBody?.choices?.[0]?.message?.content
    if (typeof text !== 'string' || !text.trim()) return null

    return text.trim()
  } catch (error) {
    console.error('[agenda-ai-recommend] openrouter exception:', error)
    return null
  }
}

function json(body: unknown, status: number): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  })
}
