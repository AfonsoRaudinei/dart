# SOLOFORTE — RELATÓRIO DE AUDITORIA COMPLETA v1.0

```
=======================================================
SOLOFORTE — RELATÓRIO DE AUDITORIA COMPLETA
Data: 2026-07-30
Build: 1.34.0+181
Schema DB: v40
Branch: cursor/map-navigation-labels-17d6 @ 5cd6116
Flutter: 3.41.6 (stable) · Dart 3.11.4
Baseline comparação: docs/SOLOFORTE_BASELINE_REAL.md (Jun/2026, schema v33)
Modo: SOMENTE LEITURA — nenhuma correção nesta sessão
=======================================================
```

## PASSO 0 — SNAPSHOT DO AMBIENTE

| Métrica | Valor |
|---|---|
| Arquivos Dart em `lib/` | **641** (baseline Jun: 520) |
| Linhas em `lib/` | **113 104** |
| Arquivos `*_test.dart` | **197** |
| TODOs/FIXME/HACK/XXX em `lib/` | **20** |
| Schema DB | **v40** (`database_helper.dart:27`) |
| `arch_check.sh` | **Exit 0 — APROVADO** |
| `flutter analyze lib/` | **1 warning**, 0 errors |
| `flutter test --no-pub` | **1167 passed · 1 skipped · 4 failed** |
| Warning analyze | `occurrence_creation_sheet_ui_helpers.dart:151` — `invalid_use_of_protected_member` (`setState`) |

### Testes falhando (suite completa)

1. `test/ui/components/map/map_layers_sheet_test.dart` — LayersSheet explicações WMS/Raster
2. `test/ui/components/side_menu_overlay_test.dart` — produtor vê apenas áreas permitidas
3. `test/core/session/local_persistence_scope_guard_test.dart` — LocalSessionIdentity (lista não vazia)
4. `test/modules/drawing/drawing_layers_test.dart` — primeiro toque renderiza ponto inicial

---

## DIMENSÃO 1 — ARQUITETURA E FRONTEIRAS

**Score: 9/10 | Status: OK**

### Achados

- **[OK]** Fronteiras proibidas: `drawing→consultoria`, `agenda→consultoria`, `consultoria→drawing`, `consultoria→agenda`, `consultoria→operacao` — sem imports ativos. `arch_check` Exit 0.
- **[OK]** `core→modules` apenas em `lib/core/router/app_router.dart` (exceção autorizada).
- **[OK]** Módulos deletados (`modules/reports/`, `consultoria/agenda/`, `modules/relatorios/`) — sem referências ativas.
- **[OK]** Contratos: **54** arquivos em `lib/core/contracts/` (interfaces + providers + DTOs).
- **[ALTO]** God-files legados >900 linhas (whitelist arch_check):  
  - `lib/modules/drawing/presentation/controllers/drawing_controller.dart` — **1699** linhas  
  - `lib/modules/drawing/domain/drawing_utils.dart` — **1190** linhas
- **[MÉDIO]** ~46 arquivos entre 500–900 linhas (radar): `client_edit_form.dart:882`, `marketing_case_sheet.dart:879`, `occurrence_creation_sheet.dart:877`, etc.
- **[MÉDIO]** Módulos sem ADR dedicado em `docs/02_ARQUITETURA_ATIVA/`: `auth`, `dashboard`, `feedback`, `public`.
- **[MÉDIO]** Drawing mantém `IClientsRepository` paralelo (adapter para `IClientLookup`) — `lib/modules/drawing/.../i_clients_repository.dart`.
- **[BAIXO]** ADR-044 duplicado: `ADR-044-OPERACAO-PLACEHOLDER.md` + `ADR-044-riverpod-legacy-whitelist.md`.
- **[OK]** Whitelist CROSS-MODULE-2 documentada: DT-025-3 (map→visitas), DT-035 (ui/map→marketing).

---

## DIMENSÃO 2 — NAVEGAÇÃO E MAP-FIRST

**Score: 7/10 | Status: ATENÇÃO**

### Achados

