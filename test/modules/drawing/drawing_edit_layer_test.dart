import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:soloforte_app/modules/drawing/data/repositories/drawing_repository.dart';
import 'package:soloforte_app/modules/drawing/domain/drawing_state.dart';
import 'package:soloforte_app/modules/drawing/domain/models/drawing_models.dart';
import 'package:soloforte_app/modules/drawing/presentation/controllers/drawing_controller.dart';
import 'package:soloforte_app/modules/drawing/presentation/widgets/drawing_edit_layer.dart';
import 'package:soloforte_app/modules/drawing/presentation/widgets/drawing_vertex_handle_overlay.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    try {
      Supabase.instance;
    } catch (_) {
      await Supabase.initialize(
        url: 'https://mock-supabase-for-tests.co',
        anonKey: 'mock-anon-key-1234567890abcdef',
      );
    }
  });

  testWidgets('arrasta vértice no mapa e persiste geometria ao salvar', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final initial = _feature();
    final repository = _UpsertDrawingRepository(initial);
    final controller = DrawingController(repository: repository);
    addTearDown(controller.dispose);
    await controller.loadFeatures();
    controller.selectFeature(controller.features.single);
    controller.startEditMode();

    final mapController = MapController();
    await _pumpInteractiveHandles(
      tester,
      controller: controller,
      mapController: mapController,
      center: const LatLng(0, 0),
      zoom: 13,
    );

    final handle = find.byKey(const Key('drawing_vertex_hit_0_0'));
    expect(handle, findsOneWidget);
    final before =
        (controller.liveGeometry! as DrawingPolygon).coordinates.first.first;

    // Arrastar a bolinha idle não puxa o polígono.
    final dot = tester.getRect(handle).topCenter + const Offset(0, 14);
    await tester.dragFrom(dot, const Offset(36, 24));
    await tester.pumpAndSettle();
    expect(
      (controller.liveGeometry! as DrawingPolygon).coordinates.first.first,
      equals(before),
    );
    expect(controller.isDraggingVertex, isFalse);

    controller.selectEditVertex(0, 0);
    await tester.pumpAndSettle();
    await tester.timedDrag(
      handle,
      const Offset(36, 24),
      const Duration(milliseconds: 300),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('drawing_vertex_drag_0_0')), findsOneWidget);

    final afterDrag =
        (controller.liveGeometry! as DrawingPolygon).coordinates.first.first;
    expect(afterDrag, isNot(equals(before)));

    controller.saveEdit();
    await tester.pumpAndSettle();

    final persisted =
        repository.features
                .where((feature) => feature.properties.ativo)
                .last
                .geometry
            as DrawingPolygon;
    expect(persisted.coordinates.first.first, equals(afterDrag));
    expect(
      persisted.coordinates.first.last,
      equals(persisted.coordinates.first.first),
    );
  });

  testWidgets('mid-draw: toque no vértice mostra gota e permite arrastar', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final controller = DrawingController(
      repository: _UpsertDrawingRepository(_feature()),
    );
    addTearDown(controller.dispose);
    controller.selectTool('polygon');
    // Pontos bem espaçados para os markers 56x72 não se sobreporem no zoom do teste.
    controller.appendDrawingPoint(const LatLng(-0.05, -0.05));
    controller.appendDrawingPoint(const LatLng(0.05, -0.05));
    controller.appendDrawingPoint(const LatLng(0.05, 0.05));

    final mapController = MapController();
    await _pumpInteractiveHandles(
      tester,
      controller: controller,
      mapController: mapController,
      center: const LatLng(0, 0),
      zoom: 11,
    );

    final vertex = find.byKey(const Key('drawing_sketch_vertex_1'));
    expect(vertex, findsOneWidget);

    // Hitbox da alça (corpo da gota) ≥44dp — o visual idle fica dentro.
    final hit = find.byKey(const Key('drawing_sketch_vertex_hit_1'));
    expect(hit, findsOneWidget);
    final idleSize = tester.getSize(hit);
    expect(idleSize.width, greaterThanOrEqualTo(44));
    expect(idleSize.height, greaterThanOrEqualTo(44));

    await tester.tap(hit);
    await tester.pumpAndSettle();
    expect(controller.selectedSketchVertexIndex, 1);

    // Gota selecionada: ponta-cima 56×78 + cruz no corpo (abaixo do dedo).
    expect(find.byIcon(Icons.open_with), findsOneWidget);
    expect(
      find.byKey(const Key('drawing_sketch_vertex_drag_1')),
      findsOneWidget,
    );
    final selectedSize = tester.getSize(
      find.byKey(const Key('drawing_sketch_vertex_1')),
    );
    expect(selectedSize.width, closeTo(56, 1));
    expect(selectedSize.height, closeTo(78, 1));

    final before = controller.currentPoints[1];
    await tester.timedDrag(
      hit,
      const Offset(64, 48),
      const Duration(milliseconds: 300),
    );
    await tester.pumpAndSettle();

    expect(controller.currentPoints[1], isNot(equals(before)));
    expect(controller.selectedSketchVertexIndex, 1);
    expect(controller.currentState, DrawingState.drawing);
  });

  testWidgets('mid-draw: pan no ponto idle seleciona e arrasta (mesmo gesto)', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final controller = DrawingController(
      repository: _UpsertDrawingRepository(_feature()),
    );
    addTearDown(controller.dispose);
    controller.selectTool('polygon');
    controller.appendDrawingPoint(const LatLng(-0.05, -0.05));
    controller.appendDrawingPoint(const LatLng(0.05, -0.05));
    controller.appendDrawingPoint(const LatLng(0.05, 0.05));

    final mapController = MapController();
    await _pumpInteractiveHandles(
      tester,
      controller: controller,
      mapController: mapController,
      center: const LatLng(0, 0),
      zoom: 11,
    );

    final before = controller.currentPoints[1];
    await tester.timedDrag(
      find.byKey(const Key('drawing_sketch_vertex_hit_1')),
      const Offset(64, 48),
      const Duration(milliseconds: 300),
    );
    await tester.pumpAndSettle();

    expect(controller.currentPoints[1], isNot(equals(before)));
    expect(controller.selectedSketchVertexIndex, 1);
  });

  testWidgets('mid-draw: arrasta gota com mapa interativo (pan habilitado)', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final controller = DrawingController(
      repository: _UpsertDrawingRepository(_feature()),
    );
    addTearDown(controller.dispose);
    controller.selectTool('polygon');
    controller.appendDrawingPoint(const LatLng(-0.05, -0.05));
    controller.appendDrawingPoint(const LatLng(0.05, -0.05));
    controller.appendDrawingPoint(const LatLng(0.05, 0.05));

    final mapController = MapController();
    await _pumpInteractiveHandles(
      tester,
      controller: controller,
      mapController: mapController,
      center: const LatLng(0, 0),
      zoom: 11,
    );

    final hit = find.byKey(const Key('drawing_sketch_vertex_hit_1'));
    await tester.tap(hit);
    await tester.pumpAndSettle();
    expect(controller.selectedSketchVertexIndex, 1);

    final before = controller.currentPoints[1];
    final hitBox = tester.getRect(hit);
    expect(hitBox.height, closeTo(78, 1));
    expect(hitBox.center.dy, greaterThan(hitBox.top + 20));
    await tester.timedDrag(
      hit,
      const Offset(72, 56),
      const Duration(milliseconds: 350),
    );
    await tester.pumpAndSettle();

    expect(controller.currentPoints[1], isNot(equals(before)));
    expect(controller.selectedSketchVertexIndex, 1);
  });

  testWidgets('edição: arrasta gota com mapa interativo após seleção', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final repository = _UpsertDrawingRepository(_feature());
    final controller = DrawingController(repository: repository);
    addTearDown(controller.dispose);
    await controller.loadFeatures();
    controller.selectFeature(controller.features.single);
    controller.startEditMode();

    final mapController = MapController();
    await _pumpInteractiveHandles(
      tester,
      controller: controller,
      mapController: mapController,
      center: const LatLng(0, 0),
      zoom: 13,
    );

    controller.selectEditVertex(0, 0);
    await tester.pumpAndSettle();

    final before =
        (controller.liveGeometry! as DrawingPolygon).coordinates.first.first;
    final hit = find.byKey(const Key('drawing_vertex_hit_0_0'));
    final hitBox = tester.getRect(hit);
    expect(hitBox.center.dy, greaterThan(hitBox.top + 20));
    await tester.timedDrag(
      hit,
      const Offset(72, 56),
      const Duration(milliseconds: 350),
    );
    await tester.pumpAndSettle();

    final after =
        (controller.liveGeometry! as DrawingPolygon).coordinates.first.first;
    expect(after, isNot(equals(before)));
    expect(controller.selectedEditRingIndex, 0);
    expect(controller.selectedEditPointIndex, 0);
  });

  testWidgets(
    'edição: canto da alça não seleciona; toque na gota volta à bolinha',
    (tester) async {
      tester.view.physicalSize = const Size(800, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final repository = _UpsertDrawingRepository(_feature());
      final controller = DrawingController(repository: repository);
      addTearDown(controller.dispose);
      await controller.loadFeatures();
      controller.selectFeature(controller.features.single);
      controller.startEditMode();

      final mapController = MapController();
      await _pumpInteractiveHandles(
        tester,
        controller: controller,
        mapController: mapController,
        center: const LatLng(0, 0),
        zoom: 13,
      );

      final handle = find.byKey(const Key('drawing_vertex_hit_0_0'));
      final rect = tester.getRect(handle);
      await tester.tapAt(rect.topLeft + const Offset(2, 40));
      await tester.pump(const Duration(milliseconds: 400));
      expect(controller.selectedEditPointIndex, isNull);

      await tester.tapAt(rect.topCenter + const Offset(0, 14));
      await tester.pump(const Duration(milliseconds: 400));
      expect(controller.selectedEditRingIndex, 0);
      expect(controller.selectedEditPointIndex, 0);

      await tester.tapAt(rect.center);
      await tester.pump(const Duration(milliseconds: 400));
      expect(controller.selectedEditRingIndex, isNull);
      expect(controller.selectedEditPointIndex, isNull);
    },
  );

  test('edição: beginEditVertexDrag não dispara notify imediato', () {
    final repository = _UpsertDrawingRepository(_feature());
    final controller = DrawingController(repository: repository);
    addTearDown(controller.dispose);

    var notifyCount = 0;
    controller.addListener(() => notifyCount++);

    controller.beginEditVertexDrag(0);
    expect(controller.isDraggingVertex, isTrue);
    expect(notifyCount, 0);

    controller.onDragEnd(persist: false);
    expect(controller.isDraggingVertex, isFalse);
    expect(notifyCount, greaterThan(0));
  });

  testWidgets('mid-draw: gota selecionada ancora ponta no vértice (tip-up)', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final controller = DrawingController(
      repository: _UpsertDrawingRepository(_feature()),
    );
    addTearDown(controller.dispose);
    controller.selectTool('polygon');
    controller.appendDrawingPoint(const LatLng(-0.05, -0.05));
    controller.appendDrawingPoint(const LatLng(0.05, -0.05));

    final mapController = MapController();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FlutterMap(
            mapController: mapController,
            options: const MapOptions(
              initialCenter: LatLng(0, 0),
              initialZoom: 11,
              interactionOptions: InteractionOptions(
                flags: InteractiveFlag.none,
              ),
            ),
            children: [
              DrawingEditLayer(
                controller: controller,
                mapController: mapController,
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    controller.selectSketchVertex(1);
    await tester.pumpAndSettle();

    final gotaBox = tester.getRect(
      find.byKey(const Key('drawing_sketch_vertex_1')),
    );
    final dragBox = tester.getRect(
      find.byKey(const Key('drawing_sketch_vertex_drag_1')),
    );
    final iconCenter = tester.getCenter(find.byIcon(Icons.open_with));

    expect(gotaBox.width, closeTo(56, 1));
    expect(gotaBox.height, closeTo(78, 1));
    expect(dragBox.width, closeTo(56, 1));
    expect(dragBox.height, closeTo(78, 1));
    expect(find.byIcon(Icons.open_with), findsOneWidget);
    // Cruz no corpo (abaixo da ponta) — dedo não cobre o LatLng no topo.
    expect(iconCenter.dy, greaterThan(gotaBox.top + gotaBox.height * 0.35));

    // flutter_map 7 + bottomCenter: topo do marker = LatLng na tela (regressão tip-up).
    final vertex = controller.currentPoints[1];
    expectMarkerTopAnchorsLatLng(
      mapController: mapController,
      markerRect: gotaBox,
      latLng: vertex,
    );
  });

  testWidgets(
    'mid-draw: ponto idle ancora topo do marker no vértice (bottomCenter)',
    (tester) async {
      tester.view.physicalSize = const Size(800, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final controller = DrawingController(
        repository: _UpsertDrawingRepository(_feature()),
      );
      addTearDown(controller.dispose);
      controller.selectTool('polygon');
      controller.appendDrawingPoint(const LatLng(-0.05, -0.05));
      controller.appendDrawingPoint(const LatLng(0.05, -0.05));
      controller.appendDrawingPoint(const LatLng(0.05, 0.05));

      final mapController = MapController();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FlutterMap(
              mapController: mapController,
              options: const MapOptions(
                initialCenter: LatLng(0, 0),
                initialZoom: 11,
                interactionOptions: InteractionOptions(
                  flags: InteractiveFlag.none,
                ),
              ),
              children: [
                DrawingEditLayer(
                  controller: controller,
                  mapController: mapController,
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      const vertexIndex = 1;
      final latLng = controller.currentPoints[vertexIndex];
      final markerRect = tester.getRect(
        find.byKey(const Key('drawing_sketch_vertex_$vertexIndex')),
      );

      expectMarkerTopAnchorsLatLng(
        mapController: mapController,
        markerRect: markerRect,
        latLng: latLng,
      );

      // Topo do círculo idle no vértice; centro em dotSize/2 (dentro do hitbox).
      const dotSize = 16.0;
      final screenY = mapController.camera.latLngToScreenPoint(latLng).y;
      expect(markerRect.top + 0.5, closeTo(screenY, 2));
      final dotCenterY = markerRect.top + 0.5 + dotSize / 2;
      expect(dotCenterY, closeTo(screenY + dotSize / 2, 2));
    },
  );

  test('edição: findEditVertexNear e selectEditVertex no controller', () async {
    final repository = _UpsertDrawingRepository(_feature());
    final controller = DrawingController(repository: repository);
    addTearDown(controller.dispose);
    await controller.loadFeatures();
    controller.selectFeature(controller.features.single);
    controller.startEditMode();

    final ring = (controller.liveGeometry! as DrawingPolygon).coordinates.first;
    final vertex = LatLng(ring[0][1], ring[0][0]);

    final hit = controller.findEditVertexNear(vertex, 5.0);
    expect(hit, isNotNull);
    expect(hit!.ring, 0);
    expect(hit.point, 0);

    expect(controller.selectEditVertex(hit.ring, hit.point), isTrue);
    expect(controller.selectedEditRingIndex, 0);
    expect(controller.selectedEditPointIndex, 0);

    controller.clearEditVertexSelection();
    expect(controller.selectedEditRingIndex, isNull);
    expect(controller.selectedEditPointIndex, isNull);
  });

  test(
    'edição: toque na linha insere e seleciona sem marcar arraste',
    () async {
      final repository = _UpsertDrawingRepository(_feature());
      final controller = DrawingController(repository: repository);
      addTearDown(controller.dispose);
      await controller.loadFeatures();
      controller.selectFeature(controller.features.single);
      controller.startEditMode();

      final before =
          (controller.liveGeometry! as DrawingPolygon).coordinates.first.length;

      final onEdge = controller.findEditEdgeNear(const LatLng(-0.01, 0), 50);
      expect(onEdge, isNotNull);
      controller.insertVertex(onEdge!.ring, onEdge.segment, onEdge.point);

      final after =
          (controller.liveGeometry! as DrawingPolygon).coordinates.first;
      expect(after.length, before + 1);
      expect(controller.selectedEditRingIndex, onEdge.ring);
      expect(controller.selectedEditPointIndex, onEdge.segment + 1);
      expect(controller.isDraggingVertex, isFalse);

      final vertexCount = after.length;
      expect(
        controller.findEditVertexNear(const LatLng(-0.01, -0.01), 50),
        isNotNull,
      );
      expect(
        (controller.liveGeometry! as DrawingPolygon).coordinates.first.length,
        vertexCount,
      );
      expect(controller.findEditEdgeNear(const LatLng(1, 1), 20), isNull);
    },
  );

  test('gota contém o corpo e ignora o canto transparente', () {
    const size = Size(56, 78);
    expect(vertexGotaContainsLocal(const Offset(28, 39), size), isTrue);
    expect(vertexGotaContainsLocal(const Offset(1, 1), size), isFalse);
    expect(vertexGotaContainsLocal(const Offset(2, 76), size), isFalse);
  });

  test(
    'edição: linha perto do vértice insere a gota; toque no vértice e no vazio desligam',
    () async {
      final repository = _UpsertDrawingRepository(_feature());
      final controller = DrawingController(repository: repository);
      addTearDown(controller.dispose);
      await controller.loadFeatures();
      controller.selectFeature(controller.features.single);
      controller.startEditMode();

      final ring =
          (controller.liveGeometry! as DrawingPolygon).coordinates.first;
      final start = LatLng(ring[0][1], ring[0][0]);
      final next = LatLng(ring[1][1], ring[1][0]);
      const distance = Distance();
      final nearLine = distance.offset(
        start,
        40,
        distance.bearing(start, next),
      );
      final before = ring.length;
      final original = ring.map((p) => [p[0], p[1]]).toList();

      final onTip = distance.offset(start, 8, distance.bearing(start, next));
      expect(
        controller.applyEditMapTap(
          onTip,
          vertexToleranceMeters: 20,
          edgeToleranceMeters: 80,
        ),
        isTrue,
      );
      expect(controller.selectedEditPointIndex, 0);
      expect(
        (controller.liveGeometry! as DrawingPolygon).coordinates.first.length,
        before,
      );
      controller.clearEditVertexSelection();

      expect(
        controller.applyEditMapTap(
          nearLine,
          vertexToleranceMeters: 20,
          edgeToleranceMeters: 80,
        ),
        isTrue,
      );
      final afterInsert =
          (controller.liveGeometry! as DrawingPolygon).coordinates.first;
      expect(afterInsert.length, before + 1);
      expect(controller.selectedEditPointIndex, 1);
      for (var i = 0; i < original.length; i++) {
        final index = i < 1 ? i : i + 1;
        expect(afterInsert[index][0], original[i][0]);
        expect(afterInsert[index][1], original[i][1]);
      }
      final inserted = LatLng(afterInsert[1][1], afterInsert[1][0]);
      expect(
        const Distance().as(LengthUnit.Meter, inserted, start),
        greaterThan(20),
      );
      expect(
        const Distance().as(LengthUnit.Meter, inserted, next),
        greaterThan(20),
      );

      final onVertex = LatLng(afterInsert[0][1], afterInsert[0][0]);
      final lengthWithVertex = afterInsert.length;
      expect(
        controller.applyEditMapTap(
          onVertex,
          vertexToleranceMeters: 20,
          edgeToleranceMeters: 80,
        ),
        isTrue,
      );
      expect(controller.selectedEditPointIndex, 0);
      expect(
        (controller.liveGeometry! as DrawingPolygon).coordinates.first.length,
        lengthWithVertex,
      );

      expect(
        controller.applyEditMapTap(
          onVertex,
          vertexToleranceMeters: 20,
          edgeToleranceMeters: 80,
        ),
        isTrue,
      );
      expect(controller.selectedEditRingIndex, isNull);
      expect(controller.selectedEditPointIndex, isNull);

      controller.selectEditVertex(0, 0);
      expect(
        controller.applyEditMapTap(
          const LatLng(1, 1),
          vertexToleranceMeters: 20,
          edgeToleranceMeters: 80,
        ),
        isTrue,
      );
      expect(controller.selectedEditPointIndex, isNull);
      expect(
        (controller.liveGeometry! as DrawingPolygon).coordinates.first.length,
        lengthWithVertex,
      );
    },
  );

  testWidgets(
    'edição: marker de vértice ancora topo no LatLng (bottomCenter)',
    (tester) async {
      tester.view.physicalSize = const Size(800, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final repository = _UpsertDrawingRepository(_feature());
      final controller = DrawingController(repository: repository);
      addTearDown(controller.dispose);
      await controller.loadFeatures();
      controller.selectFeature(controller.features.single);
      controller.startEditMode();

      final mapController = MapController();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FlutterMap(
              mapController: mapController,
              options: const MapOptions(
                initialCenter: LatLng(0, 0),
                initialZoom: 13,
                interactionOptions: InteractionOptions(
                  flags: InteractiveFlag.none,
                ),
              ),
              children: [
                DrawingEditLayer(
                  controller: controller,
                  mapController: mapController,
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final ring =
          (controller.liveGeometry! as DrawingPolygon).coordinates.first;
      final latLng = LatLng(ring[0][1], ring[0][0]);
      final markerRect = tester.getRect(
        find.byKey(const Key('drawing_vertex_0_0')),
      );

      expectMarkerTopAnchorsLatLng(
        mapController: mapController,
        markerRect: markerRect,
        latLng: latLng,
      );
    },
  );
}

/// Contrato flutter_map 7: [Alignment.bottomCenter] ancora o LatLng no topo do marker.
void expectMarkerTopAnchorsLatLng({
  required MapController mapController,
  required Rect markerRect,
  required LatLng latLng,
  double tolerancePx = 2,
}) {
  final screen = mapController.camera.latLngToScreenPoint(latLng);
  expect(
    markerRect.top,
    closeTo(screen.y, tolerancePx),
    reason:
        'topCenter no marker desloca ~78px; bottomCenter mantém topo = vértice',
  );
}

/// Mapa com pan ligado e alça da gota acima do FlutterMap.
Future<void> _pumpInteractiveHandles(
  WidgetTester tester, {
  required DrawingController controller,
  required MapController mapController,
  required LatLng center,
  required double zoom,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Stack(
          children: [
            FlutterMap(
              mapController: mapController,
              options: MapOptions(
                initialCenter: center,
                initialZoom: zoom,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.all,
                ),
              ),
              children: [
                DrawingEditLayer(
                  controller: controller,
                  mapController: mapController,
                ),
              ],
            ),
            DrawingVertexHandleOverlay(
              controller: controller,
              mapController: mapController,
            ),
          ],
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

class _UpsertDrawingRepository extends DrawingRepository {
  _UpsertDrawingRepository(DrawingFeature initial) : features = [initial];

  final List<DrawingFeature> features;

  @override
  Future<List<DrawingFeature>> getAllFeatures() async => List.of(features);

  @override
  Future<void> saveFeature(DrawingFeature feature) async {
    final index = features.indexWhere((item) => item.id == feature.id);
    if (index == -1) {
      features.add(feature);
    } else {
      features[index] = feature;
    }
  }
}

DrawingFeature _feature() {
  final now = DateTime(2026);
  return DrawingFeature(
    id: 'field-1',
    geometry: DrawingPolygon(
      coordinates: const [
        [
          [-0.01, -0.01],
          [0.01, -0.01],
          [0.01, 0.01],
          [-0.01, 0.01],
          [-0.01, -0.01],
        ],
      ],
    ),
    properties: DrawingProperties(
      nome: 'Talhão editável',
      tipo: DrawingType.talhao,
      origem: DrawingOrigin.desenho_manual,
      status: DrawingStatus.rascunho,
      autorId: 'user-1',
      autorTipo: AuthorType.consultor,
      areaHa: 1,
      versao: 1,
      ativo: true,
      createdAt: now,
      updatedAt: now,
      syncStatus: SyncStatus.synced,
    ),
  );
}
