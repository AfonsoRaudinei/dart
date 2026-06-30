// lib/modules/consultoria/fields/infra/field_lookup_geofence_adapter.dart
//
// Adapter para geofence_controller em visitas/.
// Implementa IFieldLookup com geometry (GeoJSON serializado) e listAll().
//
// ADR-024 — DT-023-4
// Separado do adapter de drawing/ por intenção e por fonte de dados.
// drawing/ usa DrawingLocalStore; este usa FieldRepository (SQLite via Supabase).
//
// NÃO importar em drawing/ nem em visitas/ diretamente.
// Consumir via iFieldLookupGeofenceProvider (core/contracts/).

import 'dart:convert';
import 'package:soloforte_app/core/contracts/i_field_lookup.dart';
import '../data/repositories/field_repository.dart';
import '../../clients/domain/agronomic_models.dart';

/// Implementação concreta de IFieldLookup para geofence_controller.
/// Vive em consultoria/fields/infra/ — dona dos dados de talhão (SQLite).
class FieldLookupGeofenceAdapter implements IFieldLookup {
  const FieldLookupGeofenceAdapter(this._repository);

  final FieldRepository _repository;

  @override
  Future<FieldSummary?> findById(String fieldId) async {
    final talhao = await _repository.getFieldById(fieldId);
    if (talhao == null) return null;
    return _toSummary(talhao);
  }

  @override
  Future<List<FieldSummary>> listByFarmId(String farmId) async {
    final talhoes = await _repository.getFieldsByFarmId(farmId);
    return talhoes.map((t) => _toSummaryWithFarm(t, farmId)).toList();
  }

  @override
  Future<List<FieldSummary>> listAll() async {
    final talhoes = await _repository.getAllFields();
    return talhoes.map(_toSummary).toList();
  }

  /// Mapper padrão — farmId desconhecido (getAllFields / getFieldById não retornam fazenda_id).
  /// geofence_controller não usa farmId; '' é aceitável para este caso.
  FieldSummary _toSummary(Talhao talhao) => _toSummaryWithFarm(talhao, '');

  FieldSummary _toSummaryWithFarm(Talhao talhao, String farmId) {
    return FieldSummary(
      id: talhao.id,
      name: talhao.name,
      farmId: farmId,
      areaHa: talhao.areaHa,
      crop: talhao.crop,
      harvest: talhao.harvest,
      bbox: _bboxFromGeometry(talhao.geometry),
      // Serializa geometry de Map<String,dynamic> para String (GeoJSON)
      // para compatibilidade com FieldSummary.geometry: String?
      geometry: talhao.geometry != null ? jsonEncode(talhao.geometry) : null,
    );
  }

  /// [minLon, minLat, maxLon, maxLat] a partir de GeoJSON em Map.
  List<double>? _bboxFromGeometry(Map<String, dynamic>? geometry) {
    if (geometry == null || geometry.isEmpty) return null;

    final values = <double>[];
    void walk(dynamic node) {
      if (node is List) {
        if (node.length >= 2 && node[0] is num && node[1] is num) {
          values.add((node[0] as num).toDouble());
          values.add((node[1] as num).toDouble());
          return;
        }
        for (final child in node) {
          walk(child);
        }
      }
    }

    walk(geometry['coordinates']);
    if (values.length < 4) return null;

    var minLon = double.infinity;
    var minLat = double.infinity;
    var maxLon = double.negativeInfinity;
    var maxLat = double.negativeInfinity;

    for (var i = 0; i < values.length; i += 2) {
      final lon = values[i];
      final lat = values[i + 1];
      if (lon < minLon) minLon = lon;
      if (lat < minLat) minLat = lat;
      if (lon > maxLon) maxLon = lon;
      if (lat > maxLat) maxLat = lat;
    }

    if (minLon == double.infinity) return null;
    return [minLon, minLat, maxLon, maxLat];
  }
}
