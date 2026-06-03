import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:soloforte_app/modules/drawing/data/repositories/drawing_repository.dart';
import 'package:soloforte_app/modules/drawing/domain/models/drawing_models.dart';
import 'package:soloforte_app/modules/drawing/presentation/controllers/drawing_controller.dart';
import 'package:soloforte_app/modules/drawing/presentation/widgets/drawing_layers.dart';

class _Repository extends DrawingRepository {
  _Repository(this.features);

  final List<DrawingFeature> features;

  @override
  Future<List<DrawingFeature>> getAllFeatures() async => features;
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

  testWidgets('renderiza todas as partes de um MultiPolygon salvo', (
    tester,
  ) async {
    final repository = _Repository([
      _feature(
        DrawingMultiPolygon(
          coordinates: [
            [_square(0)],
            [_square(2)],
          ],
        ),
      ),
    ]);
    final controller = DrawingController(repository: repository);
    await controller.loadFeatures();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FlutterMap(
            options: const MapOptions(initialCenter: LatLng(0, 0)),
            children: [DrawingLayerWidget(controller: controller)],
          ),
        ),
      ),
    );

    final polygonLayer = tester.widget<PolygonLayer>(find.byType(PolygonLayer));
    expect(polygonLayer.polygons, hasLength(2));
  });

  testWidgets(
    'desenho manual em andamento renderiza halo e traço contrastante',
    (tester) async {
      final controller = DrawingController(repository: _Repository([]));
      addTearDown(controller.dispose);

      controller.selectTool('polygon');
      controller.appendDrawingPoint(const LatLng(-10.0, -48.0));
      controller.appendDrawingPoint(const LatLng(-10.001, -48.001));
      controller.appendDrawingPoint(const LatLng(-10.002, -48.0));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FlutterMap(
              options: const MapOptions(initialCenter: LatLng(-10, -48)),
              children: [DrawingLayerWidget(controller: controller)],
            ),
          ),
        ),
      );

      final polylineLayer = tester.widget<PolylineLayer>(
        find.byType(PolylineLayer),
      );
      expect(polylineLayer.polylines, hasLength(greaterThanOrEqualTo(2)));
      expect(polylineLayer.polylines.first.color, const Color(0xCC111111));
      expect(polylineLayer.polylines[1].color, Colors.white);
    },
  );
}

DrawingFeature _feature(DrawingGeometry geometry) {
  final now = DateTime(2026);
  return DrawingFeature(
    id: 'multi',
    geometry: geometry,
    properties: DrawingProperties(
      nome: 'Talhões importados',
      tipo: DrawingType.talhao,
      origem: DrawingOrigin.importacao_kml,
      status: DrawingStatus.rascunho,
      autorId: 'test',
      autorTipo: AuthorType.sistema,
      areaHa: 2,
      versao: 1,
      ativo: true,
      createdAt: now,
      updatedAt: now,
    ),
  );
}

List<List<double>> _square(double offset) => [
  [offset, offset],
  [offset + 1, offset],
  [offset + 1, offset + 1],
  [offset, offset + 1],
  [offset, offset],
];
