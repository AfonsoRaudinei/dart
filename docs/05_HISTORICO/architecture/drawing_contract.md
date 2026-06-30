# Golden Contract — DrawingController
> Versão: 1.0 · Data: 2026-02-22 · Fase: C (Decomposição)  
> **Este documento é o checklist de regressão. Qualquer mudança de comportamento = BLOQUEIO.**

---

## 1. Responsabilidades (7 bounded concerns)

| # | Concern | Delegado para (pós C3) |
|---|---|---|
| 1 | Máquina de estados (idle→armed→drawing→confirmed) | `DrawingStateMachine` (já existia) |
| 2 | CRUD de `DrawingFeature` (add/update/delete/restore/group/properties) | `DrawingFeatureCrudService` |
| 3 | Edição de vértices (move/insert/remove/undo) | `DrawingVertexEditService` |
| 4 | Import de arquivo KML/KMZ | `DrawingImportService` + `IFilePicker` |
| 5 | Operações booleanas geométricas (union/difference/intersection) | `DrawingBooleanOpsService` |
| 6 | Bridge Cliente/Fazenda (load/create) | `DrawingClientFarmBridgeService` |
| 7 | Sincronização remota | `IDrawingRepository.sync()` |

**O `DrawingController` vira fachada**: mantém estado (`_features`, `_selectedFeature`, `_interactionMode`, etc.) + `notifyListeners()`. Toda lógica pura delega para services.

---

## 2. Contrato Externo — Métodos Públicos (API CONGELADA)

### 2.1 Getters (read-only, sem side-effects)

| Getter | Tipo de Retorno | Observação |
|---|---|---|
| `features` | `List<DrawingFeature>` | `List.unmodifiable` |
| `selectedFeature` | `DrawingFeature?` | null se nenhum selecionado |
| `clients` | `List<Client>` | `List.unmodifiable` |
| `farms` | `List<Farm>` | `List.unmodifiable` |
| `currentState` | `DrawingState` | Da state machine |
| `currentTool` | `DrawingTool` | Da state machine |
| `booleanOperation` | `BooleanOperationType` | Da state machine |
| `interactionMode` | `DrawingInteraction` | Legacy getter |
| `liveGeometry` | `DrawingGeometry?` | Computado: edit / preview / sketch |
| `liveAreaHa` | `double` | 0.0 se sem geometria |
| `livePerimeterKm` | `double` | 0.0 se sem geometria |
| `liveSegmentsKm` | `List<double>` | Vazio se sem geometria |
| `instructionText` | `String` | Texto para tooltip |
| `isDirty` | `bool` | true se há alterações não salvas |
| `errorMessage` | `String?` | null se sem erro |
| `validationResult` | `DrawingValidationResult` | Resultado da última validação |
| `pendingFeatureA` | `DrawingFeature?` | Para ops booleanas |
| `pendingFeatureB` | `DrawingFeature?` | Para ops booleanas |
| `previewGeometry` | `DrawingGeometry?` | Preview de import ou boolean |
| `pendingSyncCount` | `int` | Features com syncStatus != synced |
| `isHighComplexity` | `bool` | > 2000 vértices |
| `isDraggingVertex` | `bool` | true durante drag |
| `draggedVertexIndex` | `int?` | índice do vértice arrastado |
| `groups` | `List<String>` | Lista de grupos |

### 2.2 Métodos de Comando

