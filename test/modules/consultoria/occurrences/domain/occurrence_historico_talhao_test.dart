import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/core/contracts/i_field_lookup.dart';
import 'package:soloforte_app/modules/consultoria/occurrences/domain/occurrence.dart';
import 'package:soloforte_app/modules/consultoria/occurrences/domain/occurrence_historico_talhao.dart';

void main() {
  final square = jsonEncode({
    'type': 'Polygon',
    'coordinates': [
      [
        [-48.3, -10.3],
        [-48.1, -10.3],
        [-48.1, -10.1],
        [-48.3, -10.1],
        [-48.3, -10.3],
      ],
    ],
  });

  FieldSummary field({List<double>? bbox}) => FieldSummary(
    id: 'field-1',
    name: 'Talhão 7',
    farmId: 'farm-1',
    bbox: bbox,
    geometry: square,
  );

  Occurrence row({
    required String id,
    String description = 'Ferrugem',
    String? category = 'doenca',
    String? clientId = 'cli-1',
    String? fieldId,
    double? lat = -10.2,
    double? lng = -48.2,
    DateTime? createdAt,
    String? estadio,
    String? notas,
    bool amostraSolo = false,
    String syncStatus = 'local_only',
    String? deletedAt,
  }) {
    return Occurrence(
      id: id,
      clientId: clientId,
      type: 'Média',
      description: description,
      category: category,
      lat: lat,
      long: lng,
      fieldId: fieldId,
      createdAt: createdAt ?? DateTime(2024, 1, 1),
      estadioFenologico: estadio,
      notasCategoriasJson: notas,
      amostraSolo: amostraSolo,
      syncStatus: syncStatus,
      deletedAt: deletedAt,
    );
  }

  group('normalizeOccurrencePragaText', () {
    test('colapsa espaço e caixa', () {
      expect(
        normalizeOccurrencePragaText('  Ferrugem\n\t da   soja '),
        'ferrugem da soja',
      );
    });

    test('vazio vira null', () {
      expect(normalizeOccurrencePragaText('   '), isNull);
      expect(normalizeOccurrencePragaText(null), isNull);
    });
  });

  group('occurrencePragaKey', () {
    test('descrição vazia usa a nota da categoria ativa', () {
      final occurrence = row(
        id: 'n1',
        description: '  ',
        category: 'doenca',
        notas: jsonEncode({'doenca': '  Ferrugem  ', 'insetos': 'lagarta'}),
      );
      expect(occurrencePragaKey(occurrence), 'ferrugem');
    });

    test('nota vazia da categoria ativa não pega outra categoria', () {
      final occurrence = row(
        id: 'n2',
        description: '',
        category: 'doenca',
        notas: jsonEncode({'doenca': '  ', 'insetos': 'lagarta'}),
      );
      expect(occurrencePragaKey(occurrence), isNull);
    });
  });

  group('formatHistoricoTalhaoCopy', () {
    test('omite quando count < 2', () {
      expect(
        formatHistoricoTalhaoCopy(
          pragaKey: 'ferrugem',
          count: 1,
          estadio: 'R5',
          latestAt: DateTime(2026, 8, 15),
        ),
        isNull,
      );
    });

    test('plural e estádio da última', () {
      expect(
        formatHistoricoTalhaoCopy(
          pragaKey: 'ferrugem',
          count: 3,
          estadio: 'R5',
          latestAt: DateTime(2026, 8, 15),
        ),
        'Ferrugem apareceu 3 vezes; a última em R5.',
      );
    });

    test('sem estádio cai na data', () {
      expect(
        formatHistoricoTalhaoCopy(
          pragaKey: 'ferrugem asiática',
          count: 2,
          latestAt: DateTime(2026, 8, 15),
        ),
        'Ferrugem asiática apareceu 2 vezes; a última em data 15/08/2026.',
      );
    });
  });

  group('buildOccurrenceHistoricoTalhaoLinha', () {
    test('conta o registro atual e o legado dentro do polígono', () {
      final current = row(
        id: 'now',
        fieldId: 'field-1',
        createdAt: DateTime(2026, 8, 1),
        estadio: 'R1',
      );
      final legacy = row(
        id: 'old',
        createdAt: DateTime(2025, 3, 2),
        estadio: 'V4',
      );
      final line = buildOccurrenceHistoricoTalhaoLinha(
        current: current,
        candidates: [legacy],
        fieldId: 'field-1',
        field: field(),
      );
      expect(line, 'Ferrugem apareceu 2 vezes; a última em R1.');
    });

    test('a última é a mais nova, mesmo fora da lista de candidatos', () {
      final current = row(
        id: 'now',
        fieldId: 'field-1',
        createdAt: DateTime(2024, 1, 1),
        estadio: 'V4',
      );
      final newer = row(
        id: 'newer',
        fieldId: 'field-1',
        createdAt: DateTime(2026, 9, 1),
        estadio: 'R5',
      );
      final line = buildOccurrenceHistoricoTalhaoLinha(
        current: current,
        candidates: [newer],
        fieldId: 'field-1',
        field: field(),
      );
      expect(line, 'Ferrugem apareceu 2 vezes; a última em R5.');
    });

    test('omite com um único match', () {
      final current = row(id: 'only', fieldId: 'field-1');
      expect(
        buildOccurrenceHistoricoTalhaoLinha(
          current: current,
          candidates: [current],
          fieldId: 'field-1',
          field: field(),
        ),
        isNull,
      );
    });

    test('field_id diferente não entra, mesmo com ponto dentro', () {
      final current = row(id: 'a', fieldId: 'field-1');
      final other = row(id: 'b', fieldId: 'field-2', estadio: 'R5');
      expect(
        buildOccurrenceHistoricoTalhaoLinha(
          current: current,
          candidates: [current, other],
          fieldId: 'field-1',
          field: field(),
        ),
        isNull,
      );
    });

    test('legado fora do polígono e bbox não entra', () {
      final current = row(id: 'a', fieldId: 'field-1');
      final outside = row(id: 'b', lat: 5, lng: 5);
      expect(
        occurrenceMatchesField(
          occurrence: outside,
          fieldId: 'field-1',
          field: field(bbox: const [0, 0, 1, 1]),
        ),
        isFalse,
      );
      expect(
        buildOccurrenceHistoricoTalhaoLinha(
          current: current,
          candidates: [outside],
          fieldId: 'field-1',
          field: field(),
        ),
        isNull,
      );
    });

    test('ignora outro cliente, exclusão lógica e categorias fora', () {
      final current = row(id: 'a', fieldId: 'field-1', estadio: 'R5');
      final others = [
        row(id: 'b', fieldId: 'field-1', clientId: 'outro'),
        row(id: 'c', fieldId: 'field-1', syncStatus: 'deleted_local'),
        row(id: 'd', fieldId: 'field-1', deletedAt: '2026-01-01'),
        row(id: 'e', fieldId: 'field-1', category: 'area_visitada'),
        row(id: 'f', fieldId: 'field-1', category: 'amostra_solo'),
        row(id: 'g', fieldId: 'field-1', description: 'lagarta'),
      ];
      expect(
        buildOccurrenceHistoricoTalhaoLinha(
          current: current,
          candidates: [current, ...others],
          fieldId: 'field-1',
          field: field(),
        ),
        isNull,
      );
    });

    test('candidato com o mesmo id não esconde a ocorrência atual', () {
      final current = row(
        id: 'same',
        description: 'Ferrugem',
        fieldId: 'field-1',
        createdAt: DateTime(2026, 9, 1),
        estadio: 'R5',
      );
      final stale = row(
        id: 'same',
        description: 'lagarta',
        fieldId: 'field-1',
        createdAt: DateTime(2020, 1, 1),
      );
      final other = row(
        id: 'other',
        fieldId: 'field-1',
        createdAt: DateTime(2024, 1, 1),
        estadio: 'V4',
      );
      expect(
        buildOccurrenceHistoricoTalhaoLinha(
          current: current,
          candidates: [stale, other],
          fieldId: 'field-1',
          field: field(),
        ),
        'Ferrugem apareceu 2 vezes; a última em R5.',
      );
    });

    test('sem chave de praga não gera linha', () {
      final current = row(id: 'a', description: ' ', fieldId: 'field-1');
      final other = row(id: 'b', description: ' ', fieldId: 'field-1');
      expect(
        buildOccurrenceHistoricoTalhaoLinha(
          current: current,
          candidates: [other],
          fieldId: 'field-1',
          field: field(),
        ),
        isNull,
      );
    });
  });
}
