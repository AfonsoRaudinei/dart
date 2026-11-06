import 'dart:convert';
import 'dart:math' as math;

import 'package:soloforte_app/core/geo/geo_json_polygon_geometry.dart';

import 'models/visit_route_stop.dart';

/// Gera paradas dentro do polígono do talhão (ADR-057).
///
/// Centróide + amostragem quasi-aleatória (Halton) e grade no bbox, depois
/// seleção pelo ponto mais distante com separação mínima. Tudo em Dart puro.
class VisitRouteGenerator {
  static const int minStops = 3;
  static const int maxStops = 12;

  const VisitRouteGenerator();

  /// Separação mínima em graus, no lado menor do bbox.
  ///
  /// `span / (sqrt(N) + 1)` — heurística para não juntar as paradas num canto.
  static double minSeparationDegrees({
    required double spanLat,
    required double spanLng,
    required int stopCount,
  }) {
    final span = math.min(spanLat.abs(), spanLng.abs());
    if (span == 0 || stopCount <= 1) return 0;
    return span / (math.sqrt(stopCount) + 1);
  }

  List<VisitRouteStop> generate({
    required String? geometryJson,
    required int stopCount,
  }) {
    if (geometryJson == null || geometryJson.trim().isEmpty) return const [];
    final count = stopCount.clamp(minStops, maxStops);
    final ring = _largestOuterRing(geometryJson);
    if (ring == null || ring.length < 3) return const [];

    final bounds = _bounds(ring);
    if (bounds.spanLat == 0 || bounds.spanLng == 0) return const [];

    final centroid = _centroid(ring);
    final pool = <_Pt>[];
    if (geoJsonContainsPoint(geometryJson, centroid.lat, centroid.lng)) {
      pool.add(centroid);
    }
    _addGrid(pool, geometryJson, bounds);
    _addHalton(pool, geometryJson, bounds);
    if (pool.isEmpty) return const [];

    final minSep = minSeparationDegrees(
      spanLat: bounds.spanLat,
      spanLng: bounds.spanLng,
      stopCount: count,
    );
    final selected = _selectSpread(pool, count, minSep, centroid);
    if (selected.isEmpty) return const [];

    final ordered = _orderAround(selected, centroid);
    return [
      for (var i = 0; i < ordered.length; i++)
        VisitRouteStop(
          index: i + 1,
          lat: ordered[i].lat,
          lng: ordered[i].lng,
          status: VisitRouteStopStatus.pending,
        ),
    ];
  }

  void _addGrid(List<_Pt> pool, String geometryJson, _Bounds bounds) {
    const cells = 8;
    for (var row = 0; row < cells; row++) {
      for (var col = 0; col < cells; col++) {
        final lat = bounds.minLat + (row + 0.5) / cells * bounds.spanLat;
        final lng = bounds.minLng + (col + 0.5) / cells * bounds.spanLng;
        if (!geoJsonContainsPoint(geometryJson, lat, lng)) continue;
        pool.add(_Pt(lat, lng));
      }
    }
  }

  void _addHalton(List<_Pt> pool, String geometryJson, _Bounds bounds) {
    for (var i = 1; i <= 240; i++) {
      final lat = bounds.minLat + _halton(i, 3) * bounds.spanLat;
      final lng = bounds.minLng + _halton(i, 2) * bounds.spanLng;
      if (!geoJsonContainsPoint(geometryJson, lat, lng)) continue;
      pool.add(_Pt(lat, lng));
    }
  }

  List<_Pt> _selectSpread(
    List<_Pt> pool,
    int count,
    double minSep,
    _Pt centroid,
  ) {
    var sep = minSep;
    for (var relax = 0; relax < 5; relax++) {
      final picked = _farthest(pool, count, sep, centroid);
      if (picked.length >= count) return picked;
      sep *= 0.55;
    }
    return _farthest(pool, count, 0, centroid);
  }

  List<_Pt> _farthest(List<_Pt> pool, int count, double minSep, _Pt centroid) {
    var start = 0;
    var startScore = double.infinity;
    for (var i = 0; i < pool.length; i++) {
      final score = _dist2(pool[i], centroid);
      if (score < startScore) {
        startScore = score;
        start = i;
      }
    }

    final selected = <_Pt>[pool[start]];
    final used = <int>{start};
    final minSep2 = minSep * minSep;

    while (selected.length < count && used.length < pool.length) {
      var pick = -1;
      var pickScore = -1.0;
      for (var i = 0; i < pool.length; i++) {
        if (used.contains(i)) continue;
        var nearest = double.infinity;
        for (final chosen in selected) {
          final distance = _dist2(pool[i], chosen);
          if (distance < nearest) nearest = distance;
        }
        if (nearest + 1e-12 < minSep2) continue;
        if (nearest > pickScore) {
          pickScore = nearest;
          pick = i;
        }
      }
      if (pick < 0) break;
      selected.add(pool[pick]);
      used.add(pick);
    }
    return selected;
  }

