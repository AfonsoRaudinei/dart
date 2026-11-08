# AGENTS.md — planos

## Bounded context

`planos/` e o modulo de monetizacao: planos pagos, pagamentos, indicacoes e status de assinatura.

## Contratos e dependencias

- Pode usar Supabase e servicos neutros de `core/`.
- `marketing/` pode depender de `planos/` para verificar plano ativo.
- `map/` pode depender de `planos/` para exibicao de badge.

## Proibido

- Importar qualquer modulo de dominio (`consultoria`, `drawing`, `agenda`, `marketing`, `visitas`, `carteira`).
- Misturar regra financeira com UI sem camada de dominio/data.
- Simular pagamento real com dado ficticio.

## Cache local (Adendo 1)

`PlanoLocalCache` persiste o último `UserPlan` verificado online em
`PreferencesService` (não SQLite), namespaced por `userId`, com TTL de 24h.
`planoAtivoProvider` usa esse cache em falhas não-auth (offline / timeout).
`AuthException` nunca serve cache.

## Pagamento (Adendo 2)

Compra in-app, quando existir, é só StoreKit ou Play Billing. `MercadoPagoService` recusa iOS e Android. As telas de planos não mostram preço nem chamada à ação enquanto os produtos `soloforte_plano_bronze`, `soloforte_plano_prata` e `soloforte_plano_ouro` não existirem nas duas consoles. Não conceder plano no cliente.

## Qualidade obrigatoria

- Fluxos financeiros devem ter estados explicitos: pendente, confirmado, erro/cancelado.
- Dados remotos devem tratar falha e idempotencia.
- Rodar `flutter analyze lib/modules/planos/` e `./tool/arch_check.sh`.

