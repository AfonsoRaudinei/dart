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
import 'package:soloforte_app/modules/drawing/presentation/widgets/drawing_vertex_drag_handle.dart';
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

  testWidgets('durante o desenho arrasta vértice sem sair do sketch', (
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
    controller.appendDrawingPoint(const LatLng(0.0, 0.0));
    controller.appendDrawingPoint(const LatLng(0.01, 0.0));
    controller.appendDrawingPoint(const LatLng(0.01, 0.01));

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

    final handle = find.byKey(const Key('drawing_vertex_0_1'));
    expect(handle, findsOneWidget);
    final before = controller.currentPoints[1];

    await tester.drag(handle, const Offset(36, 24));
    await tester.pumpAndSettle();

    expect(controller.currentPoints[1], isNot(equals(before)));
    expect(controller.currentState, DrawingState.drawing);
    expect(controller.currentPoints.length, 3);
  });

  testWidgets('DrawingVertexDragHandle renderiza pingo azul', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(child: DrawingVertexDragHandle()),
        ),
      ),
    );
    expect(find.byType(DrawingVertexDragHandle), findsOneWidget);
    expect(find.byType(CustomPaint), findsWidgets);
  });
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
