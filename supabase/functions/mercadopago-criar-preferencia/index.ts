import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2"

const corsHeaders = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

const PLANOS = {
    bronze: { title: 'Plano Bronze SoloForte', price: 49.90, months: 3 },
    prata: { title: 'Plano Prata SoloForte', price: 79.90, months: 5 },
    ouro: { title: 'Plano Ouro SoloForte', price: 119.90, months: 8 },
}

serve(async (req) => {
    // CORS HTTP OPTIONS
    if (req.method === 'OPTIONS') {
        return new Response('ok', { headers: corsHeaders })
    }

    try {
        if (req.method !== 'POST') {
            return new Response(JSON.stringify({ error: 'Método não permitido.' }), {
                status: 405,
                headers: { ...corsHeaders, 'Content-Type': 'application/json' },
            })
        }

        // Configurando Supabase Client
        const supabaseUrl = Deno.env.get('SUPABASE_URL') ?? ''
        const supabaseAnonKey = Deno.env.get('SUPABASE_ANON_KEY') ?? ''

        // Obter Token do header
        const authHeader = req.headers.get('Authorization')
        if (!authHeader) {
            return new Response(JSON.stringify({ error: 'Authorization header ausente.' }), {
                status: 401,
                headers: { ...corsHeaders, 'Content-Type': 'application/json' },
            })
        }
        const token = authHeader.replace('Bearer ', '')

        // Validar JWT no Supabase Auth
        const supabase = createClient(supabaseUrl, supabaseAnonKey)
        const { data: { user }, error: authError } = await supabase.auth.getUser(token)

        if (authError || !user) {
            return new Response(JSON.stringify({ error: 'Token JWT inválido ou expirado.' }), {
                status: 401,
                headers: { ...corsHeaders, 'Content-Type': 'application/json' },
            })
        }

        const body = await req.json()
        const { plano } = body

        if (!plano || !PLANOS[plano as keyof typeof PLANOS]) {
            return new Response(JSON.stringify({ error: 'Plano inválido ou ausente.' }), {
                status: 400,
                headers: { ...corsHeaders, 'Content-Type': 'application/json' },
            })
        }

        const planoData = PLANOS[plano as keyof typeof PLANOS]
        const mpAccessToken = Deno.env.get('MERCADOPAGO_ACCESS_TOKEN')

        if (!mpAccessToken) {
            throw new Error('MERCADOPAGO_ACCESS_TOKEN não configurado no servidor.')
        }

        // Montando a requisição para o MercadoPago
        const mpPayload = {
            items: [{
                title: planoData.title,
                quantity: 1,
                currency_id: 'BRL',
                unit_price: planoData.price
            }],
            external_reference: `${user.id}:${plano}`,
            notification_url: `${supabaseUrl}/functions/v1/mercadopago-webhook`,
            back_urls: {
                success: "soloforte://planos/confirmacao",
                failure: "soloforte://planos/pagamento",
                pending: "soloforte://planos/pagamento"
            },
            auto_return: "approved"
        }

        const mpResponse = await fetch('https://api.mercadopago.com/checkout/preferences', {
            method: 'POST',
            headers: {
                'Authorization': `Bearer ${mpAccessToken}`,
                'Content-Type': 'application/json'
            },
            body: JSON.stringify(mpPayload)
        })

        if (!mpResponse.ok) {
            const errorData = await mpResponse.text()
            console.error('MercadoPago API Error:', errorData)
            throw new Error('Falha ao criar preferência no MercadoPago.')
        }

        const mpData = await mpResponse.json()

        return new Response(JSON.stringify({ init_point: mpData.init_point }), {
            status: 200,
            headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        })

    } catch (error: any) {
        console.error('Function error:', error)
        return new Response(JSON.stringify({ error: error.message || 'Erro interno do servidor.' }), {
            status: 500,
            headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        })
    }
})
