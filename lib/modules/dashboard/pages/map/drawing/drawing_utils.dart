import 'dart:math' as math;
import 'package:latlong2/latlong.dart';
import 'package:uuid/uuid.dart';
import 'drawing_models.dart';

class DrawingUtils {
  static const Uuid _uuid = Uuid();

  /// Generates a new UUID v4
  static String generateId() => _uuid.v4();

  /// Calculates the area of a polygon in hectares.
  /// Uses a spherical approximation (Shoelace formula on projected coordinates or simpler spherical calc).
  /// For high precision on earth, we should use a library like 'vector_math' or 'dart_jts',
  /// but for this module constraint (Flutter/Dart only), we implement a simplified WGS84 area calculation.
  static double calculateAreaHa(List<List<double>> ring) {
    if (ring.length < 3) return 0.0;

    double area = 0.0;
    const double radius = 6378137.0; // Earth radius in meters

    if (ring.length > 2) {
      for (var i = 0; i < ring.length - 1; i++) {
        var p1 = ring[i];
        var p2 = ring[i + 1];
        area +=
            _toRadians(p2[0] - p1[0]) *
            (2 + math.sin(_toRadians(p1[1])) + math.sin(_toRadians(p2[1])));
      }
      area = area * radius * radius / 2.0;
    }

    // Convert sq meters to hectares
    return area.abs() / 10000.0;
  }

  static double _toRadians(double deg) => deg * (math.pi / 180.0);

  /// Helper: Creates a circular polygon (approximation) for a Pivot.
  /// [center] is [lng, lat].
  static DrawingPolygon createPivotPolygon(
    LatLng center,
    double radiusMetros, {
    int steps = 64,
  }) {
    final List<List<double>> ring = [];
    // 1 degree of latitude ~= 111km
    // 1 degree of longitude ~= 111km * cos(lat)

    // Simple equirectangular approximation for generating points is acceptable for visual
    // or we can use proper destinationPoint formulas.
    // Let's use a simple destination point logic if we want to be fancy, or simple approx.

    // proper formula:
    const R = 6378137.0; // Earth's radius in m

    for (int i = 0; i <= steps; i++) {
      final angle = (2 * math.pi * i) / steps;
      final dx = radiusMetros * math.cos(angle);
      final dy = radiusMetros * math.sin(angle);

      // Coordinate offsets in radians
      final dLat = dy / R;
      final dLng = dx / (R * math.cos(center.latitude * math.pi / 180));

      final lat = center.latitude + (dLat * 180 / math.pi);
      final lng = center.longitude + (dLng * 180 / math.pi);

      ring.add([lng, lat]);
    }

    // First point is automatically repeated by the loop if we go 0 to steps?
    // 2*pi * steps/steps = 2*pi (same as 0).
    // Let's ensure explicit closure just in case floating point drift.
    if (ring.first[0] != ring.last[0] || ring.first[1] != ring.last[1]) {
      ring.add(ring.first);
    }

    return DrawingPolygon(coordinates: [ring]);
  }

  /// Merges two geometries into a single MultiPolygon context.
  /// Current implementation aggregates shapes into a MultiPolygon representation.
  static DrawingGeometry unionGeometries(
    DrawingGeometry g1,
    DrawingGeometry g2,
  ) {
    List<List<List<List<double>>>> allPolys = [];

    // Helper to extract polygons
    void addGeo(DrawingGeometry g) {
      if (g is DrawingPolygon) {
        allPolys.add(g.coordinates);
      } else if (g is DrawingMultiPolygon) {
        allPolys.addAll(g.coordinates);
      }
    }

    addGeo(g1);
    addGeo(g2);

    // If only one polygon resulted (unlikely unless empty), return Polygon
    if (allPolys.length == 1) {
      return DrawingPolygon(coordinates: allPolys.first);
    }

    return DrawingMultiPolygon(coordinates: allPolys);
  }

  /// Subtracts [cut] from [base] by adding [cut] as a hole.
  /// Simplification: Assumes [base] is a Polygon and [cut] is fully contained.
  static DrawingGeometry cutGeometry(
    DrawingGeometry base,
    DrawingGeometry cut,
  ) {
    // If base is MultiPolygon, we'd need to check bounds to see which poly contains the hole.
    // For this MVP version, we stick to single Polygon cuts or first match.
    if (base is! DrawingPolygon) {
      // Logic for MultiPolygon cut could go here: find which sub-poly contains cut.
      // Returning base for safety if not supported.
      return base;
    }
    if (cut is! DrawingPolygon || cut.coordinates.isEmpty) return base;

    // The hole is defined by the exterior ring of the cut polygon
    final holeRing = cut.coordinates.first;

    // Validate hole ring
    if (holeRing.length < 4) return base;

    // Create new coordinate list with the added hole
    final newCoords = List<List<List<double>>>.from(base.coordinates);
    newCoords.add(holeRing);

    return DrawingPolygon(coordinates: newCoords);
  }
}
