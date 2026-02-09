# 🎯 PLANO DE AÇÃO PÓS-AUDITORIA SOLOFORTE
**DATA:** 08/02/2026  
**BASE:** AUDITORIA_COMPLETA_SOLOFORTE_2026-02-08.md  
**OBJETIVO:** Elevar SoloForte de "base sólida" para "produto maduro"

---

## 📊 VISÃO GERAL

### Situação Atual
- ✅ Base arquitetural sólida (22 pontos fortes)
- ⚠️ 19 pontos de melhoria identificados
- 🔴 3 itens críticos bloqueando maturidade

### Meta Final
**SoloForte estará maduro quando:**
- ✅ Usuário consegue desenhar talhão sem confusão
- ✅ Usuário sabe quando está sincronizado
- ✅ Usuário resolve conflitos conscientemente
- ✅ Talhão é ferramenta de trabalho, não apenas dado
- ✅ Desenho é núcleo operacional, não feature

### Estratégia
**3 Sprints Focadas** (2 semanas cada) + **Backlog Contínuo**

---

## 🔴 SPRINT 1: NÚCLEO TÉCNICO (2 semanas)
**OBJETIVO:** Elevar Desenho e Talhão a entidades de primeira classe

### 1.1. Elevar Desenho a Módulo Central
**PRIORIDADE:** 🔴 CRÍTICA  
**ESFORÇO:** 5 dias  
**RESPONSÁVEL:** Dev Backend + Dev Frontend

#### Tarefas

##### 1.1.1. Criar Estrutura de Módulo Independente
```bash
# Criar estrutura
mkdir -p lib/modules/drawing/{domain,data,presentation}/{use_cases,models,controllers,widgets}
```

**Arquivos a criar:**
- `lib/modules/drawing/domain/drawing_feature.dart`
- `lib/modules/drawing/domain/drawing_tool.dart` (point, line, polygon, circle)
- `lib/modules/drawing/domain/drawing_state.dart` (idle, drawing, editing, reviewing)
- `lib/modules/drawing/domain/use_cases/start_drawing_use_case.dart`
- `lib/modules/drawing/domain/use_cases/complete_drawing_use_case.dart`
- `lib/modules/drawing/domain/use_cases/edit_geometry_use_case.dart`
- `lib/modules/drawing/domain/use_cases/validate_geometry_use_case.dart`

**Checklist:**
- [ ] Mover `drawing_models.dart` para `/modules/drawing/domain/`
- [ ] Mover `drawing_repository.dart` para `/modules/drawing/data/`
- [ ] Criar use cases para cada operação de desenho
- [ ] Extrair lógica de `drawing_sheet.dart` para controllers
- [ ] Atualizar imports em `private_map_screen.dart`

##### 1.1.2. Implementar Máquina de Estados
**Arquivo:** `lib/modules/drawing/domain/drawing_state_machine.dart`

```dart
enum DrawingState {
  idle,        // Navegação normal do mapa
  armed,       // Ferramenta selecionada, aguardando primeiro ponto
  drawing,     // Desenhando geometria (adicionando pontos)
  reviewing,   // Geometria completa, aguardando confirmação
  editing,     // Editando geometria existente (movendo vértices)
  measuring,   // Medindo área/perímetro
}

class DrawingStateMachine {
  DrawingState _currentState = DrawingState.idle;
  
  // Matriz de transições válidas
  static const _validTransitions = {
    DrawingState.idle: [DrawingState.armed],
    DrawingState.armed: [DrawingState.drawing, DrawingState.idle],
    DrawingState.drawing: [DrawingState.reviewing, DrawingState.idle],
    DrawingState.reviewing: [DrawingState.editing, DrawingState.idle],
    DrawingState.editing: [DrawingState.reviewing, DrawingState.idle],
  };
  
  bool canTransitionTo(DrawingState newState) {
    return _validTransitions[_currentState]?.contains(newState) ?? false;
  }
  
  void transitionTo(DrawingState newState) {
    if (!canTransitionTo(newState)) {
      throw StateError('Invalid transition: $_currentState -> $newState');
    }
    _currentState = newState;
    _notifyListeners();
  }
}
```

**Checklist:**
- [ ] Criar `DrawingStateMachine`
- [ ] Integrar com `DrawingController`
- [ ] Adicionar feedback visual por estado
- [ ] Testar todas as transições

