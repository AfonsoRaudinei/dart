# Fase 6 — Sync & Offline Hardening

**Meta holística:** 89% · **Pré-requisito:** Fase 5 (matriz de testes)

## Objetivo

Reduzir tempo total de sync pós-reconexão e endurecer contrato offline sem alterar bounded contexts.

## Entregas

| Item | Arquivo | Descrição |
|---|---|---|
| Sync tiered | `lib/core/services/sync_module_runner.dart` | Tier 0 sequencial; tiers > 0 em `Future.wait` |
| `syncTier` | `SyncModule` + `AgronomicSyncModule` | Agronomic = tier 0 (clientes/fazendas antes de dependentes) |
| Coalescing | `SyncOrchestrator.triggerSync` | `SyncPriority.immediate` enfileirado se já sincronizando |
| Resultados | `SyncModuleResult` + `lastResults` | Duração/erro por módulo para observabilidade |
| Contrato | `lib/core/services/sync_status_contract.dart` | Valores AGENTS.md + normalização legado |
| Testes | `test/core/services/*_test.dart` | Runner, orchestrator, sync_status |

## Ordem de execução (pós Fase 6)

```
Tier 0 (sequencial):  Agronomic
Tier 1 (paralelo):    Drawing | Occurrence | Visit | Agenda
```

**Antes:** serial Agronomic → Drawing → Occurrence → Visit → Agenda  
**Meta perf:** −40% tempo total (Cenário 3 — `FASE0_PERF_PROFILING_GUIDE.md`)

## Ferramentas

```bash
flutter test test/core/services/
flutter analyze lib/core/services/
./tool/arch_check.sh
```

## Baseline manual (DevTools)

1. Profile build + device físico
2. Modo avião ON 10 s → OFF
3. Medir tempo até `SyncOrchestrator.isSyncing == false`
4. Registrar em `docs/04_AUDITORIAS/traces/fase6/`

## Riscos mitigados

- **SQLite contention:** apenas tier 0 escreve FK base; tier 1 usa tabelas distintas por módulo
- **Erro isolado:** falha em um módulo não aborta o batch (`SyncModuleResult.success`)
- **Lifecycle:** `notifyListeners` guardado pós-`dispose`

## Ratchet

- Manter `AgronomicSyncModule.syncTier == 0`
- Não re-serializar tier 1 sem ADR
- Novos `SyncModule` devem declarar `syncTier` explicitamente se dependem de Agronomic

---

*Fase 6 — Sync & Offline Hardening | Jun/2026*
