# CONTRATO DO MÓDULO DE DESENHO
**STATUS:** Ativo  
**VERSÃO:** 1.0  
**DATA:** 09/02/2026

---

## 1. VISÃO GERAL

O módulo de Desenho (`/modules/drawing/`) é um **módulo técnico independente** responsável por toda a lógica de criação, edição e manipulação de geometrias geoespaciais no SoloForte.

### 1.1. Princípio Fundamental
> **"Desenho é um módulo técnico central, não uma feature do mapa."**

O módulo é:
- ✅ Independente (não acoplado ao mapa)
- ✅ Reutilizável (pode ser usado em outros contextos)
- ✅ Testável (lógica isolada)
- ✅ Stateful (gerencia seu próprio estado via máquina de estados)

---

## 2. ARQUITETURA INTERNA

```
lib/modules/drawing/
├── domain/
│   ├── drawing_state.dart          # Máquina de estados
│   ├── models/
│   │   ├── drawing_feature.dart    # Feature GeoJSON
│   │   ├── drawing_geometry.dart   # Geometrias (Polygon, MultiPolygon)
│   │   └── drawing_properties.dart # Metadados
│   └── use_cases/
│       ├── start_drawing_use_case.dart
│       ├── complete_drawing_use_case.dart
│       ├── edit_geometry_use_case.dart
│       └── validate_geometry_use_case.dart
├── data/
│   ├── repositories/
│   │   ├── drawing_repository.dart      # Interface
│   │   └── drawing_repository_impl.dart # Implementação
│   └── data_sources/
│       ├── drawing_local_store.dart     # SQLite
│       └── drawing_remote_store.dart    # Supabase
└── presentation/
    ├── controllers/
    │   └── drawing_controller.dart      # Controller principal
    └── widgets/
        ├── drawing_state_indicator.dart # Feedback visual
        ├── drawing_toolbar.dart         # Ferramentas
        └── geometry_editor.dart         # Editor de vértices
```

---

## 3. INTERFACE PÚBLICA

### 3.1. Estados (DrawingState)

```dart
enum DrawingState {
  idle,              // Navegação normal
  armed,             // Ferramenta selecionada
  drawing,           // Adicionando pontos
  reviewing,         // Aguardando confirmação
  editing,           // Editando vértices
  measuring,         // Medindo área
  importPreview,     // Visualizando importação
  booleanOperation,  // Operações booleanas
}
```

### 3.2. Ferramentas (DrawingTool)

```dart
enum DrawingTool {
  none,
  polygon,    // Polígono manual
  freehand,   // Desenho livre
  pivot,      // Pivô circular
  rectangle,  // Retângulo
  circle,     // Círculo
}
```

### 3.3. Operações Booleanas (BooleanOperationType)

```dart
enum BooleanOperationType {
  none,
  union,         // Unir áreas (A + B)
  difference,    // Subtrair (A - B)
  intersection,  // Interseção (A ∩ B)
}
```

---

## 4. INTEGRAÇÃO COM O MAPA

### 4.1. O Mapa Fornece para Drawing:

```dart
// Coordenadas onde o usuário tocou
LatLng tapCoordinate;

// Callback para atualizar renderização
void Function(List<DrawingFeature> features) onFeaturesUpdated;

// Callback para eventos de mapa
void Function(DrawingMapEvent event) onMapEvent;
```

### 4.2. Drawing Fornece para o Mapa:

```dart
// Features para renderização
Stream<List<DrawingFeature>> get features;

// Estado atual (para UI)
DrawingState get currentState;

// Ferramenta atual (para cursor/ícones)
DrawingTool get currentTool;

// Notificações de mudança
void addListener(VoidCallback listener);
```

---

## 5. MÁQUINA DE ESTADOS

### 5.1. Transições Válidas

```
idle ──────────────────┐
  │                    │
  ├→ armed ───→ drawing ───→ reviewing ───→ editing
  │                              │              │
  ├→ importPreview ──────────────┤              │
  │                              │              │
  └──────────────────────────────┴──────────────┘
                                 │
                                 ├→ booleanOperation
                                 │       │
                                 └───────┘
```

### 5.2. Regras de Transição

