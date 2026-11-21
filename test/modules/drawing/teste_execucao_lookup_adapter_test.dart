import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/modules/drawing/data/data_sources/drawing_local_store.dart';
import 'package:soloforte_app/modules/drawing/domain/models/drawing_models.dart';
import 'package:soloforte_app/modules/drawing/domain/models/teste_execucao.dart';
import 'package:soloforte_app/modules/drawing/infra/teste_execucao_lookup_adapter.dart';

void main() {
  test('listByClient retorna só execuções do cliente e exclui outras fazendas', () async {
    const clientId = 'c1';
    const farmA = 'f1';
    final drawingStore = _FakeDrawingStore([
      _drawing(id: 'd-tal', clientId: clientId, farmId: farmA, tipo: DrawingType.talhao),
      _drawing(id: 'd-test-a', clientId: clientId, farmId: farmA, tipo: DrawingType.teste),
      _drawing(id: 'd-test-b', clientId: clientId, farmId: 'f2', tipo: DrawingType.teste),
    ]);
    final execStore = _FakeExecStore({
      'd-test-a': [
        TesteExecucao(
          id: 'exec-a',
          drawingId: 'd-test-a',
          userId: 'u',
          syncStatus: SyncStatus.synced,
          talhao: 'Talhão A',
          criadoEm: DateTime.utc(2026),
          atualizadoEm: DateTime.utc(2026),
        ),
      ],
      'd-test-b': [
        TesteExecucao(
          id: 'exec-b',
          drawingId: 'd-test-b',
          userId: 'u',
          syncStatus: SyncStatus.synced,
          criadoEm: DateTime.utc(2026),
          atualizadoEm: DateTime.utc(2026),
        ),
      ],
    });

    final adapter = TesteExecucaoLookupAdapter(
      drawingStore: drawingStore,
      execucaoStore: execStore,
    );

    final all = await adapter.listByClient(clientId: clientId);
    expect(all.map((e) => e.id), containsAll(['exec-a', 'exec-b']));

    final farmOnly = await adapter.listByClient(
      clientId: clientId,
      farmId: farmA,
    );
    expect(farmOnly.map((e) => e.id).toList(), ['exec-a']);
  });
}

class _FakeDrawingStore extends DrawingLocalStore {
  _FakeDrawingStore(this._features);

  final List<DrawingFeature> _features;

  @override
  Future<List<DrawingFeature>> getAll() async => _features;
}

class _FakeExecStore extends TesteExecucaoLocalStore {
  _FakeExecStore(this._byDrawing);

  final Map<String, List<TesteExecucao>> _byDrawing;

  @override
  Future<List<TesteExecucao>> findByDrawingId(String drawingId) async =>
      _byDrawing[drawingId] ?? const [];
}

DrawingFeature _drawing({
  required String id,
  required String clientId,
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
      areaHa: 2.5,
      versao: 1,
      ativo: true,
      createdAt: now,
      updatedAt: now,
      clienteId: clientId,
      fazendaId: farmId,
    ),
  );
}