# Fase 3 — Checklist de validação (Polish e submissão)

Validação estática executada em 29/06/2026 — **24/24 checks automáticos passaram**.

## ÉPICO 10 — Metadados

- [x] `docs/store/METADADOS_LOJAS.md` — descrição pt-BR, categoria, keywords
- [x] Screenshots: guia de captura documentado
- [x] Export compliance iOS documentado (`ITSAppUsesNonExemptEncryption = NO`)

## Conformidade lojas

- [x] `docs/store/DATA_SAFETY_GOOGLE_PLAY.md`
- [x] `docs/store/APP_PRIVACY_APPLE.md`
- [x] `docs/store/CONTA_DEMO_REVIEW.md`
- [x] `docs/store/GUIA_SUBMISSAO.md`

## QA

- [x] `docs/SMOKE_TEST_CHECKLIST.md` — 30 cenários
- [x] CI GitHub Actions ativo (`.github/workflows/flutter_ci.yml`)
- [x] Teste `test/session_models_test.dart` (SessionUnknown)

## Polish código

- [x] Zero `print()` em `lib/`
- [x] Feedback funcional (Supabase ou mailto) — `lib/modules/feedback/`
- [x] `supabase/feedback_table.sql` com RLS
- [x] SessionUnknown sem flash de redirect (router + AppShell loading)
- [x] Alerta visita longa deduplicado (`_longVisitAlertSessionId`)
- [x] Settings → Relatórios navega para `AppRoutes.reports`
- [x] `talhao_map_adapter.dart` usa `appLog()` em vez de `print()`

## Baseline preservado

- [x] `private_map_screen.dart` **não alterado** nesta fase
- [x] Modo armado ocorrências intacto (`_toggleOccurrenceMode`)
- [x] Geofence core inalterado (apenas dedupe de notificação BUG-08)

## Gate Fase 3 (manual — pós-merge)

- [ ] Smoke test 100% em dispositivos reais (`docs/SMOKE_TEST_CHECKLIST.md`)
- [ ] `flutter analyze` + `flutter test` localmente
- [ ] Builds release gerados (`docs/BUILD_RELEASE.md`)
- [ ] Executar `supabase/feedback_table.sql` no Supabase
- [ ] Criar conta demo conforme `docs/store/CONTA_DEMO_REVIEW.md`
- [ ] Submissão Play + App Store executada (`docs/store/GUIA_SUBMISSAO.md`)