- **[OK]** `context.pop()` / `context.canPop()` — nenhum uso ativo (só docs/comentários). REGRA-NAV-1 PASS.
- **[OK]** Sub-rotas `"/map/..."` — nenhuma. `/map` permanece folha.
- **[OK]** `GoRoute(` declarado só em `app_router.dart`.
- **[ALTO]** FAB local fora do SmartButton: `lib/modules/carteira/presentation/screens/carteira_screen.dart:321` — `FloatingActionButton.extended`.
- **[MÉDIO]** `Navigator.pop` em dialogs/sheets (~33 usos) — permitido por `lib/ui/AGENTS.md` para modais; concentrado em agenda, relatórios, settings, marketing. Exemplos: `agenda_filters_sheet.dart:112`, `relatorios_page.dart:415`, `settings_screen.dart:361`.
- **[MÉDIO]** `AppBar(` / `SliverAppBar(` em módulos (contrato “sem AppBar fixa”): `agenda_month_page.dart:65`, `agenda_day_page.dart:40`, `planos_screen.dart:25`, `carteira_screen.dart:36`, `settings_screen.dart:39`, `client_list_screen.dart:31`, `publicacao_editor_screen.dart:128`, etc.
- **[BAIXO]** `context.go('/…')` com literais em vez de `AppRoutes`: `relatorios_page.dart:286,316`, `client_form_screen.dart:411,470`, `login_screen.dart:223`, etc.

---

## DIMENSÃO 3 — ESTADO E PROVIDERS

**Score: 7/10 | Status: ATENÇÃO**

### Achados

- **[OK]** Sem BLoC / Cubit.
- **[ALTO]** `extends StateNotifier` (legado ADR-044): `marketing_providers.dart:27`, `location_providers.dart:36`, `visit_controller.dart:24`, `settings_providers.dart:15,64,119`.
- **[ALTO]** `extends ChangeNotifier`: `drawing_controller.dart:40`, `drawing_gps_orchestrator.dart:16`, `router_notifier.dart:27`, `sync_orchestrator.dart:23` (whitelist parcial; volume além dos “3 casos” do prompt).
- **[OK]** Logout invalida providers via `SessionController.registerLogoutInvalidation` + `_invalidateUserScopedProviders` (`session_controller.dart:375–470`).
- **[MÉDIO]** keepAlive sem registro explícito de invalidação em alguns sites: `agenda_filters_provider.dart:79`, `visit_completion_observer.dart:47`, vários em `map_state.dart` (parcialmente cobertos por invalidate hardcode).
- **[BAIXO]** `Provider`/`FutureProvider` manuais sem `autoDispose` em repositórios e bridges (padrão legado aceitável se keepAlive intencional).

---

## DIMENSÃO 4 — PERSISTÊNCIA E DADOS

**Score: 6/10 | Status: ATENÇÃO**

### Achados

- **[OK]** Schema **v40**; migrações `migrateToV1`…`migrateToV40` presentes (`database_migrations.dart` + `database_migrations_v24_v38.dart:531`).
- **[OK]** Contrato canônico documentado em `sync_status_contract.dart` (`local_only | pending_sync | synced | sync_error | deleted_local`).
- **[OK]** Sem `DELETE FROM` SQL raw.
- **[ALTO]** Hard `db.delete` em sync de ocorrências: `occurrence_sync_service.dart:174,217,242`.
- **[ALTO]** `sync_status` legado `'pending'` ainda escrito no domínio agenda: `create_event_use_case.dart:100`, `update_event_use_case.dart:98`, `event.dart:79`, defaults em `database_migrations_v1_v23.dart:293,309`.
- **[ALTO]** `sync_status` legado `'local'` em occurrences: `occurrence.dart:14,150,196`, `occurrence_sync_service.dart:53,268`.
- **[MÉDIO]** Hard deletes de cache/local-only (parcialmente justificados): `marketing_case_repository_impl.dart:198`, `ndvi_local_datasource.dart:62`, `clima_local_datasource.dart:77`, `clearUserLocalData` em `database_helper.dart`.
- **[BAIXO]** `ALTER TABLE ADD COLUMN` sem `IF NOT EXISTS` — idempotência via try/catch nas migrações antigas.
- **Delta baseline:** schema avançou de **v33 → v40** desde `SOLOFORTE_BASELINE_REAL.md`.

---

## DIMENSÃO 5 — SEGURANÇA E PRIVACIDADE

**Score: 6/10 | Status: ATENÇÃO**

### Achados

