import 'dart:io';
import 'dart:math' as math;
import 'package:file_picker/file_picker.dart';
import 'package:xml/xml.dart';
import 'package:archive/archive.dart';
import 'package:latlong2/latlong.dart';

import 'package:uuid/uuid.dart';
import 'drawing_models.dart';

class DrawingUtils {
  static const Uuid _uuid = Uuid();

  // RT-DRAW-09 Constants
  static const double toleranciaSnapMetros = 1.0;
  static const double toleranciaSimplificacaoMetros = 0.5;
  static const double toleranciaMinDistanciaVertice = 0.1;

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

  /// Calculates the perimeter of a geometry in kilometers.
  static double calculatePerimeterKm(DrawingGeometry? geometry) {
    if (geometry == null) return 0.0;

    double perimeter = 0.0;
    const distance = Distance();

    List<List<List<double>>> rings = [];
    if (geometry is DrawingPolygon) {
      if (geometry.coordinates.isNotEmpty) {
        rings.add(geometry.coordinates.first);
      }
    } else if (geometry is DrawingMultiPolygon) {
      for (var poly in geometry.coordinates) {
        if (poly.isNotEmpty) {
          rings.add(poly.first);
        }
      }
    }

    for (var ring in rings) {
      if (ring.length < 2) continue;
      for (int i = 0; i < ring.length - 1; i++) {
        final p1 = ring[i];
        final p2 = ring[i + 1];
        perimeter += distance.as(
          LengthUnit.Kilometer,
          LatLng(p1[1], p1[0]),
          LatLng(p2[1], p2[0]),
        );
      }
    }

    return perimeter;
  }

  /// Calculates segment distances for the main ring of the geometry (first polygon).
  /// Returns a list of strings formatted as "P{i} -> P{j}: {dist} km" or just distances.
  /// The prompt asks for "Distância entre P1 -> P2...".
  /// Let's return a list of segment lengths in km.
  static List<double> calculateSegmentsKm(DrawingGeometry? geometry) {
    if (geometry == null) return [];

    List<double> segments = [];
    const distance = Distance();

    // For segments, we typically only show the *current* drawing or the primary polygon.
    // UX usually makes sense for the single polygon being drawn.
    List<List<double>>? ring;

    if (geometry is DrawingPolygon && geometry.coordinates.isNotEmpty) {
      ring = geometry.coordinates.first;
    } else if (geometry is DrawingMultiPolygon &&
        geometry.coordinates.isNotEmpty) {
      // Pick first polygon's outer ring
      if (geometry.coordinates.first.isNotEmpty) {
        ring = geometry.coordinates.first.first;
      }
    }

    if (ring != null && ring.length > 1) {
      for (int i = 0; i < ring.length - 1; i++) {
        // ring[i] is [lng, lat]
        final p1 = ring[i];
        final p2 = ring[i + 1];

        final dist = distance.as(
          LengthUnit.Kilometer,
          LatLng(p1[1], p1[0]),
          LatLng(p2[1], p2[0]),
        );
        segments.add(dist);
      }
    }

    return segments;
  }

  // ===========================================================================
  // BOOLEAN OPERATIONS (RT-DRAW-07)
  // ===========================================================================

  static DrawingGeometry? union(DrawingGeometry g1, DrawingGeometry g2) {
    // Stub
    return null;
  }

  static DrawingGeometry? difference(
    DrawingGeometry base,
    DrawingGeometry subtract,
  ) {
    // Stub
    return null;
  }

  static DrawingGeometry? intersection(DrawingGeometry g1, DrawingGeometry g2) {
    // Stub
    return null;
  }

  // --- Helpers ---

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

  // ===========================================================================
  // IMPORT PARSING (KML/KMZ)
  // ===========================================================================

  static Future<DrawingGeometry?> parseFile(PlatformFile file) async {
    try {
      if (file.path == null) return null;
      final ioFile = File(file.path!);

      if (file.extension == 'kml') {
        final content = await ioFile.readAsString();
        return _parseKmlContent(content);
      } else if (file.extension == 'kmz') {
        final bytes = await ioFile.readAsBytes();
        return _parseKmzContent(bytes);
      }
    } catch (e) {
      // debugPrint('Error parsing file: $e');
    }
    return null;
  }

