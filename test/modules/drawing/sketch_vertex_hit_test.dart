import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:soloforte_app/modules/drawing/domain/sketch_vertex_hit.dart';

void main() {
  group('findNearestSketchVertexIndex', () {
    final vertices = [
      const LatLng(-15.0, -47.0),
      const LatLng(-15.001, -47.0),
      const LatLng(-15.001, -47.001),
    ];

    math.Point<double> toScreen(LatLng p) {
      return math.Point<double>(p.longitude * 10000, p.latitude * 10000);
    }

    test('retorna null quando nenhum vértice está dentro da tolerância', () {
      expect(
        findNearestSketchVertexIndex(
          vertices: vertices,
          tapScreen: const math.Point<double>(0, 0),
          latLngToScreen: toScreen,
          pixelTolerance: 32,
        ),
        isNull,
      );
    });

    test('retorna índice do vértice mais próximo dentro da tolerância', () {
      final target = toScreen(vertices[1]);
      expect(
        findNearestSketchVertexIndex(
          vertices: vertices,
          tapScreen: math.Point<double>(target.x + 10, target.y + 5),
          latLngToScreen: toScreen,
          pixelTolerance: 32,
        ),
        1,
      );
    });

    test('prefere vértice mais próximo quando vários estão na tolerância', () {
      final near0 = toScreen(vertices[0]);
      final near1 = toScreen(vertices[1]);
      final mid = math.Point<double>(
        (near0.x + near1.x) / 2,
        (near0.y + near1.y) / 2,
      );
      expect(
        findNearestSketchVertexIndex(
          vertices: vertices,
          tapScreen: mid,
          latLngToScreen: toScreen,
          pixelTolerance: 5000,
        ),
        anyOf(0, 1),
      );
    });
  });
}
