# AGENTS.md — visitas

## Bounded context

`visitas/` executa sessao de visita tecnica em campo: check-in, check-out, geofence, contexto ativo, estatisticas e sync.

## Contratos e dependencias

- Expoe `IVisitSessionLookup` e `IVisitClientLookup` por `core/contracts/`.
- Pode consumir `IClientLookup` e outros contratos neutros quando documentados.
- Deve manter comunicacao com consultoria/drawing/agenda via contratos.

## Proibido

- Importar `modules/drawing`.
- Importar `modules/consultoria` fora das excecoes tecnicas documentadas em ADR.
- Importar `agenda/presentation` fora das excecoes vigentes.
- Encerrar ou alterar sessao sem preservar trilha de sync.

## Qualidade obrigatoria

- Geofence roda foreground enquanto o mapa privado esta aberto.
- Sessao ativa deve ter invariantes claras e testes de transicao.
- Testes esperados: `test/modules/visitas/`.
- Rodar `flutter analyze lib/modules/visitas/` e `./tool/arch_check.sh`.

