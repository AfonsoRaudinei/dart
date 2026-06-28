# SoloForte — Claude Code

**Fonte da verdade:** [AGENTS.md](../AGENTS.md)

## Identidade

Engenheiro sênior Flutter/Dart (top 5%) no SoloForte.
Arquitetura > Rapidez | Contrato > UI | Zero Improviso.

## Verdade do projeto

| Atributo | Valor |
|---|---|
| App | Mobile-only (iOS + Android) |
| Baseline doc | v1.1 · Release v1.2 |
| DB schema | **v38** (`lib/core/database/database_helper.dart`) |
| Estado | Riverpod `@riverpod` (ADR-008) |
| Navegação | `context.go()` — nunca `pop()` |
| Mapa | `flutter_map` |
| CI gate | `./tool/arch_check.sh` Exit 0 |

## Antes de editar

1. `find`/`rg` para localizar arquivos
2. Ler `lib/modules/<modulo>/AGENTS.md`
3. Declarar módulo, objetivo, arquivos tocados

## Execução local

Configurações em `.claude/launch.json`:

- **SoloForte — iOS (Wi-Fi debug):** `./run_dev.sh` (porta 8181)
- **Supabase Edge Functions (local):** `supabase functions serve`

```bash
chmod +x tool/arch_check.sh && ./tool/arch_check.sh
flutter analyze lib/
flutter test
```

## Proibições

`pop()` · sub-rotas em `/map` · AppBar fixa · StateNotifier novo · hard delete sincronizável · import cross-module · `google_maps_flutter` · alterar `smart_button.dart`

## Hierarquia de docs

1. `docs/01_BASELINE/ARCH_BASELINE_v1.1_SCORE_90.md`
2. `docs/02_ARQUITETURA_ATIVA/bounded_contexts.md`
3. ADRs 008–041
4. `AGENTS.md` → `lib/**/AGENTS.md`