##### 1.1.3. Adicionar Feedback Visual por Estado
**Arquivo:** `lib/modules/drawing/presentation/widgets/drawing_state_indicator.dart`

```dart
class DrawingStateIndicator extends ConsumerWidget {
  Widget build(context, ref) {
    final state = ref.watch(drawingStateProvider);
    
    return AnimatedContainer(
      duration: Duration(milliseconds: 300),
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: _colorForState(state),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_iconForState(state), size: 16, color: Colors.white),
          SizedBox(width: 8),
          Text(_messageForState(state), style: TextStyle(color: Colors.white)),
        ],
      ),
    );
  }
  
  Color _colorForState(DrawingState state) {
    switch (state) {
      case DrawingState.idle: return Colors.grey;
      case DrawingState.armed: return Colors.orange;
      case DrawingState.drawing: return Colors.blue;
      case DrawingState.reviewing: return Colors.green;
      case DrawingState.editing: return Colors.purple;
      case DrawingState.measuring: return Colors.teal;
    }
  }
  
  IconData _iconForState(DrawingState state) {
    switch (state) {
      case DrawingState.idle: return Icons.touch_app;
      case DrawingState.armed: return Icons.my_location;
      case DrawingState.drawing: return Icons.edit_location;
      case DrawingState.reviewing: return Icons.check_circle_outline;
      case DrawingState.editing: return Icons.edit;
      case DrawingState.measuring: return Icons.straighten;
    }
  }
  
  String _messageForState(DrawingState state) {
    switch (state) {
      case DrawingState.idle: return 'Toque no mapa para navegar';
      case DrawingState.armed: return 'Toque para iniciar desenho';
      case DrawingState.drawing: return 'Desenhando... (toque duplo para finalizar)';
      case DrawingState.reviewing: return 'Revisar e confirmar';
      case DrawingState.editing: return 'Editando vértices';
      case DrawingState.measuring: return 'Medindo área';
    }
  }
}
```

**Checklist:**
- [ ] Criar `DrawingStateIndicator`
- [ ] Posicionar no topo do mapa
- [ ] Animar transições de estado
- [ ] Testar em dispositivo real

**ENTREGA SPRINT 1.1:**
- ✅ Módulo `/modules/drawing/` independente
- ✅ Máquina de estados funcionando
- ✅ Feedback visual por estado
- ✅ Use cases testáveis

---

### 1.2. Tornar Talhão Entidade Visual Primária
**PRIORIDADE:** 🔴 CRÍTICA  
**ESFORÇO:** 5 dias  
**RESPONSÁVEL:** Dev Frontend + UX

#### Tarefas

##### 1.2.1. Criar Modelo de Talhão como Entidade Visual
**Arquivo:** `lib/modules/consultoria/fields/domain/field_map_entity.dart`

```dart
enum FieldVisualState {
  idle,        // Cinza claro, não selecionado
  selected,    // Verde destacado, borda grossa
  editing,     // Azul com handles de vértices
  measuring,   // Amarelo com dimensões visíveis
  highlighted, // Pulsando (busca ou filtro)
}

enum FieldInteractionMode {
  view,     // Apenas visualização
  select,   // Pode selecionar
  edit,     // Pode editar geometria
  measure,  // Mostra medidas
  analyze,  // Overlay de dados (NDVI, etc)
}

class FieldMapEntity {
  final String id;
  final String name;
  final GeoJSON geometry;
  final FieldVisualState visualState;
  final FieldInteractionMode interactionMode;
  final double area; // m²
  final String? culture;
  final Color color;
  
  // Comportamentos
  void onTap() {
    // Seleciona talhão
    _transitionTo(FieldVisualState.selected);
    _showFieldBottomSheet();
  }
  
  void onLongPress() {
    // Abre menu contextual
    _showFieldContextMenu();
  }
  
  void onDoubleTap() {
    // Entra em modo edição
    _transitionTo(FieldVisualState.editing);
  }
  
  void onVertexDrag(int vertexIndex, LatLng newPosition) {
    // Move vértice
    _updateGeometry(vertexIndex, newPosition);
  }
}
```

**Checklist:**
- [ ] Criar `FieldMapEntity`
- [ ] Implementar estados visuais
- [ ] Adicionar comportamentos de interação
- [ ] Integrar com `flutter_map`