- **[ALTO]** Credenciais demo com default no binário: `lib/ui/screens/login_screen.dart:27–34` — `demo@soloforte.com` / `demo1234` via `String.fromEnvironment(..., defaultValue: ...)`. Comentário “remover antes do release público” ainda presente.
- **[ALTO]** Bootstrap COUNT sem filtro `user_id`: `private_map_bootstrap_screen.dart:20` (`clients`), `:23` (`agenda_events`).
- **[ALTO]** Queries `ndvi_cache` por `field_id` sem `user_id`: `ndvi_local_datasource.dart:13–44` (coluna `user_id` existe no schema v24+).
- **[OK]** `print(` em produção: **0**.
- **[BAIXO]** `debugPrint(`: 3 usos em agenda use cases (`complete_event_use_case.dart:71`, `start_event_use_case.dart:78`, `cancel_event_use_case.dart:82`).
- **[MÉDIO]** Sem `FlutterSecureStorage` no app; sessão via Supabase SDK.
- **[OK]** Secrets tracked: nenhum `.env`, `.jks`, `.p8`, `google-services.json` em `git ls-files`. `.gitignore` cobre `map_secrets.dart`, `.env*`, keys.
- **[OK]** API keys via `--dart-define` com default vazio (`map_config.dart`, `clima_config.dart`).
- **[MÉDIO]** Upserts/sync por `id` apenas (sem `user_id` no WHERE) em alguns sync services — risco residual se IDs colidirem entre usuários.

---

## DIMENSÃO 6 — QUALIDADE DE CÓDIGO

**Score: 8/10 | Status: ATENÇÃO**

### Achados

- **[ALTO]** 1 warning analyze: `occurrence_creation_sheet_ui_helpers.dart:151` — `invalid_use_of_protected_member` (`setState` fora de `State`).
- **[OK]** 0 errors em `flutter analyze lib/`.
- **[BAIXO]** ~20 TODOs; 4 com `TODO(ADR-*)` (rastreáveis) — ex.: `map_ui_providers.dart:47,53,58`, `map_armed_mode_provider.dart:1`.
- **[MÉDIO]** `drawing_sheet_builders_b.dart:493` — TODO com identidade `'SELF'` hardcoded.
- **[BAIXO]** Uso intenso de `Map<String, dynamic>` / casts `as` em fronteiras JSON/DB (~409 `dynamic`, ~1130 `as`) — esperado, mas risco em presentation layers.
- **[OK]** Baseline Jun documentava 0 errors; mantido. Warning novo vs baseline “sem issues novos”.

---

## DIMENSÃO 7 — TESTES

**Score: 7/10 | Status: ATENÇÃO**

### Achados

- **[OK]** Regression Shield presente: 4 arquivos em `test/regression/` cobrindo **BUG-001…005**.
- **[OK]** Sem `expect(true, isTrue)` trivial.
- **[ALTO]** Suite completa: **4 testes falhando** (ver Passo 0) — CI `flutter test --coverage` no job coverage falharia se executado nesta branch.
- **[ALTO]** Rede real em teste: `test/modules/clima/rainviewer_contract_test.dart:25–48` — `HttpClient` live contra RainViewer.
- **[MÉDIO]** SQLite real (FFI) em testes offline: `drawing_local_store_offline_test.dart:41`, `occurrence_repository_offline_test.dart:41`.
- **[OK]** 197 arquivos de teste; maioria Supabase com URL mock.
- **Delta baseline:** baseline Jun — 702 verdes; agora 1167 verdes + 4 falhas (cobertura cresceu, qualidade da suite com regressões).

---

## DIMENSÃO 8 — PERFORMANCE E EXPERIÊNCIA

**Score: 6/10 | Status: ATENÇÃO**

### Achados

- **[MÉDIO]** `setState(`: **~329** ocorrências — hotspots: `novo_case_sheet.dart` (21), `visit_form_dialog.dart` (15), `occurrence_creation_sheet.dart` (13).
- **[OK]** Sem `readAsStringSync` / `writeAsStringSync` em `lib/`.
- **[BAIXO]** `existsSync` / I/O sync em cache tiles e assets: `offline_tile_cache_service.dart:64+`, `ndvi_remote_datasource.dart:128`.
- **[OK]** `Image.network`: **0**; uso de `CachedNetworkImage` / `NetworkImage` (~14).
- **[MÉDIO]** `kFabSafeArea`: **46** usos vs ~98 scrollables (`ListView`/`SingleChildScrollView`/`CustomScrollView`/`GridView`); ~50 arquivos scrolláveis sem padding FAB — risco de conteúdo sob o SmartButton.

---

## DIMENSÃO 9 — ACESSIBILIDADE E UX

**Score: 5/10 | Status: ATENÇÃO**

### Achados