  List<_Pt> _orderAround(List<_Pt> points, _Pt centroid) {
    final ordered = List<_Pt>.from(points);
    ordered.sort((a, b) {
      final angleA = math.atan2(a.lat - centroid.lat, a.lng - centroid.lng);
      final angleB = math.atan2(b.lat - centroid.lat, b.lng - centroid.lng);
      return angleA.compareTo(angleB);
    });
    return ordered;
  }
}

class _Pt {
  final double lat;
  final double lng;
  const _Pt(this.lat, this.lng);
}

class _Bounds {
  final double minLat;
  final double maxLat;
  final double minLng;
  final double maxLng;

  const _Bounds(this.minLat, this.maxLat, this.minLng, this.maxLng);

  double get spanLat => maxLat - minLat;
  double get spanLng => maxLng - minLng;
}

_Bounds _bounds(List<_Pt> ring) {
  var minLat = ring.first.lat;
  var maxLat = ring.first.lat;
  var minLng = ring.first.lng;
  var maxLng = ring.first.lng;
  for (final point in ring) {
    minLat = math.min(minLat, point.lat);
    maxLat = math.max(maxLat, point.lat);
    minLng = math.min(minLng, point.lng);
    maxLng = math.max(maxLng, point.lng);
  }
  return _Bounds(minLat, maxLat, minLng, maxLng);
}

_Pt _centroid(List<_Pt> ring) {
  final closed =
      ring.length > 3 &&
      ring.first.lat == ring.last.lat &&
      ring.first.lng == ring.last.lng;
  final usable = closed ? ring.length - 1 : ring.length;
  var sumLat = 0.0;
  var sumLng = 0.0;
  for (var i = 0; i < usable; i++) {
    sumLat += ring[i].lat;
    sumLng += ring[i].lng;
  }
  return _Pt(sumLat / usable, sumLng / usable);
}

double _halton(int index, int base) {
  var result = 0.0;
  var fraction = 1.0;
  var current = index;
  while (current > 0) {
    fraction /= base;
    result += fraction * (current % base);
    current ~/= base;
  }
  return result;
}

double _dist2(_Pt a, _Pt b) {
  final dLat = a.lat - b.lat;
  final dLng = a.lng - b.lng;
  return dLat * dLat + dLng * dLng;
}

List<_Pt>? _largestOuterRing(String geometryJson) {
  Object? decoded;
  try {
    decoded = jsonDecode(geometryJson);
  } catch (_) {
    return null;
  }
  final rings = <List<_Pt>>[];
  _collectOuterRings(decoded, rings);
  if (rings.isEmpty) return null;
  rings.sort((a, b) => b.length.compareTo(a.length));
  return rings.first;
}

void _collectOuterRings(Object? node, List<List<_Pt>> into) {
  if (node is! Map) return;
  switch (node['type']) {
    case 'Feature':
      _collectOuterRings(node['geometry'], into);
    case 'FeatureCollection':
      final features = node['features'];
      if (features is! List) return;
      for (final feature in features) {
        _collectOuterRings(feature, into);
      }
    case 'Polygon':
      final ring = _ringPoints(node['coordinates']);
      if (ring != null) into.add(ring);
    case 'MultiPolygon':
      final polygons = node['coordinates'];
      if (polygons is! List) return;
      for (final polygon in polygons) {
        final ring = _ringPoints(polygon);
        if (ring != null) into.add(ring);
      }
  }
}

List<_Pt>? _ringPoints(Object? rings) {
  if (rings is! List || rings.isEmpty) return null;
  final ring = rings.first;
  if (ring is! List) return null;
  final points = <_Pt>[];
  for (final position in ring) {
    if (position is! List || position.length < 2) continue;
    final lng = position[0];
    final lat = position[1];
    if (lng is! num || lat is! num) continue;
    points.add(_Pt(lat.toDouble(), lng.toDouble()));
  }
  if (points.length < 3) return null;
  return points;
}