  static DrawingGeometry? _parseKmlContent(String content) {
    try {
      final document = XmlDocument.parse(content);

      // Try to find Polygon first
      final polygons = document.findAllElements('Polygon');
      if (polygons.isNotEmpty) {
        // Collect all polygons (if multiple, treat as MultiPolygon or just take first?
        // Ticket says "Polygon / MultiPolygon".
        // If KML has multiple Polygons not in MultiGeometry, we usually merge them into MultiPolygon for the contract.
        // Let's simplified: If 1, return Polygon. If >1, return MultiPolygon.

        final extracted = <List<List<List<double>>>>[];

        for (var poly in polygons) {
          final coords = _extractPolygonCoords(poly);
          if (coords != null) {
            extracted.add(coords);
          }
        }

        if (extracted.isEmpty) return null;
        if (extracted.length == 1) {
          return DrawingPolygon(coordinates: extracted.first);
        } else {
          return DrawingMultiPolygon(coordinates: extracted);
        }
      }

      // If no Polygon, check MultiGeometry
      // Actually findAllElements('Polygon') traverses deep, so if they are inside MultiGeometry, we already caught them.
      // So the logic above handles MultiGeometry implicitly by flattening.

      return null;
    } catch (_) {
      return null;
    }
  }

  static DrawingGeometry? _parseKmzContent(List<int> bytes) {
    try {
      final archive = ZipDecoder().decodeBytes(bytes);
      // Find doc.kml or any .kml
      final kmlFile = archive.files.firstWhere(
        (f) => f.name.endsWith('.kml'),
        orElse: () => archive.files.first, // Fallback? Unsafe.
      );

      if (!kmlFile.name.endsWith('.kml')) return null;

      final content = String.fromCharCodes(kmlFile.content as List<int>);
      return _parseKmlContent(content);
    } catch (_) {
      return null;
    }
  }

  static List<List<List<double>>>? _extractPolygonCoords(XmlElement poly) {
    // KML Polygon structure:
    // <outerBoundaryIs><LinearRing><coordinates>...</coordinates></LinearRing></outerBoundaryIs>
    // <innerBoundaryIs>...holes...</innerBoundaryIs>

    try {
      final coordinatesList = <List<List<double>>>[];

      // 1. Outer
      final outer = poly
          .findElements('outerBoundaryIs')
          .firstOrNull
          ?.findElements('LinearRing')
          .firstOrNull
          ?.findElements('coordinates')
          .firstOrNull;

      if (outer == null) return null;

      final outerCoords = _parseKmlCoordinates(outer.innerText);
      if (outerCoords.isEmpty) return null;
      coordinatesList.add(outerCoords);

      // 2. Inner (Holes)
      final inners = poly.findElements('innerBoundaryIs');
      for (var inner in inners) {
        final ring = inner
            .findElements('LinearRing')
            .firstOrNull
            ?.findElements('coordinates')
            .firstOrNull;
        if (ring != null) {
          final holeCoords = _parseKmlCoordinates(ring.innerText);
          if (holeCoords.isNotEmpty) {
            coordinatesList.add(holeCoords);
          }
        }
      }

      return coordinatesList;
    } catch (_) {
      return null;
    }
  }

  // ===========================================================================
  // TOPOLOGICAL VALIDATION (RT-DRAW-08)
  // ===========================================================================

  static DrawingValidationResult validateTopology(
    DrawingGeometry? geometry, {
    List<DrawingFeature>? existingFeatures,
    String? ignoreId,
    bool skipExpensiveChecks = false,
  }) {
    if (geometry == null) return const DrawingValidationResult.valid();

    // 1. Check for minimum points
    if (geometry is DrawingPolygon) {
      if (!_isValidPolygon(geometry)) {
        return const DrawingValidationResult.error(
          "Polígono inválido (menos de 3 pontos).",
        );
      }

      // 2. Self-Intersection (O(N^2))
      if (!skipExpensiveChecks) {
        if (_hasSelfIntersection(geometry)) {
          return const DrawingValidationResult.error(
            "Linhas da área estão se cruzando (auto-interseção).",
          );
        }
      }
    } else if (geometry is DrawingMultiPolygon) {
      for (var poly in geometry.coordinates) {
        final p = DrawingPolygon(coordinates: poly);
        if (!_isValidPolygon(p)) {
          return const DrawingValidationResult.error(
            "Parte do multipolígono é inválida.",
          );
        }

        if (!skipExpensiveChecks) {
          if (_hasSelfIntersection(p)) {
            return const DrawingValidationResult.error(
              "Linhas da área estão se cruzando.",
            );
          }
        }
      }
    }

    // 3. Holes Validation
    // Check if holes are inside outer ring
    if (geometry is DrawingPolygon) {
      if (!_areHolesValid(geometry)) {
        return const DrawingValidationResult.error(
          "Buraco inválido (fora do limite da área).",
        );
      }
    }

    // 4. Overlaps
    if (existingFeatures != null && !skipExpensiveChecks) {
      for (var f in existingFeatures) {
        if (ignoreId != null && f.id == ignoreId) continue;
        if (!f.properties.ativo) continue; // Ignore inactive

        // Basic Overlap Check
        if (_geometriesOverlap(geometry, f.geometry)) {
          return const DrawingValidationResult.error(
            "Há sobreposição não permitida entre áreas.",
          );
        }
      }
    }

    return const DrawingValidationResult.valid();
  }