- **[ALTO]** ~166/216 controles `IconButton`/`GestureDetector`/`InkWell` sem `tooltip`/`Semantics` próximos. Amostra: `misc_screens.dart:16`, `publicacao_editor_screen.dart:133`, `edit_profile_screen.dart:79`, `register_page.dart:299`, `occurrence_list_sheet.dart:109`, `client_list_screen.dart:45`, `side_menu_overlay.dart:52`, `camera_button.dart:11`.
- **[ALTO]** ~434 `Text("…")` hardcoded; sem superfície l10n/`.arb` significativa.
- **[MÉDIO]** ~730 `Color(0x…)` fora de theme/palette + uso amplo de `Colors.*` em features (agenda, main, sheets). Parte centralizada em `sheet_tokens.dart` (aceitável).
- **[BAIXO]** Poucos `Semantics(` (~18) no app.

---

## DIMENSÃO 10 — DEPENDÊNCIAS E PUBSPEC

**Score: 7/10 | Status: ATENÇÃO**

### Achados

- **[OK]** Sem duplicatas de stack: só `http` (sem dio); só `sqflite` (sem drift); só Riverpod (sem bloc).
- **[MÉDIO]** Muitos majors desatualizados: `flutter_riverpod` 2.6→3.x, `go_router` 14→17, `flutter_map` 7→8, `geolocator` 13→14, `permission_handler` 11→12, `share_plus` 10→13, etc. (117 packages com versões mais novas incompatíveis).
- **[ALTO]** `SCHEDULE_EXACT_ALARM` em `android/app/src/main/AndroidManifest.xml:11` — Play Console exige declaração de uso justificado.
- **[OK]** `PrivacyInfo.xcprivacy` presente em `ios/Runner/PrivacyInfo.xcprivacy`.
- **[OK]** Info.plist com Location / Camera / PhotoLibrary usage descriptions.
- **[BAIXO]** `NSPrivacyAccessedAPITypes` vazio no PrivacyInfo — pode exigir Required Reason APIs se UserDefaults/file timestamps forem usados.

---

## DIMENSÃO 11 — BUILD E RELEASE

**Score: 8/10 | Status: OK**

### Achados

- **[OK]** `flutter build apk --debug` — **sucesso** (`app-debug.apk`, ~552s Gradle).
- **[OK]** `flutter build ios --no-codesign` — **sucesso** (`Runner.app` 38.0MB, ~62s Xcode).
- **[OK]** Versão consistente: `pubspec.yaml` `1.34.0+181`; iOS `CFBundleVersion=$(FLUTTER_BUILD_NUMBER)`; Android `versionCode`/`versionName` via Flutter Gradle plugin.
- **[ALTO]** Release Android **sem** `isMinifyEnabled` / ProGuard / R8 em `android/app/build.gradle.kts` (`buildTypes.release` só configura signing — linhas 57–67).
- **[MÉDIO]** Sem `key.properties`, release cai para signing debug (fallback documentado no gradle) — risco de upload acidental com debug key.
- **[ALTO]** `SCHEDULE_EXACT_ALARM` (ver Dimensão 10) — impacto Play release.
- **[BAIXO]** Warnings Java source/target 8 obsolete em dependências nativas Android durante o build.

---

## DIMENSÃO 12 — CI/CD E AUTOMAÇÃO

**Score: 7/10 | Status: ATENÇÃO**

### Achados

- **[OK]** Workflow ativo: `.github/workflows/architecture.yml` com jobs: `architecture` (`arch_check`), `ndvi-regression`, `clima-radar-regression`, **`regression-shield`** (`flutter test test/regression/`), `coverage`, `baseline-metrics`.
- **[OK]** Regression Shield no CI: job `Regression Shield (BUG-001–005)` → `flutter test test/regression/ --reporter=compact` (linhas 82–100).
- **[ALTO]** **`flutter analyze` ausente** do workflow `architecture.yml` nesta branch — regressões de analyzer não bloqueiam PR.
- **[MÉDIO]** Job `coverage` roda `flutter test --coverage` completo — falharia hoje pelos 4 testes quebrados.
- **[OK]** Secrets: nenhum arquivo de credencial tracked; `.gitignore` cobre `.env*`, `map_secrets.dart`, keys.
- **[BAIXO]** PR #22 → `main` está CONFLICTING; checks podem não disparar até mergeável (contexto operacional, não gap de YAML).

---

## SCORE GLOBAL E TOTAIS

```
=======================================================
SCORE GLOBAL: 6.9 / 10
CRÍTICOS: 0 | ALTOS: 18 | MÉDIOS: 22 | BAIXOS: 14
=======================================================
```

