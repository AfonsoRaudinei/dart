// supabase/functions/delete-user/index.ts
// Runtime: Deno — NÃO usar APIs Node.js
// Deploy: supabase functions deploy delete-user --project-ref pyoejhhkjlrjijiviryq

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

const TABLES_TO_DELETE = [
  'visit_sessions',
  'agenda_visit_sessions',
  'agenda_events',
  'occurrences',
  'fields', // Added based on DB verification
  'pins',
  'marketing_avaliacoes', // Changed from marketing_case_images based on DB verification
  'marketing_cases',
  'documents',
  'producers',
  'farms',
  'clients',
  'referrals',
  'referral_codes',
  'user_plans',
  'webhook_configurations',
  'conversations',
  'security_logs',
  'app_settings',
  'user_preferences',
  'feedback', // Added based on DB verification
  'perfis', // Added based on DB verification
  'profiles',
]

Deno.serve(async (req: Request) => {
  // CORS Preflight
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  // Apenas DELETE ou POST
  if (req.method !== 'DELETE' && req.method !== 'POST') {
    return json({ error: 'Método não permitido.' }, 405)
  }

  // Extrair JWT
  const authHeader = req.headers.get('Authorization')
  if (!authHeader?.startsWith('Bearer ')) {
    return json({ error: 'Não autorizado.' }, 401)
  }
  const jwt = authHeader.replace('Bearer ', '').trim()

  // Client admin com service_role
  const supabaseAdmin = createClient(
    Deno.env.get('SUPABASE_URL') ?? '',
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
    { auth: { persistSession: false } }
  )

  // Verificar JWT e obter user_id
  const { data: { user }, error: authError } = await supabaseAdmin.auth.getUser(jwt)
  if (authError || !user) {
    return json({ error: 'Não autorizado.' }, 401)
  }
  const userId = user.id
  const deletionErrors: string[] = []

  // Deletar referências diretas primeiro
  try {
      await supabaseAdmin.from('referrals').delete().eq('referred_id', userId)
  } catch (e) {}

  // Deletar dados de todas as tabelas mapeadas
  for (const table of TABLES_TO_DELETE) {
    let col = 'user_id'
    if (table === 'perfis' || table === 'profiles') col = 'id'
    if (table === 'referrals') col = 'referrer_id'
    
    const { error } = await supabaseAdmin
      .from(table)
      .delete()
      .eq(col, userId)

    if (error) {
      // Log mas não interrompe — deleta o máximo possível
      console.error(`[delete-user] Erro em ${table}:`, error.message)
      deletionErrors.push(table)
    }
  }

  // Deletar usuário do Auth (passo final — irreversível)
  const { error: deleteAuthError } = await supabaseAdmin.auth.admin.deleteUser(userId)
  if (deleteAuthError) {
    console.error('[delete-user] Erro ao deletar Auth user:', deleteAuthError.message)
    return json({
      error: 'Falha ao excluir conta. Dados parcialmente removidos.',
      tablesWithErrors: deletionErrors,
    }, 500)
  }

  // Sucesso
  if (deletionErrors.length > 0) {
    console.warn('[delete-user] Concluído com erros em tabelas:', deletionErrors)
  }

  return json({
    success: true,
    message: 'Conta excluída com sucesso.',
    ...(deletionErrors.length > 0 && { warnings: deletionErrors }),
  }, 200)
})

// Helper
function json(body: unknown, status: number): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  })
}
