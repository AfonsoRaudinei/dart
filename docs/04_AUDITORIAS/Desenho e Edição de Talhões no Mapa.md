# SKILL: Desenho e Edição de Talhões no Mapa — SoloForte
**Versão:** 1.0  
**Módulo alvo:** `drawing`  
**Rota:** `/map` (estado interno — NUNCA sub-rota)  
**Engine de mapa:** `flutter_map` (NÃO google_maps_flutter)  
**Estado:** Riverpod  
**Persistência:** SQLite offline-first  
**Data:** 2026-03-03  

---

## 0. PRINCÍPIOS INEGOCIÁVEIS (SOLOFORTE)

> Desenho é um **modo de interação do mapa**, não uma tela.  
> A URL permanece sempre `/map`.  
> O SmartButton (FAB único) **não muda** durante o desenho.  
> Nenhuma sub-rota de `/map` pode ser criada.  
> Nenhum FAB local pode ser criado no módulo drawing.  

```
❌ /map/desenho        → PROIBIDO
❌ /map/editor         → PROIBIDO  
❌ FAB local em DrawingScreen → PROIBIDO
✅ MapContext.drawing  → CORRETO (estado interno do mapa)
```

---

## 1. BOUNDED CONTEXT E FRONTEIRAS

```
drawing/ → NÃO depende de: consultoria/, agenda/
drawing/ → PODE depender de: core/ (database, router)
map/     → PODE depender de: drawing/ (lê providers, renderiza layers)
```

Ponte autorizada para dados de clientes/fazendas:
`ClientsRepositoryAdapter` em `drawing/infra/` — única ponte autorizada.

---

## 2. MODELO DE DADOS

### 2.1. Entidade Principal: `DrawingFeature`

```dart
class DrawingFeature {
  final String id;           // UUID v4
  final String name;         // ex: "Talhão 01"
  final FeatureType type;    // polygon | polyline | point
  final List<LatLng> vertices; // vértices reais (sem midpoints)
  final DrawingMeta meta;
  final SyncStatus syncStatus;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt; // soft delete
}

class DrawingMeta {
  final String? clientId;
  final String? farmId;
  final String? cultura;
  final String? safra;
  final double? areaHa;          // calculado, não digitado
  final double? perimeterM;      // calculado, não digitado
  final String? soilSamplingScheme; // grade | zona | dirigido
  final Map<String, double>? recByNutrient; // gancho agronômico
}

enum FeatureType { polygon, polyline, point }
```

**Regras:**
- `vertices` armazena apenas vértices reais — midpoints são gerados apenas para UI, nunca persistidos.
- `areaHa` e `perimeterM` são sempre calculados pelo sistema, nunca digitados pelo usuário.
- Soft delete obrigatório — nunca `DELETE` físico em features já sincronizadas.

### 2.2. Contrato de Vértice (UI only)

```dart
// Apenas para renderização — não persiste
class VertexHandle {
  final int index;
  final LatLng position;
  final bool isMidpoint; // midpoint → ao arrastar, vira vértice real
}
```

---

## 3. ESTADOS DO MODO DESENHO

```dart
enum DrawingMode {
  idle,           // mapa em modo normal — sem interação de desenho
  drawPolygon,    // adicionando vértices por toque sucessivo
  drawFreehand,   // traçado livre (opcional, fase 2)
  drawPolyline,   // linha/cerca/estrada
  drawPoint,      // marcador de ponto (pivô, poço, entrada)
  editVertices,   // alças de vértice visíveis, drag ativo
  gpsTracking,    // modo caminhada — GPS captura vértices automaticamente
}
```

**Integração com `MapContext`:**

```dart
// DrawingMode é estado LOCAL do módulo drawing.
// MapContext.drawing é o estado do mapa que ativa o módulo.
// São independentes — MapContext não conhece DrawingMode.
```

---

## 4. MODO DESENHO POR TOQUE (flutter_map)

### 4.1. Fluxo

```
Usuário toca "Desenhar talhão"
  → DrawingMode = drawPolygon
  → map.onTap(LatLng p): adiciona p a drawingPoints
  → TileLayer + PolygonLayer se atualizam via Riverpod
  → Overlay de área/perímetro atualiza em tempo real
  → Toque duplo OU botão "Fechar": fecha polígono (mínimo 3 pontos)
  → DrawingMode = editVertices (permite ajuste imediato)
  → Botão "Salvar": persiste no SQLite, syncStatus = localOnly
```

### 4.2. Implementação com flutter_map

