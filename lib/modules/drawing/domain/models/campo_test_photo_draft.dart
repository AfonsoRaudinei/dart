import 'package:latlong2/latlong.dart';

import 'drawing_models.dart';

/// Foto opcional anexada na revisão de um [DrawingType.teste] antes do save.
class CampoTestPhotoDraft {
  const CampoTestPhotoDraft({
    required this.localPath,
    this.lat,
    this.lng,
  });

  /// Path absoluto ou temporário retornado pelo picker.
  final String localPath;
  final double? lat;
  final double? lng;
}

/// Centro do anel externo do sketch ou o primeiro vértice válido.
LatLng? resolveCampoTestSketchGeo(DrawingGeometry? geometry) {
  if (geometry == null) return null;

  List<List<double>>? outerRing;
  if (geometry is DrawingPolygon) {
    if (geometry.coordinates.isEmpty) return null;
    outerRing = geometry.coordinates.first;
  } else if (geometry is DrawingMultiPolygon) {
    if (geometry.coordinates.isEmpty) return null;
    final poly = geometry.coordinates.first;
    if (poly.isEmpty) return null;
    outerRing = poly.first;
  } else {
    return null;
  }

  final vertices = <LatLng>[];
  for (final point in outerRing) {
    if (point.length < 2) continue;
    final lng = point[0];
    final lat = point[1];
    if (!lat.isFinite || !lng.isFinite) continue;
    vertices.add(LatLng(lat, lng));
  }
  if (vertices.isEmpty) return null;

  if (vertices.length >= 2 &&
      vertices.first.latitude == vertices.last.latitude &&
      vertices.first.longitude == vertices.last.longitude) {
    vertices.removeLast();
  }
  if (vertices.isEmpty) return null;

  if (vertices.length == 1) return vertices.first;

  var sumLat = 0.0;
  var sumLng = 0.0;
  for (final v in vertices) {
    sumLat += v.latitude;
    sumLng += v.longitude;
  }
  final n = vertices.length;
  return LatLng(sumLat / n, sumLng / n);
}