##### 1.2.2. Implementar Renderização com Estados Visuais
**Arquivo:** `lib/modules/consultoria/fields/presentation/widgets/field_polygon_layer.dart`

```dart
class FieldPolygonLayer extends ConsumerWidget {
  Widget build(context, ref) {
    final fields = ref.watch(fieldsMapEntitiesProvider);
    
    return PolygonLayer(
      polygons: fields.map((field) {
        return Polygon(
          points: field.geometry.coordinates,
          color: _fillColorForState(field.visualState),
          borderColor: _borderColorForState(field.visualState),
          borderStrokeWidth: _borderWidthForState(field.visualState),
          isFilled: true,
          isDotted: field.visualState == FieldVisualState.measuring,
        );
      }).toList(),
    );
  }
  
  Color _fillColorForState(FieldVisualState state) {
    switch (state) {
      case FieldVisualState.idle: 
        return SoloForteColors.greenIOS.withOpacity(0.1);
      case FieldVisualState.selected: 
        return SoloForteColors.greenIOS.withOpacity(0.3);
      case FieldVisualState.editing: 
        return Colors.blue.withOpacity(0.3);
      case FieldVisualState.measuring: 
        return Colors.yellow.withOpacity(0.2);
      case FieldVisualState.highlighted: 
        return SoloForteColors.greenIOS.withOpacity(0.5);
    }
  }
  
  Color _borderColorForState(FieldVisualState state) {
    switch (state) {
      case FieldVisualState.idle: return SoloForteColors.greenIOS;
      case FieldVisualState.selected: return SoloForteColors.greenIOS;
      case FieldVisualState.editing: return Colors.blue;
      case FieldVisualState.measuring: return Colors.yellow;
      case FieldVisualState.highlighted: return SoloForteColors.greenIOS;
    }
  }
  
  double _borderWidthForState(FieldVisualState state) {
    switch (state) {
      case FieldVisualState.idle: return 1.0;
      case FieldVisualState.selected: return 3.0;
      case FieldVisualState.editing: return 2.0;
      case FieldVisualState.measuring: return 2.0;
      case FieldVisualState.highlighted: return 4.0;
    }
  }
}
```

**Checklist:**
- [ ] Criar `FieldPolygonLayer`
- [ ] Implementar cores por estado
- [ ] Adicionar animações de transição
- [ ] Testar performance com 50+ talhões

##### 1.2.3. Adicionar Menu Contextual e Bottom Sheet
**Arquivo:** `lib/modules/consultoria/fields/presentation/widgets/field_context_menu.dart`

```dart
void showFieldContextMenu(BuildContext context, FieldMapEntity field) {
  showModalBottomSheet(
    context: context,
    builder: (_) => Container(
      padding: EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: Icon(Icons.edit, color: SoloForteColors.greenIOS),
            title: Text('Editar Geometria'),
            onTap: () => _startEditingField(field),
          ),
          ListTile(
            leading: Icon(Icons.straighten, color: Colors.blue),
            title: Text('Medir Área'),
            subtitle: Text('${field.area.toStringAsFixed(2)} m²'),
            onTap: () => _showMeasurements(field),
          ),
          ListTile(
            leading: Icon(Icons.add_location, color: Colors.orange),
            title: Text('Adicionar Ocorrência'),
            onTap: () => _createOccurrenceInField(field),
          ),
          ListTile(
            leading: Icon(Icons.history, color: Colors.grey),
            title: Text('Ver Histórico'),
            onTap: () => _showFieldHistory(field),
          ),
          Divider(),
          ListTile(
            leading: Icon(Icons.delete, color: Colors.red),
            title: Text('Excluir Talhão', style: TextStyle(color: Colors.red)),
            onTap: () => _confirmDeleteField(field),
          ),
        ],
      ),
    ),
  );
}
```

**Checklist:**
- [ ] Criar menu contextual
- [ ] Implementar ações (editar, medir, histórico)
- [ ] Adicionar confirmação para exclusão
- [ ] Testar fluxo completo

**ENTREGA SPRINT 1.2:**
- ✅ Talhão como entidade visual de primeira classe
- ✅ Estados visuais implementados
- ✅ Interação direta (tap, long press, double tap)
- ✅ Menu contextual funcional

---