```dart
// No FlutterMap, use onTap do mapa ou GestureDetector sobre o mapa
// flutter_map expõe MapOptions.onTap

FlutterMap(
  options: MapOptions(
    onTap: (tapPosition, latLng) {
      if (drawingMode == DrawingMode.drawPolygon) {
        ref.read(drawingControllerProvider.notifier)
           .addVertex(latLng);
      }
    },
    onLongPress: (tapPosition, latLng) {
      // long press fecha o polígono
      if (drawingMode == DrawingMode.drawPolygon &&
          drawingPoints.length >= 3) {
        ref.read(drawingControllerProvider.notifier).closePolygon();
      }
    },
  ),
  children: [
    TileLayer(...), // Stadia Stamen Terrain — MapConfig.stadiaStamenTerrain
    // Camada de polígonos salvos:
    PolygonLayer(polygons: savedPolygons),
    // Polígono em construção:
    if (drawingMode == DrawingMode.drawPolygon)
      PolylineLayer(polylines: [draftPolyline]),
    // Handles de vértice (modo edit):
    if (drawingMode == DrawingMode.editVertices)
      MarkerLayer(markers: vertexHandles),
  ],
)
```

### 4.3. Cálculo de Área e Perímetro (geodésico)

```dart
// Usar pacote geodesy (Dart) ou implementação Haversine local
// NUNCA calcular em pixels — sempre em coordenadas geográficas

double computeAreaHa(List<LatLng> points) {
  // Algoritmo de Shoelace esférico (fórmula de Gauss adaptada)
  // resultado em m², dividir por 10000 para ha
}

double computePerimeterM(List<LatLng> points) {
  double total = 0;
  for (int i = 0; i < points.length; i++) {
    final a = points[i];
    final b = points[(i + 1) % points.length];
    total += haversineDistanceM(a, b);
  }
  return total;
}
```

---

## 5. EDIÇÃO DE VÉRTICES

### 5.1. Handles e Midpoints

```dart
List<VertexHandle> buildHandles(List<LatLng> vertices) {
  final handles = <VertexHandle>[];
  for (int i = 0; i < vertices.length; i++) {
    // Vértice real
    handles.add(VertexHandle(index: i, position: vertices[i], isMidpoint: false));
    // Midpoint entre i e i+1
    final next = vertices[(i + 1) % vertices.length];
    final mid = LatLng(
      (vertices[i].latitude + next.latitude) / 2,
      (vertices[i].longitude + next.longitude) / 2,
    );
    handles.add(VertexHandle(index: i, position: mid, isMidpoint: true));
  }
  return handles;
}
```

### 5.2. Drag de Vértice (flutter_map Marker draggable)

`flutter_map` não tem Marker nativo arrastável. Use `GestureDetector` + `Draggable` sobre `MarkerLayer`, ou sobreponha um `Stack` com widgets posicionados via `MapController.latLngToScreenPoint`.

```dart
// Padrão recomendado:
// 1. Converter LatLng → pixel com MapController
// 2. Usar Positioned + GestureDetector no Stack sobre o mapa
// 3. onPanUpdate: converter pixel de volta para LatLng e atualizar provider

void onVertexDrag(int index, Offset delta, MapController mapController) {
  final currentPixel = mapController.latLngToScreenPoint(vertices[index]);
  final newPixel = currentPixel + delta;
  final newLatLng = mapController.screenPointToLatLng(newPixel);
  ref.read(drawingControllerProvider.notifier)
     .updateVertex(index, newLatLng);
  // recalcula área e perímetro automaticamente
}
```

### 5.3. Operações de Vértice

```dart
// Remover vértice — mínimo 3 pontos obrigatório
void removeVertex(int index) {
  if (vertices.length <= 3) return; // guard obrigatório
  final updated = [...vertices]..removeAt(index);
  _updateAndRecalculate(updated);
}

// Inserir vértice a partir de midpoint
void insertVertexAtMidpoint(int afterIndex, LatLng position) {
  final updated = [...vertices]..insert(afterIndex + 1, position);
  _updateAndRecalculate(updated);
}
```

### 5.4. Undo / Redo

