# Fluxo armado de ocorrências no mapa

**Status:** ATIVO · **Atualizado:** Ago/2026 · **IPA alvo:** 207+

> Fonte de verdade arquitetural: `docs/02_ARQUITETURA_ATIVA/arquitetura-ocorrencias.md`

---

## Fluxo oficial (Map-First)

```
Ícone + (ações) → PublicationActionsBottomSheet
  → Ocorrência
  → armedModeProvider = ArmedMode.occurrences
  → ArmedModeBanner: "Toque no mapa para marcar o ponto"

Tap simples no mapa (ArmedMode.occurrences)
  → map_build_orchestrator.onTap
  → private_map_screen._openOccurrenceSheet(lat, lng)
  → MapSheetState(occurrences, isCreatingOccurrence, occurrenceLatitude/Longitude)
  → MapBottomSheet → OccurrenceCreationSheet
```

**Proibido neste fluxo:** tela intermediária "Marque o ponto no mapa" (removida Ago/2026).

---

## Arquivos principais

| Papel | Arquivo |
|---|---|
| Modo armado | `lib/ui/screens/map/providers/map_armed_mode_provider.dart` |
| Dispatcher tap | `lib/ui/screens/map/widgets/map_build_orchestrator.dart` |
| Abrir sheet | `lib/ui/screens/private_map_screen.dart` → `_openOccurrenceSheet` |
| Estado sheet + pin | `lib/ui/components/map/map_sheet_state.dart` |
| Pin efêmero | `lib/core/state/map_ui_providers.dart` → `pendingOccurrenceLocationProvider` |
| Formulário | `lib/modules/consultoria/occurrences/presentation/widgets/occurrence_creation_sheet.dart` |
| Menu ações | `lib/ui/components/map/widgets/publication_actions_bottom_sheet.dart` |

---

## Regras de gesto

1. `ArmedMode.occurrences` e `ArmedMode.marketing` têm **prioridade** sobre `suppressesMapContextTaps`.
2. Long press em modo ocorrência reutiliza `openOccurrenceSheet` (não abre MarketingCase).
3. `_armOccurrenceMode` cancela desenho bloqueante e fecha `MapSheetType.draw` se aberto.

---

## Contrato de coordenada

- Pin viaja **atomicamente** em `MapSheetState.occurrenceLatitude/Longitude` (`occurrencePin` getter).
- `pendingOccurrenceLocationProvider` é espelho para rascunho keyed — **sem** `autoDispose`.
- Sem pin válido → sheet de criação **não** abre (fecha imediatamente).

---

## Testes de regressão

- `test/regression/map/map_occurrence_gesture_routing_regression_test.dart`
- `test/ui/components/map/map_bottom_sheet_occurrence_host_test.dart`
- `test/regression/map/occurrence_sheet_regression_test.dart`
