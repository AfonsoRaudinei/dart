import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:soloforte_app/modules/drawing/data/repositories/drawing_repository.dart';
import 'package:soloforte_app/modules/drawing/domain/models/drawing_models.dart';
import 'package:soloforte_app/modules/drawing/presentation/controllers/drawing_controller.dart';

class _BatchRepository extends DrawingRepository {
  final List<DrawingFeature> initial;
  final List<DrawingFeature> saved = [];

  _BatchRepository(this.initial);

  @override
  Future<List<DrawingFeature>> getAllFeatures() async => [...initial];

  @override
  Future<void> saveFeature(DrawingFeature feature) async {
    saved.add(feature);
  }

  @override
  Future<double> getTotalAreaByClienteId(String clienteId) async => 42;
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

  group('DrawingController batch actions', () {
    test('duplicar selecionados atualiza total do cliente', () async {
      final original = _feature(id: 'original');
      final repository = _BatchRepository([original]);
      final areaUpdates = <String, double>{};
      final controller = DrawingController(
        repository: repository,
        onClientAreaUpdate: (clientId, total) async {
          areaUpdates[clientId] = total;
        },
      );
      addTearDown(controller.dispose);
      await controller.loadFeatures();
      controller.setMultiSelectEnabled(true);
      controller.toggleFeatureSelection(original);

      await controller.duplicateSelectedFeatures();

      expect(controller.features, hasLength(2));
      expect(repository.saved, hasLength(1));
      expect(areaUpdates, {'client-1': 42});
    });

    test('mover selecionados cria nova versão e desativa anterior', () async {
      final original = _feature(id: 'original');
      final repository = _BatchRepository([original]);
      final areaUpdates = <String, double>{};
      final controller = DrawingController(
        repository: repository,
        onClientAreaUpdate: (clientId, total) async {
          areaUpdates[clientId] = total;
        },
      );
      addTearDown(controller.dispose);
      await controller.loadFeatures();
      controller.setMultiSelectEnabled(true);
      controller.toggleFeatureSelection(original);

      await controller.moveSelectedFeatures(deltaLat: 0.1, deltaLng: 0.1);

      expect(repository.saved, hasLength(2));
      expect(repository.saved.first.properties.ativo, isFalse);
      final moved = controller.features.single;
      expect(moved.id, isNot('original'));
      expect(moved.properties.versao, 2);
      expect(moved.properties.versaoAnteriorId, 'original');
      expect(moved.properties.syncStatus, SyncStatus.local_only);
      expect(controller.selectedFeatureIds, {moved.id});
      expect(areaUpdates, {'client-1': 42});
    });
  });
}

DrawingFeature _feature({required String id}) {
  final now = DateTime(2026);
  return DrawingFeature(
    id: id,
    geometry: DrawingPolygon(
      coordinates: [
        [
          [-48, -10],
          [-47.99, -10],
          [-47.99, -9.99],
          [-48, -10],
        ],
      ],
    ),
    properties: DrawingProperties(
      nome: 'Talhão',
      tipo: DrawingType.talhao,
      origem: DrawingOrigin.desenho_manual,
      status: DrawingStatus.rascunho,
      autorId: 'user-1',
      autorTipo: AuthorType.consultor,
      clienteId: 'client-1',
      areaHa: 1,
      versao: 1,
      ativo: true,
      createdAt: now,
      updatedAt: now,
      syncStatus: SyncStatus.synced,
    ),
  );
}
