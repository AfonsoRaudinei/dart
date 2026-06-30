# SoloForte — Architectural Baseline v1.2
## Score Holístico 79/100 · Score Estrutural 86/100

> **Sucessor de:** [ARCH_BASELINE_v1.1_SCORE_90.md](./ARCH_BASELINE_v1.1_SCORE_90.md)  
> **Fase:** 0 — Baseline & Instrumentação (auditoria Jun/2026)  
> **Tag sugerida:** `ARCH_BASELINE_v1.2_SCORE_79`

---

## 1. Identificação

| Campo | Valor |
|---|---|
| **Projeto** | SoloForte App |
| **Tecnologia** | Flutter (Dart) — mobile-only iOS/Android |
| **Arquitetura** | Map-First + Clean Architecture + Bounded Contexts |
| **Versão arquitetural** | v1.2 (estabilização) |
| **Última atualização** | 27/Jun/2026 |
| **Commit snapshot** | `538b97a` (working tree audit) |
| **Módulos registrados** | core, ui, map, drawing, agenda, agenda_ai, operacao (placeholder), consultoria, visitas, settings, auth, planos, produtor, carteira, ndvi, marketing, feedback, dashboard, public, clima |
| **Score holístico** | **79/100** (arquitetura + perf + testes + manutenção) |
| **Score estrutural** | **86/100** (fronteiras + CI + contratos) |

---

## 2. Métricas Reais (Fase 0 — congeladas)

| Métrica | v1.1 (Fev/2026) | v1.2 (Jun/2026) | Δ |
|---|---:|---:|---|
| Arquivos Dart em `lib/` | 520 | **577** | +57 |
| Testes verdes | 649/649 | **898/898** | +249 |
| Coverage global (lcov) | ~36,46% gate | **42,97%** | +6,5 pp |
| `flutter analyze lib/` | 0 | **0** | = |
| `arch_check.sh` | Exit 0 | **Exit 0** | = |
| Contratos `core/contracts/` | ~15 | **40 arquivos** | +25 |
| Schema SQLite | v31 | **v38** | +7 |
| ADRs ativos | 008–037 | **008–044** | +7 |
| TODO/FIXME/HACK em `lib/` | — | **34** | baseline |
| God files >900 linhas | 5 | **5** (monitorados) | = |
| Acoplamentos laterais (WARN) | — | **13 imports** | baseline |
| `operacao/` código Dart | — | **0 arquivos** | ADR-044 |

### Performance snapshot (Fase 0)

Gerado por `./tool/perf_baseline.sh`:

| Hot path | Métrica | Baseline Fase 0 |
|---|---|---:|
| `map_build_orchestrator.dart` | `ref.watch(` | 21 |
| `isolated_marker_layers.dart` | `ref.watch(` | 12 |
| `drawing_controller.dart` | `notifyListeners(` | 44 |
| `drawing_sheet.dart` | `setState(` | 20 |
| `map_occurrence_sheet.dart` | `setState(` | 8 |
| `lib/` total | `ref.watch(` | 360 |
| `lib/` total | `setState(` | 310 |
| `lib/` total | `.select(` | 48 |
| `lib/` total | `ListView/GridView.builder` | 11 |

### God files monitorados

| Arquivo | Linhas |
|---|---:|
| `drawing_sheet.dart` | 2.015 |
| `drawing_controller.dart` | 1.847 |
| `database_helper.dart` | 1.676 |
| `map_occurrence_sheet.dart` | 1.094 |
| `map_build_orchestrator.dart` | 639 |

---

## 3. Score por dimensão (%)

| Dimensão | Score | Evidência |
|---|---:|---|
| Arquitetura & blindagem | **86%** | arch_check PASS; 13 cross-imports warning-only |
| Desempenho & fluidez | **71%** | hot paths acima; isolamento parcial ADR-035 |
| Testes & coverage | **77%** | 42,97% global; desigualdade por módulo |
| Manutenibilidade | **68%** | 5 god files; estado heterogêneo Riverpod |
| CI & qualidade estática | **96%** | analyze 0; gates ativos |
| Sync offline-first | **83%** | 5 módulos sync; schema v38 |
| Governança docs | **87%** | 18 AGENTS.md; ADR-044 operacao |
| **Holístico ponderado** | **79%** | meta pós-Fase 0: **81%** |

