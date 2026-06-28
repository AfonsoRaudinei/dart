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

## Qualidade obrigatoria

- Fluxos financeiros devem ter estados explicitos: pendente, confirmado, erro/cancelado.
- Dados remotos devem tratar falha e idempotencia.
- Rodar `flutter analyze lib/modules/planos/` e `./tool/arch_check.sh`.

