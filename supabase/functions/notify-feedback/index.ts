// supabase/functions/notify-feedback/index.ts
// Deploy: supabase functions deploy notify-feedback --project-ref pyoejhhkjlrjijiviryq
// Secrets: RESEND_API_KEY (opcional — sem chave, grava no log e retorna ok)

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers':
    'authorization, x-client-info, apikey, content-type',
}

const FEEDBACK_INBOX = 'raudyneyb@icloud.com'

type FeedbackPayload = {
  tipo?: string
  modulo?: string
  impacto?: string
  mensagem?: string
  user_email?: string | null
}

Deno.serve(async (req: Request) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  if (req.method !== 'POST') {
    return json({ error: 'Método não permitido.' }, 405)
  }

  const authHeader = req.headers.get('Authorization')
  if (!authHeader?.startsWith('Bearer ')) {
    return json({ error: 'Não autorizado.' }, 401)
  }

  const jwt = authHeader.replace('Bearer ', '').trim()
  const supabaseAdmin = createClient(
    Deno.env.get('SUPABASE_URL') ?? '',
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
    { auth: { persistSession: false } },
  )

  const {
    data: { user },
    error: authError,
  } = await supabaseAdmin.auth.getUser(jwt)
  if (authError || !user) {
    return json({ error: 'Não autorizado.' }, 401)
  }

  let body: FeedbackPayload
  try {
    body = (await req.json()) as FeedbackPayload
  } catch {
    return json({ error: 'Payload inválido.' }, 400)
  }

  const tipo = (body.tipo ?? 'Feedback').trim()
  const modulo = (body.modulo ?? 'Outro').trim()
  const impacto = (body.impacto ?? 'Baixo').trim()
  const mensagem = (body.mensagem ?? '').trim()
  const reporter = (body.user_email ?? user.email ?? 'sem e-mail').trim()

  const resendKey = Deno.env.get('RESEND_API_KEY')
  if (!resendKey) {
    console.log(
      `[notify-feedback] RESEND_API_KEY ausente — ${tipo}/${modulo}/${impacto}`,
    )
    return json({ ok: true, emailed: false, reason: 'resend_not_configured' })
  }

  const fromAddress =
    Deno.env.get('FEEDBACK_FROM_EMAIL') ?? 'SoloForte <onboarding@resend.dev>'

  const subject = `[SoloForte] ${tipo} · ${modulo} (${impacto})`
  const text = [
    'Novo feedback recebido pelo app SoloForte.',
    '',
    `Tipo: ${tipo}`,
    `Módulo: ${modulo}`,
    `Impacto: ${impacto}`,
    `Usuário: ${reporter}`,
    `User ID: ${user.id}`,
    '',
    'Mensagem:',
    mensagem || '(vazia)',
    '',
    'Dashboard: https://afonsoraudinei.github.io/Feedback/',
  ].join('\n')

  try {
    const res = await fetch('https://api.resend.com/emails', {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${resendKey}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        from: fromAddress,
        to: [FEEDBACK_INBOX],
        subject,
        text,
      }),
    })

    if (!res.ok) {
      const detail = await res.text()
      console.error('[notify-feedback] Resend falhou:', detail)
      return json({ ok: true, emailed: false, reason: 'resend_error' })
    }

    return json({ ok: true, emailed: true })
  } catch (error) {
    console.error('[notify-feedback] erro de rede:', error)
    return json({ ok: true, emailed: false, reason: 'network_error' })
  }
})

function json(payload: Record<string, unknown>, status = 200) {
  return new Response(JSON.stringify(payload), {
    status,
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  })
}
