// supabase/functions/delete-user/index.ts
//
// Edge Function: Exclusão permanente de conta de usuário.
// Apple Guidelines 5.1.1(v): obrigatório para apps com criação de conta.
//
// Fluxo:
// 1. Valida que o chamador é o próprio usuário (JWT)
// 2. Deleta dados em todas as tabelas relacionadas ao user_id
// 3. Remove arquivos do Storage (avatars)
// 4. Deleta o auth.user via service_role
//
// Deploy: supabase functions deploy delete-user

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  // CORS preflight
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    // 1. Criar client com service_role (necessário para admin.deleteUser)
    const supabaseAdmin = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
    )

    // 2. Validar JWT do chamador
    const authHeader = req.headers.get('Authorization')
    if (!authHeader) {
      return new Response(
        JSON.stringify({ error: 'Token de autenticação ausente' }),
        { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      )
    }

    const token = authHeader.replace('Bearer ', '')
    const { data: { user }, error: authError } = await supabaseAdmin.auth.getUser(token)

    if (authError || !user) {
      return new Response(
        JSON.stringify({ error: 'Token inválido ou expirado' }),
        { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      )
    }

    const userId = user.id

    // 3. Validar que o body.user_id confere com o JWT (proteção extra)
    const body = await req.json()
    if (body.user_id && body.user_id !== userId) {
      return new Response(
        JSON.stringify({ error: 'user_id não confere com o token' }),
        { status: 403, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      )
    }

    console.log(`[delete-user] Iniciando exclusão para user_id: ${userId}`)

    // 4. Deletar dados em todas as tabelas (ordem: dependentes primeiro)
    // Nomes reais conforme soloforte_db_setup.sql (schema v13)
    const tablesToClean = [
      // Marketing (avaliacoes depende de marketing_cases via FK cascade)
      { table: 'marketing_avaliacoes', column: 'user_id' },
      { table: 'marketing_cases', column: 'user_id' },
      // Ocorrências
      { table: 'occurrences', column: 'user_id' },
      // Visitas / sessões
      { table: 'visit_sessions', column: 'user_id' },
      { table: 'agenda_visit_sessions', column: 'user_id' },
      { table: 'agenda_events', column: 'user_id' },
      // Consultoria (fields→farms→clients, deletar nessa ordem)
      { table: 'fields', column: 'user_id' },
      { table: 'farms', column: 'user_id' },
      { table: 'clients', column: 'user_id' },
      // Planos e pagamentos
      { table: 'user_plans', column: 'user_id' },
      // Indicações
      { table: 'referrals', column: 'referrer_id' },
      { table: 'referral_codes', column: 'user_id' },
      // Feedback
      { table: 'feedback', column: 'user_id' },
      // Perfil (por último)
      { table: 'perfis', column: 'id' },
    ]

    // Referrals onde o usuário foi indicado (referred_id)
    try {
      await supabaseAdmin.from('referrals').delete().eq('referred_id', userId)
    } catch (_) { /* ignora se não existir */ }

    for (const { table, column } of tablesToClean) {
      try {
        const { error } = await supabaseAdmin
          .from(table)
          .delete()
          .eq(column, userId)

        if (error) {
          // Tabela pode não existir no schema atual — log e continuar
          console.warn(`[delete-user] Erro ao limpar ${table}: ${error.message}`)
        } else {
          console.log(`[delete-user] ✅ ${table} limpo`)
        }
      } catch (e) {
        console.warn(`[delete-user] Exceção ao limpar ${table}: ${e}`)
      }
    }

    // 5. Remover arquivos do Storage (avatars do usuário)
    try {
      const { data: files } = await supabaseAdmin.storage
        .from('avatars')
        .list('avatars', { search: userId })

      if (files && files.length > 0) {
        const paths = files.map((f: { name: string }) => `avatars/${f.name}`)
        await supabaseAdmin.storage.from('avatars').remove(paths)
        console.log(`[delete-user] ✅ ${paths.length} arquivo(s) removido(s) do storage`)
      }
    } catch (e) {
      console.warn(`[delete-user] Erro ao limpar storage: ${e}`)
    }

    // 6. Deletar o auth.user (irreversível)
    const { error: deleteError } = await supabaseAdmin.auth.admin.deleteUser(userId)

    if (deleteError) {
      console.error(`[delete-user] ❌ Erro ao deletar auth user: ${deleteError.message}`)
      return new Response(
        JSON.stringify({ error: `Erro ao excluir usuário: ${deleteError.message}` }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      )
    }

    console.log(`[delete-user] ✅ Conta ${userId} excluída com sucesso`)

    return new Response(
      JSON.stringify({ success: true, message: 'Conta excluída permanentemente' }),
      { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
    )
  } catch (err) {
    console.error(`[delete-user] Erro inesperado: ${err}`)
    return new Response(
      JSON.stringify({ error: 'Erro interno ao processar exclusão' }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
    )
  }
})
