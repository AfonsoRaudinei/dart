# Auditoria Completa v1 — Follow-up (Fases 0–6)

**Data:** 2026-07-31  
**Baseline:** `AUDITORIA_COMPLETA_v1_2026-07-30.md` (score 6.9/10)  
**Escopo deste follow-up:** implementação das fases 0–6 do plano de correção

---

## Resumo executivo

| Fase | Status | Evidência principal |
|---|---|---|
| F0 — Suite / CI | ✅ | 5 arquivos-alvo verdes + `test/regression/` |
| F1 — user_id / demo | ✅ | Sem defaults demo; bootstrap COUNT; NDVI cache |
| F2 — FAB carteira | ✅ | `rg FloatingActionButton lib/modules` vazio |
| F3 — sync_status | ✅ | `local_only` / `pending_sync`; soft delete occurrences |
| F4 — analyze CI | ✅ | Warning sheet corrigido; step `flutter analyze lib/` |
| F5 — Android release | ✅ | Minify R8 + doc `SCHEDULE_EXACT_ALARM` |
| F6 — Dívida estrutural | ⚠️ Parcial | Logout radar; a11y login; ADR-044 nota; backlog abaixo |

**Score estimado pós-correção:** ~7.8/10 (Dim 5/6/10/11 melhoradas; F6 residual documentado)

---

## Checklist global (Fases 0–5)

- [x] `./tool/arch_check.sh` → Exit 0
- [x] `flutter analyze lib/` — warning `occurrence_creation_sheet_ui_helpers` resolvido
- [x] `flutter test test/regression/` verde
- [x] Sem `demo1234` / `demo@soloforte.com` como default no binário
- [x] Bootstrap COUNT e `ndvi_cache` filtrados por `user_id`
- [x] Sem FAB local em `lib/modules/`
- [x] Occurrences/agenda escrevem sync_status canônico (normalizer)
- [x] Soft delete em pull de occurrences (`deleted_local`)
- [x] CI: analyze + Regression Shield
- [x] Android release minify/R8; exact alarm documentado
- [x] `smart_button.dart` intocado

---

## Fase 6 — itens entregues vs backlog

### Entregue neste ciclo

- `ClimaRadarEnabled` registra `registerLogoutInvalidation` no logout
- Semantics nos campos de login (`LoginInputField`)
- Cross-reference ADR-044 operacao ↔ riverpod whitelist
- Este documento de follow-up

### Backlog (PRs futuros, um tema por PR)

| Ticket | Módulo | Prioridade |
|---|---|---|
| drawing-god-file | `drawing_controller` / `drawing_utils` >900 LOC | Média |
| adr-044-migration | Migrar StateNotifier whitelisted → `@riverpod` | Média |
| map-keepalive-logout | Providers map keepAlive sem invalidação | Média |
| appbar-map-first | AppBars Material → shell em agenda/planos/carteira/settings | Baixa |
| a11y-map-shell | Tooltips/Semantics telas mapa + auth restantes | Baixa |
| deps-major | Riverpod 3 / go_router / flutter_map (sprint isolado) | Baixa |

---

## Comandos de validação

```bash
./tool/arch_check.sh
flutter analyze lib/
flutter test test/regression/
flutter test test/modules/ndvi/ndvi_local_datasource_test.dart
rg "FloatingActionButton" lib/modules/
rg "demo1234|demo@soloforte" lib/
```

---

*Gerado automaticamente pelo plano `correção_auditoria_fases` — não editar o plano; usar este addendum como status.*
