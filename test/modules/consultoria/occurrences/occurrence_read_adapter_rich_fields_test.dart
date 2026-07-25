import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/modules/consultoria/occurrences/data/occurrence_repository.dart';
import 'package:soloforte_app/modules/consultoria/occurrences/domain/occurrence.dart';
import 'package:soloforte_app/modules/consultoria/occurrences/infra/occurrence_read_adapter.dart';

class _FakeOccurrenceRepository extends OccurrenceRepository {
  _FakeOccurrenceRepository(this._items);

  final List<Occurrence> _items;

  @override
  Future<List<Occurrence>> getOccurrencesBySession(String sessionId) async {
    return _items
        .where((o) => o.visitSessionId == sessionId)
        .toList(growable: false);
  }
}

void main() {
  group('OccurrenceReadAdapter ADR-047', () {
    test('mapeia campos agronômicos ricos para OccurrenceSummary', () async {
      final occurrence = Occurrence(
        id: 'occ-1',
        visitSessionId: 'sess-1',
        type: 'Alta',
        description: 'Ferrugem no terço médio',
        photoPath: '/tmp/foto.jpg',
        lat: -10.1,
        long: -48.2,
        createdAt: DateTime.utc(2026, 7, 1, 12),
        category: 'doenca',
        status: 'confirmed',
        geometry: '{"type":"Point"}',
        cultivar: 'TMG 2183',
        estadioFenologico: 'R5.1',
        tipoOcorrencia: 'sazonal',
        recomendacoes: 'Aplicar fungicida',
        metricasJson: '{"doenca":{"severidade":3}}',
        nutrientesJson: '["N","K"]',
        categoriasJson: '["doenca"]',
        notasCategoriasJson: '{"doenca":"foco"}',
        fotosCategoriasJson: '{"doenca":["/tmp/foto.jpg"]}',
      );

      final adapter = OccurrenceReadAdapter(
        _FakeOccurrenceRepository([occurrence]),
      );

      final list = await adapter.getBySessionId('sess-1');
      expect(list, hasLength(1));
      final s = list.single;
      expect(s.id, 'occ-1');
      expect(s.type, 'doenca');
      expect(s.categoria, 'doenca');
      expect(s.cultivar, 'TMG 2183');
      expect(s.estadioFenologico, 'R5.1');
      expect(s.recomendacoes, 'Aplicar fungicida');
      expect(s.metricasJson, contains('severidade'));
      expect(s.fotoPaths, ['/tmp/foto.jpg']);
      expect(s.geometry, contains('Point'));
      expect(s.status, 'confirmed');
    });
  });
}
