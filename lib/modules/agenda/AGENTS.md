# AGENTS.md — agenda

## Bounded context

`agenda/` e o dominio de planejamento agronomico: eventos, conflitos, notificacoes e ciclo `agendado -> emAndamento -> finalizando -> concluido/cancelado`.

## Contratos e dependencias

- Pode consumir `core/contracts/IClientLookup`.
- Pode consumir contratos de sessao/agenda quando documentados.
- Pode integrar com `visitas/` no fluxo de inicio/finalizacao conforme ADR vigente.

## Proibido

- Importar `modules/consultoria` diretamente.
- Criar estado com `StateNotifier` ou `ChangeNotifier`.
- Pular use cases para mutar eventos diretamente na UI.
- Usar navegacao baseada em stack.

## Qualidade obrigatoria

- Regras de transicao ficam em entidades/use cases, nao em widgets.
- Toda persistencia deve preservar `user_id` e `sync_status`.
- Testes esperados: `test/modules/agenda/` e use cases afetados.
- Rodar `flutter analyze lib/modules/agenda/` e `./tool/arch_check.sh`.