```dart
// Stack de histórico — apenas no modo editVertices
// Limpar ao salvar ou cancelar

class DrawingHistory {
  final List<List<LatLng>> _stack = [];
  int _cursor = -1;

  void push(List<LatLng> state) {
    // descarta redo pendente
    if (_cursor < _stack.length - 1) {
      _stack.removeRange(_cursor + 1, _stack.length);
    }
    _stack.add(List.from(state));
    _cursor = _stack.length - 1;
  }

  List<LatLng>? undo() {
    if (_cursor <= 0) return null;
    _cursor--;
    return List.from(_stack[_cursor]);
  }

  List<LatLng>? redo() {
    if (_cursor >= _stack.length - 1) return null;
    _cursor++;
    return List.from(_stack[_cursor]);
  }
}
```

---

## 6. MODO GPS — CAMINHANDO O PERÍMETRO

### 6.1. Conceito

Usuário ativa o modo GPS, **caminha ao redor da área** com o celular e o app registra os vértices automaticamente. Ao finalizar, fecha o polígono e entra em modo de edição fina.

### 6.2. Dependências Flutter

```yaml
# pubspec.yaml
geolocator: ^10.x   # stream de posição GPS
```

### 6.3. Filtros de Qualidade

```dart
const double kMaxAccuracyM = 15.0;  // descarta pontos com precisão pior que 15m
const double kMinSegmentM  = 5.0;   // distância mínima entre pontos aceitos
const int    kMinVertices  = 3;     // mínimo para fechar polígono
```

### 6.4. Controller GPS

```dart
class GpsTrackingController {
  bool isTracking = false;
  final List<LatLng> points = [];
  StreamSubscription<Position>? _sub;

  void start() {
    isTracking = true;
    points.clear();
    _sub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: 1, // pré-filtro de 1m — filtro real em _onPosition
      ),
    ).listen(_onPosition);
  }

  void pause() => isTracking = false;
  void resume() => isTracking = true;

  void undoLast() {
    if (points.isNotEmpty) points.removeLast();
  }

  /// Finaliza: fecha polígono e retorna vértices para modo editVertices
  List<LatLng>? finish() {
    _sub?.cancel();
    isTracking = false;
    if (points.length < kMinVertices) return null;

    final first = points.first;
    final last = points.last;
    if (_distanceM(first, last) > 10) {
      points.add(LatLng(first.latitude, first.longitude));
    }
    return List.from(points);
  }

  void _onPosition(Position pos) {
    if (!isTracking) return;
    if (pos.accuracy > kMaxAccuracyM) return;

    final p = LatLng(pos.latitude, pos.longitude);
    if (points.isEmpty || _distanceM(points.last, p) >= kMinSegmentM) {
      points.add(p);
      // notifica Riverpod → flutter_map redesenha polyline + área parcial
    }
  }

  double _distanceM(LatLng a, LatLng b) {
    return Geolocator.distanceBetween(
      a.latitude, a.longitude,
      b.latitude, b.longitude,
    );
  }
}
```

### 6.5. Feedback Visual durante GPS

```dart
// Enquanto tracking: PolylineLayer com os pontos aceitos
// Área parcial: PolygonLayer com fillOpacity 0.15 (mostra o que foi capturado)
// Card overlay (bottom): área parcial em ha + botões Pausar / Desfazer / Finalizar
// Indicador de precisão GPS: verde (< 5m), amarelo (5–15m), vermelho (> 15m — descarta)
```

### 6.6. Overlay de UI (GPS Mode)

```dart
// Posicionado acima do mapa — NÃO usa FAB local, NÃO cria rota nova
// É um widget sobreposto no Stack do PrivateMapScreen via MapContext.drawing

Widget _buildGpsOverlay() {
  return Positioned(
    bottom: kFabSafeArea + 16, // respeita kFabSafeArea=88dp
    left: 16,
    right: 72, // não sobrepõe coluna de controles direita
    child: GpsMeasureCard(
      areaHa: partialAreaHa,
      perimeterM: partialPerimeterM,
      accuracy: currentAccuracy,
      onPause: controller.pause,
      onResume: controller.resume,
      onUndo: controller.undoLast,
      onFinish: _finishGpsTracking,
    ),
  );
}
```

---

## 7. EXPORTAÇÃO / IMPORTAÇÃO GEOJSON

### 7.1. Exportar

```dart
Map<String, dynamic> toGeoJson(DrawingFeature feature) {
  return {
    'type': 'Feature',
    'geometry': {
      'type': 'Polygon',
      'coordinates': [
        feature.vertices
          .map((v) => [v.longitude, v.latitude]) // GeoJSON: [lng, lat]
          .toList()
          ..add([feature.vertices.first.longitude,
                 feature.vertices.first.latitude]), // fecha o anel
      ],
    },
    'properties': {
      'id': feature.id,
      'name': feature.name,
      'cultura': feature.meta.cultura,
      'safra': feature.meta.safra,
      'areaHa': feature.meta.areaHa,
    },
  };
}
```

