# SoloForte — Baseline de testes (`flutter test`)

**Atualizado:** 2026-08-08  
**Branch de referência:** `cursor/carteira-finalize-618c` (após Marketing/Gerados + ADR-048)

## Snapshot atual (medido localmente)

| Métrica | Valor |
|---|---|
| Passed | **1238** |
| Skipped | **1** |
| Failed | **2** (pré-existentes, fora do escopo Marketing/Gerados) |

### Falhas conhecidas (não bloqueiam este ciclo)

1. `test/ui/components/map/isolated_occurrence_markers_layer_test.dart` — `MarkerLayer` não encontrado
2. `test/modules/agenda/use_cases/start_event_use_case_test.dart` — `Happy Path falha no espelho não impede persistência da sessão da agenda`

## Histórico (não usar como gate sem revalidar)

| Data / contexto | Passed | Skipped | Failed |
|---|---:|---:|---:|
| Baseline legado citado em sessão Marketing | 1216 | 1 | 1 |
| Branch sem mudanças unstaged Marketing (stash) | 1231 | 1 | 2 |
| Após Marketing/Gerados + testes novos | 1235 | 1 | 2 |
| Após ADR-048 + teste integração saveCase | 1238 | 1 | 2 |

## Delta por entrega Marketing/Gerados (esta sessão)

| Entrega | Novos `testWidgets` / `test` |
|---|---|
| Filtro + exclusão UI | +4 em `relatorios_page_actions_test.dart` |
| Fallback `ativo` merge | +2 em `marketing_case_repository_save_case_ativo_test.dart` |
| Integração `saveCase` | +1 em `marketing_case_repository_save_case_integration_test.dart` |

## Comando de validação

```bash
flutter test
./tool/arch_check.sh
```

Coverage mínimo CI permanece **36.46%** (`tool/coverage_gate.sh`).
