import 'dart:convert';

import 'package:latlong2/latlong.dart';

/// GeoJSON Polygon / MultiPolygon — hit-test, furos e amostras para bbox.
///
/// Coordenadas GeoJSON são `[lon, lat]`. [geoJsonContainsPoint] recebe `(lat, lng)`.
bool isValidGeoPoint(double? lat, double? lng) {
  if (lat == null || lng == null) return false;
  if (!lat.isFinite || !lng.isFinite) return false;
  return !(lat == 0 && lng == 0);
}

/// Aceita Polygon, MultiPolygon, Feature e FeatureCollection.
bool geoJsonContainsPoint(String? geometryJson, double lat, double lng) {
  if (geometryJson == null || geometryJson.trim().isEmpty) return false;
  if (!isValidGeoPoint(lat, lng)) return false;
  Object? decoded;
  try {
    decoded = jsonDecode(geometryJson);
  } catch (_) {
    return false;
  }
  return _geoJsonObjectContains(decoded, lat, lng);
}

bool geoJsonContainsLatLng(String? geometryJson, LatLng point) {
  return geoJsonContainsPoint(
    geometryJson,
    point.latitude,
    point.longitude,
  );
}

bool geoJsonContainsLatLngMap(Map<String, dynamic>? geometry, LatLng point) {
  if (geometry == null || geometry.isEmpty) return false;
  return geoJsonContainsLatLng(jsonEncode(geometry), point);
}

/// Vértices de todos os anéis (contorno + furos) de todas as partes — bbox/câmera.
List<LatLng> geoJsonVerticesForBounds(String? rawGeoJson) {
  if (rawGeoJson == null || rawGeoJson.isEmpty) return const [];

  try {
    final decoded = jsonDecode(rawGeoJson);
    return _collectVertices(decoded);
  } catch (_) {
    return const [];
  }
}

List<LatLng> geoJsonVerticesForBoundsMap(Map<String, dynamic>? geometry) {
  if (geometry == null || geometry.isEmpty) return const [];
  return geoJsonVerticesForBounds(jsonEncode(geometry));
}

List<LatLng> _collectVertices(Object? node) {
  if (node is! Map) return const [];
  switch (node['type']) {
    case 'Feature':
      return _collectVertices(node['geometry']);
    case 'FeatureCollection':
      final features = node['features'];
      if (features is! List) return const [];
      final out = <LatLng>[];
      for (final feature in features) {
        out.addAll(_collectVertices(feature));
      }
      return out;
    case 'Polygon':
      return _ringsToLatLngs(node['coordinates']);
    case 'MultiPolygon':
      final polygons = node['coordinates'];
      if (polygons is! List) return const [];
      final out = <LatLng>[];
      for (final part in polygons) {
        out.addAll(_ringsToLatLngs(part));
      }
      return out;
    default:
      return const [];
  }
}

List<LatLng> _ringsToLatLngs(Object? rings) {
  if (rings is! List) return const [];
  final out = <LatLng>[];
  for (final ring in rings) {
    if (ring is! List) continue;
    for (final position in ring) {
      if (position is! List || position.length < 2) continue;
      final lng = position[0];
      final lat = position[1];
      if (lng is! num || lat is! num) continue;
      out.add(LatLng(lat.toDouble(), lng.toDouble()));
    }
  }
  return out;
}

bool _geoJsonObjectContains(Object? node, double lat, double lng) {
  if (node is! Map) return false;
  switch (node['type']) {
    case 'Feature':
      return _geoJsonObjectContains(node['geometry'], lat, lng);
    case 'FeatureCollection':
      final features = node['features'];
      if (features is! List) return false;
      return features.any((f) => _geoJsonObjectContains(f, lat, lng));
    case 'Polygon':
      return _polygonContains(node['coordinates'], lat, lng);
    case 'MultiPolygon':
      final polygons = node['coordinates'];
      if (polygons is! List) return false;
      return polygons.any((p) => _polygonContains(p, lat, lng));
    default:
      return false;
  }
}

/// Primeiro anel = contorno externo; demais = furos.
bool _polygonContains(Object? rings, double lat, double lng) {
  if (rings is! List || rings.isEmpty) return false;
  if (!_ringContains(rings.first, lat, lng)) return false;
  for (final hole in rings.skip(1)) {
    if (_ringContains(hole, lat, lng)) return false;
  }
  return true;
}

bool _ringContains(Object? ring, double lat, double lng) {
  if (ring is! List || ring.length < 3) return false;
  final xs = <double>[];
  final ys = <double>[];
  for (final position in ring) {
    if (position is! List || position.length < 2) return false;
    final x = position[0];
    final y = position[1];
    if (x is! num || y is! num) return false;
    xs.add(x.toDouble());
    ys.add(y.toDouble());
  }

  var inside = false;
  for (var i = 0, j = xs.length - 1; i < xs.length; j = i++) {
    final crosses = (ys[i] > lat) != (ys[j] > lat);
    if (crosses &&
        lng < (xs[j] - xs[i]) * (lat - ys[i]) / (ys[j] - ys[i]) + xs[i]) {
      inside = !inside;
    }
  }
  return inside;
}