### 1.3. Implementar Sync Orchestration
**PRIORIDADE:** 🔴 CRÍTICA  
**ESFORÇO:** 4 dias  
**RESPONSÁVEL:** Dev Backend

#### Tarefas

##### 1.3.1. Criar Orquestrador de Sync
**Arquivo:** `lib/core/services/sync_orchestrator.dart`

```dart
enum SyncTrigger {
  onAppStart,        // Ao abrir app
  onMapOpen,         // Ao abrir mapa
  onVisitClose,      // Ao fechar visita
  onManualRequest,   // Botão "Sincronizar"
  onConnectivity,    // Ao reconectar
  periodic,          // A cada X minutos
}

enum SyncPriority {
  critical,   // Visitas, Ocorrências críticas
  high,       // Talhões, Clientes
  medium,     // Publicações
  low,        // Logs, Analytics
}

class SyncEntity {
  final String name;
  final SyncPriority priority;
  final Future<void> Function() syncFunction;
  
  const SyncEntity(this.name, this.priority, this.syncFunction);
}

class SyncOrchestrator {
  final Ref _ref;
  final _syncQueue = <SyncEntity>[];
  bool _isSyncing = false;
  
  Future<void> sync(SyncTrigger trigger) async {
    if (_isSyncing) return;
    
    _isSyncing = true;
    _notifySyncStarted();
    
    try {
      // 1. Determinar política baseada no trigger
      final policy = _policyForTrigger(trigger);
      
      // 2. Montar fila priorizada
      final queue = _buildPrioritizedQueue(policy);
      
      // 3. Executar sync com feedback
      for (final entity in queue) {
        await _syncEntity(entity);
      }
      
      _notifySyncCompleted();
    } catch (e) {
      _notifySyncFailed(e);
    } finally {
      _isSyncing = false;
    }
  }
  
  List<SyncEntity> _buildPrioritizedQueue(SyncPolicy policy) {
    final entities = [
      SyncEntity('Visitas', SyncPriority.critical, _syncVisits),
      SyncEntity('Ocorrências', SyncPriority.critical, _syncOccurrences),
      SyncEntity('Talhões', SyncPriority.high, _syncFields),
      SyncEntity('Clientes', SyncPriority.high, _syncClients),
      SyncEntity('Publicações', SyncPriority.medium, _syncPublications),
    ];
    
    // Filtrar e ordenar por prioridade
    return entities
        .where((e) => policy.shouldSync(e))
        .sorted((a, b) => a.priority.index.compareTo(b.priority.index));
  }
  
  Future<void> _syncEntity(SyncEntity entity) async {
    _notifyProgress(entity.name, 0.0);
    
    try {
      await entity.syncFunction();
      _notifyProgress(entity.name, 1.0);
    } catch (e) {
      _notifyEntityFailed(entity.name, e);
    }
  }
}
```

**Checklist:**
- [ ] Criar `SyncOrchestrator`
- [ ] Implementar políticas por trigger
- [ ] Adicionar priorização
- [ ] Integrar com `SyncService` existente

##### 1.3.2. Adicionar Feedback Visual de Sync
**Arquivo:** `lib/ui/components/sync_status_bar.dart`

```dart
enum SyncStatus {
  idle,
  syncing,
  synced,
  offline,
  error,
}

class SyncStatusBar extends ConsumerWidget {
  Widget build(context, ref) {
    final status = ref.watch(syncStatusProvider);
    final progress = ref.watch(syncProgressProvider);
    
    if (status == SyncStatus.idle || status == SyncStatus.synced) {
      return SizedBox.shrink(); // Oculta quando não relevante
    }
    
    return AnimatedContainer(
      duration: Duration(milliseconds: 300),
      height: 40,
      color: _colorForStatus(status),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              _iconForStatus(status),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _messageForStatus(status),
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                    if (status == SyncStatus.syncing && progress != null)
                      LinearProgressIndicator(
                        value: progress,
                        backgroundColor: Colors.white24,
                        valueColor: AlwaysStoppedAnimation(Colors.white),
                      ),
                  ],
                ),
              ),
              if (status == SyncStatus.error)
                TextButton(
                  onPressed: () => ref.read(syncOrchestratorProvider).retry(),
                  child: Text('Tentar Novamente', style: TextStyle(color: Colors.white)),
                ),
            ],
          ),
        ),
      ),
    );
  }
  
  Color _colorForStatus(SyncStatus status) {
    switch (status) {
      case SyncStatus.syncing: return Colors.blue;
      case SyncStatus.offline: return Colors.orange;
      case SyncStatus.error: return Colors.red;
      default: return Colors.green;
    }
  }
  
  Widget _iconForStatus(SyncStatus status) {
    switch (status) {
      case SyncStatus.syncing: 
        return SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation(Colors.white),
          ),
        );
      case SyncStatus.offline: return Icon(Icons.cloud_off, color: Colors.white, size: 16);
      case SyncStatus.error: return Icon(Icons.error, color: Colors.white, size: 16);
      default: return Icon(Icons.check_circle, color: Colors.white, size: 16);
    }
  }
  
  String _messageForStatus(SyncStatus status) {
    switch (status) {
      case SyncStatus.syncing: return 'Sincronizando dados...';
      case SyncStatus.offline: return 'Modo offline - dados serão sincronizados quando conectar';
      case SyncStatus.error: return 'Erro ao sincronizar';
      default: return 'Sincronizado';
    }
  }
}
```