| Dimensão | Score | Status |
|---|---|---|
| 1 Arquitetura | 9 | OK |
| 2 Navegação | 7 | ATENÇÃO |
| 3 Estado | 7 | ATENÇÃO |
| 4 Persistência | 6 | ATENÇÃO |
| 5 Segurança | 6 | ATENÇÃO |
| 6 Qualidade | 8 | ATENÇÃO |
| 7 Testes | 7 | ATENÇÃO |
| 8 Performance | 6 | ATENÇÃO |
| 9 Acessibilidade | 5 | ATENÇÃO |
| 10 Dependências | 7 | ATENÇÃO |
| 11 Build/Release | 8 | OK |
| 12 CI/CD | 7 | ATENÇÃO |

---

## AÇÕES IMEDIATAS (itens ALTO — prompts cirúrgicos sugeridos)

1. **Remover defaults demo do login** — `login_screen.dart:27–34` (`demo@soloforte.com` / `demo1234`).
2. **Corrigir 4 testes falhando** (layers sheet, side menu produtor, LocalSessionIdentity guard, drawing layers).
3. **Escopar bootstrap COUNTs por `user_id`** — `private_map_bootstrap_screen.dart:20,23`.
4. **Filtrar `ndvi_cache` por `user_id`** — `ndvi_local_datasource.dart`.
5. **Remover FAB local da carteira** — `carteira_screen.dart:321` (usar SmartButton / padrão Map-First).
6. **Adicionar `flutter analyze` no CI** (`architecture.yml`).
7. **Habilitar minify/R8 + ProGuard no release Android** — `build.gradle.kts`.
8. **Justificar ou remover `SCHEDULE_EXACT_ALARM`** no Manifest.
9. **Mockar RainViewer** em `rainviewer_contract_test.dart` (sem rede real).
10. **Normalizar `sync_status`** agenda (`pending`→`pending_sync`) e occurrences (`local`→`local_only`) alinhado a `sync_status_contract.dart`.
11. **Corrigir warning** `occurrence_creation_sheet_ui_helpers.dart:151` (`setState` protegido).
12. **Revisar hard `db.delete` em `occurrence_sync_service.dart`** — preferir soft delete canônico.

---

## BACKLOG DE QUALIDADE (ALTO / MÉDIO)

1. Decompor `drawing_controller.dart` / `drawing_utils.dart` (>900 linhas).
2. Migrar StateNotifier/ChangeNotifier remanescentes para `@riverpod` (ADR-044).
3. Auditar keepAlive sem `registerLogoutInvalidation`.
4. Eliminar AppBars Material onde o DS Map-First exige shell sem AppBar.
5. Expandir `kFabSafeArea` em scrollables de módulo.
6. Plano de a11y: tooltips/Semantics nos ~166 controles sem label.
7. Plano i18n (substituir ~434 `Text("` hardcoded).
8. ADRs para `auth`, `dashboard`, `feedback`, `public`.
9. Unificar ADR-044 duplicado.
10. Avaliar upgrade controlado Riverpod 3 / go_router 17 / flutter_map 8.

---

## RADAR (MÉDIO — próximo sprint)

1. Arquivos 500–900 linhas (46) — prevenir novos god-files.
2. `Navigator.pop` cluster — consolidar em helpers de sheet.
3. `context.go` literais → constantes `AppRoutes`.
4. Volume de `setState` em sheets grandes → Riverpod local.
5. PrivacyInfo `NSPrivacyAccessedAPITypes` vazio — revisar Required Reason APIs.
6. Coverage job: separar gate “must-pass suites” vs coverage ratchet.
7. Documentar justificação de hard deletes de cache.

---

## COMPARAÇÃO COM BASELINE (`SOLOFORTE_BASELINE_REAL.md`)

| Item | Baseline Jun/2026 | Auditoria Jul/2026 |
|---|---|---|
| Schema DB | v33 | **v40** |
| Arquivos `lib/` | 520 | **641** |
| analyze errors | 0 | **0** (1 warning) |
| arch_check | Exit 0 | **Exit 0** |
| Testes verdes | 702 | **1167** (+4 falhas) |
| God-files >900 | 5 monitorados | **2** na whitelist arch_check |
| Regression Shield | ausente | **presente (BUG-001–005 + CI job)** |
| Build number | +111 | **+181** |

---

*Auditoria executada em 2026-07-30 · Prompt AUDITORIA_COMPLETA v1.0 · Zero alteração em código de app · Relatório: `docs/04_AUDITORIAS/AUDITORIA_COMPLETA_v1_2026-07-30.md`*
