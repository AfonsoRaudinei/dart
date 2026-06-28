import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:soloforte_app/modules/drawing/data/repositories/drawing_repository.dart';
import 'package:soloforte_app/modules/drawing/domain/models/drawing_models.dart';
import 'package:soloforte_app/modules/drawing/domain/models/drawing_visual_style.dart';
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

  testWidgets('primeiro toque renderiza imediatamente o ponto inicial', (
    tester,
  ) async {
    final controller = DrawingController(repository: _Repository([]));
    addTearDown(controller.dispose);

    controller.selectTool('polygon');
    controller.appendDrawingPoint(const LatLng(-10.0, -48.0));

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

    expect(find.byKey(const Key('drawing_point_0')), findsOneWidget);
    final markerLayer = tester.widget<MarkerLayer>(find.byType(MarkerLayer));
    expect(markerLayer.markers.single.point, const LatLng(-10.0, -48.0));
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

  testWidgets('poligono salvo usa contraste reforcado no estado padrao', (
    tester,
  ) async {
    final repository = _Repository([
      _feature(
        DrawingPolygon(coordinates: [_square(0)]),
        status: DrawingStatus.aprovado,
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
    final polygon = polygonLayer.polygons.single;

    expect(
      polygon.color,
      FieldStyle.standard.fillColor.withValues(alpha: 0.28),
    );
    expect(polygon.borderColor, FieldStyle.standard.borderColor);
    expect(polygon.borderStrokeWidth, FieldStyle.standard.borderWidth);
  });

  testWidgets('poligono selecionado preserva destaque visual de selecao', (
    tester,
  ) async {
    final feature = _feature(
      DrawingPolygon(coordinates: [_square(0)]),
      status: DrawingStatus.aprovado,
    );
    final controller = DrawingController(repository: _Repository([feature]));
    await controller.loadFeatures();
    controller.selectFeature(feature);
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
    final polygon = polygonLayer.polygons.single;

    expect(
      polygon.color,
      FieldStyle.selected.fillColor.withValues(alpha: 0.34),
    );
    expect(polygon.borderColor, FieldStyle.selected.borderColor);
    expect(polygon.borderStrokeWidth, FieldStyle.selected.borderWidth);
  });

  testWidgets('cor personalizada mantem preenchimento e reforca a borda', (
    tester,
  ) async {
    const customColor = Color(0xFF4CAF50);
    final repository = _Repository([
      _feature(
        DrawingPolygon(coordinates: [_square(0)]),
        status: DrawingStatus.aprovado,
        cor: customColor.toARGB32(),
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
    final polygon = polygonLayer.polygons.single;

    expect(polygon.color, customColor.withValues(alpha: 0.26));
    expect(polygon.borderColor, isNot(customColor));
    expect(polygon.borderStrokeWidth, 3.0);
  });
}

DrawingFeature _feature(
  DrawingGeometry geometry, {
  DrawingStatus status = DrawingStatus.rascunho,
  int? cor,
}) {
  final now = DateTime(2026);
  return DrawingFeature(
    id: 'multi',
    geometry: geometry,
    properties: DrawingProperties(
      nome: 'Talhões importados',
      tipo: DrawingType.talhao,
      origem: DrawingOrigin.importacao_kml,
      status: status,
      autorId: 'test',
      autorTipo: AuthorType.sistema,
      areaHa: 2,
      versao: 1,
      ativo: true,
      createdAt: now,
      updatedAt: now,
      cor: cor,
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
