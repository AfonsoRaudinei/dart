# Monetização — App Store e Play Store

Data: 2026-11-08
Escopo: compra nativa nas lojas (ADR-012, Adendo 2).

## Decisão

O app não inicia compra por Mercado Pago e não abre checkout externo. O meio de pagamento é o da loja: StoreKit no iOS e Play Billing no Android. A taxa é a da loja.

Prazos publicados: Bronze 3 meses, Prata 6 meses, Ouro 12 meses. A Apple não oferece 5 nem 8 meses em assinatura não renovável. O preço exibido é o que a loja devolver. Referência de cadastro: R$ 49,90, R$ 79,90 e R$ 119,90.

IDs iguais nas duas lojas: `soloforte_plano_bronze`, `soloforte_plano_prata`, `soloforte_plano_ouro`.

Bundle iOS: `com.soloforte.soloforteApp`. Pacote Android: `com.soloforte.app`.

## Comportamento

- `/planos`: no iOS e no Android, lista só os produtos que a loja devolver, com o preço da loja, compra e restaurar compras. Se a loja não devolver produto, a tela não mostra preço nem botão.
- `/planos/pagamento` e `/planos/confirmacao`: sem checkout externo.
- `MercadoPagoService`: aborta no iOS e no Android antes da Edge.
- A Edge `loja-verificar-compra` valida o recibo e só então grava `user_plans`. O cliente não concede plano. Sem segredo de verificação, a Edge não grava.

## Ordem de publicação

1. App Store Connect: três assinaturas não renováveis, acordo de apps pagos, chave da App Store Server API no Supabase, usuário sandbox.
2. Enviar o binário iOS com esses produtos na versão.
3. Depois do iOS em revisão, cadastrar os mesmos IDs na Play como produto único consumível e enviar o Android.

## Nota sugerida ao revisor

O aplicativo não oferece compra de planos digitais por checkout externo. A compra dentro do app usa o faturamento da própria loja. O plano só é concedido depois da validação do recibo no servidor.
