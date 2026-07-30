import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:soloforte_app/core/geo/br_state_boundaries_datasource.dart';

void main() {
  group('BrStateBoundariesDatasource', () {
    test('converte GeoJSON UF em polígonos', () async {
      final payload = [
        {
          'geometry': {
            'type': 'Polygon',
            'coordinates': [
              [
                [-48.0, -10.0],
                [-47.0, -10.0],
                [-47.0, -11.0],
                [-48.0, -11.0],
                [-48.0, -10.0],
              ],
            ],
          },
        },
      ];

      final datasource = BrStateBoundariesDatasource(
        client: MockClient((_) async {
          return http.Response(jsonEncode(payload), 200);
        }),
      );

      final polygons = await datasource.fetchStatePolygons();

      expect(polygons, hasLength(1));
      expect(polygons.first.points, hasLength(5));
      expect(polygons.first.points.first.latitude, closeTo(-10.0, 0.001));
      expect(polygons.first.points.first.longitude, closeTo(-48.0, 0.001));
    });

    test('HTTP não-200 retorna lista vazia', () async {
      final datasource = BrStateBoundariesDatasource(
        client: MockClient((_) async => http.Response('', 503)),
      );

      final polygons = await datasource.fetchStatePolygons();

      expect(polygons, isEmpty);
    });
  });
}