| Método | Parâmetros | Estado Final | Side-effects |
|---|---|---|---|
| `loadFeatures()` | — | `_features` atualizado | `_repository.getAllFeatures()` |
| `syncFeatures()` | — | `_errorMessage` atualizado se erro | `_repository.sync()` |
| `loadClients()` | — | `_clients` atualizado | `clientsRepo.getClients()` |
| `loadFarms(clientId)` | `String clientId` | `_farms` atualizado | `clientsRepo.getFarms()` |
| `createFarm(name, clientId, city, state)` | 4 strings | `_farms` recarregado | `clientsRepo.saveFarm()` |
| `addFeature({...})` | geometry + nome + tipo + origem + autorId + autorTipo + opcionais | `_features` +1, `_selectedFeature` = novo, `_isDirty` = true, state = idle | `_repository.saveFeature()` |
| `updateFeature(id, {...})` | id + opcionais | `_features[i]` atualizado, `_selectedFeature` = atualizado | `_repository.saveFeature()` (2x se versão) |
| `selectFeature(feature?)` | `DrawingFeature?` | `_selectedFeature` atualizado | Nenhum |
| `deleteFeature(id)` | `String id` | `_features` -1, `_selectedFeature` = null se era o deletado | `_repository.deleteFeature()` |
| `restoreFeature(feature)` | `DrawingFeature` | `_features` +1 se não existia | `_repository.saveFeature()` |
| `selectTool(toolKey)` | `String` | state = armed (ou idle se 'none') | Nenhum |
| `appendDrawingPoint(point)` | `LatLng` | `_currentPoints` +1, state = drawing | Nenhum |
| `updateManualSketch(geometry?)` | `DrawingGeometry?` | `_manualSketch` atualizado | Nenhum |
| `cancelOperation()` | — | state = idle, tudo limpo | Nenhum |
| `clearError()` | — | `_errorMessage` = null | Nenhum |
| `validateGeometry(g, {forceFull})` | `DrawingGeometry?` | `_validationResult` atualizado | Nenhum |
| `startEditMode()` | — | mode = editing, `_editGeometry` clonado, `_undoStack` reset | Nenhum |
| `cancelEdit()` | — | mode = normal, `_editGeometry` = null | Nenhum |
| `saveEdit()` | — | Chama `updateFeature()` + `cancelEdit()` | `_repository.saveFeature()` |
| `undoEdit()` | — | `_editGeometry` = topo anterior do stack | Nenhum |
| `moveVertex(ri, pi, pos)` | ringIndex, pointIndex, LatLng | `_editGeometry` atualizado | Nenhum (debounce validate) |
| `onDragStart([index?])` | `int?` | `_isDraggingVertex` = true, snapshot no undo stack | Nenhum |
| `onDragEnd()` | — | `_isDraggingVertex` = false | `_repository.saveFeature()` (se editando) |
| `insertVertex(ri, si, point)` | ringIndex, segmentIndex, LatLng | `_editGeometry` +1 vértice | Nenhum |
| `removeVertex(ri, pi)` | ringIndex, pointIndex | `_editGeometry` -1 vértice (mín 4 pontos) | Nenhum |
| `completeDrawing()` | — | state = confirmed | Nenhum |
| `updateFeatureProperties(id, {grupo, cor})` | id + opcionais | `_features[i].properties` atualizado | Nenhum |
| `createGroup(name)` | `String name` | `_groups` +1 se não existia | Nenhum |
| `startImportMode()` | — | mode = importing, erro limpo | Nenhum |
| `pickImportFile(isKmz)` | `bool` | preview geometry ou erro | `IFilePicker.pickSingleFile()` |
| `startUnionMode()` | — | mode = unionSelection | Nenhum |
| `startDifferenceMode()` | — | mode = differenceSelection | Nenhum |
| `startIntersectionMode()` | — | mode = intersectionSelection | Nenhum |
| `onFeatureTapped(feature)` | `DrawingFeature` | seleciona ou calcula boolean op | Nenhum |
| `confirmBooleanOp()` | — | aplica resultado, chama `cancelOperation()` | `_repository.saveFeature()` |
| `confirmImport()` | — | chama `addFeature()`, chama `cancelOperation()` | `_repository.saveFeature()` |
| `findFeatureAt(point)` | `LatLng` | retorna feature ou null | Nenhum |

---

## 3. Dependências (pré vs pós C1–C3)

| Dependência | Pré C1 | Pós C1 | Testável? |
|---|---|---|---|
| `DrawingRepository` | Concreto | `IDrawingRepository` | ✅ sim |
| `ClientsRepository` | Concreto | `IClientsRepository` | ✅ sim |
| `FilePicker.platform` | Hardcoded | `IFilePicker` | ✅ sim |
| `DrawingStateMachine` | Concreto interno | Concreto (sem I/O) | ✅ já era |
| `DrawingUtils` | Static | Static | ⚠️ indireto |

---

## 4. Invariantes Críticas (NUNCA violar)

1. **Fechamento do polígono**: todo ring deve ter `first == last` (ou manter o original).
2. **Mínimo de 4 pontos** para um ring válido (triângulo + fechamento).
3. **`addFeature()` sempre valida** antes de persistir.
4. **`saveEdit()` usa `forceFull: true`** (validação completa, não simplificada).
5. **`onDragEnd()` persiste** se `_editGeometry != null && _selectedFeature != null`.
6. **`selectTool()` bloqueia** mudança de ferramenta quando `state == drawing`.
7. **`undoEdit()` requer** `_undoStack.length > 1` (mantém estado base).
8. **Undo stack máximo: 20 entradas** (evita memory leak).

---

## 5. Checklist de Regressão (rodar após qualquer mudança)

```
[ ] flutter analyze → zero erros em lib/
[ ] bash tool/arch_check.sh → exit 0
[ ] flutter test test/modules/drawing/ → todos passam
[ ] selectTool('polygon') → state = armed
[ ] appendDrawingPoint(LatLng) → state = drawing
[ ] cancelOperation() → state = idle
[ ] addFeature() com geometria inválida → _errorMessage != null, _features não cresce
[ ] saveEdit() com geometria inválida → não persiste
[ ] undoEdit() com stack vazio → não crasha
[ ] removeVertex() com ring de 4 pontos → _errorMessage definido, geometria não muda
[ ] pickImportFile() com arquivo inválido → _errorMessage definido
[ ] confirmBooleanOp() sem previewGeometry → no-op
```
