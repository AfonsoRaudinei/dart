# SoloForte — Copilot Instructions

**Fonte da verdade:** [AGENTS.md](../AGENTS.md) — em conflito, AGENTS.md vence.

**App:** SoloForte — agri-tech, Flutter/Dart, **mobile-only** (iOS + Android).  
**Baseline doc:** v1.1 | **Release:** v1.2 | **DB Schema:** v38 | **ADRs:** 008–041  
macOS é só para dev/testes. Web, Windows e Linux **não existem** neste projeto.

---

## Arquitetura

Clean Architecture + Bounded Contexts + Map-First.

```
lib/
  core/       ← infraestrutura pura (database, network, router, contracts)
  modules/    ← domínios de negócio
  app/        ← composição (tema, providers globais)
  ui/         ← componentes compartilhados
```

**Bounded contexts:** `core` · `ui` · `map` · `drawing` · `agenda` · `agenda_ai` · `operacao` · `consultoria` · `visitas` · `settings` · `auth` · `planos` · `produtor` · `carteira` · `ndvi` · `marketing` · `feedback` · `dashboard` · `public` · `clima`

### Fronteiras (`tool/arch_check.sh`)

- `core/**` → **NÃO importa** `modules/**` (exceção: `core/router/app_router.dart`)
- Módulos **NÃO importam uns aos outros** — só via `core/contracts/`
- Proibidos: `drawing→consultoria`, `agenda→consultoria`, `consultoria→drawing`, `visitas→consultoria/drawing`

Contratos: ver tabela completa em [AGENTS.md](../AGENTS.md#fronteras-entre-módulos).

---

## Estado — Riverpod (ADR-008)

Codegen `@riverpod`. Nunca criar `StateNotifier` ou `ChangeNotifier` novos.

---

## Navegação — Map-First

- `/map` é raiz após login
- Retorno: `context.go('/map')` — **nunca** `pop()`
- Um FAB (`SmartButton`); sem AppBar fixa
- Sem sub-rotas em `/map` — modos são estado interno

Rotas: [app_routes.dart](../lib/core/router/app_routes.dart)

---

## Persistência — Offline-First

SQLite = fonte da verdade. `sync_status`: `local_only | pending_sync | synced | sync_error | deleted_local`  
Hard delete só com `sync_status == 'local_only'`. Schema v38 em `database_helper.dart`.

---

## Mapa

`flutter_map` — nunca `google_maps_flutter`.

---

## Supabase / Backend

Edge Functions: `delete-user`, `ndvi-fetch`, `agenda-ai-recommend`, `mercadopago-criar-preferencia`, `mercadopago-webhook`, `ingest-soil-analysis`

---

## Workflow

1. `find lib/ -name "arquivo.dart"` — confirmar caminho
2. Declarar módulo, bounded context, objetivo, arquivos
3. Ler `lib/modules/<modulo>/AGENTS.md`

```bash
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs  # se @riverpod novo
flutter test
./tool/arch_check.sh
flutter run -d <device>   # ou ./run_dev.sh (iOS Wi-Fi)
```

CI: `arch_check.sh` + coverage mínimo **36.46%** (`.github/workflows/architecture.yml`).

---

## Proibições

`pop()` · AppBar fixa · StateNotifier novo · hard delete sincronizável · import cross-module · sub-rotas em `/map` · dados fictícios · refatoração oportunista · `google_maps_flutter`

---

## Hierarquia de docs

1. `docs/01_BASELINE/ARCH_BASELINE_v1.1_SCORE_90.md`
2. `docs/02_ARQUITETURA_ATIVA/bounded_contexts.md`
3. ADRs em `docs/02_ARQUITETURA_ATIVA/`
4. `AGENTS.md`
5. `lib/**/AGENTS.md` do módulo