### 7.2. Importar

```dart
DrawingFeature fromGeoJson(Map<String, dynamic> json) {
  final coords = (json['geometry']['coordinates'][0] as List)
    .map((c) => LatLng(c[1] as double, c[0] as double)) // GeoJSON: [lng, lat] → LatLng(lat, lng)
    .toList();
  
  // Remove ponto de fechamento duplicado se presente
  if (coords.length > 1 && coords.first == coords.last) {
    coords.removeLast();
  }

  final props = json['properties'] as Map<String, dynamic>? ?? {};
  return DrawingFeature(
    id: props['id'] ?? const Uuid().v4(),
    name: props['name'] ?? 'Talhão importado',
    type: FeatureType.polygon,
    vertices: coords,
    meta: DrawingMeta(cultura: props['cultura'], safra: props['safra']),
    syncStatus: SyncStatus.localOnly,
    createdAt: DateTime.now().toUtc(),
    updatedAt: DateTime.now().toUtc(),
  );
}
```

---

## 8. CAMADAS NO FLUTTER_MAP

```dart
// Ordem de camadas no FlutterMap (de baixo para cima):
children: [
  // 1. Tile base — Stadia Stamen Terrain
  TileLayer(urlTemplate: MapConfig.stadiaStamenTerrain),

  // 2. Polígonos salvos (modo view)
  PolygonLayer(
    polygons: savedFeatures.map((f) => Polygon(
      points: f.vertices,
      color: _colorForFeature(f).withOpacity(0.15),
      borderColor: _colorForFeature(f),
      borderStrokeWidth: 2,
      label: f.name,
    )).toList(),
  ),

  // 3. Rascunho em construção (drawPolygon mode)
  if (mode == DrawingMode.drawPolygon)
    PolylineLayer(polylines: [
      Polyline(points: [...draftPoints, draftPoints.first],
               color: Colors.blue, strokeWidth: 2),
    ]),

  // 4. Handles de edição (editVertices mode)
  // Implementados como Stack + Positioned sobre o mapa
  // (flutter_map não tem Marker draggable nativo)

  // 5. GPS track parcial (gpsTracking mode)
  if (mode == DrawingMode.gpsTracking) ...[
    PolygonLayer(polygons: [
      Polygon(
        points: [...gpsPoints, if (gpsPoints.isNotEmpty) gpsPoints.first],
        color: Colors.green.withOpacity(0.15),
        borderColor: Colors.green,
        borderStrokeWidth: 2,
      ),
    ]),
  ],
]
```

---

## 9. PROVIDER RIVERPOD

```dart
// drawing_mode_provider.dart — estado local do modo de desenho
// AutoDispose: NÃO (modo persiste enquanto mapa estiver na tela)

final drawingModeProvider = StateProvider<DrawingMode>(
  (ref) => DrawingMode.idle,
);

// drawing_draft_provider.dart — vértices do rascunho atual
final drawingDraftProvider = StateProvider<List<LatLng>>(
  (ref) => [],
);

// drawing_features_provider.dart — features salvas (lê do SQLite)
final drawingFeaturesProvider = FutureProvider<List<DrawingFeature>>(
  (ref) => ref.watch(drawingRepositoryProvider).getAll(),
);

// drawing_history_provider.dart — undo/redo local
final drawingHistoryProvider = StateProvider<DrawingHistory>(
  (ref) => DrawingHistory(),
);
```

---

## 10. PERSISTÊNCIA SQLITE

```dart
// Schema — tabela drawing_features
// Deve usar ALTER TABLE idempotente para migrações

CREATE TABLE IF NOT EXISTS drawing_features (
  id           TEXT PRIMARY KEY,
  name         TEXT NOT NULL,
  type         TEXT NOT NULL,        -- polygon | polyline | point
  vertices_json TEXT NOT NULL,       -- JSON array de [lat, lng]
  meta_json    TEXT,                 -- JSON do DrawingMeta
  sync_status  TEXT NOT NULL DEFAULT 'local_only',
  created_at   TEXT NOT NULL,
  updated_at   TEXT NOT NULL,
  deleted_at   TEXT                  -- soft delete
);
```