- ✅ **idle → armed**: Selecionar ferramenta
- ✅ **armed → drawing**: Primeiro ponto adicionado
- ✅ **drawing → reviewing**: Geometria completa (duplo toque ou fechar polígono)
- ✅ **reviewing → editing**: Usuário clica "Editar"
- ✅ **editing → reviewing**: Salvar edição
- ✅ **reviewing → booleanOperation**: Iniciar operação (unir, subtrair, etc)
- ✅ **booleanOperation → reviewing**: Operação confirmada
- ✅ **Qualquer → idle**: Cancelar ou confirmar

❌ **Proibido:**
- idle → drawing (sem passar por armed)
- drawing → editing (sem passar por reviewing)
- armed → reviewing (sem desenhar)

---

## 6. USE CASES

### 6.1. StartDrawingUseCase

```dart
class StartDrawingUseCase {
  Future<Result<void>> execute(DrawingTool tool) async {
    // 1. Validar ferramenta
    // 2. Transicionar estado para 'armed'
    // 3. Preparar listeners de mapa
    // 4. Retornar sucesso/erro
  }
}
```

### 6.2. CompleteDrawingUseCase

```dart
class CompleteDrawingUseCase {
  Future<Result<DrawingFeature>> execute(List<LatLng> points) async {
    // 1. Validar geometria (mínimo 3 pontos)
    // 2. Converter para GeoJSON
    // 3. Calcular área e perímetro
    // 4. Criar DrawingFeature
    // 5. Transicionar para 'reviewing'
    // 6. Retornar feature
  }
}
```

### 6.3. EditGeometryUseCase

```dart
class EditGeometryUseCase {
  Future<Result<DrawingFeature>> execute({
    required String featureId,
    required List<LatLng> newCoordinates,
  }) async {
    // 1. Buscar feature original
    // 2. Validar novas coordenadas
    // 3. Criar nova versão (versionamento)
    // 4. Calcular nova área
    // 5. Marcar para sync
    // 6. Retornar feature atualizada
  }
}
```

### 6.4. ValidateGeometryUseCase

```dart
class ValidateGeometryUseCase {
  Result<bool> execute(DrawingGeometry geometry) {
    // 1. Verificar se é GeoJSON válido
    // 2. Verificar self-intersections
    // 3. Verificar área mínima
    // 4. Verificar número de vértices
    // 5. Retornar validação + mensagens
  }
}
```

---

## 7. PERSISTÊNCIA

### 7.1. Estados de Sincronização

Cada `DrawingFeature` tem um `syncStatus`:

```dart
enum SyncStatus {
  local_only,    // Criado localmente, nunca enviado
  pending_sync,  // Modificado, aguardando envio
  synced,        // Sincronizado com backend
  conflict,      // Conflito detectado
}
```

### 7.2. Fluxo de Dados

```
[Usuário desenha]
      ↓
[DrawingController]
      ↓
[Use Case: CompleteDrawing]
      ↓
[DrawingRepository.save()]
      ↓
[SQLite (local_only)]
      ↓
[SyncService detecta]
      ↓
[Envia para Supabase]
      ↓
[Atualiza status → synced]
```

---

## 8. FEEDBACK VISUAL

### 8.1. DrawingStateIndicator

Widget posicionado no topo do mapa que exibe:
- **Cor** por estado (azul=drawing, verde=reviewing, etc)
- **Ícone** da ferramenta/estado
- **Mensagem** descritiva

### 8.2. Cores por Estado

| Estado | Cor | Ícone | Mensagem |
|--------|-----|-------|----------|
| idle | Cinza | touch_app | Toque no mapa para navegar |
| armed | Laranja | my_location | Toque para iniciar desenho |
| drawing | Azul | edit_location | Desenhando... (toque duplo para finalizar) |
| reviewing | Verde | check_circle_outline | Revisar e confirmar |
| editing | Roxo | edit | Editando vértices |
| measuring | Azul-petróleo | straighten | Medindo área |
| importPreview | Índigo | visibility | Visualizando importação |
| booleanOperation | Âmbar | merge_type | Operação booleana |

---

## 9. EVENTOS E CALLBACKS

### 9.1. DrawingMapEvent

```dart
enum DrawingMapEventType {
  tap,           // Usuário tocou no mapa
  longPress,     // Segurou o toque
  drag,          // Arrastou (edição de vértice)
  doubleTap,     // Duplo toque (finalizar)
}

class DrawingMapEvent {
  final DrawingMapEventType type;
  final LatLng coordinate;
  final int? vertexIndex; // Para edição
}
```

