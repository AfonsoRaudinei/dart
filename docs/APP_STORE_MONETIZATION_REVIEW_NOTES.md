# Monetização — App Store e Play Store

Data: 2026-11-08
Escopo: decisão de pagamento nativo nas lojas (ADR-012, Adendo 2).

## Decisão

O binário iOS e o binário Android não iniciam compra de plano digital por Mercado Pago, não exibem preço de plano e não apresentam chamada à ação nem link para checkout externo.

O meio de pagamento aprovado para o app é o da própria loja: StoreKit no iOS e Play Billing no Android. A taxa é a da loja. O app não escolhe PIX nem cartão.

Essa compra ainda não está no binário. Não há produtos de plano cadastrados nas consoles e não há validação de recibo. Até essa entrega, o app só mostra o status do plano já existente na conta.

## Comportamento neste release

- `/planos`: status do plano e retorno ao mapa. Sem preço e sem botão de assinar.
- `/planos/pagamento`: tela de bloqueio, sem método de pagamento.
- `/planos/confirmacao`: tela de bloqueio, sem abertura de checkout.
- `MercadoPagoService`: aborta no iOS e no Android antes de invocar a Edge Function.

## O que permanece no repositório

As Edge Functions `mercadopago-*` continuam no código e não são o funil de compra do app. Nenhuma tela as chama.

## Quando a compra na loja entrar

1. Cadastrar três produtos de prazo fixo, sem renovação automática, com os mesmos IDs nas duas lojas: `soloforte_plano_bronze` (3 meses), `soloforte_plano_prata` (5 meses), `soloforte_plano_ouro` (8 meses). Na Apple, assinatura não renovável. Na Google, produto único consumível.
2. O preço em BRL é o cadastrado na loja. Referência atual do catálogo: R$ 49,90, R$ 79,90 e R$ 119,90.
3. Validar o recibo no servidor e só então gravar `user_plans`. O cliente não concede plano.
4. Aí as telas passam a mostrar o preço devolvido pela loja e a compra nativa.

Sem os produtos e sem os segredos de verificação, o botão de compra não entra no binário.

## Nota sugerida ao revisor

O aplicativo não oferece compra de planos digitais por checkout externo. O módulo de planos exibe apenas o status do plano associado à conta. A compra dentro do app, quando for publicada, usará o faturamento da própria loja.
