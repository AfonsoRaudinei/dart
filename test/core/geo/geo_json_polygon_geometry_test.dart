import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:soloforte_app/core/geo/geo_json_polygon_geometry.dart';
import 'package:soloforte_app/ui/screens/map/utils/field_hit_index.dart';

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
  return ring.map((p) => [p[0] + dx, p[1] + dy]).toList(growable: false);
}

Map<String, dynamic> _polygonGeo(List<List<List<double>>> rings) {
  return {'type': 'Polygon', 'coordinates': rings};
}

void main() {
  group('geoJsonContainsLatLngMap', () {
    test('parte externa conta como dentro', () {
      final geo = _polygonGeo([_outerRing]);
      expect(
        geoJsonContainsLatLngMap(geo, const LatLng(-15.775, -47.925)),
        isTrue,
      );
    });

    test('fora das partes retorna false', () {
      final geo = _polygonGeo([_outerRing]);
      expect(
        geoJsonContainsLatLngMap(geo, const LatLng(-15.70, -47.70)),
        isFalse,
      );
    });

    test('ponto no furo não conta', () {
      final geo = _polygonGeo([_outerRing, _holeRing]);
      expect(
        geoJsonContainsLatLngMap(geo, const LatLng(-15.775, -47.925)),
        isFalse,
      );
      expect(
        geoJsonContainsLatLngMap(geo, const LatLng(-15.779, -47.929)),
        isTrue,
      );
    });

    test('MultiPolygon: qualquer parte', () {
      final geo = {
        'type': 'MultiPolygon',
        'coordinates': [
          [_outerRing],
          [_shift(_outerRing, 0.05, 0.05)],
        ],
      };
      expect(
        geoJsonContainsLatLngMap(geo, const LatLng(-15.775, -47.925)),
        isTrue,
      );
      expect(
        geoJsonContainsLatLngMap(geo, const LatLng(-15.725, -47.875)),
        isTrue,
      );
      expect(
        geoJsonContainsLatLngMap(geo, const LatLng(-15.70, -47.70)),
        isFalse,
      );
    });
  });

  group('geoJsonVerticesForBounds', () {
    test('MultiPolygon inclui vértices de todas as partes', () {
      final geo = jsonEncode({
        'type': 'MultiPolygon',
        'coordinates': [
          [_outerRing],
          [_shift(_outerRing, 0.05, 0.0)],
        ],
      });
      final verts = geoJsonVerticesForBounds(geo);
      expect(verts.length, greaterThan(_outerRing.length));
      final lngs = verts.map((v) => v.longitude).toSet();
      expect(lngs.any((lng) => lng <= -47.93), isTrue);
      expect(lngs.any((lng) => lng >= -47.88), isTrue);
    });
  });

  group('FieldHitIndex', () {
    test('hit em parte e rejeita furo', () {
      final geo = _polygonGeo([_outerRing, _holeRing]);
      final index = FieldHitIndex(
        entries: [(id: 't1', geometry: geo)],
      );

      final insideHole = index.hitTest(
        const LatLng(-15.775, -47.925),
        (p, geo) => geoJsonContainsLatLngMap(geo, p),
      );
      expect(insideHole, isNull);

      final insideField = index.hitTest(
        const LatLng(-15.779, -47.929),
        (p, geo) => geoJsonContainsLatLngMap(geo, p),
      );
      expect(insideField, 't1');
    });
  });
}