**Checklist:**
- [ ] Criar `SyncStatusBar`
- [ ] Adicionar ao `AppShell`
- [ ] Implementar animações
- [ ] Testar em modo offline

##### 1.3.3. Implementar Resolução de Conflitos Visível
**Arquivo:** `lib/core/services/conflict_resolution_ui.dart`

```dart
class ConflictResolutionDialog extends StatelessWidget {
  final Occurrence localOccurrence;
  final Occurrence remoteOccurrence;
  
  Widget build(context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.warning_amber, color: Colors.orange),
          SizedBox(width: 12),
          Text('Conflito Detectado'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Esta ocorrência foi editada em outro dispositivo.',
            style: TextStyle(fontSize: 14),
          ),
          SizedBox(height: 20),
          _buildVersionComparison(),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => _keepLocal(context),
          child: Text('Manter Minha Versão'),
        ),
        TextButton(
          onPressed: () => _useRemote(context),
          child: Text('Usar Versão Remota'),
        ),
        ElevatedButton(
          onPressed: () => _createBoth(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: SoloForteColors.greenIOS,
          ),
          child: Text('Criar Cópia de Ambas'),
        ),
      ],
    );
  }
  
  Widget _buildVersionComparison() {
    return Row(
      children: [
        Expanded(
          child: _buildVersionCard(
            'Sua Versão',
            localOccurrence,
            Colors.blue,
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: _buildVersionCard(
            'Versão Remota',
            remoteOccurrence,
            Colors.orange,
          ),
        ),
      ],
    );
  }
  
  Widget _buildVersionCard(String title, Occurrence occurrence, Color color) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: color, width: 2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: color)),
          SizedBox(height: 8),
          Text('Tipo: ${occurrence.type}', style: TextStyle(fontSize: 12)),
          Text('Editado: ${_formatDate(occurrence.updatedAt)}', style: TextStyle(fontSize: 12)),
          Text('Descrição: ${occurrence.description}', style: TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}
```

**Checklist:**
- [ ] Criar `ConflictResolutionDialog`
- [ ] Integrar com `SyncOrchestrator`
- [ ] Implementar opções de resolução
- [ ] Testar cenário de conflito real

**ENTREGA SPRINT 1.3:**
- ✅ Sync orchestration com políticas
- ✅ Feedback visual de sync
- ✅ Resolução de conflitos visível
- ✅ Priorização inteligente

---

## 🟡 SPRINT 2: APPLICATION LAYER & TESTES (2 semanas)
**OBJETIVO:** Desacoplar UI de dados e garantir robustez

### 2.1. Adicionar Application Layer (Use Cases)
**PRIORIDADE:** 🟡 IMPORTANTE  
**ESFORÇO:** 5 dias

#### Estrutura de Use Cases

```
lib/modules/consultoria/clients/
  ├── domain/
  │   ├── client.dart
  │   └── use_cases/
  │       ├── get_clients_use_case.dart
  │       ├── get_client_by_id_use_case.dart
  │       ├── save_client_use_case.dart
  │       ├── filter_clients_use_case.dart
  │       └── search_clients_use_case.dart
```

#### Exemplo de Use Case

