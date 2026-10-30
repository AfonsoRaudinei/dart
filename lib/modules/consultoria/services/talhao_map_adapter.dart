import 'package:flutter/material.dart';
import 'package:soloforte_app/ui/theme/premium/design_tokens.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/state/map_state.dart';
import '../../../core/utils/app_logger.dart';
import '../../../core/utils/area_display_format.dart';
import '../clients/domain/agronomic_models.dart';

class TalhaoMapAdapter {
  /// Converte [talhao] em um ou mais polígonos do mapa (MultiPolygon + furos).
  ///
  /// Rótulo/área usam [Talhao.areaHa]; label só no primeiro polígono gerado.
  static List<Polygon> toMapPolygons(
    Talhao talhao, {
    bool isSelected = false,
    AreaDisplayUnit unit = AreaDisplayUnit.hectare,
    TalhaoMapLabelPrefs labelPrefs = const TalhaoMapLabelPrefs(),
  }) {
    if (talhao.geometry == null) return const [];

    final parts = _parseGeoJsonRingSets(talhao.geometry!);
    if (parts.isEmpty) return const [];

    final labelText = buildTalhaoMapLabel(
      talhao.name,
      talhao.areaHa,
      unit,
      prefs: labelPrefs,
      cultura: talhao.crop,
    );

    final fillColor = isSelected
        ? PremiumTokens.brandGreen.withValues(alpha: 0.4)
        : PremiumTokens.brandGreen.withValues(alpha: 0.15);
    final borderColor = isSelected ? Colors.white : const Color(0xFF248A3D);
    final borderStrokeWidth = isSelected ? 3.0 : 1.5;
    final labelStyle = TextStyle(
      color: Colors.black,
      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      fontSize: 12,
    );

    final polygons = <Polygon>[];
    var labelAssigned = false;

    for (final rings in parts) {
      if (rings.isEmpty || rings.first.isEmpty) continue;

      final outer = _ringToLatLng(rings.first);
      if (outer.isEmpty) continue;

      final holes = rings.length > 1
          ? rings.skip(1).map(_ringToLatLng).where((h) => h.length >= 3).toList()
          : null;

      final showLabel = !labelAssigned && labelText.isNotEmpty;
      if (showLabel) labelAssigned = true;

      polygons.add(
        Polygon(
          points: outer,
          holePointsList: holes?.isEmpty ?? true ? null : holes,
          color: fillColor,
          borderColor: borderColor,
          borderStrokeWidth: borderStrokeWidth,
          label: showLabel ? labelText : null,
          labelStyle: labelStyle,
          rotateLabel: true,
        ),
      );
    }

    return polygons;
  }

  /// Um único [Polygon] (anel externo apenas). Mantido para hit/viewport legados.
  static Polygon toPolygon(
    Talhao talhao, {
    bool isSelected = false,
    AreaDisplayUnit unit = AreaDisplayUnit.hectare,
    TalhaoMapLabelPrefs labelPrefs = const TalhaoMapLabelPrefs(),
  }) {
    if (talhao.geometry == null) {
      return Polygon(points: []); // Empty if no geometry
    }

    final points = _parseGeoJsonOuterRing(talhao.geometry!);
    final labelText = buildTalhaoMapLabel(
      talhao.name,
      talhao.areaHa,
      unit,
      prefs: labelPrefs,
      cultura: talhao.crop,
    );

    return Polygon(
      points: points,
      color: isSelected
          ? PremiumTokens.brandGreen.withValues(alpha: 0.4)
          : PremiumTokens.brandGreen.withValues(alpha: 0.15),
      borderColor: isSelected ? Colors.white : const Color(0xFF248A3D),
      borderStrokeWidth: isSelected ? 3.0 : 1.5,
      label: labelText.isEmpty ? null : labelText,
      labelStyle: TextStyle(
        color: Colors.black,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        fontSize: 12,
      ),
      rotateLabel: true,
    );
  }

  /// Partes GeoJSON como listas de anéis `[lng,lat]` (outer + holes).
  static List<List<List<List<double>>>> _parseGeoJsonRingSets(
    Map<String, dynamic> geometry,
  ) {
    try {
      final type = geometry['type'];
      if (type == 'Polygon') {
        final rings = _ringsFromGeoJsonCoordinates(geometry['coordinates']);
        return rings.isEmpty ? [] : [rings];
      }
      if (type == 'MultiPolygon') {
        final raw = geometry['coordinates'];
        if (raw is! List) return [];
        final parts = <List<List<List<double>>>>[];
        for (final part in raw) {
          if (part is! List) continue;
          final rings = _ringsFromGeoJsonCoordinates(part);
          if (rings.isNotEmpty) parts.add(rings);
        }
        return parts;
      }
    } catch (e) {
      AppLogger.warning(
        'Erro ao parsear geometry do talhão',
        tag: 'TalhaoMap',
        error: e,
      );
    }
    return [];
  }

  static List<LatLng> _parseGeoJsonOuterRing(Map<String, dynamic> geometry) {
    final parts = _parseGeoJsonRingSets(geometry);
    if (parts.isEmpty || parts.first.isEmpty || parts.first.first.isEmpty) {
      return [];
    }
    return _ringToLatLng(parts.first.first);
  }

  static List<List<List<double>>> _ringsFromGeoJsonCoordinates(Object? raw) {
    if (raw is! List || raw.isEmpty) return [];

    final rings = <List<List<double>>>[];
    for (final ringRaw in raw) {
      if (ringRaw is! List) continue;
      final ring = <List<double>>[];
      for (final coord in ringRaw) {
        if (coord is! List || coord.length < 2) continue;
        final lng = coord[0];
        final lat = coord[1];
        if (lng is! num || lat is! num) continue;
        ring.add([lng.toDouble(), lat.toDouble()]);
      }
      if (ring.length >= 3) rings.add(ring);
    }
    return rings;
  }

  static List<LatLng> _ringToLatLng(List<List<double>> ring) {
    return ring
        .map((coord) => LatLng(coord[1], coord[0]))
        .toList(growable: false);
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
