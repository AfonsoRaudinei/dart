import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/modules/consultoria/clients/domain/agronomic_models.dart';
import 'package:soloforte_app/modules/consultoria/services/talhao_map_adapter.dart';

Talhao _talhao(Map<String, dynamic>? geometry, {String id = 't1'}) {
  return Talhao(
    id: id,
    name: 'Talhão A',
    areaHa: 12.5,
    crop: 'Soja',
    harvest: '2025/26',
    geometry: geometry,
  );
}

const _outerRing = [
  [-47.93, -15.78],
  [-47.92, -15.78],
  [-47.92, -15.77],
  [-47.93, -15.77],
  [-47.93, -15.78],
];

const _holeRing = [
  [-47.927, -15.777],
  [-47.923, -15.777],
  [-47.923, -15.773],
  [-47.927, -15.773],
  [-47.927, -15.777],
];

List<List<double>> _shift(List<List<double>> ring, double dx, double dy) {
  return ring
      .map((p) => [p[0] + dx, p[1] + dy])
      .toList(growable: false);
}

void main() {
  group('TalhaoMapAdapter.toMapPolygons', () {
    test('Polygon simples gera um polígono sem furos', () {
      final polys = TalhaoMapAdapter.toMapPolygons(
        _talhao({'type': 'Polygon', 'coordinates': [_outerRing]}),
      );

      expect(polys, hasLength(1));
      expect(polys.first.points, isNotEmpty);
      expect(polys.first.holePointsList, isNull);
      expect(polys.first.label, isNotNull);
    });

    test('Polygon com furo expõe holePointsList', () {
      final polys = TalhaoMapAdapter.toMapPolygons(
        _talhao({
          'type': 'Polygon',
          'coordinates': [_outerRing, _holeRing],
        }),
      );

      expect(polys, hasLength(1));
      expect(polys.first.holePointsList, isNotNull);
      expect(polys.first.holePointsList!, hasLength(1));
      expect(polys.first.holePointsList!.first, isNotEmpty);
    });

    test('MultiPolygon gera N polígonos', () {
      final partB = _shift(_outerRing, 0.01, 0.01);
      final polys = TalhaoMapAdapter.toMapPolygons(
        _talhao({
          'type': 'MultiPolygon',
          'coordinates': [
            [_outerRing],
            [partB],
          ],
        }),
      );

      expect(polys, hasLength(2));
      expect(polys[0].points, isNotEmpty);
      expect(polys[1].points, isNotEmpty);
      expect(polys[0].label, isNotNull);
      expect(polys[1].label, isNull);
    });

    test('MultiPolygon com furo em uma parte', () {
      final polys = TalhaoMapAdapter.toMapPolygons(
        _talhao({
          'type': 'MultiPolygon',
          'coordinates': [
            [_outerRing, _holeRing],
            [_shift(_outerRing, 0.02, 0.0)],
          ],
        }),
      );

      expect(polys, hasLength(2));
      expect(polys.first.holePointsList, isNotNull);
      expect(polys.last.holePointsList, isNull);
    });

    test('geometria nula ou inválida retorna lista vazia', () {
      expect(TalhaoMapAdapter.toMapPolygons(_talhao(null)), isEmpty);
      expect(
        TalhaoMapAdapter.toMapPolygons(
          _talhao({'type': 'LineString', 'coordinates': []}),
        ),
        isEmpty,
      );
      expect(
        TalhaoMapAdapter.toMapPolygons(
          _talhao({'type': 'Polygon', 'coordinates': []}),
        ),
        isEmpty,
      );
    });
  });

  group('TalhaoMapAdapter.containsPoint / boundsSamplePoints', () {
    test('containsPoint respeita furo', () {
      final t = _talhao({
        'type': 'Polygon',
        'coordinates': [_outerRing, _holeRing],
      });
      expect(
        TalhaoMapAdapter.containsPoint(const LatLng(-15.775, -47.925), t),
        isFalse,
      );
      expect(
        TalhaoMapAdapter.containsPoint(const LatLng(-15.779, -47.929), t),
        isTrue,
      );
    });

    test('boundsSamplePoints inclui MultiPolygon', () {
      final t = _talhao({
        'type': 'MultiPolygon',
        'coordinates': [
          [_outerRing],
          [_shift(_outerRing, 0.05, 0.0)],
        ],
      });
      expect(TalhaoMapAdapter.boundsSamplePoints(t).length, greaterThan(4));
    });
  });

  group('TalhaoMapAdapter.toPolygon (legado)', () {
    test('mantém anel externo para chamadores antigos', () {
      final legacy = TalhaoMapAdapter.toPolygon(
        _talhao({
          'type': 'Polygon',
          'coordinates': [_outerRing, _holeRing],
        }),
      );
      expect(legacy.points, isNotEmpty);
      expect(legacy.holePointsList, isNull);
    });
  });
}