### 9.2. Callbacks do Controller

```dart
class DrawingController extends ChangeNotifier {
  // Notifica quando features mudam
  void addListener(VoidCallback listener);
  
  // Callback para mapa renderizar
  void Function(List<DrawingFeature>)? onFeaturesChanged;
  
  // Callback para mudança de estado
  void Function(DrawingState)? onStateChanged;
  
  // Callback para erros
  void Function(String)? onError;
}
```

---

## 10. REGRAS DE NEGÓCIO

### 10.1. Validações Obrigatórias

- ✅ Polígono deve ter **mínimo 3 pontos**
- ✅ Área deve ser **> 0.01 ha** (100 m²)
- ✅ Não pode ter **self-intersections**
- ✅ Coordenadas devem estar em **WGS84** (EPSG:4326)
- ✅ Primeiro e último ponto devem ser **idênticos** (anel fechado)

### 10.2. Versionamento

Toda edição cria uma **nova versão**:

```dart
DrawingFeature v1 = feature; // Original
DrawingFeature v2 = v1.createNewVersion(...); // Edição

// v2.properties.versao = 2
// v2.properties.versaoAnteriorId = v1.id
// v1.properties.ativo = false (marcado no banco)
```

---

## 11. PROIBIÇÕES (ANTIPADRÕES)

❌ **Proibido:**
- Desenho sem máquina de estados
- Transições diretas sem validação
- Persistir geometria apenas em RAM (Provider/State)
- Hard delete de features sincronizadas
- Edição sem versionamento
- Geometrias inválidas (self-intersecting)
- Área sem validação mínima

---

## 12. EXEMPLO DE USO COMPLETO

```dart
// 1. Inicializar controller
final controller = DrawingController(
  repository: DrawingRepository(),
  stateMachine: DrawingStateMachine(),
);

// 2. Usuário seleciona ferramenta
controller.startDrawing(DrawingTool.polygon);
// Estado: idle → armed

// 3. Usuário toca no mapa (primeiro ponto)
controller.handleMapTap(LatLng(-23.55, -46.63));
// Estado: armed → drawing

// 4. Usuário adiciona mais pontos
controller.handleMapTap(LatLng(-23.56, -46.63));
controller.handleMapTap(LatLng(-23.56, -46.64));
controller.handleMapTap(LatLng(-23.55, -46.64));

// 5. Usuário finaliza (duplo toque)
controller.handleDoubleTap();
// Estado: drawing → reviewing
// Feature criada e persistida (local_only)

// 6. Usuário confirma
await controller.confirmDrawing(name: 'Talhão 01');
// Estado: reviewing → idle
// Feature salva no SQLite
// SyncService detecta e envia para Supabase

// 7. Feature sincronizada
// syncStatus: local_only → synced
```

---

## 13. INTEGRAÇÃO COM OUTROS MÓDULOS

### 13.1. Mapa (Map Module)

```dart
// O mapa renderiza as features
MapController.renderFeatures(drawingController.features);

// O mapa envia eventos para o drawing
drawingController.handleMapEvent(event);
```

### 13.2. Consultoria (Fields/Talhões)

```dart
// Talhão pode ser criado a partir de DrawingFeature
final talhao = Field.fromDrawingFeature(feature);

// Talhão existente pode ser editado via Drawing
drawingController.editFeature(talhao.geometryFeature);
```

### 13.3. Sync Service

```dart
// SyncService detecta features pendentes
final pending = await drawingRepository.getPendingSync();

// Envia para backend
await syncService.syncDrawings(pending);
```

---

## 14. TESTES OBRIGATÓRIOS

### 14.1. Testes Unitários

- [ ] DrawingStateMachine - todas transições válidas
- [ ] DrawingStateMachine - transições inválidas lançam erro
- [ ] ValidateGeometryUseCase - geometrias válidas/inválidas
- [ ] CompleteDrawingUseCase - cálculo de área correto
- [ ] EditGeometryUseCase - versionamento correto

### 14.2. Testes de Integração

- [ ] Desenhar → Salvar → Reabrir app → Feature persiste
- [ ] Editar → Versão nova criada
- [ ] Offline → Desenhar → Online → Sync

---

**FIM DO CONTRATO**  
**Versão:** 1.0  
**Próxima revisão:** Após Sprint 1