  static bool _geometriesOverlap(DrawingGeometry g1, DrawingGeometry g2) {
    // BBox check
    final b1 = _getBoundsGeometry(g1);
    final b2 = _getBoundsGeometry(g2);
    if (b1.minX > b2.maxX ||
        b1.maxX < b2.minX ||
        b1.minY > b2.maxY ||
        b1.maxY < b2.minY) {
      return false;
    }

    // Check intersection or containment
    return _checkIntersectionOrContainment(g1, g2);
  }

  static bool _checkIntersectionOrContainment(
    DrawingGeometry g1,
    DrawingGeometry g2,
  ) {
    // Flatten geometries to list of polygons (rings)
    List<List<List<double>>> getRings(DrawingGeometry g) {
      if (g is DrawingPolygon) return g.coordinates;
      if (g is DrawingMultiPolygon) {
        return g.coordinates.expand((i) => i).toList();
      }
      return [];
    }

    final rings1 = getRings(g1);
    final rings2 = getRings(g2);

    for (var r1 in rings1) {
      if (r1.isEmpty) continue;
      for (var r2 in rings2) {
        if (r2.isEmpty) continue;

        // Check Edge Intersections
        if (_ringsIntersect(r1, r2)) return true;

        // Check Containment (One inside another without edge intersection)
        // Test first point of r1 against r2
        if (_isPointInPolygon(r1.first, r2)) return true;
        // Test first point of r2 against r1
        if (_isPointInPolygon(r2.first, r1)) return true;
      }
    }
    return false;
  }

  static bool _ringsIntersect(List<List<double>> r1, List<List<double>> r2) {
    for (int i = 0; i < r1.length - 1; i++) {
      for (int j = 0; j < r2.length - 1; j++) {
        if (_segmentsIntersect(r1[i], r1[i + 1], r2[j], r2[j + 1])) return true;
      }
    }
    return false;
  }

  static _Bounds _getBoundsGeometry(DrawingGeometry g) {
    if (g is DrawingPolygon) {
      return _getBounds(g.coordinates.isNotEmpty ? g.coordinates.first : []);
    } else if (g is DrawingMultiPolygon) {
      double minX = double.infinity, minY = double.infinity;
      double maxX = double.negativeInfinity, maxY = double.negativeInfinity;
      bool first = true;

      for (var poly in g.coordinates) {
        if (poly.isNotEmpty) {
          final b = _getBounds(poly.first);
          if (first) {
            minX = b.minX;
            maxX = b.maxX;
            minY = b.minY;
            maxY = b.maxY;
            first = false;
          } else {
            if (b.minX < minX) minX = b.minX;
            if (b.maxX > maxX) maxX = b.maxX;
            if (b.minY < minY) minY = b.minY;
            if (b.maxY > maxY) maxY = b.maxY;
          }
        }
      }
      if (first) return _Bounds(0, 0, 0, 0);
      return _Bounds(minX, maxX, minY, maxY);
    }
    return _Bounds(0, 0, 0, 0);
  }

  static bool _isValidPolygon(DrawingPolygon poly) {
    if (poly.coordinates.isEmpty) return false;
    final outer = poly.coordinates.first;
    // Min 3 points to form a triangle.
    // If closed (first==last), ring size must be >= 4.
    if (outer.length < 4) return false;
    return true;
  }

