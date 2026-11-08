import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2"
import { verifyMercadoPagoWebhookSignature } from './webhook_hmac.ts'
import {
    processMercadoPagoPaymentWebhook,
    type UserPlansWriter,
} from './webhook_process_payment.ts'

serve(async (req) => {
    try {
        if (req.method !== 'POST') {
            return new Response('ok', { status: 200 })
        }

        const payloadText = await req.text()

        const secret = Deno.env.get('MERCADOPAGO_WEBHOOK_SECRET')
        const payloadObj = JSON.parse(payloadText) as { data?: { id?: unknown } }
        const notificationPaymentId = String(payloadObj.data?.id ?? '')

        const hmac = await verifyMercadoPagoWebhookSignature({
            secret,
            xSignature: req.headers.get('x-signature') ?? '',
            xRequestId: req.headers.get('x-request-id') ?? '',
            notificationPaymentId,
        })
        if (hmac === 'invalid') {
            console.error('Webhook signature inválida')
            return new Response('ok', { status: 200 })
        }

        const body = JSON.parse(payloadText)

        if (body.type !== 'payment') {
            return new Response('ok', { status: 200 })
        }

        const mpAccessToken = Deno.env.get('MERCADOPAGO_ACCESS_TOKEN')
        if (!mpAccessToken) {
            console.error('MERCADOPAGO_ACCESS_TOKEN ausente.')
            return new Response('ok', { status: 200 })
        }

        const supabaseUrl = Deno.env.get('SUPABASE_URL') ?? ''
        const supabaseKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
        if (!supabaseUrl || !supabaseKey) {
            console.error('Supabase credenciais de Backend ausentes')
            return new Response('ok', { status: 200 })
        }

        const supabase = createClient(supabaseUrl, supabaseKey)

        const userPlans: UserPlansWriter = {
            async deactivateActivePlans(userId: string) {
                await supabase.from('user_plans')
                    .update({ ativo: false })
                    .eq('user_id', userId)
                    .eq('ativo', true)
            },
            async insertPlan(row) {
                return await supabase.from('user_plans').insert(row)
            },
        }

        const paymentResult = await processMercadoPagoPaymentWebhook(
            {
                fetch,
                mpAccessToken,
                now: () => new Date(),
                userPlans,
            },
            body,
        )

        if (paymentResult.kind !== 'activated') {
            return new Response('ok', { status: 200 })
        }

        const { planRow } = paymentResult
        const userId = planRow.user_id
        const planoId = planRow.plano

        console.log(
            `Plano ${planoId} inserido/renovado para ${userId} com expiração em ${planRow.expira_em}`,
        )

        // 5. Processar lógicas de Indicações Pending
        const { data: pendencias } = await supabase
            .from('referrals')
            .select('*')
            .eq('referred_id', userId)
            .eq('status', 'pendente')
            .gt('expira_em', new Date().toISOString())

        if (pendencias && pendencias.length > 0) {
            const referral = pendencias[0]

            await supabase.from('referrals').update({
                status: 'validada',
                validado_em: new Date().toISOString()
            }).eq('id', referral.id)

            await supabase.rpc('increment_referral_count', {
                p_user_id: referral.referrer_id
            })

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
        return new Response('ok', { status: 200 })
    }
})

async function executeUpgrade(supabase: any, referrerId: string, novoPlano: string, meses: number) {
    await supabase.from('user_plans')
        .update({ ativo: false })
        .eq('user_id', referrerId)
        .eq('ativo', true)

    const expira = new Date()
    expira.setMonth(expira.getMonth() + meses)

    await supabase.from('user_plans')
        .insert({
            user_id: referrerId,
            plano: novoPlano,
            origem: 'indicacao',
            ativo: true,
            expira_em: expira.toISOString()
        })

    await supabase.from('referral_codes')
        .update({ indicacoes_validadas: 0 })
        .eq('user_id', referrerId)
}
