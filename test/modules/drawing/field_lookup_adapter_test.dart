import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/modules/drawing/data/data_sources/drawing_local_store.dart';
import 'package:soloforte_app/modules/drawing/domain/models/drawing_models.dart';
import 'package:soloforte_app/modules/drawing/infra/field_lookup_adapter.dart';

void main() {
  group('FieldLookupAdapter.listByFarmId', () {
    test('exclui tipo teste e mantém talhões da fazenda', () async {
      const farmId = 'farm-a';
      final store = _InMemoryDrawingStore([
        _drawing(id: 'tal-1', farmId: farmId, tipo: DrawingType.talhao),
        _drawing(id: 'test-1', farmId: farmId, tipo: DrawingType.teste),
        _drawing(id: 'tal-2', farmId: 'farm-b', tipo: DrawingType.talhao),
      ]);
      final adapter = FieldLookupAdapter(store);

      final result = await adapter.listByFarmId(farmId);

      expect(result.map((f) => f.id).toList(), ['tal-1']);
    });

    test('fazenda só com testes retorna lista vazia', () async {
      const farmId = 'farm-c';
      final store = _InMemoryDrawingStore([
        _drawing(id: 'test-2', farmId: farmId, tipo: DrawingType.teste),
      ]);
      final adapter = FieldLookupAdapter(store);

      final result = await adapter.listByFarmId(farmId);

      expect(result, isEmpty);
    });
  });
}

class _InMemoryDrawingStore extends DrawingLocalStore {
  _InMemoryDrawingStore(this._features);

  final List<DrawingFeature> _features;

  @override
  Future<List<DrawingFeature>> getAll() async => _features;
}

DrawingFeature _drawing({
  required String id,
  required String farmId,
  required DrawingType tipo,
}) {
  final now = DateTime.utc(2026, 11, 21);
  return DrawingFeature(
    id: id,
    geometry: DrawingPolygon(
      coordinates: [
        [
          [0.0, 0.0],
          [1.0, 0.0],
          [1.0, 1.0],
          [0.0, 1.0],
          [0.0, 0.0],
        ],
      ],
    ),
    properties: DrawingProperties(
      nome: id,
      tipo: tipo,
      origem: DrawingOrigin.desenho_manual,
      status: DrawingStatus.aprovado,
      autorId: 'user',
      autorTipo: AuthorType.consultor,
      areaHa: 1,
      versao: 1,
      ativo: true,
      createdAt: now,
      updatedAt: now,
      fazendaId: farmId,
    ),
  );
}