---

## 4. Instrumentação Fase 0 (nova)

| Ferramenta | Caminho | Função |
|---|---|---|
| Performance baseline | `tool/perf_baseline.sh` | Conta métricas hot path; warning-only CI |
| Coverage por módulo | `tool/coverage_by_module.sh` | Segmenta lcov por bounded context |
| Coverage gate | `tool/coverage_gate.sh` | Mínimo 36,46%; alvo 60% |
| Profiling manual | `docs/04_AUDITORIAS/FASE0_PERF_PROFILING_GUIDE.md` | 3 cenários DevTools |
| Operacao placeholder | `docs/02_ARQUITETURA_ATIVA/ADR-044-OPERACAO-PLACEHOLDER.md` | Governança módulo vazio |

### CI (`.github/workflows/architecture.yml`)

- Job **coverage:** `flutter test --coverage` + gate + **coverage por módulo**
- Job **baseline-metrics:** `perf_baseline.sh` (warning-only)

---

## 5. Coverage por setor (Fase 0)

Relatório gerado automaticamente: `coverage/coverage_by_module.md`  
Regenerar: `flutter test --coverage && ./tool/coverage_by_module.sh`

| Setor | Prioridade testes (Fase 5) |
|---|---|
| `modules/consultoria` | P0 — 99 arquivos lib, ratio teste baixo |
| `modules/marketing` | P0 |
| `modules/carteira` | P0 |
| `modules/agenda` | P1 |
| `modules/public` | P1 — zero testes |
| `modules/ndvi` | Referência (86% file-test ratio) |

---

## 6. Fronteiras arquiteturais (inalteradas vs v1.1)

Validadas por `tool/arch_check.sh`:

- **REGRA 1:** `core/` não importa `modules/` (exceto `app_router.dart`)
- **REGRA 2:** acoplamentos laterais proibidos — PASS
- **REGRA 3:** arquivos novos ≤900 linhas — PASS
- **REGRA-SHEET-1:** bottom sheets padronizados — PASS
- **REGRA-CROSS-MODULE-2:** 13 imports warning (promover a FAIL na Fase 2)
- **REGRA-NDVI:** ADR-042 invariants — PASS

---

## 7. Módulo `operacao/` — decisão Fase 0

Ver **ADR-044**. Resumo:

- Placeholder documental — **não é módulo zumbi com código morto**
- Responsabilidades operacionais em **`visitas/`** (ADR-024, ADR-033)
- Reimplementação exige ADR + contratos + testes

---

## 8. Riscos remanescentes (atualizado)

| Risco | Severidade | Fase de mitigação |
|---|---|---|
| MapBuildOrchestrator 21× ref.watch | Alta | Fase 1 |
| Drawing 44× notifyListeners | Alta | Fase 1 |
| 13 cross-imports warning-only | Média | Fase 2 |
| Coverage consultoria/marketing baixo | Média | Fase 5 |
| 5 god files legados | Média | Fase 3 |
| StateNotifier/ChangeNotifier legado | Baixa | Fase 4 |
| `context.pop()` em auth/agenda | Baixa | Fase 7 ✅ |

---

## 9. Roadmap pós-baseline

| Fase | Meta score | Foco |
|---|---:|---|
| 0 (atual) | 81% | Baseline + instrumentação |
| 1 | 84% | Hot paths mapa/drawing |
| 2 | 88% | Blindagem v1.2 (contratos) |
| 3 | 86% | Decomposição god files |
| 4 | 87% | Riverpod normalization |
| 5 | 90% | Matriz de testes |
| 6–7 | 91% | Sync + governança |
| 7 | 91% | Navegação declarativa + REGRA-NAV-1 |

---

## 10. Conclusão

v1.2 congela o **estado real** do sistema em Jun/2026: arquitetura **protegida por CI**, testes **898 verdes**, coverage **42,97%**, mas **débito de performance e testes desiguais** documentado com ferramentas automatizadas.

Qualquer PR que aumente métricas acima dos baselines Fase 0 deve justificar o delta ou ser acompanhado de redução na mesma fase.

---

*Congelado: 27/Jun/2026 | Fase 0 Baseline & Instrumentação | `./tool/perf_baseline.sh` + `./tool/coverage_by_module.sh`*
