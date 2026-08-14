# Plano de blindagem — Ocorrências no mapa (anti-regressão)

**Status:** ATIVO · **Criado:** Ago/2026 · **Bug origem:** IPA 206 (placeholder sem formulário)  
**Responsável:** qualquer agente que tocar `private_map_screen`, `map_build_orchestrator`, `map_bottom_sheet`, `map_sheet_state`, `map_ui_providers`

> Fonte de verdade: `docs/02_ARQUITETURA_ATIVA/arquitetura-ocorrencias.md`  
> Fluxo resumido: `.agent/IMPLEMENTACAO_OCORRENCIAS_ARMADO.md`

---

## 1. O que não pode regredir (contrato P0)

| ID | Comportamento | Sintoma de regressão |
|---|---|---|
| **OCC-GESTURE-1** | `ArmedMode.occurrences` no tap **antes** de `suppressesMapContextTaps` | Tap no mapa não abre nada com banner visível |
| **OCC-GESTURE-2** | Long press em modo ocorrência → `openOccurrenceSheet`, **não** MarketingCase | Abre sheet de Resultado |
| **OCC-PIN-1** | Coordenada viaja **atomicamente** em `MapSheetState.occurrenceLatitude/Longitude` | Sheet abre sem pin |
| **OCC-PIN-2** | `pendingOccurrenceLocationProvider` **sem** `autoDispose` | Pin perdido entre write e mount do overlay |
| **OCC-PIN-3** | Host resolve pin: `provider ?? sheetState.occurrencePin` | `OccurrenceCreationSheet` não monta |
| **OCC-UI-1** | **Proibido** placeholder "Marque o ponto no mapa" no fluxo armado→tap | Tela intermediária da IPA 206 |
| **OCC-UI-2** | Tap com pin válido → `OccurrenceCreationSheet` expandido | Formulário ausente |

---

## 2. Camadas de defesa (implementadas)

### Camada A — `arch_check.sh` (CI gate)

| Regra | Verificação |
|---|---|
| REGRA-OCC-1..7 | BUG-006 (sheet altura, foto, rascunho, dismiss) — já existente |
| **REGRA-OCC-8** | `MapSheetState` contém `occurrenceLatitude` / `occurrencePin` |
| **REGRA-OCC-9** | `pendingOccurrenceLocationProvider` não é `autoDispose` |
| **REGRA-OCC-10** | Sem placeholder "Marque o ponto no mapa" em `map_bottom_sheet.dart` |
| **REGRA-OCC-11** | Gesture: `ArmedMode.occurrences` antes do guard de desenho no orchestrator |

### Camada B — Testes estáticos (regression shield)

| Arquivo | Cobre |
|---|---|
| `test/regression/map/map_occurrence_gesture_routing_regression_test.dart` | OCC-GESTURE-1/2, pin no sheet state, autoDispose |
| `test/regression/map/occurrence_creation_flow_regression_test.dart` | BUG-006 + OCC-PIN/UI |
| `test/regression/map/occurrence_sheet_regression_test.dart` | `createOccurrence` + `sync_status` |

### Camada C — Testes de widget (quando estáveis)

| Arquivo | Estado |
|---|---|
| `test/ui/components/map/map_bottom_sheet_occurrence_host_test.dart` | Parcial — overflow em `pumpAndSettle` (não bloqueia CI hoje) |

### Camada D — Checklist manual (TestFlight)

1. FAB `+` → **Ocorrência** → banner "Toque no mapa para marcar o ponto"
2. **Tap simples** no mapa → `OccurrenceCreationSheet` com categorias visíveis
3. Salvar → pin no mapa + `local_only`
4. FAB `+` → **Resultado** → long press → MarketingCase (sem regressão)

---

## 3. Arquivos na zona de perigo

Alterar qualquer um destes exige rodar blindagem completa:

```
lib/ui/screens/private_map_screen.dart          → _openOccurrenceSheet, _armOccurrenceMode
lib/ui/screens/map/widgets/map_build_orchestrator.dart → onTap/onLongPress
lib/ui/screens/map/widgets/map_performance_hosts.dart  → MapBottomSheetOverlayHost
lib/ui/components/map/map_sheet_state.dart      → occurrencePin
lib/ui/components/map/map_bottom_sheet.dart       → _buildOccurrenceForm
lib/core/state/map_ui_providers.dart            → pendingOccurrenceLocationProvider
lib/ui/screens/map/providers/map_armed_mode_provider.dart
```

---

## 4. Comando de validação obrigatório

```bash
flutter test test/regression/map/
flutter analyze lib/ui/screens/private_map_screen.dart \
  lib/ui/screens/map/widgets/map_build_orchestrator.dart \
  lib/ui/components/map/map_bottom_sheet.dart \
  lib/core/state/map_ui_providers.dart
./tool/arch_check.sh   # Exit 0 obrigatório
```

---

## 5. Histórico de bugs blindados

| IPA / BUG | Causa | Fix | Regra |
|---|---|---|---|
| BUG-006 | Sheet 350px, foto perdia dados | OccurrenceCloseCoordinator, detent expanded | OCC-1..7 |
| IPA 206 | `autoDispose` perdia pin; placeholder intermediário | Pin em `MapSheetState` + sem placeholder | OCC-8..11 |
| IPA 206 | Gesture bloqueado por desenho | `ArmedMode` antes de `suppressesMapContextTaps` | OCC-GESTURE-1 |

---

## 6. Proibições explícitas para agentes

- ❌ Reintroduzir `_buildOccurrencePinRequiredPlaceholder` ou texto "Marque o ponto no mapa"
- ❌ Marcar `pendingOccurrenceLocationProvider` como `autoDispose`
- ❌ Abrir `isCreatingOccurrence: true` sem `occurrenceLatitude/Longitude` válidos
- ❌ Mover checagem de `ArmedMode` para depois de `suppressesMapContextTaps`
- ❌ Usar docs `.agent/` de Fev/2026 que citam dialog legado ou `setState` local

---

## 7. Próximos passos (backlog blindagem)

- [ ] Widget test estável do fluxo armado→tap→form (sem `pumpAndSettle` em overflow)
- [ ] Integrar `test/regression/map/` no CI GitHub Actions (se ainda não estiver)
- [ ] Golden test do `ArmedModeBanner` + sheet expandido (opcional)
