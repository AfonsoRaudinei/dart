# Monetizacao iOS — App Review

Data: 2026-06-07
Escopo: Fase 3 de publicacao iOS App Store.

## Decisao para este release

O build iOS nao inicia compra de plano digital por Mercado Pago, nao exibe preco
de plano no iOS e nao apresenta CTA/link para checkout externo.

Motivo: planos digitais que liberam funcionalidade dentro do app entram no risco
da App Review Guideline 3.1.1 quando comprados por mecanismo externo dentro do
app. Para este release, o fluxo Mercado Pago permanece apenas para canais nao
iOS. No iOS, o app mostra somente o status do plano ja existente na conta.

## Comportamento esperado no iOS

- `/planos`: mostra status do plano e retorno ao mapa.
- `/planos/pagamento`: tela de bloqueio funcional, sem metodo de pagamento.
- `/planos/confirmacao`: tela de bloqueio funcional, sem abertura de checkout.
- `MercadoPagoService`: aborta chamadas em iOS antes de invocar Edge Function.

## Comportamento mantido fora do iOS

- Cards de planos com preco continuam disponiveis.
- Tela de pagamento continua criando preferencia Mercado Pago via Supabase.
- Confirmacao continua abrindo checkout externo e aguardando webhook.
- Edge Functions `mercadopago-*` permanecem ativas para canais nao iOS.

## App Store Connect

Modelo deste release:

- App iOS sem In-App Purchases configuradas.
- Nao cadastrar preco de plano digital como IAP enquanto StoreKit nao for
  implementado.
- Preco do app: conforme estrategia comercial do app na loja, sem prometer
  desbloqueio de plano por checkout externo no app.

Se a compra de plano digital precisar ocorrer dentro do iOS no futuro:

1. Implementar StoreKit / In-App Purchase.
2. Cadastrar produtos ou assinaturas no App Store Connect.
3. Migrar validacao de recibo e concessao de plano.
4. Remover dependencia de Mercado Pago do fluxo iOS.

## Nota sugerida ao revisor

O aplicativo iOS nao oferece compra de planos digitais por checkout externo. O
modulo de planos no iOS exibe apenas o status do plano associado a conta do
usuario. Fluxos Mercado Pago existentes no codigo sao destinados a canais nao
iOS e ficam bloqueados no runtime iOS.