```dart
// lib/modules/consultoria/clients/domain/use_cases/get_clients_use_case.dart
class GetClientsUseCase {
  final ClientsRepository _repository;
  
  GetClientsUseCase(this._repository);
  
  Future<Result<List<Client>>> execute({
    String? statusFilter,
    String? searchQuery,
  }) async {
    try {
      // 1. Buscar dados
      final clients = await _repository.getClients();
      
      // 2. Aplicar filtros (lógica de negócio aqui)
      var filtered = clients;
      
      if (statusFilter != null && statusFilter != 'Todos') {
        filtered = filtered.where((c) {
          return statusFilter == 'Ativos' ? c.active : !c.active;
        }).toList();
      }
      
      if (searchQuery != null && searchQuery.isNotEmpty) {
        filtered = filtered.where((c) {
          return c.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
                 c.document.contains(searchQuery);
        }).toList();
      }
      
      // 3. Ordenar
      filtered.sort((a, b) => a.name.compareTo(b.name));
      
      return Result.success(filtered);
    } catch (e) {
      return Result.failure(e.toString());
    }
  }
}
```

**Checklist:**
- [ ] Criar use cases para Clientes
- [ ] Criar use cases para Talhões
- [ ] Criar use cases para Ocorrências
- [ ] Refatorar providers para usar use cases
- [ ] Adicionar testes unitários para cada use case

---

### 2.2. Criar Testes de Fluxo Crítico
**PRIORIDADE:** 🟡 IMPORTANTE  
**ESFORÇO:** 5 dias

#### Testes a Implementar

##### 2.2.1. Teste: Login → Mapa → Criar Ocorrência
```dart
// test/integration/create_occurrence_flow_test.dart
void main() {
  testWidgets('User can login and create occurrence', (tester) async {
    // 1. Setup
    await tester.pumpWidget(MyApp());
    
    // 2. Login
    await tester.enterText(find.byKey(Key('email_field')), 'test@test.com');
    await tester.enterText(find.byKey(Key('password_field')), 'password');
    await tester.tap(find.byKey(Key('login_button')));
    await tester.pumpAndSettle();
    
    // 3. Verify map loaded
    expect(find.byType(FlutterMap), findsOneWidget);
    
    // 4. Open occurrence mode
    await tester.tap(find.byIcon(Icons.add_location));
    await tester.pumpAndSettle();
    
    // 5. Tap on map to create occurrence
    await tester.tapAt(Offset(200, 200));
    await tester.pumpAndSettle();
    
    // 6. Fill occurrence form
    await tester.tap(find.text('Doença'));
    await tester.tap(find.text('Alta'));
    await tester.enterText(find.byType(TextField), 'Ferrugem detectada');
    await tester.tap(find.text('Confirmar'));
    await tester.pumpAndSettle();
    
    // 7. Verify occurrence created
    final occurrences = await getOccurrencesFromSQLite();
    expect(occurrences.length, 1);
    expect(occurrences.first.type, 'Doença');
  });
}
```

##### 2.2.2. Teste: Desenho → Salvar → Reabrir
```dart
// test/integration/drawing_persistence_test.dart
void main() {
  testWidgets('Drawing persists after app restart', (tester) async {
    // 1. Create drawing
    await tester.pumpWidget(MyApp());
    await tester.tap(find.byIcon(Icons.draw));
    await tester.tapAt(Offset(100, 100));
    await tester.tapAt(Offset(200, 100));
    await tester.tapAt(Offset(200, 200));
    await tester.tapAt(Offset(100, 200));
    await tester.doubleTapAt(Offset(100, 100)); // Close polygon
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();
    
    // 2. Restart app
    await tester.pumpWidget(Container());
    await tester.pumpWidget(MyApp());
    await tester.pumpAndSettle();
    
    // 3. Verify drawing still visible
    final drawings = await getDrawingsFromSQLite();
    expect(drawings.length, 1);
    expect(drawings.first.geometry.type, 'Polygon');
  });
}
```