**Regras de persistência:**
- Salvar sempre localmente primeiro — nunca aguardar resposta de rede.
- `syncStatus = localOnly` ao criar/editar offline.
- Soft delete: preencher `deleted_at`, nunca `DELETE` físico em registros sincronizados.
- `arch_check.sh` garante que `drawing/` não importa `consultoria/`.

---

## 11. INTERFACE DO USUÁRIO — DIRETRIZES CAMPO

```
Botões grandes (mínimo 48dp touch target) — uso a céu aberto
Textos curtos — usuário pode estar com luvas ou sol na tela
Feedback imediato — área atualiza a cada vértice adicionado
Alternância satélite/terreno — para alinhamento preciso de vértices
Indicador GPS sempre visível no modo gpsTracking
```

### 11.1. Controles no modo drawPolygon

```
[Fechar polígono]  [Desfazer vértice]  [Cancelar]
```

### 11.2. Controles no modo editVertices

```
[Salvar]  [Desfazer]  [Refazer]  [Cancelar]
```

### 11.3. Controles no modo gpsTracking

```
[Pausar/Retomar]  [Desfazer último]  [Finalizar]
Card inferior: Área: X,XX ha | Perímetro: XXX m | GPS: 🟢 Xm
```

### 11.4. Posicionamento (respeita arquitetura do mapa)

```
- Controles ficam na borda inferior esquerda do mapa
- Respeitam kFabSafeArea = 88dp (SmartButton, canto inferior direito)
- Não conflitam com a coluna vertical direita de botões do mapa
  (edit | layers | ocorrências | marketing | check-in)
- Implementados como widgets no Stack do PrivateMapScreen,
  ativados via MapContext.drawing
```

---

## 12. GANCHO AGRONÔMICO (Integração futura)

```dart
// DrawingMeta já tem os campos prontos para integração agrônomica
// Ativar quando necessário — sem impacto na feature atual

class DrawingMeta {
  // ...campos existentes...
  
  // Zonas de amostragem
  final String? soilSamplingScheme;   // grade | zona | dirigido
  
  // Receituário por nutriente (calculado a partir de areaHa)
  final Map<String, double>? recByNutrient; // ex: {'P2O5': 120.5, 'K2O': 80.0} em kg

  // Versioning por safra (boundary history)
  final String? safra;          // ex: "2024/2025"
  final int? boundaryVersion;   // ex: 1, 2, 3
}
```

---

## 13. CHECKLIST DE CONFORMIDADE ARQUITETURAL

Antes de executar qualquer prompt usando esta skill:

```
[ ] DrawingMode é estado interno — NÃO cria rota /map/desenho
[ ] SmartButton não foi alterado
[ ] Nenhum FAB local foi criado no módulo drawing
[ ] drawing/ não importa consultoria/
[ ] consultoria/ não importa drawing/
[ ] Persistência via SQLite (offline-first) — nunca aguarda rede
[ ] Vértices reais persistidos — midpoints apenas em memória/UI
[ ] areaHa e perimeterM calculados pelo sistema, não digitados
[ ] Soft delete aplicado — sem DELETE físico
[ ] Arquivos novos < 900 linhas
[ ] arch_check.sh passa com Exit 0 após implementação
[ ] flutter analyze: 0 errors
```

---

## 14. ANTI-PADRÕES PROIBIDOS

```
❌ Criar rota /map/desenho ou /map/editor
❌ Esconder SmartButton durante desenho
❌ FAB local no módulo drawing
❌ Usar pop() para cancelar desenho
❌ Persistir midpoints como vértices reais
❌ Calcular área em pixels (deve ser geodésico)
❌ Bloquear criação se offline
❌ Criar tela fullscreen separada para o editor
❌ Abrir Google Maps em vez de flutter_map
❌ drawing/ importar consultoria/ (CI bloqueia)
❌ DELETE físico em features sincronizadas
```

---

## 15. REFERÊNCIAS DO PROJETO

```
arquitetura-navegacao.md      → Regras Map-First e FAB único
arquitetura-namespaces-rotas.md → Contrato de namespace /map
bounded_contexts.md           → Fronteiras drawing × consultoria
ARCH_BASELINE_v1.1_SCORE_90.md → Score estrutural e métricas
ADR-008 (Riverpod)            → Padrão de providers
arquitetura-persistencia.md   → Offline-first e SyncStatus
```

---

*Skill gerada para uso exclusivo no projeto SoloForte.*  
*Compatível com: flutter_map, Riverpod, Clean Architecture, Map-First.*  
*Incompatível com: google_maps_flutter, rotas novas, FABs locais.*