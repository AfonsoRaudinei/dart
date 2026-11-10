import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/modules/consultoria/occurrences/domain/occurrence_point_in_field.dart';

void main() {
  // Quadrado lng -48.40..-48.30, lat -10.80..-10.70, com buraco no centro.
  final outer = [
    [-48.40, -10.80],
    [-48.30, -10.80],
    [-48.30, -10.70],
    [-48.40, -10.70],
    [-48.40, -10.80],
  ];
  final hole = [
    [-48.36, -10.76],
    [-48.34, -10.76],
    [-48.34, -10.74],
    [-48.36, -10.74],
    [-48.36, -10.76],
  ];
  final polygon = jsonEncode({
    'type': 'Polygon',
    'coordinates': [outer],
  });

  test('ponto dentro do Polygon', () {
    expect(
      occurrencePointInFieldGeometry(polygon, lat: -10.72, lng: -48.38),
      isTrue,
    );
  });

  test('ponto fora do Polygon', () {
    expect(
      occurrencePointInFieldGeometry(polygon, lat: -10.60, lng: -48.38),
      isFalse,
    );
    expect(
      occurrencePointInFieldGeometry(polygon, lat: -10.72, lng: -48.20),
      isFalse,
    );
  });

  test('ponto no buraco fica fora', () {
    final withHole = jsonEncode({
      'type': 'Polygon',
      'coordinates': [outer, hole],
    });
    expect(
      occurrencePointInFieldGeometry(withHole, lat: -10.75, lng: -48.35),
      isFalse,
    );
    expect(
      occurrencePointInFieldGeometry(withHole, lat: -10.72, lng: -48.38),
      isTrue,
    );
  });

  test('MultiPolygon: qualquer parte conta', () {
    final multi = jsonEncode({
      'type': 'MultiPolygon',
      'coordinates': [
        [
          [
            [-47.0, -9.0],
            [-46.9, -9.0],
            [-46.9, -8.9],
            [-47.0, -8.9],
            [-47.0, -9.0],
          ],
        ],
        [outer],
      ],
    });
    expect(
      occurrencePointInFieldGeometry(multi, lat: -10.72, lng: -48.38),
      isTrue,
    );
    expect(
      occurrencePointInFieldGeometry(multi, lat: -8.95, lng: -46.95),
      isTrue,
    );
    expect(
      occurrencePointInFieldGeometry(multi, lat: -5.0, lng: -40.0),
      isFalse,
    );
  });

  test('Feature com geometria Polygon', () {
    final feature = jsonEncode({
      'type': 'Feature',
      'properties': <String, dynamic>{},
      'geometry': {
        'type': 'Polygon',
        'coordinates': [outer],
      },
    });
    expect(
      occurrencePointInFieldGeometry(feature, lat: -10.72, lng: -48.38),
      isTrue,
    );
  });

  test('geometria inválida ou ausente → false', () {
    for (final raw in <String?>[
      null,
      '',
      'não é json',
      '{"type":"Point","coordinates":[-48.38,-10.72]}',
      '{"type":"Polygon","coordinates":[]}',
      '{"type":"Polygon","coordinates":[[["a","b"],[1,2],[3,4]]]}',
      '{"type":"Polygon"}',
    ]) {
      expect(
        occurrencePointInFieldGeometry(raw, lat: -10.72, lng: -48.38),
        isFalse,
        reason: raw,
      );
    }
  });
}