##### 2.2.3. Teste: Offline → Criar Dado → Online → Sync
```dart
// test/integration/offline_sync_test.dart
void main() {
  testWidgets('Data syncs after going online', (tester) async {
    // 1. Go offline
    await setConnectivity(false);
    await tester.pumpWidget(MyApp());
    
    // 2. Create occurrence offline
    await createOccurrence(tester, 'Offline occurrence');
    
    // 3. Verify local persistence
    final localOccurrences = await getOccurrencesFromSQLite();
    expect(localOccurrences.length, 1);
    expect(localOccurrences.first.syncStatus, SyncStatus.local_only);
    
    // 4. Go online
    await setConnectivity(true);
    await tester.pump(Duration(seconds: 6)); // Wait for auto-sync
    
    // 5. Verify remote sync
    final remoteOccurrences = await getOccurrencesFromSupabase();
    expect(remoteOccurrences.length, 1);
    
    // 6. Verify local status updated
    final updatedLocal = await getOccurrencesFromSQLite();
    expect(updatedLocal.first.syncStatus, SyncStatus.synced);
  });
}
```

**Checklist:**
- [ ] Implementar 3 testes de integração críticos
- [ ] Configurar CI/CD para rodar testes
- [ ] Adicionar testes de navegação
- [ ] Criar golden tests para componentes visuais

**ENTREGA SPRINT 2:**
- ✅ Use cases implementados para módulos principais
- ✅ 3+ testes de fluxo crítico funcionando
- ✅ CI/CD rodando testes automaticamente
- ✅ Cobertura de código > 60%

---

## 🟡 SPRINT 3: DOCUMENTAÇÃO & POLISH (2 semanas)
**OBJETIVO:** Documentar contratos e melhorar UX

### 3.1. Documentar Contratos Entre Módulos
**PRIORIDADE:** 🟡 IMPORTANTE  
**ESFORÇO:** 3 dias

#### Contratos a Criar

##### Contrato: Dashboard ↔ Consultoria
```markdown
# Contrato: Dashboard ↔ Consultoria

## Dashboard fornece para Consultoria:
- `selectedLocation: LatLng?` (coordenada selecionada no mapa)
- `currentVisitSession: VisitSession?` (sessão ativa)
- `mapBounds: LatLngBounds` (área visível do mapa)

## Consultoria fornece para Dashboard:
- `Client.farms: List<Farm>` (fazendas para overlay)
- `Field.geometry: GeoJSON` (talhões para renderização)
- `Occurrence.geometry: GeoJSON` (ocorrências para pins)

## Regras:
1. Dashboard NUNCA acessa diretamente ClientsRepository
2. Consultoria NUNCA manipula estado do mapa
3. Comunicação via providers específicos
4. Mudanças em geometria disparam evento de atualização

## Providers de Integração:
- `selectedLocationProvider` (Dashboard → Consultoria)
- `fieldsForMapProvider` (Consultoria → Dashboard)
- `occurrencesForMapProvider` (Consultoria → Dashboard)
```

**Checklist:**
- [ ] Criar `docs/contratos/dashboard-consultoria.md`
- [ ] Criar `docs/contratos/mapa-desenho.md`
- [ ] Criar `docs/contratos/sync-persistencia.md`
- [ ] Validar contratos com código existente

---

### 3.2. Refatorar Providers para Composição
**PRIORIDADE:** 🟢 DESEJÁVEL  
**ESFORÇO:** 4 dias

#### Exemplo de Refatoração

```dart
// ❌ ANTES: Provider monolítico
final filteredClientsProvider = Provider.autoDispose<AsyncValue<List<Client>>>((ref) {
  final clientsAsync = ref.watch(clientsListProvider);
  final filter = ref.watch(clientFilterProvider);
  final search = ref.watch(clientSearchProvider).toLowerCase();
  
  return clientsAsync.whenData((clients) {
    return clients.where((c) {
      final matchesSearch = c.name.toLowerCase().contains(search);
      final matchesFilter = /* lógica complexa */;
      return matchesSearch && matchesFilter;
    }).toList();
  });
});

// ✅ DEPOIS: Providers compostos
final clientsListProvider = FutureProvider.autoDispose<List<Client>>((ref) async {
  final useCase = ref.watch(getClientsUseCaseProvider);
  final result = await useCase.execute();
  return result.getOrThrow();
});

final searchFilteredClientsProvider = Provider.autoDispose<List<Client>>((ref) {
  final clients = ref.watch(clientsListProvider).value ?? [];
  final search = ref.watch(clientSearchProvider);
  final useCase = ref.watch(searchClientsUseCaseProvider);
  return useCase.execute(clients, search);
});

final statusFilteredClientsProvider = Provider.autoDispose<List<Client>>((ref) {
  final clients = ref.watch(searchFilteredClientsProvider);
  final filter = ref.watch(clientFilterProvider);
  final useCase = ref.watch(filterClientsUseCaseProvider);
  return useCase.execute(clients, filter);
});

final finalClientsProvider = Provider.autoDispose<List<Client>>((ref) {
  return ref.watch(statusFilteredClientsProvider);
});
```

