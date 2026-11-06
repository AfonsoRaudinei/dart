import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/core/geo/geo_json_polygon_geometry.dart';
import 'package:soloforte_app/modules/visitas/domain/visit_route_generator.dart';

void main() {
  const square = '''
    {
      "type": "Polygon",
      "coordinates": [[
        [-48.0, -10.0],
        [-47.0, -10.0],
        [-47.0, -9.0],
        [-48.0, -9.0],
        [-48.0, -10.0]
      ]]
    }
  ''';

  test('N pontos dentro do quadrado e separados pela heurística', () {
    const count = 5;
    final stops = const VisitRouteGenerator().generate(
      geometryJson: square,
      stopCount: count,
    );

    expect(stops, hasLength(count));
    for (final stop in stops) {
      expect(geoJsonContainsPoint(square, stop.lat, stop.lng), isTrue);
      expect(stop.status.name, 'pending');
    }
    expect(stops.map((stop) => stop.index).toList(), [1, 2, 3, 4, 5]);

    final minSep = VisitRouteGenerator.minSeparationDegrees(
      spanLat: 1,
      spanLng: 1,
      stopCount: count,
    );
    expect(minSep, closeTo(1 / (math.sqrt(count) + 1), 1e-9));

    var closest = double.infinity;
    var minLat = stops.first.lat;
    var maxLat = stops.first.lat;
    var minLng = stops.first.lng;
    var maxLng = stops.first.lng;
    for (var i = 0; i < stops.length; i++) {
      minLat = math.min(minLat, stops[i].lat);
      maxLat = math.max(maxLat, stops[i].lat);
      minLng = math.min(minLng, stops[i].lng);
      maxLng = math.max(maxLng, stops[i].lng);
      for (var j = i + 1; j < stops.length; j++) {
        final dLat = stops[i].lat - stops[j].lat;
        final dLng = stops[i].lng - stops[j].lng;
        closest = math.min(closest, math.sqrt(dLat * dLat + dLng * dLng));
      }
    }

    expect(closest, greaterThanOrEqualTo(minSep * 0.95));
    expect(maxLat - minLat, greaterThan(0.4));
    expect(maxLng - minLng, greaterThan(0.4));
    expect(jsonEncode(stops.first.toJson()), contains('"lat"'));
  });

  test('polígono vazio não inventa parada', () {
    expect(
      const VisitRouteGenerator().generate(geometryJson: null, stopCount: 5),
      isEmpty,
    );
  });
}