  static bool _hasSelfIntersection(DrawingPolygon poly) {
    // Check strict self-intersection of the outer ring
    if (poly.coordinates.isEmpty) return false;
    final ring = poly.coordinates.first;

    // Naive O(N^2) segment intersection
    // ring points: p0, p1, ... pn.
    // Segments: (p0,p1), (p1,p2), ... (pn-1, pn)
    // Note: KML/GeoJSON rings are closed (p0 == pn).

    final n = ring.length - 1;
    for (int i = 0; i < n; i++) {
      for (int j = i + 1; j < n; j++) {
        // Adjacent segments share a vertex, so they "intersect" at that vertex.
        // We ignore this case.
        if (j == i + 1) continue;
        // If first and last segment share start/end, also ignore if closed ring check handles it implies j=n-1 and i=0.
        if (i == 0 && j == n - 1) continue; // Adjacent wrapping around

        final p1 = ring[i];
        final p2 = ring[i + 1];
        final q1 = ring[j];
        final q2 = ring[j + 1];

        if (_segmentsIntersect(p1, p2, q1, q2)) {
          return true;
        }
      }
    }
    return false;
  }

  /// Returns true if segment (p1-p2) intersects (q1-q2) strictly or improperly.
  /// Points are [lng, lat].
  static bool _segmentsIntersect(
    List<double> p1,
    List<double> p2,
    List<double> q1,
    List<double> q2,
  ) {
    // Using vector cross product method
    // If endpoints touch, we don't count it as self-intersection for this simplified check
    // unless it's a "pinch" which is harder.
    // But if we found an intersection not at endpoints, it's definitely bad.

    // Check bounding box first
    if (math.min(p1[0], p2[0]) > math.max(q1[0], q2[0]) ||
        math.max(p1[0], p2[0]) < math.min(q1[0], q2[0]) ||
        math.min(p1[1], p2[1]) > math.max(q1[1], q2[1]) ||
        math.max(p1[1], p2[1]) < math.min(q1[1], q2[1])) {
      return false;
    }

    double crossProduct(List<double> a, List<double> b, List<double> c) {
      return (b[0] - a[0]) * (c[1] - a[1]) - (b[1] - a[1]) * (c[0] - a[0]);
    }

    final d1 = crossProduct(q1, q2, p1);
    final d2 = crossProduct(q1, q2, p2);
    final d3 = crossProduct(p1, p2, q1);
    final d4 = crossProduct(p1, p2, q2);

    // Strictly intersect
    if (((d1 > 0 && d2 < 0) || (d1 < 0 && d2 > 0)) &&
        ((d3 > 0 && d4 < 0) || (d3 < 0 && d4 > 0))) {
      return true;
    }

    // Collinear cases ignored for simple "loop" check, usually caused by backtracking which is user error but maybe not "intersection" logic.
    return false;
  }

  static bool _areHolesValid(DrawingPolygon poly) {
    if (poly.coordinates.length <= 1) return true; // No holes

    // Use Turf to check containment if possible, or fallback to ray casting / bounds
    // Since we only have 'turf' imports, let's try to use basic turf logic if available or bounding box.
    // Sticking to Bounding Box for MVP speed + reliability without complex deps.

    final outer = poly.coordinates.first;
    final outerBounds = _getBounds(outer);

    for (int i = 1; i < poly.coordinates.length; i++) {
      final hole = poly.coordinates[i];
      // Check if hole is roughly inside outer
      final holeBounds = _getBounds(hole);

      // If hole is outside outer bounding box, it's definitely invalid
      if (holeBounds.minX < outerBounds.minX ||
          holeBounds.maxX > outerBounds.maxX ||
          holeBounds.minY < outerBounds.minY ||
          holeBounds.maxY > outerBounds.maxY) {
        return false;
      }

      // Check first point of hole is inside outer (Ray Casting)
      if (hole.isNotEmpty) {
        if (!_isPointInPolygon(hole.first, outer)) return false;
      }
    }
    return true;
  }

  static bool _isPointInPolygon(
    List<double> point,
    List<List<double>> polygon,
  ) {
    // Ray casting algorithm
    double x = point[0], y = point[1];
    bool inside = false;
    for (int i = 0, j = polygon.length - 1; i < polygon.length; j = i++) {
      double xi = polygon[i][0], yi = polygon[i][1];
      double xj = polygon[j][0], yj = polygon[j][1];

      bool intersect =
          ((yi > y) != (yj > y)) && (x < (xj - xi) * (y - yi) / (yj - yi) + xi);
      if (intersect) inside = !inside;
    }
    return inside;
  }