**Checklist:**
- [ ] Refatorar providers de Clientes
- [ ] Refatorar providers de Talhões
- [ ] Refatorar providers de Ocorrências
- [ ] Adicionar testes para cada provider

**ENTREGA SPRINT 3:**
- ✅ Contratos entre módulos documentados
- ✅ Providers refatorados para composição
- ✅ Overlay policy documentada
- ✅ Glossário técnico criado

---

## 🟢 BACKLOG CONTÍNUO

### Itens para Próximas Iterações

#### B.1. Implementar Overlay Policy
- Documentar z-order de camadas
- Criar constantes de z-index
- Validar em código

#### B.2. Criar Glossário Técnico
- Definir vocabulário único
- Documentar regras de negócio
- Validar com stakeholders

#### B.3. Modularizar Mapa em Subcamadas
- Separar layers (base, fields, occurrences)
- Separar interactions (tap, drag, long press)
- Separar overlays (toolbar, info, measurement)

#### B.4. Adicionar Testes de Regressão Visual
- Golden tests para componentes críticos
- Validação de renderização de mapa
- CI/CD para visual regression

---

## 📊 MÉTRICAS DE SUCESSO

### Sprint 1 (Núcleo Técnico)
- [ ] Módulo `/modules/drawing/` independente criado
- [ ] Máquina de estados de desenho funcionando
- [ ] Talhão com 5 estados visuais implementados
- [ ] Menu contextual de talhão funcional
- [ ] Sync orchestration com 3 políticas
- [ ] Feedback visual de sync visível

### Sprint 2 (Application Layer & Testes)
- [ ] 10+ use cases implementados
- [ ] 3+ testes de integração passando
- [ ] Cobertura de código > 60%
- [ ] CI/CD rodando testes

### Sprint 3 (Documentação & Polish)
- [ ] 3 contratos entre módulos documentados
- [ ] Providers refatorados em 3 módulos
- [ ] Overlay policy documentada
- [ ] Glossário técnico com 20+ termos

### Métrica Final de Maturidade
- [ ] Usuário desenha talhão sem confusão (UX test)
- [ ] Usuário sabe quando está sincronizado (feedback visual)
- [ ] Usuário resolve conflitos conscientemente (UI de resolução)
- [ ] Talhão é ferramenta de trabalho (interação rica)
- [ ] Desenho é núcleo operacional (módulo independente)

---

## 🚀 PRÓXIMOS PASSOS IMEDIATOS

### Semana 1 (Dias 1-5)
1. **Dia 1-2:** Criar estrutura `/modules/drawing/`
2. **Dia 3:** Implementar `DrawingStateMachine`
3. **Dia 4:** Adicionar `DrawingStateIndicator`
4. **Dia 5:** Testar e validar módulo de desenho

### Semana 2 (Dias 6-10)
1. **Dia 6-7:** Criar `FieldMapEntity` e estados visuais
2. **Dia 8:** Implementar `FieldPolygonLayer`
3. **Dia 9:** Adicionar menu contextual de talhão
4. **Dia 10:** Testar e validar talhão como entidade primária

### Semana 3 (Dias 11-14)
1. **Dia 11-12:** Criar `SyncOrchestrator`
2. **Dia 13:** Implementar `SyncStatusBar`
3. **Dia 14:** Adicionar `ConflictResolutionDialog`

---

## ✅ CHECKLIST DE VALIDAÇÃO FINAL

Antes de considerar o plano completo, validar:

- [ ] Todos os arquivos críticos foram criados
- [ ] Testes de integração estão passando
- [ ] Documentação está atualizada
- [ ] Contratos foram validados com código
- [ ] UX foi testada com usuário real
- [ ] Performance foi medida (50+ talhões no mapa)
- [ ] Sync foi testado em cenário offline real
- [ ] Conflitos foram testados com 2 dispositivos

---

**FIM DO PLANO DE AÇÃO**  
**Próxima Ação:** Iniciar Sprint 1, Tarefa 1.1.1 (Criar estrutura `/modules/drawing/`)
