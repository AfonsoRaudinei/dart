import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:soloforte_app/modules/drawing/data/repositories/drawing_repository.dart';
import 'package:soloforte_app/modules/drawing/domain/drawing_state.dart';
import 'package:soloforte_app/modules/drawing/domain/models/drawing_models.dart';
import 'package:soloforte_app/modules/drawing/presentation/controllers/drawing_controller.dart';
import 'package:soloforte_app/modules/drawing/presentation/providers/drawing_provider.dart';
import 'package:soloforte_app/modules/drawing/presentation/widgets/drawing_edit_layer.dart';
import 'package:soloforte_app/modules/drawing/presentation/widgets/drawing_vertex_drag_overlay.dart';
import 'package:soloforte_app/modules/drawing/presentation/widgets/drawing_vertex_gota_metrics.dart';
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

  testWidgets(
    'overlay acima do mapa com InteractiveFlag.all move vértice em edição',
    (tester) async {
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
      controller.selectEditVertex(0, 0);

      final mapController = MapController();
      final container = ProviderContainer(
        overrides: [
          drawingControllerProvider.overrideWith((ref) => controller),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: Stack(
                children: [
                  FlutterMap(
                    mapController: mapController,
                    options: const MapOptions(
                      initialCenter: LatLng(0, 0),
                      initialZoom: 13,
                      interactionOptions: InteractionOptions(
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
                  DrawingVertexDragOverlay(
                    mapController: mapController,
                    isMapReady: true,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final before =
          (controller.liveGeometry! as DrawingPolygon).coordinates.first.first;
      final vertex = LatLng(before[1], before[0]);
      final screen = mapController.camera.latLngToScreenPoint(vertex);
      final start = Offset(
        screen.x,
        screen.y - DrawingVertexGotaMetrics.height * 0.55,
      );

      await tester.dragFrom(start, const Offset(48, 32));
      await tester.pumpAndSettle();

      final after =
          (controller.liveGeometry! as DrawingPolygon).coordinates.first.first;
      expect(after, isNot(equals(before)));
    },
  );

  testWidgets(
    'overlay move vértice do sketch com gota selecionada',
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
      controller.selectSketchVertex(1);

      final mapController = MapController();
      final container = ProviderContainer(
        overrides: [
          drawingControllerProvider.overrideWith((ref) => controller),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: Stack(
                children: [
                  FlutterMap(
                    mapController: mapController,
                    options: const MapOptions(
                      initialCenter: LatLng(0, 0),
                      initialZoom: 11,
                      interactionOptions: InteractionOptions(
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
                  DrawingVertexDragOverlay(
                    mapController: mapController,
                    isMapReady: true,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final before = controller.currentPoints[1];
      final screen = mapController.camera.latLngToScreenPoint(before);
      final start = Offset(
        screen.x,
        screen.y - DrawingVertexGotaMetrics.height * 0.55,
      );

      await tester.dragFrom(start, const Offset(56, 40));
      await tester.pumpAndSettle();

      expect(controller.currentPoints[1], isNot(equals(before)));
    },
  );

  testWidgets('toque fora da gota no overlay limpa seleção de edição', (
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
    await controller.loadFeatures();
    controller.selectFeature(controller.features.single);
    controller.startEditMode();
    controller.selectEditVertex(0, 0);

    final mapController = MapController();
    final container = ProviderContainer(
      overrides: [
        drawingControllerProvider.overrideWith((ref) => controller),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                FlutterMap(
                  mapController: mapController,
                  options: const MapOptions(
                    initialCenter: LatLng(0, 0),
                    initialZoom: 13,
                    interactionOptions: InteractionOptions(
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
                DrawingVertexDragOverlay(
                  mapController: mapController,
                  isMapReady: true,
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tapAt(const Offset(12, 12));
    await tester.pumpAndSettle();

    expect(controller.selectedEditRingIndex, isNull);
    expect(controller.selectedEditPointIndex, isNull);
  });
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

class _UpsertDrawingRepository extends DrawingRepository {
  _UpsertDrawingRepository(this.initial);

  final DrawingFeature initial;
  final List<DrawingFeature> features = [];

  @override
  Future<List<DrawingFeature>> getAllFeatures() async {
    if (features.isEmpty) return [initial];
    return List.of(features);
  }

  @override
  Future<void> saveFeature(DrawingFeature feature) async {
    features.removeWhere((f) => f.id == feature.id);
    features.add(feature);
  }
}
