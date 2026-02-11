import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:soloforte_app/ui/theme/soloforte_theme.dart';
import '../clients/domain/agronomic_models.dart';

class TalhaoMapAdapter {
  // Convert Talhao entity to Polygon
  static Polygon toPolygon(Talhao talhao, {bool isSelected = false}) {
    if (talhao.geometry == null) {
      return Polygon(points: []); // Empty if no geometry
    }

    final points = _parseGeoJsonCoordinates(talhao.geometry!);

    return Polygon(
      points: points,
      color: isSelected
          ? SoloForteColors.greenIOS.withValues(alpha: 0.4)
          : SoloForteColors.greenIOS.withValues(alpha: 0.15),
      borderColor: isSelected ? Colors.white : SoloForteColors.greenDark,
      borderStrokeWidth: isSelected ? 3.0 : 1.5,
      label: talhao.name,
      labelStyle: TextStyle(
        color: Colors.black,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        fontSize: 12,
      ),
      rotateLabel:
          true, // Requires newer flutter_map, assuming 7.0 supports it or ignores if not.
    );
  }

  // Helper to parse standard GeoJSON Polygon
  // Assumes geometry type is 'Polygon'.
  // TODO: Support MultiPolygon if needed.
  static List<LatLng> _parseGeoJsonCoordinates(Map<String, dynamic> geometry) {
    try {
      final type = geometry['type'];
      if (type == 'Polygon') {
        final List coordinates = geometry['coordinates'];
        // Outer ring is first element
        if (coordinates.isNotEmpty) {
          final ring = coordinates[0] as List;
          return ring.map((coord) {
            // GeoJSON is [lng, lat]
            final double lng = (coord[0] as num).toDouble();
            final double lat = (coord[1] as num).toDouble();
            return LatLng(lat, lng);
          }).toList();
        }
      }
    } catch (e) {
      debugPrint('Error parsing geometry: $e');
    }
    return [];
  }

  // Hit Test: Check if point is inside polygon
  // Basic Ray-Casting algorithm
  static bool isPointInside(LatLng point, List<LatLng> polygonPoints) {
    int intersectCount = 0;
    for (int j = 0; j < polygonPoints.length - 1; j++) {
      if (rayCastIntersect(point, polygonPoints[j], polygonPoints[j + 1])) {
        intersectCount++;
      }
    }
    return (intersectCount % 2) == 1; // odd = inside, even = outside
  }

  static bool rayCastIntersect(LatLng point, LatLng vertA, LatLng vertB) {
    double aY = vertA.latitude;
    double bY = vertB.latitude;
    double aX = vertA.longitude;
    double bX = vertB.longitude;
    double pY = point.latitude;
    double pX = point.longitude;

    if ((aY > pY && bY > pY) || (aY < pY && bY < pY) || (aX < pX && bX < pX)) {
      return false; // Quick rejection
    }

    if (aY == bY) {
      return false; // Horizontal segment
    }

    double m = (bX - aX) / (bY - aY);
    double bee = -aY * m + aX;
    double x = pY * m + bee;

    return x > pX;
  }
}