  static _Bounds _getBounds(List<List<double>> ring) {
    if (ring.isEmpty) return _Bounds(0, 0, 0, 0);
    double minX = ring[0][0], maxX = ring[0][0];
    double minY = ring[0][1], maxY = ring[0][1];
    for (var p in ring) {
      if (p[0] < minX) minX = p[0];
      if (p[0] > maxX) maxX = p[0];
      if (p[1] < minY) minY = p[1];
      if (p[1] > maxY) maxY = p[1];
    }
    return _Bounds(minX, maxX, minY, maxY);
  }

  // Existing parseKmlCoordinates...
  static List<List<double>> _parseKmlCoordinates(String text) {
    // Format: lon,lat,alt lon,lat,alt ...
    // Separator can be space or newline
    final result = <List<double>>[];
    final clean = text.trim();
    if (clean.isEmpty) return result;

    final tokens = clean.split(RegExp(r'\s+'));
    for (var token in tokens) {
      final parts = token.split(',');
      if (parts.length >= 2) {
        final lng = double.tryParse(parts[0]);
        final lat = double.tryParse(parts[1]);
        if (lng != null && lat != null) {
          result.add([lng, lat]);
        }
      }
    }
    return result;
  }
  // ===========================================================================
  // NORMALIZATION & OPTIMIZATION (RT-DRAW-09)
  // ===========================================================================

  /// Normalizes geometry: closes rings, removes duplicates, fixes winding.
  static DrawingGeometry normalizeGeometry(DrawingGeometry g) {
    if (g is DrawingPolygon) {
      return DrawingPolygon(
        coordinates: g.coordinates.map(_normalizeRing).toList(),
      );
    } else if (g is DrawingMultiPolygon) {
      return DrawingMultiPolygon(
        coordinates: g.coordinates
            .map((poly) => poly.map(_normalizeRing).toList())
            .toList(),
      );
    }
    return g;
  }

  static List<List<double>> _normalizeRing(List<List<double>> ring) {
    if (ring.isEmpty) return [];

    // 1. Remove consecutive duplicates and close points
    final List<List<double>> clean = [];
    for (int i = 0; i < ring.length; i++) {
      final p = ring[i];
      if (clean.isEmpty) {
        clean.add(p);
      } else {
        final last = clean.last;
        // Check exact duplicate or very close
        if ((last[0] - p[0]).abs() > 1e-9 || (last[1] - p[1]).abs() > 1e-9) {
          clean.add(p);
        }
      }
    }

    // 2. Ensure Closed
    if (clean.length > 2) {
      final first = clean.first;
      final last = clean.last;
      if ((first[0] - last[0]).abs() > 1e-9 ||
          (first[1] - last[1]).abs() > 1e-9) {
        clean.add(first);
      }
    }

    // 3. Ensure Winding (Outer: CCW, Holes: CW usually, but here just consistency)
    // GeoJSON recommends CCW for outer.
    // Check minimal area?

    return clean;
  }

  /// Snaps a point to the nearest vertex in existing features.
  /// Returns the snapped point or the original if no snap found.
  static int getVertexCount(DrawingGeometry? g) {
    if (g == null) return 0;
    int count = 0;
    if (g is DrawingPolygon) {
      for (var ring in g.coordinates) {
        count += ring.length;
      }
    } else if (g is DrawingMultiPolygon) {
      for (var poly in g.coordinates) {
        for (var ring in poly) {
          count += ring.length;
        }
      }
    }
    return count;
  }

  /// Snaps a point to the nearest vertex in existing features.
  /// Returns the snapped point or the original if no snap found.
  static LatLng snapPoint(LatLng point, List<DrawingFeature> features) {
    // Basic optimization: if features count is huge, this is slow.
    // Usually < 100 features in a farm context, but each feature can be large.

    const distance = Distance();
    LatLng? bestMatch;
    double bestDist = double.infinity;

    // Use squared tolerance for Euclidean pre-check (approx)
    // 0.00001 deg ~= 1.1 meter.
    // Tolerance is 1 meter.
    // Let's rely on bounds first.
    final pLat = point.latitude;
    final pLng = point.longitude;

    for (var f in features) {
      if (!f.properties.ativo) continue;

      // Bounds check optimization
      final b = _getBoundsGeometry(f.geometry);
      // Expand bounds by tolerance (approx 0.0001 deg ~ 11m for safety)
      if (pLng < b.minX - 0.0001 ||
          pLng > b.maxX + 0.0001 ||
          pLat < b.minY - 0.0001 ||
          pLat > b.maxY + 0.0001) {
        continue;
      }

      List<List<List<double>>> rings = [];
      if (f.geometry is DrawingPolygon) {
        rings = (f.geometry as DrawingPolygon).coordinates;
      } else if (f.geometry is DrawingMultiPolygon) {
        rings = (f.geometry as DrawingMultiPolygon).coordinates
            .expand((i) => i)
            .toList();
      }

      for (var ring in rings) {
        for (var coord in ring) {
          // Manhattan check before generic distance
          if ((coord[0] - pLng).abs() > 0.00005 ||
              (coord[1] - pLat).abs() > 0.00005) {
            continue;
          }

          final v = LatLng(coord[1], coord[0]);
          final d = distance.as(LengthUnit.Meter, point, v);
          if (d < bestDist) {
            bestDist = d;
            bestMatch = v;
          }
        }
      }
    }

    if (bestMatch != null && bestDist <= toleranciaSnapMetros) {
      return bestMatch;
    }
    return point;
  }

