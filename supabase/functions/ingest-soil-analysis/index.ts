// Server-to-server only. Deploy with JWT verification disabled; authentication
// is performed with x-integration-key against a backend-only credential hash.
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

type JsonObject = Record<string, unknown>

type IngestRequest = {
  external_analysis_id?: unknown
  client_id?: unknown
  latitude?: unknown
  longitude?: unknown
  analysis_payload?: unknown
  updated_at?: unknown
  deleted_at?: unknown
  description?: unknown
}

Deno.serve(async (request: Request) => {
  if (request.method !== 'POST') {
    return json({ error: 'method_not_allowed' }, 405)
  }

  const credential = request.headers.get('x-integration-key')?.trim() ?? ''
  if (credential.length < 32) {
    return json({ error: 'invalid_integration_credential' }, 401)
  }

  const supabaseUrl = Deno.env.get('SUPABASE_URL') ?? ''
  const serviceRole = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
  if (!supabaseUrl || !serviceRole) {
    console.error('[ingest-soil-analysis] backend environment is incomplete')
    return json({ error: 'backend_not_configured' }, 500)
  }

  const admin = createClient(supabaseUrl, serviceRole, {
    auth: { persistSession: false, autoRefreshToken: false },
  })

  const credentialHash = await sha256(credential)
  const { data: integration, error: integrationError } = await admin
    .from('external_analysis_integrations')
    .select('external_source, owner_user_id')
    .eq('credential_hash', credentialHash)
    .eq('active', true)
    .maybeSingle()

  if (integrationError || !integration) {
    return json({ error: 'invalid_integration_credential' }, 401)
  }

  let body: IngestRequest
  try {
    body = await request.json()
  } catch (_) {
    return json({ error: 'invalid_json' }, 400)
  }

  const validation = validate(body)
  if ('error' in validation) return json({ error: validation.error }, 422)

  const { data: client, error: clientError } = await admin
    .from('clients')
    .select('id, user_id, deleted_at')
    .eq('id', validation.clientId)
    .eq('user_id', integration.owner_user_id)
    .is('deleted_at', null)
    .maybeSingle()

  if (clientError || !client) {
    return json({ error: 'client_not_owned_by_integration_owner' }, 403)
  }

  const geometry = validation.coordinates === null
    ? null
    : {
        type: 'Point',
        coordinates: [
          validation.coordinates.longitude,
          validation.coordinates.latitude,
        ],
      }

  const row = {
    user_id: integration.owner_user_id,
    client_id: validation.clientId,
    external_source: integration.external_source,
    external_analysis_id: validation.externalAnalysisId,
    latitude: validation.coordinates?.latitude ?? null,
    longitude: validation.coordinates?.longitude ?? null,
    geometry,
    category: 'amostra_solo',
    amostra_solo: true,
    type: 'Info',
    description: typeof body.description === 'string' ? body.description : '',
    status: 'confirmed',
    sync_status: validation.deletedAt === null ? 'synced' : 'deleted_local',
    analysis_payload: validation.analysisPayload,
    updated_at: validation.updatedAt,
    deleted_at: validation.deletedAt,
  }

  const { data: occurrence, error: upsertError } = await admin
    .from('occurrences')
    .upsert(row, {
      onConflict: 'external_source,user_id,external_analysis_id',
    })
    .select('id, external_source, external_analysis_id, updated_at, deleted_at')
    .single()

  if (upsertError) {
    console.error('[ingest-soil-analysis] upsert failed', upsertError.message)
    return json({ error: 'upsert_failed' }, 500)
  }

  return json({ occurrence }, 200)
})

function validate(body: IngestRequest):
  | {
      externalAnalysisId: string
      clientId: string
      coordinates: { latitude: number; longitude: number } | null
      analysisPayload: JsonObject
      updatedAt: string
      deletedAt: string | null
    }
  | { error: string } {
  const externalAnalysisId = String(body.external_analysis_id ?? '').trim()
  if (!externalAnalysisId) return { error: 'external_analysis_id_required' }

  const clientId = String(body.client_id ?? '').trim()
  if (!isUuid(clientId)) return { error: 'client_id_must_be_uuid' }

  if (!isJsonObject(body.analysis_payload)) {
    return { error: 'analysis_payload_must_be_object' }
  }

  const updatedAt = isoDate(body.updated_at)
  if (updatedAt === null) return { error: 'updated_at_required' }

  const deletedAt = body.deleted_at == null ? null : isoDate(body.deleted_at)
  if (body.deleted_at != null && deletedAt === null) {
    return { error: 'deleted_at_invalid' }
  }

  const hasLatitude = body.latitude != null
  const hasLongitude = body.longitude != null
  if (hasLatitude !== hasLongitude) {
    return { error: 'latitude_and_longitude_must_be_sent_together' }
  }

  let coordinates: { latitude: number; longitude: number } | null = null
  if (hasLatitude && hasLongitude) {
    const latitude = Number(body.latitude)
    const longitude = Number(body.longitude)
    if (!Number.isFinite(latitude) || latitude < -90 || latitude > 90) {
      return { error: 'latitude_out_of_range' }
    }
    if (!Number.isFinite(longitude) || longitude < -180 || longitude > 180) {
      return { error: 'longitude_out_of_range' }
    }
    if (latitude === 0 && longitude === 0) {
      return { error: 'zero_coordinates_are_not_allowed' }
    }
    coordinates = { latitude, longitude }
  }

  return {
    externalAnalysisId,
    clientId,
    coordinates,
    analysisPayload: body.analysis_payload,
    updatedAt,
    deletedAt,
  }
}

function isJsonObject(value: unknown): value is JsonObject {
  return typeof value === 'object' && value !== null && !Array.isArray(value)
}

function isUuid(value: string): boolean {
  return /^[0-9a-f]{8}-[0-9a-f]{4}-[1-8][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i.test(value)
}

function isoDate(value: unknown): string | null {
  if (typeof value !== 'string' || !value.trim()) return null
  const date = new Date(value)
  return Number.isNaN(date.getTime()) ? null : date.toISOString()
}

async function sha256(value: string): Promise<string> {
  const bytes = new TextEncoder().encode(value)
  const digest = await crypto.subtle.digest('SHA-256', bytes)
  return [...new Uint8Array(digest)]
    .map((byte) => byte.toString(16).padStart(2, '0'))
    .join('')
}

function json(body: unknown, status: number): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { 'Content-Type': 'application/json; charset=utf-8' },
  })
}
