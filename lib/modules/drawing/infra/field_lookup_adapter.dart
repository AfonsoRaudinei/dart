import 'dart:convert';

import 'package:soloforte_app/core/contracts/i_field_lookup.dart';
import 'package:soloforte_app/core/utils/app_logger.dart';
import 'package:soloforte_app/modules/drawing/domain/models/drawing_models.dart';
import 'package:soloforte_app/modules/drawing/data/data_sources/drawing_local_store.dart';

/// Adapter que implementa IFieldLookup usando DrawingLocalStore.
/// Vive em drawing/infra/ — única ponte autorizada para dados de talhão.
class FieldLookupAdapter implements IFieldLookup {
  final DrawingLocalStore _store;

  const FieldLookupAdapter(this._store);

  @override
  Future<FieldSummary?> findById(String fieldId) async {
    final feature = await _store.getById(fieldId);
    if (feature == null) return null;
    return _toSummary(feature);
  }

  @override
  Future<List<FieldSummary>> listByFarmId(String farmId) async {
    final all = await _store.getAll();
    return all
        .where(
          (f) => f.properties.fazendaId == farmId,
        ) // Usando fazendaId do DrawingProperties
        .map(_toSummary)
        .toList();
  }

  @override
  Future<List<FieldSummary>> listAll() async {
    // drawing/ não tem listAll impl — geofence usa FieldLookupGeofenceAdapter
    // ADR-024
    return const [];
  }

  FieldSummary _toSummary(DrawingFeature feature) {
    return FieldSummary(
      id: feature.id,
      name: feature.properties.nome,
      farmId: feature.properties.fazendaId ?? '',
      areaHa: feature.properties.areaHa,
      bbox: _calculateBbox(feature),
      geometry: jsonEncode(feature.geometry.toJson()),
    );
  }

  List<double>? _calculateBbox(DrawingFeature feature) {
    final rings = _extractRings(feature);
    if (rings.isEmpty) return null;

    double minLon = double.infinity;
    double minLat = double.infinity;
    double maxLon = double.negativeInfinity;
    double maxLat = double.negativeInfinity;

    for (final ring in rings) {
      for (final point in ring) {
        if (point.length < 2) continue;
        final lon = point[0];
        final lat = point[1];
        if (lon < minLon) minLon = lon;
        if (lat < minLat) minLat = lat;
        if (lon > maxLon) maxLon = lon;
        if (lat > maxLat) maxLat = lat;
      }
    }

    if (minLon == double.infinity) return null;
    return [minLon, minLat, maxLon, maxLat];
  }

  List<List<List<double>>> _extractRings(DrawingFeature feature) {
    try {
      final geometry = feature.geometry;
      if (geometry is DrawingPolygon) {
        return geometry.coordinates;
      } else if (geometry is DrawingMultiPolygon) {
        return geometry.coordinates.expand((polygon) => polygon).toList();
      }
    } catch (error) {
      AppLogger.warning(
        'Geometria inválida ignorada no lookup de talhão',
        tag: 'FieldLookup',
        error: error,
      );
    }
    return [];
  }
}
