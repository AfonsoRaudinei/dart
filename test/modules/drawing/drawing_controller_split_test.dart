import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:soloforte_app/modules/drawing/data/repositories/drawing_repository.dart';
import 'package:soloforte_app/modules/drawing/domain/models/drawing_models.dart';
import 'package:soloforte_app/modules/drawing/presentation/controllers/drawing_controller.dart';

DrawingMultiPolygon _twoPartMultiPolygon() {
  return DrawingMultiPolygon(
    coordinates: [
      [
        [
          [0.0, 0.0],
          [0.01, 0.0],
          [0.01, 0.01],
          [0.0, 0.0],
        ],
      ],
      [
        [
          [0.02, 0.02],
          [0.03, 0.02],
          [0.03, 0.03],
          [0.02, 0.02],
        ],
      ],
    ],
  );
}

class _SplitTestRepository extends DrawingRepository {
  final savedFeatures = <DrawingFeature>[];

  @override
  Future<List<DrawingFeature>> getAllFeatures() async {
    return List.of(savedFeatures);
  }

  @override
  Future<void> saveFeature(DrawingFeature feature) async {
    savedFeatures.removeWhere((f) => f.id == feature.id);
    savedFeatures.add(feature);
  }

  @override
  Future<void> deleteFeature(String id) async {
    savedFeatures.removeWhere((f) => f.id == id);
  }

  @override
  Future<double> getTotalAreaByClienteId(String clienteId) async {
    return savedFeatures
        .where(
          (f) =>
              f.properties.ativo &&
              f.properties.clienteId == clienteId,
        )
        .fold<double>(0.0, (total, f) => total + f.properties.areaHa);
  }

  @override
  Future<void> updateClientAreaTotal(String clientId, double areaTotal) async {}
}

Future<DrawingController> _controller() async {
  final repository = _SplitTestRepository();
  final controller = DrawingController(repository: repository);
  await controller.loadFeatures();
  return controller;
}

Future<DrawingFeature?> _saveMultiFeature(DrawingController controller) {
  return controller.addFeature(
    geometry: _twoPartMultiPolygon(),
    nome: 'Talhão Novo',
    tipo: DrawingType.talhao,
    origem: DrawingOrigin.importacao_kml,
    autorId: 'user-1',
    autorTipo: AuthorType.consultor,
    clienteId: 'cli-1',
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

  group('DrawingController - split / multi import', () {
    test('addFeaturesFromGeometry com MultiPolygon cria N features', () async {
      final controller = await _controller();

      final created = await controller.addFeaturesFromGeometry(
        geometry: _twoPartMultiPolygon(),
        nome: 'Talhão Novo',
        tipo: DrawingType.talhao,
        origem: DrawingOrigin.importacao_kml,
        autorId: 'user-1',
        autorTipo: AuthorType.consultor,
        clienteId: 'cli-1',
      );

      expect(created, hasLength(2));
      expect(controller.features, hasLength(2));
      expect(created[0].properties.nome, equals('Talhão 1'));
      expect(created[1].properties.nome, equals('Talhão 2'));
      expect(created.every((f) => f.geometry is DrawingPolygon), isTrue);
    });

    test('findFeatureAt encontra feature na segunda parte do MultiPolygon',
        () async {
      final controller = await _controller();
      await _saveMultiFeature(controller);

      final hit = controller.findFeatureAt(const LatLng(0.025, 0.025));
      expect(hit, isNotNull);
      expect(hit!.properties.nome, equals('Talhão Novo'));
    });

    test('splitSelectedFeature divide feature existente', () async {
      final controller = await _controller();
      await _saveMultiFeature(controller);
      expect(controller.features, hasLength(1));

      await controller.splitSelectedFeature();

      expect(controller.features, hasLength(2));
      expect(
        controller.features.every((f) => f.geometry is DrawingPolygon),
        isTrue,
      );
      expect(controller.selectedFeature?.properties.nome, equals('Talhão 1'));
      expect(
        controller.features.map((f) => f.properties.nome).toList(),
        equals(['Talhão 1', 'Talhão 2']),
      );
    });
  });
}
