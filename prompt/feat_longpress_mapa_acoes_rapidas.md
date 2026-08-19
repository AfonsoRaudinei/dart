# PROMPT — FEATURE: Long Press no Mapa → Ações Rápidas

**Agente:** Engenheiro Sênior Flutter/Dart  
**Data:** Ago/2026  
**Branch:** `cursor/longpress-acoes-rapidas-mapa`  
**Status:** 100% (revisão aprovada) — QA físico pendente antes do merge em `main`

---

## Objetivo

Substituir o botão `+` da coluna direita do mapa pelo gesto de **long press em área vazia**, abrindo `PublicationActionsBottomSheet` (Resultado, Antes/Depois, Avaliação, Ocorrência), com hint progressivo e `AbsorbPointer` enquanto o sheet estiver aberto.

## Arquivos tocados

- `lib/ui/screens/private_map_screen.dart`
- `lib/ui/screens/map/widgets/map_build_orchestrator.dart`
- `lib/ui/components/map/widgets/map_controls_overlay.dart`
- `lib/ui/components/map/widgets/map_long_press_hint.dart`
- `lib/ui/screens/map/utils/map_empty_area_hit_test.dart`
- `lib/ui/screens/map/utils/map_long_press_prefs.dart`
- `lib/core/constants/layout_constants.dart`

## Regras

- Long press só em área vazia (hit-test pin/talhão/desenho/ocorrência)
- `DrawingController.suppressesMapContextTaps` respeitado; DrawingController não alterado
- Preferência `map_longpress_used_at` via `PreferencesService` existente
- `MapActionFabMenu` permanece no repo; não montado no overlay
- Sem merge em `main` até QA físico dos 10 cenários

## Preferência

- Chave: `map_longpress_used_at` (ISO8601)
- Helpers: `hasUsedMapLongPress` / `markMapLongPressUsed`

## QA físico (obrigatório antes do merge)

1. Primeiro acesso → hint 3s  
2. Long press área vazia → sheet  
3. Reabrir app → sem hint  
4. Modo desenho → gesto ignorado  
5. Long press em pin → sem sheet  
6. Sheet aberto → mapa bloqueado  
7. Fechar sheet → mapa ok  
8. Botão `+` ausente  
9. Press curto → sem sheet  
10. Landscape → hint ok  
