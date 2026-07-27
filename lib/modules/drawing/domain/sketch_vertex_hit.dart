import 'dart:math' as math;

import 'package:latlong2/latlong.dart';

/// Hit-test de vértices de sketch em coordenadas de tela (flutter_map).
int? findNearestSketchVertexIndex({
  required List<LatLng> vertices,
  required math.Point<double> tapScreen,
  required math.Point<double> Function(LatLng point) latLngToScreen,
  double pixelTolerance = 32,
}) {
  if (vertices.isEmpty) return null;

  int? bestIndex;
  var bestDistance = pixelTolerance;

  for (var i = 0; i < vertices.length; i++) {
    final vertexScreen = latLngToScreen(vertices[i]);
    final dx = tapScreen.x - vertexScreen.x;
    final dy = tapScreen.y - vertexScreen.y;
    final distance = math.sqrt(dx * dx + dy * dy);
    if (distance <= bestDistance) {
      bestDistance = distance;
      bestIndex = i;
    }
  }

  return bestIndex;
}
