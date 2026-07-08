# ADR-044 — Whitelist oficial de StateNotifier/ChangeNotifier legados

## Status

Ativo — 2026-07-08

## Contexto

O `AGENTS.md` proibia `StateNotifier`/`ChangeNotifier` "exceto 3 casos já
documentados", mas a auditoria de Jul/2026 encontrou **10 classes** em 8
arquivos. A regra e o código divergiam, tornando o enforcement ambíguo:
nem o revisor sabia quais casos eram dívida aceita e quais eram violação.

## Decisão

A whitelist oficial de notifiers legados passa a ser esta tabela.
Qualquer classe fora dela é violação de ADR-008 e bloqueia PR.

| # | Classe | Arquivo | Justificativa |
|---|---|---|---|
| 1 | `RouterNotifier` (ChangeNotifier) | `lib/core/router/router_notifier.dart` | Contrato do GoRouter (`refreshListenable` exige `Listenable`) |
| 2 | `DrawingController` (ChangeNotifier) | `lib/modules/drawing/presentation/controllers/drawing_controller.dart` | God Object legado governado (DT arch_check, 1680 linhas); migração acoplada ao split pendente |
| 3 | `DrawingGpsOrchestrator` (ChangeNotifier) | `lib/modules/drawing/presentation/controllers/drawing_gps_orchestrator.dart` | Orquestrador interno do DrawingController; migra junto com ele |
| 4 | `SyncOrchestrator` (ChangeNotifier) | `lib/core/services/sync_orchestrator.dart` | Serviço core com ciclo de vida próprio (timer + listeners fora de widgets) |
| 5 | `VisitController` (StateNotifier) | `lib/modules/visitas/presentation/controllers/visit_controller.dart` | Blindagem visitas (ADR-024); migração exige re-teste do fluxo completo |
| 6 | `ProfileNotifier` (StateNotifier) | `lib/modules/settings/presentation/providers/settings_providers.dart` | Trio de settings legado; baixo risco, migrar em lote |
| 7 | `ReportBrandingNotifier` (StateNotifier) | `lib/modules/settings/presentation/providers/settings_providers.dart` | Idem |
| 8 | `ThemeNotifier` (StateNotifier) | `lib/modules/settings/presentation/providers/settings_providers.dart` | Idem |
| 9 | `MarketingCasesNotifier` (StateNotifier) | `lib/modules/marketing/presentation/providers/marketing_providers.dart` | Módulo de baixa criticidade; migrar quando tocado |
| 10 | `LocationStateNotifier` (StateNotifier) | `lib/modules/dashboard/providers/location_providers.dart` | Consumido pelo mapa (hot path); migrar com testes de regressão de GPS |

## Consequências

- `AGENTS.md` referencia este ADR em vez do número mágico "3 casos".
- Novos `StateNotifier`/`ChangeNotifier` continuam proibidos (ADR-008);
  este documento só reconhece o estoque existente.
- Meta de redução: itens 6–9 são candidatos naturais à próxima migração
  em lote; itens 2–3 migram no split do DrawingController.
