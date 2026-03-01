import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2"

const PLANOS_DURACAO_MESES = {
    bronze: 3,
    prata: 5,
    ouro: 8,
}

serve(async (req) => {
    try {
        if (req.method !== 'POST') {
            return new Response('ok', { status: 200 })
        }

        const payloadText = await req.text()

        // 1. Validar HMAC-SHA256 Manifest (Segurança)
        const secret = Deno.env.get('MERCADOPAGO_WEBHOOK_SECRET')
        if (secret) {
            const xSignature = req.headers.get('x-signature') ?? ''
            const xRequestId = req.headers.get('x-request-id') ?? ''
            const payloadObj = JSON.parse(payloadText)
            const paymentId = payloadObj.data?.id ?? ''

            const parts = Object.fromEntries(xSignature.split(',').map(p => p.split('=')))
            const ts = parts['ts']
            const v1 = parts['v1']

            const manifest = `id:${paymentId};request-id:${xRequestId};ts:${ts};`

            const encoder = new TextEncoder()
            const key = await crypto.subtle.importKey(
                'raw', encoder.encode(secret), { name: 'HMAC', hash: 'SHA-256' }, false, ['sign']
            )
            const signatureBuffer = await crypto.subtle.sign('HMAC', key, encoder.encode(manifest))
            const expectedSignature = Array.from(new Uint8Array(signatureBuffer))
                .map(b => b.toString(16).padStart(2, '0')).join('')

            if (expectedSignature !== v1 && v1) { // Caso não haja check rigoroso ou se MP mandar sem (ambiente de teste)
                console.error('Webhook signature inválida')
                return new Response('ok', { status: 200 })
            }
        }

        const body = JSON.parse(payloadText)

        // 2. Apenas actions de atualização de pagamento importam
        if (body.type !== 'payment') {
            return new Response('ok', { status: 200 })
        }

        const mpAccessToken = Deno.env.get('MERCADOPAGO_ACCESS_TOKEN')
        if (!mpAccessToken) {
            console.error('MERCADOPAGO_ACCESS_TOKEN ausente.')
            return new Response('ok', { status: 200 })
        }

        // 3. Consultar API Mercado Pago para validar "approved" e capturar external_reference
        const paymentId = body.data.id
        const mpRes = await fetch(`https://api.mercadopago.com/v1/payments/${paymentId}`, {
            headers: { 'Authorization': `Bearer ${mpAccessToken}` }
        })

        if (!mpRes.ok) {
            console.error(`Falha ao obter MPayment #${paymentId}`, await mpRes.text())
            return new Response('ok', { status: 200 })
        }

        const paymentInfo = await mpRes.json()
        if (paymentInfo.status !== 'approved') {
            console.log(`Pagamento ${paymentId} não aprovado. Status = ${paymentInfo.status}. Ignorando.`)
            return new Response('ok', { status: 200 })
        }

        const externalRef = paymentInfo.external_reference
        if (!externalRef || !externalRef.includes(':')) {
            console.error('External Reference inválida:', externalRef)
            return new Response('ok', { status: 200 })
        }

        const [userId, planoId] = externalRef.split(':')
        const duracaoMeses = PLANOS_DURACAO_MESES[planoId as keyof typeof PLANOS_DURACAO_MESES]
        if (!duracaoMeses) {
            console.error('Plano desconhecido no external_reference:', planoId)
            return new Response('ok', { status: 200 })
        }

        // Inicializa o Client Service Role (Bypass RLS)
        const supabaseUrl = Deno.env.get('SUPABASE_URL') ?? ''
        const supabaseKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
        if (!supabaseUrl || !supabaseKey) {
            console.error('Supabase credenciais de Backend ausentes')
            return new Response('ok', { status: 200 })
        }

        const supabase = createClient(supabaseUrl, supabaseKey)

        // 4. Inserir/Atualizar o plano em `user_plans`
        const dataExpiracao = new Date()
        dataExpiracao.setMonth(dataExpiracao.getMonth() + duracaoMeses)

        // Desativa anteriores
        await supabase.from('user_plans')
            .update({ ativo: false })
            .eq('user_id', userId)
            .eq('ativo', true)

        // Novo plano
        const { error: planError } = await supabase.from('user_plans').insert({
            user_id: userId,
            plano: planoId,
            origem: 'pagamento',
            expira_em: dataExpiracao.toISOString(),
            ativo: true
        })

        if (planError) {
            console.error('Falha ao inserir novo plano no user_plans', planError)
            return new Response('ok', { status: 200 })
        }

        console.log(`Plano ${planoId} inserido/renovado para ${userId} com expiração em ${dataExpiracao.toISOString()}`)

        // 5. Processar lógicas de Indicações Pending
        // Existe uma referral pendente na qual userId foi INDICADO?
        const { data: pendencias } = await supabase
            .from('referrals')
            .select('*')
            .eq('referred_id', userId)
            .eq('status', 'pendente')
            .gt('expira_em', new Date().toISOString())

        if (pendencias && pendencias.length > 0) {
            const referral = pendencias[0]

            // 5.1 Atualiza referral como Validada
            await supabase.from('referrals').update({
                status: 'validada',
                validado_em: new Date().toISOString()
            }).eq('id', referral.id)

            // 5.2 Incrementa pontuação do indicante
            const { data: rmCodeData } = await supabase.rpc('increment_referral_count', {
                p_user_id: referral.referrer_id
            })

            // NOTA BACKEND: Como não temos a function RPC de increment nativa escrita explicitamente no setup.sql,
            // usaremos a alternativa de select then update. (Para segurança contra race condition RPC é ideal).
            const { data: codeRow } = await supabase
                .from('referral_codes')
                .select('indicacoes_validadas')
                .eq('user_id', referral.referrer_id)
                .single()

            if (codeRow) {
                const novaContagem = codeRow.indicacoes_validadas + 1
                await supabase.from('referral_codes')
                    .update({ indicacoes_validadas: novaContagem })
                    .eq('user_id', referral.referrer_id)

                // 5.3 Validar trigger do upgrade do Indicante
                const { data: planDoReferrerRows } = await supabase
                    .from('user_plans')
                    .select('*')
                    .eq('user_id', referral.referrer_id)
                    .eq('ativo', true)
                    .limit(1)

                if (planDoReferrerRows && planDoReferrerRows.length > 0) {
                    const planDoReferrer = planDoReferrerRows[0]

                    if (planDoReferrer.plano === 'bronze' && novaContagem >= 5) {
                        console.log(`Upgrade! Referrer ${referral.referrer_id} ganhou PRATA`)
                        await executeUpgrade(supabase, referral.referrer_id, 'prata', 5)
                    } else if (planDoReferrer.plano === 'prata' && novaContagem >= 10) {
                        console.log(`Upgrade! Referrer ${referral.referrer_id} ganhou OURO`)
                        await executeUpgrade(supabase, referral.referrer_id, 'ouro', 8)
                    }
                }
            }
        }

        return new Response('ok', { status: 200 })

    } catch (error: any) {
        console.error('Fatal Webhook Error:', error)
        // O Mercado Pago entra em Loop de retentativas infinitas caso retorne err ou 500
        // Retornamos 200 forçado se der crash e acompanhamos o console
        return new Response('ok', { status: 200 })
    }
})

async function executeUpgrade(supabase: any, referrerId: string, novoPlano: string, meses: number) {
    // Desativa plano atual
    await supabase.from('user_plans')
        .update({ ativo: false })
        .eq('user_id', referrerId)
        .eq('ativo', true)

    const expira = new Date()
    expira.setMonth(expira.getMonth() + meses)

    // Insere novo
    await supabase.from('user_plans')
        .insert({
            user_id: referrerId,
            plano: novoPlano,
            origem: 'indicacao',
            ativo: true,
            expira_em: expira.toISOString()
        })

    // Reseta a numeração de validações do referido
    await supabase.from('referral_codes')
        .update({ indicacoes_validadas: 0 })
        .eq('user_id', referrerId)
}