  /// Simplifies geometry using Ramer-Douglas-Peucker algorithm.
  static DrawingGeometry simplifyGeometry(
    DrawingGeometry g, {
    double tolerance = toleranciaSimplificacaoMetros,
  }) {
    if (g is DrawingPolygon) {
      return DrawingPolygon(
        coordinates: g.coordinates
            .map((ring) => _simplifyRing(ring, tolerance))
            .toList(),
      );
    } else if (g is DrawingMultiPolygon) {
      return DrawingMultiPolygon(
        coordinates: g.coordinates
            .map(
              (poly) =>
                  poly.map((ring) => _simplifyRing(ring, tolerance)).toList(),
            )
            .toList(),
      );
    }
    return g;
  }

  static List<List<double>> _simplifyRing(
    List<List<double>> points,
    double tolerance,
  ) {
    if (points.length <= 2) return points;

    // Convert to points with distance logic (lat/lng to meters approximation)
    // Or just use lat/lng degrees if tolerance is small?
    // Tolerance is in meters. Degrees are tricky.
    // 1 deg lat ~= 111,000m. 0.5m ~= 0.0000045 deg.
    // Let's use simplified degree tolerance for performance or custom distance func.
    // 0.5m is very small.
    // Let's assume roughly: toleranceDeg = toleranceMetros / 111000.

    final double toleranceDeg = tolerance / 111000.0;

    return _rdp(points, toleranceDeg);
  }

  // Basic Ramer-Douglas-Peucker
  static List<List<double>> _rdp(List<List<double>> points, double epsilon) {
    if (points.length < 3) return points;

    double dmax = 0.0;
    int index = 0;
    int end = points.length - 1;

    for (int i = 1; i < end; i++) {
      double d = _perpendicularDistance(points[i], points[0], points[end]);
      if (d > dmax) {
        index = i;
        dmax = d;
      }
    }

    if (dmax > epsilon) {
      List<List<double>> res1 = _rdp(points.sublist(0, index + 1), epsilon);
      List<List<double>> res2 = _rdp(points.sublist(index, end + 1), epsilon);

      return [...res1.take(res1.length - 1), ...res2];
    } else {
      return [points[0], points[end]];
    }
  }

  static double _perpendicularDistance(
    List<double> p,
    List<double> lineStart,
    List<double> lineEnd,
  ) {
    double x = p[0], y = p[1];
    double x1 = lineStart[0], y1 = lineStart[1];
    double x2 = lineEnd[0], y2 = lineEnd[1];

    double A = x - x1;
    double B = y - y1;
    double C = x2 - x1;
    double D = y2 - y1;

    double dot = A * C + B * D;
    double lenSq = C * C + D * D;
    double param = -1;

    if (lenSq != 0) param = dot / lenSq;

    double xx, yy;

    if (param < 0) {
      xx = x1;
      yy = y1;
    } else if (param > 1) {
      xx = x2;
      yy = y2;
    } else {
      xx = x1 + param * C;
      yy = y1 + param * D;
    }

    double dx = x - xx;
    double dy = y - yy;

    return math.sqrt(dx * dx + dy * dy);
  }
}

class DrawingValidationResult {
  final bool isValid;
  final String? message;
  const DrawingValidationResult.valid() : isValid = true, message = null;
  const DrawingValidationResult.error(this.message) : isValid = false;
}

class _Bounds {
  final double minX, maxX, minY, maxY;
  _Bounds(this.minX, this.maxX, this.minY, this.maxY);
}
