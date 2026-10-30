import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:soloforte_app/core/geo/geo_json_polygon_geometry.dart';

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

List<LatLng> _outerOnly(String? raw) {
  if (raw == null) return const [];
  final json = jsonDecode(raw) as Map<String, dynamic>;
  final type = json['type'];
  final coordinates = json['coordinates'];
  if (type == 'Polygon') {
    final ring = (coordinates as List).first as List;
    return _ringToLatLng(ring);
  }
  if (type == 'MultiPolygon') {
    final firstPolygon = (coordinates as List).first as List;
    return _ringToLatLng(firstPolygon.first as List);
  }
  return const [];
}

List<LatLng> _ringToLatLng(List ring) {
  return ring
      .whereType<List>()
      .where((p) => p.length >= 2)
      .map(
        (p) => LatLng((p[1] as num).toDouble(), (p[0] as num).toDouble()),
      )
      .toList(growable: false);
}

void main() {
  test('desenho: primeiro anel; bbox: todas as partes com furo', () {
    final raw = jsonEncode({
      'type': 'Polygon',
      'coordinates': [_outerRing, _holeRing],
    });
    final draw = _outerOnly(raw);
    final bounds = geoJsonVerticesForBounds(raw);

    expect(draw.length, _outerRing.length);
    expect(bounds.length, greaterThan(draw.length));
  });

  test('MultiPolygon: desenho 1ª parte; bbox inclui segunda', () {
    final partB = _outerRing
        .map((p) => [p[0] + 0.05, p[1]])
        .toList(growable: false);
    final raw = jsonEncode({
      'type': 'MultiPolygon',
      'coordinates': [
        [_outerRing],
        [partB],
      ],
    });
    final draw = _outerOnly(raw);
    final bounds = geoJsonVerticesForBounds(raw);
    final lngs = bounds.map((p) => p.longitude).toSet();

    expect(draw.length, _outerRing.length);
    expect(lngs.any((lng) => lng >= -47.88), isTrue);
  });
}
