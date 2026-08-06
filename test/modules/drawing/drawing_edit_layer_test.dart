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

    final handle = find.byKey(const Key('drawing_vertex_0_0'));
    expect(handle, findsOneWidget);
    final before =
        (controller.liveGeometry! as DrawingPolygon).coordinates.first.first;

    await tester.drag(handle, const Offset(36, 24));
    await tester.pumpAndSettle();

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

    final vertex = find.byKey(const Key('drawing_sketch_vertex_1'));
    expect(vertex, findsOneWidget);

    // Hitbox idle ≥44dp (não o círculo visual 16–20px).
    final idleSize = tester.getSize(vertex);
    expect(idleSize.width, greaterThanOrEqualTo(44));
    expect(idleSize.height, greaterThanOrEqualTo(44));

    await tester.tap(vertex);
    await tester.pumpAndSettle();
    expect(controller.selectedSketchVertexIndex, 1);

    // Gota selecionada: CustomPaint pin 48×56 + handle de arraste na bolha.
    final paint = tester.widgetList<CustomPaint>(find.byType(CustomPaint));
    final gotaPaint = paint.where((p) => p.size == const Size(48, 56));
    expect(gotaPaint, isNotEmpty);
    expect(
      find.byKey(const Key('drawing_sketch_vertex_drag_1')),
      findsOneWidget,
    );

    final before = controller.currentPoints[1];
    await tester.timedDrag(
      find.byKey(const Key('drawing_sketch_vertex_drag_1')),
      const Offset(64, 48),
      const Duration(milliseconds: 300),
    );
    await tester.pumpAndSettle();

    expect(controller.currentPoints[1], isNot(equals(before)));
    expect(controller.selectedSketchVertexIndex, 1);
    expect(controller.currentState, DrawingState.drawing);
  });

  testWidgets('mid-draw: ponto branco idle não arrasta sem selecionar', (
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

    final before = controller.currentPoints[1];
    await tester.timedDrag(
      find.byKey(const Key('drawing_sketch_vertex_1')),
      const Offset(64, 48),
      const Duration(milliseconds: 300),
    );
    await tester.pumpAndSettle();

    expect(controller.currentPoints[1], equals(before));
    expect(controller.selectedSketchVertexIndex, isNull);
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
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: _SketchFreezeMapHarness(
            controller: controller,
            mapController: mapController,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('drawing_sketch_vertex_1')));
    await tester.pumpAndSettle();
    expect(controller.selectedSketchVertexIndex, 1);

    final before = controller.currentPoints[1];
    await tester.timedDrag(
      find.byKey(const Key('drawing_sketch_vertex_drag_1')),
      const Offset(72, 56),
      const Duration(milliseconds: 350),
    );
    await tester.pumpAndSettle();

    expect(controller.currentPoints[1], isNot(equals(before)));
    expect(controller.selectedSketchVertexIndex, 1);
  });

  testWidgets('mid-draw: bolha de arraste fica acima da ponta da gota', (
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

    await tester.tap(find.byKey(const Key('drawing_sketch_vertex_1')));
    await tester.pumpAndSettle();

    final dragHandle = find.byKey(const Key('drawing_sketch_vertex_drag_1'));
    final dragBox = tester.getRect(dragHandle);
    final tipHandle = find.byKey(const Key('drawing_sketch_vertex_1'));
    final tipBox = tester.getRect(tipHandle);

    expect(dragBox.bottom, lessThanOrEqualTo(tipBox.top + 1));
    expect(tipBox.height, lessThanOrEqualTo(20));
  });
}

/// Espelha o freeze do [MapBuildOrchestrator] quando há vértice sketch ativo.
class _SketchFreezeMapHarness extends StatelessWidget {
  const _SketchFreezeMapHarness({
    required this.controller,
    required this.mapController,
  });

  final DrawingController controller;
  final MapController mapController;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final freeze =
            controller.selectedSketchVertexIndex != null ||
            controller.isDraggingSketchVertex;
        return FlutterMap(
          mapController: mapController,
          options: MapOptions(
            initialCenter: const LatLng(0, 0),
            initialZoom: 11,
            interactionOptions: InteractionOptions(
              flags: freeze ? InteractiveFlag.none : InteractiveFlag.all,
            ),
          ),
          children: [
            DrawingEditLayer(
              controller: controller,
              mapController: mapController,
            ),
          ],
        );
      },
    );
  }
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
