import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:soloforte_app/modules/consultoria/clients/domain/agronomic_models.dart';
import 'package:soloforte_app/modules/consultoria/clients/presentation/providers/field_providers.dart';
import 'package:soloforte_app/modules/consultoria/occurrences/domain/occurrence.dart';
import 'package:soloforte_app/ui/screens/map/handlers/visit_check_in_map_focus.dart';

void main() {
  group('visitCheckInNavigateToAreaEnabled', () {
    test('false sem produtor', () {
      expect(
        visitCheckInNavigateToAreaEnabled(
          clientId: null,
          farmId: 'f1',
          talhaoId: null,
        ),
        isFalse,
      );
    });

    test('true só produtor (permite buscar por desenhos/ocorrências)', () {
      expect(
        visitCheckInNavigateToAreaEnabled(
          clientId: 'c1',
          farmId: null,
          talhaoId: null,
        ),
        isTrue,
      );
    });

    test('true com fazenda', () {
      expect(
        visitCheckInNavigateToAreaEnabled(
          clientId: 'c1',
          farmId: 'f1',
          talhaoId: null,
        ),
        isTrue,
      );
    });

    test('true com talhão', () {
      expect(
        visitCheckInNavigateToAreaEnabled(
          clientId: 'c1',
          farmId: null,
          talhaoId: 't1',
        ),
        isTrue,
      );
    });
  });

  group('visitCheckInMapFocusSamplePoints', () {
    Talhao talhao(String id, Map<String, dynamic>? geometry) => Talhao(
      id: id,
      name: id,
      areaHa: 1,
      crop: 'Soja',
      harvest: '2024/2025',
      geometry: geometry,
    );

    const square = {
      'type': 'Polygon',
      'coordinates': [
        [
          [-47.0, -15.0],
          [-47.01, -15.0],
          [-47.01, -15.01],
          [-47.0, -15.01],
          [-47.0, -15.0],
        ],
      ],
    };

    test('talhão específico com geometria', () {
      final fields = [
        talhao('t1', square),
        talhao('t2', null),
      ];
      final points = visitCheckInMapFocusSamplePoints(
        farmFields: fields,
        talhaoId: 't1',
      );
      expect(points, isNotEmpty);
      expect(points.first, isA<LatLng>());
    });

    test('talhão inexistente retorna vazio', () {
      final points = visitCheckInMapFocusSamplePoints(
        farmFields: [talhao('t1', square)],
        talhaoId: 'missing',
      );
      expect(points, isEmpty);
    });

    test('fazenda inteira agrega talhões com geometria', () {
      final fields = [
        talhao('t1', square),
        talhao('t2', null),
      ];
      final points = visitCheckInMapFocusSamplePoints(
        farmFields: fields,
        talhaoId: null,
      );
      expect(points.length, greaterThan(4));
    });

    test('sem geometria retorna vazio', () {
      final points = visitCheckInMapFocusSamplePoints(
        farmFields: [talhao('t1', null)],
        talhaoId: null,
      );
      expect(points, isEmpty);
    });
  });

  group('visitCheckInMapFocusPointsFromLinked', () {
    const square = [
      LatLng(-15, -47),
      LatLng(-15, -47.01),
      LatLng(-15.01, -47.01),
      LatLng(-15.01, -47),
    ];

    test('fazenda usa polígono desenhado no mapa', () {
      const fields = [
        FarmLinkedFieldSummary(
          id: 'cadastro',
          name: 'Sem contorno',
          areaHa: 1,
          source: FarmLinkedFieldSource.field,
        ),
        FarmLinkedFieldSummary(
          id: 'drawing-1',
          name: 'Talhão do mapa',
          areaHa: 12,
          source: FarmLinkedFieldSource.drawing,
          boundsVertices: square,
        ),
      ];

      final points = visitCheckInMapFocusPointsFromLinked(
        fields: fields,
        talhaoId: null,
      );
      expect(points, square);
    });

    test('talhão sem contorno enquadra os polígonos da fazenda', () {
      const fields = [
        FarmLinkedFieldSummary(
          id: 't1',
          name: 'Cadastro',
          areaHa: 1,
          source: FarmLinkedFieldSource.field,
        ),
        FarmLinkedFieldSummary(
          id: 'drawing-1',
          name: 'Mapa',
          areaHa: 12,
          source: FarmLinkedFieldSource.drawing,
          boundsVertices: square,
        ),
      ];

      final points = visitCheckInMapFocusPointsFromLinked(
        fields: fields,
        talhaoId: 't1',
      );
      expect(points, square);
    });

    test('cadastro com geometria sem desenho não bloqueia fallback', () {
      const fields = [
        FarmLinkedFieldSummary(
          id: 't1',
          name: 'Cadastro com KML',
          areaHa: 1,
          source: FarmLinkedFieldSource.field,
          boundsVertices: square,
        ),
      ];

      final points = visitCheckInMapFocusPointsFromLinked(
        fields: fields,
        talhaoId: null,
      );
      expect(points, isEmpty);
    });
  });

  group('visitCheckInMapFocusPointsFromOccurrences', () {
    test('usa lat/long das ocorrências do produtor', () {
      final points = visitCheckInMapFocusPointsFromOccurrences([
        Occurrence(
          id: 'o1',
          type: 'doenca',
          description: 'Teste',
          lat: -15.5,
          long: -47.5,
          clientId: 'c1',
          createdAt: DateTime.utc(2026, 1, 1),
        ),
        Occurrence(
          id: 'o2',
          type: 'insetos',
          description: 'Sem coords',
          clientId: 'c1',
          createdAt: DateTime.utc(2026, 1, 2),
        ),
      ]);
      expect(points, [const LatLng(-15.5, -47.5)]);
    });
  });
}
