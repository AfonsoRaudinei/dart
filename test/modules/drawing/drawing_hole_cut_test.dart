import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:soloforte_app/modules/drawing/data/repositories/drawing_repository.dart';
import 'package:soloforte_app/modules/drawing/domain/drawing_state.dart';
import 'package:soloforte_app/modules/drawing/domain/drawing_utils.dart';
import 'package:soloforte_app/modules/drawing/domain/models/drawing_models.dart';
import 'package:soloforte_app/modules/drawing/presentation/controllers/drawing_controller.dart';

const _outer = <List<double>>[
  [-47.93, -15.78],
  [-47.92, -15.78],
  [-47.92, -15.77],
  [-47.93, -15.77],
  [-47.93, -15.78],
];

class _HoleRepository extends DrawingRepository {
  _HoleRepository(this.features);

  final List<DrawingFeature> features;

  @override
  Future<List<DrawingFeature>> getAllFeatures() async => features;

  @override
  Future<void> saveFeature(DrawingFeature feature) async {}
}

DrawingFeature _brasiliaSquare() {
  final now = DateTime(2026, 10, 28);
  return DrawingFeature(
    id: 'talhao-bsb',
    geometry: DrawingPolygon(coordinates: [_outer]),
    properties: DrawingProperties(
      nome: 'Talhão BSB',
      tipo: DrawingType.talhao,
      origem: DrawingOrigin.desenho_manual,
      status: DrawingStatus.rascunho,
      autorId: 'user-1',
      autorTipo: AuthorType.consultor,
      areaHa: 100,
      versao: 1,
      ativo: true,
      createdAt: now,
      updatedAt: now,
      syncStatus: SyncStatus.synced,
    ),
  );
}

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

  late DrawingController controller;

  setUp(() async {
    controller = DrawingController(
      repository: _HoleRepository([_brasiliaSquare()]),
    );
    await controller.loadFeatures();
    await Future<void>.delayed(Duration.zero);
  });

  tearDown(() {
    controller.dispose();
  });

  test('recorta o miolo e desconta a área no mesmo talhão', () async {
    expect(controller.features, isNotEmpty);
    controller.selectFeature(controller.features.first);
    final outerArea = DrawingUtils.calculateGeometryArea(
      DrawingPolygon(coordinates: [_outer]),
    );

    controller.startHoleCut();

    expect(controller.currentState, DrawingState.armed);
    expect(controller.isCuttingHole, isTrue);
    expect(controller.selectedFeature, isNotNull);
    expect(controller.currentTool, DrawingTool.polygon);
    expect(controller.liveAreaHa, closeTo(outerArea, 1e-6));
    expect(
      controller.instructionText,
      'Desenhe o contorno da parte que sai da área',
    );

    controller.appendDrawingPoint(const LatLng(-15.777, -47.927));
    controller.appendDrawingPoint(const LatLng(-15.777, -47.923));
    controller.appendDrawingPoint(const LatLng(-15.773, -47.925));

    expect(controller.currentState, DrawingState.drawing);
    expect(controller.liveAreaHa, lessThan(outerArea));
    expect(controller.liveAreaHa, greaterThan(0));

    controller.completeDrawing();

    expect(controller.currentState, DrawingState.selected);
    expect(controller.isCuttingHole, isFalse);
    final selected = controller.selectedFeature!;
    final geometry = selected.geometry as DrawingPolygon;
    expect(geometry.coordinates, hasLength(2));
    expect(selected.properties.areaHa, lessThan(outerArea));
    expect(selected.properties.areaHa, greaterThan(0));
  });

  test('cancelar no armed volta para o talhão selecionado', () async {
    controller.selectFeature(controller.features.first);
    final id = controller.selectedFeature!.id;

    controller.startHoleCut();
    expect(controller.currentState, DrawingState.armed);
    expect(controller.isCuttingHole, isTrue);

    controller.cancelOperation();

    expect(controller.currentState, DrawingState.selected);
    expect(controller.isCuttingHole, isFalse);
    expect(controller.selectedFeature?.id, id);
  });

  test('ponto fora do talhão não confirma e permanece em drawing', () async {
    controller.selectFeature(controller.features.first);
    final outerArea = DrawingUtils.calculateGeometryArea(
      DrawingPolygon(coordinates: [_outer]),
    );

    controller.startHoleCut();
    controller.appendDrawingPoint(const LatLng(-15.777, -47.927));
    controller.appendDrawingPoint(const LatLng(-15.777, -47.923));
    controller.appendDrawingPoint(const LatLng(-15.775, -47.90));

    expect(controller.currentState, DrawingState.drawing);
    controller.completeDrawing();

    expect(controller.currentState, DrawingState.drawing);
    expect(controller.isCuttingHole, isTrue);
    expect(
      controller.intersectionWarningMessage,
      'O recorte precisa ficar dentro do talhão.',
    );
    expect(controller.liveAreaHa, closeTo(outerArea, 1e-6));
    final geometry = controller.selectedFeature!.geometry as DrawingPolygon;
    expect(geometry.coordinates, hasLength(1));
  });
}
