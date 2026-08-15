# AGENTS.md — map

## Bounded context

`map/` e a **projecao agregadora espacial em camada leve**: adapters, providers/observers e widgets de visita ainda colocados aqui.

**Politica 4A (Ago/2026):** o **host UI Map-First** (chrome, layers, overlays, `private_map_screen`) vive em `lib/ui/` — **nao** neste modulo. Ver `AGENTS.md` (raiz) e `lib/ui/AGENTS.md`.

## O que pertence a `modules/map/`

| Tipo | Exemplos |
|---|---|
| Domain / adapter | `domain/field_map_adapter.dart` → `core/domain/field_map_entity.dart` |
| Providers finos | `map_location_mode_provider`, `visit_completion_observer` |
| Widgets de visita (legado colocalizado) | `visit_sheet.dart`, `visit_active_card.dart` |

## O que **nao** pertence aqui

- Coluna direita / `map_controls_overlay` → `lib/ui/components/map/`
- MapBottomSheet / layers / tools sheets → `lib/ui/components/map/`
- Orchestrator / handlers da tela mapa → `lib/ui/screens/map/`
- Migracao em massa `ui/ → modules/map/` (= **4B**) sem ADR + aprovacao explicita

## Contratos e dependencias

- Pode depender de outros modulos quando a ADR permitir.
- Deve preferir contratos em `core/contracts/` para fronteiras sensiveis.
- Ninguem deve depender de `map/` (outros bounded contexts).
- Entidade visual unificada: `lib/core/domain/field_map_entity.dart`
  (`FieldMapAdapter` converte; **nao** recriar a entidade em `map/domain/`).

## Proibido

- Criar sub-rotas sob `/map`; `/map` e singleton.
- Usar `google_maps_flutter`; o mapa oficial e `flutter_map`.
- Criar FAB local ou alterar o SmartButton.
- Fazer outro modulo de dominio importar `modules/map`.
- Criar bottom sheet fora do padrão global.
- Assumir que “bug do mapa” = editar so `modules/map/` — checar `lib/ui/` primeiro.

## Padrão de bottom sheets

- Usar `showSoloForteSheet` de `lib/core/ui/sheets/soloforte_sheet.dart`.
- Usar `SoloForteSheetTokens` de `lib/core/ui/sheets/sheet_tokens.dart` para fundo, texto, inputs e divisores.
- Não duplicar handle, título, botão de fechar ou criar controles claros/brancos dentro de sheets escuros.

## Qualidade obrigatoria

- Contextos do mapa sao estado interno, nao rotas.
- Camadas devem ser isoladas, previsiveis e sem recomposicao desnecessaria.
- Testes esperados: testes de mapa em `test/ui/components/map/` e modulo afetado.
- Rodar `flutter analyze lib/modules/map/` e `./tool/arch_check.sh`.

## Coluna direita — REGRA-MAP-CHROME-1

Implementacao em **`lib/ui/`** (nao neste modulo):

- Posicao travada: `kMapActionColumnBottomInset` + `safeBottom` — **nunca** `mapSheetChromeInsetProvider`
- Gaps canonicos: 26dp (camadas↔+) · 16dp (+↔check-in)
- Teste: `flutter test test/regression/map/controls_overlay_regression_test.dart`
- Doc: `.agent/Prompt.md`

## Sheets do mapa — REGRA-SHEET-BLAST-1

MapBottomSheet (em `lib/ui/`) usa SheetSkin iOS no tema Azul. Mudanca em `core/ui/sheets/` e transversal — ver `.agent/AUDITORIA_REGRESSAO_IPA210.md`.
