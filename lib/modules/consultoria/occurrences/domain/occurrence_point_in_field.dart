import 'dart:convert';

/// Ponto dentro do GeoJSON do talhão (`Polygon`, `MultiPolygon` ou `Feature`).
///
/// Coordenadas GeoJSON são `[lng, lat]`. Anel externo inclui, buracos
/// excluem. Geometria ausente, inválida ou de outro tipo → false.
bool occurrencePointInFieldGeometry(
  String? geometryJson, {
  required double lat,
  required double lng,
}) {
  final raw = geometryJson?.trim() ?? '';
  if (raw.isEmpty || !lat.isFinite || !lng.isFinite) return false;
  try {
    return _pointInGeoJson(jsonDecode(raw), lat: lat, lng: lng);
  } catch (_) {
    return false;
  }
}

bool _pointInGeoJson(Object? node, {required double lat, required double lng}) {
  if (node is! Map) return false;
  final type = node['type'];
  final coordinates = node['coordinates'];
  switch (type) {
    case 'Feature':
      return _pointInGeoJson(node['geometry'], lat: lat, lng: lng);
    case 'Polygon':
      return _pointInPolygon(coordinates, lat: lat, lng: lng);
    case 'MultiPolygon':
      if (coordinates is! List) return false;
      return coordinates.any(
        (polygon) => _pointInPolygon(polygon, lat: lat, lng: lng),
      );
    default:
      return false;
  }
}

bool _pointInPolygon(
  Object? rings, {
  required double lat,
  required double lng,
}) {
  if (rings is! List || rings.isEmpty) return false;
  final outer = _parseRing(rings.first);
  if (outer == null || !_pointInRing(outer, lat: lat, lng: lng)) return false;
  for (final hole in rings.skip(1)) {
    final parsed = _parseRing(hole);
    if (parsed != null && _pointInRing(parsed, lat: lat, lng: lng)) {
      return false;
    }
  }
  return true;
}

List<(double, double)>? _parseRing(Object? ring) {
  if (ring is! List || ring.length < 3) return null;
  final points = <(double, double)>[];
  for (final position in ring) {
    if (position is! List || position.length < 2) return null;
    final x = position[0];
    final y = position[1];
    if (x is! num || y is! num) return null;
    points.add((x.toDouble(), y.toDouble()));
  }
  return points;
}

/// Ray-casting com x = lng, y = lat.
bool _pointInRing(
  List<(double, double)> ring, {
  required double lat,
  required double lng,
}) {
  var inside = false;
  for (var i = 0, j = ring.length - 1; i < ring.length; j = i++) {
    final (xi, yi) = ring[i];
    final (xj, yj) = ring[j];
    final crosses =
        (yi > lat) != (yj > lat) &&
        lng < (xj - xi) * (lat - yi) / (yj - yi) + xi;
    if (crosses) inside = !inside;
  }
  return inside;
}
