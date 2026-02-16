import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:soloforte_app/modules/drawing/domain/services/async_geometry_service.dart';
import 'package:soloforte_app/modules/drawing/domain/services/geometry_service.dart';
import 'package:soloforte_app/modules/drawing/domain/models/drawing_models.dart';

void main() {
  group('AsyncGeometryService -', () {
    group('Complexity Detection', () {
      test('Simple polygon (<2000 vertices) is not complex', () {
        final simpleSquare = DrawingPolygon(
          coordinates: [
            [
              [-15.7801, -47.9292],
              [-15.7801, -47.9202],
              [-15.7711, -47.9202],
              [-15.7711, -47.9292],
              [-15.7801, -47.9292],
            ],
          ],
        );

        expect(AsyncGeometryService.isComplex(simpleSquare), false);
      });

      test('Complex polygon (>=2000 vertices) is complex', () {
        // Gerar polígono com 2500 vértices
        final points = List.generate(2500, (i) {
          final angle = (i * 360 / 2500) * (3.14159 / 180);
          return [
            -15.7801 + 0.01 * angle,
            -47.9292 + 0.01 * angle,
          ];
        });
        points.add(points.first); // Fechar

        final complexPolygon = DrawingPolygon(coordinates: [points]);

        expect(AsyncGeometryService.isComplex(complexPolygon), true);
      });

      test('MultiPolygon complexity is sum of all polygons', () {
        // 3 polígonos com 800 vértices cada = 2400 total (complex)
        final poly1 = List.generate(800, (i) => [-15.0 + i * 0.0001, -47.0]);
        poly1.add(poly1.first);

        final poly2 = List.generate(800, (i) => [-16.0 + i * 0.0001, -48.0]);
        poly2.add(poly2.first);

        final poly3 = List.generate(800, (i) => [-17.0 + i * 0.0001, -49.0]);
        poly3.add(poly3.first);

        final multiPolygon = DrawingMultiPolygon(
          coordinates: [
            [poly1],
            [poly2],
            [poly3],
          ],
        );

        expect(AsyncGeometryService.isComplex(multiPolygon), true);
      });
    });

    group('Async Calculations (Simple Geometries)', () {
      test('calculateAreaAsync returns same as sync for simple polygon',
          () async {
        final square = DrawingPolygon(
          coordinates: [
            [
              [-15.7801, -47.9292],
              [-15.7801, -47.9202],
              [-15.7711, -47.9202],
              [-15.7711, -47.9292],
              [-15.7801, -47.9292],
            ],
          ],
        );

        final asyncResult = await AsyncGeometryService.calculateAreaAsync(square);
        final syncResult = GeometryService.calculateArea(square);

        expect(asyncResult, closeTo(syncResult, 0.01));
      });

      test('calculatePerimeterAsync returns same as sync for simple polygon',
          () async {
        final square = DrawingPolygon(
          coordinates: [
            [
              [-15.7801, -47.9292],
              [-15.7801, -47.9202],
              [-15.7711, -47.9202],
              [-15.7711, -47.9292],
              [-15.7801, -47.9292],
            ],
          ],
        );

        final asyncResult =
            await AsyncGeometryService.calculatePerimeterAsync(square);
        final syncResult = GeometryService.calculatePerimeter(square);

        expect(asyncResult, closeTo(syncResult, 0.01));
      });

      test('calculateSegmentDistancesAsync returns same as sync', () async {
        final triangle = DrawingPolygon(
          coordinates: [
            [
              [-15.7801, -47.9292],
              [-15.7801, -47.9202],
              [-15.7711, -47.9202],
              [-15.7801, -47.9292],
            ],
          ],
        );

        final asyncResult =
            await AsyncGeometryService.calculateSegmentDistancesAsync(triangle);
        final syncResult = GeometryService.calculateSegmentDistances(triangle);

        expect(asyncResult.length, syncResult.length);
        for (var i = 0; i < asyncResult.length; i++) {
          expect(asyncResult[i], closeTo(syncResult[i], 0.01));
        }
      });
    });

    group('Async Validation', () {
      test('validatePolygonAsync validates simple valid polygon', () async {
        final validSquare = DrawingPolygon(
          coordinates: [
            [
              [-15.7801, -47.9292],
              [-15.7801, -47.9202],
              [-15.7711, -47.9202],
              [-15.7711, -47.9292],
              [-15.7801, -47.9292],
            ],
          ],
        );

        final result =
            await AsyncGeometryService.validatePolygonAsync(validSquare);

        expect(result.isValid, true);
      });

      test('validatePolygonAsync detects invalid polygon', () async {
        final invalidPolygon = DrawingPolygon(
          coordinates: [
            [
              [-15.7801, -47.9292],
              [-15.7801, -47.9202],
              // Faltando pontos (< 3)
            ],
          ],
        );

        final result =
            await AsyncGeometryService.validatePolygonAsync(invalidPolygon);

        expect(result.isValid, false);
        expect(result.message, isNotNull);
      });
    });

    group('Async Normalization', () {
      test('normalizePolygonAsync closes open ring', () async {
        final openRing = DrawingPolygon(
          coordinates: [
            [
              [-15.7801, -47.9292],
              [-15.7801, -47.9202],
              [-15.7711, -47.9202],
              [-15.7711, -47.9292],
              // NÃO fechado
            ],
          ],
        );

        final normalized =
            await AsyncGeometryService.normalizePolygonAsync(openRing);

        final firstPoint = normalized.coordinates.first.first;
        final lastPoint = normalized.coordinates.first.last;

        expect(firstPoint[0], closeTo(lastPoint[0], 1e-9));
        expect(firstPoint[1], closeTo(lastPoint[1], 1e-9));
      });

      test('normalizePolygonAsync removes duplicate consecutive points',
          () async {
        final withDuplicates = DrawingPolygon(
          coordinates: [
            [
              [-15.7801, -47.9292],
              [-15.7801, -47.9292], // Duplicata
              [-15.7801, -47.9202],
              [-15.7711, -47.9202],
              [-15.7711, -47.9292],
              [-15.7801, -47.9292],
            ],
          ],
        );

        final normalized =
            await AsyncGeometryService.normalizePolygonAsync(withDuplicates);

        // 4 pontos únicos + 1 fechamento = 5 total
        expect(normalized.coordinates.first.length, 5);
      });
    });

    group('Async Simplification', () {
      test('simplifyPolygonAsync reduces vertices with RDP algorithm',
          () async {
        // Criar polígono com muitos pontos colineares
        final detailed = DrawingPolygon(
          coordinates: [
            [
              [-15.7801, -47.9292],
              [-15.7750, -47.9292], // Colinear
              [-15.7700, -47.9292], // Colinear
              [-15.7650, -47.9292], // Colinear
              [-15.7600, -47.9292],
              [-15.7600, -47.9202],
              [-15.7801, -47.9202],
              [-15.7801, -47.9292],
            ],
          ],
        );

        final simplified = await AsyncGeometryService.simplifyPolygonAsync(
          detailed,
          toleranceMeters: 10.0, // Tolerância 10 metros
        );

        // Deve reduzir vértices colineares
        expect(
          simplified.coordinates.first.length,
          lessThan(detailed.coordinates.first.length),
        );
      });
    });

    group('Async Point-in-Polygon', () {
      test('isPointInPolygonAsync detects point inside', () async {
        final square = DrawingPolygon(
          coordinates: [
            [
              [0.0, 0.0],
              [4.0, 0.0],
              [4.0, 4.0],
              [0.0, 4.0],
              [0.0, 0.0],
            ],
          ],
        );

        final insidePoint = const LatLng(2.0, 2.0); // Centro

        final result = await AsyncGeometryService.isPointInPolygonAsync(
          insidePoint,
          square.coordinates.first, // Ring externo
        );

        expect(result, true);
      });

      test('isPointInPolygonAsync detects point outside', () async {
        final square = DrawingPolygon(
          coordinates: [
            [
              [0.0, 0.0],
              [4.0, 0.0],
              [4.0, 4.0],
              [0.0, 4.0],
              [0.0, 0.0],
            ],
          ],
        );

        final outsidePoint = const LatLng(5.0, 5.0); // Fora

        final result = await AsyncGeometryService.isPointInPolygonAsync(
          outsidePoint,
          square.coordinates.first, // Ring externo
        );

        expect(result, false);
      });
    });

    group('Performance with Complex Geometries', () {
      test('Complex polygon triggers isolate usage', () async {
        // Gerar polígono com 3000 vértices (acima do threshold)
        final points = List.generate(3000, (i) {
          final angle = (i * 360 / 3000) * (3.14159 / 180);
          return [
            -15.7801 + 0.001 * (angle % 1),
            -47.9292 + 0.001 * (angle % 1),
          ];
        });
        points.add(points.first);

        final complexPolygon = DrawingPolygon(coordinates: [points]);

        // Deve completar sem bloquear (em isolate)
        final area =
            await AsyncGeometryService.calculateAreaAsync(complexPolygon);

        expect(area, greaterThan(0));
      });
    });
  });
}
