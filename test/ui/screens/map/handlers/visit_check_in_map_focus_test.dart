import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:soloforte_app/modules/consultoria/clients/domain/agronomic_models.dart';
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

    test('false só produtor', () {
      expect(
        visitCheckInNavigateToAreaEnabled(
          clientId: 'c1',
          farmId: null,
          talhaoId: null,
        ),
        isFalse,
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
}
