import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soloforte_app/core/session/local_session_identity.dart';
import 'package:soloforte_app/core/database/database_helper.dart';
import 'package:soloforte_app/modules/consultoria/fields/data/repositories/field_repository.dart';
import 'package:latlong2/latlong.dart';
import 'package:sqflite/sqflite.dart';
import '../../domain/agronomic_models.dart';

class ClientDrawingFieldSummary {
  const ClientDrawingFieldSummary({
    required this.id,
    required this.name,
    required this.areaHa,
    required this.vertices,
    this.farmId,
    this.updatedAt,
    this.syncStatus,
  });

  final String id;
  final String name;
  final double areaHa;
  final List<LatLng> vertices;
  final String? farmId;
  final DateTime? updatedAt;
  final int? syncStatus;
}

enum FarmLinkedFieldSource { field, drawing }

class FarmLinkedFieldSummary {
  const FarmLinkedFieldSummary({
    required this.id,
    required this.name,
    required this.areaHa,
    required this.source,
    this.vertices = const [],
    this.crop,
    this.harvest,
    this.updatedAt,
    this.syncStatus,
    this.perimeter,
    this.thumbnailPath,
  });

  final String id;
  final String name;
  final double areaHa;
  final FarmLinkedFieldSource source;
  final List<LatLng> vertices;
  final String? crop;
  final String? harvest;
  final DateTime? updatedAt;
  final int? syncStatus;
  final double? perimeter;
  final String? thumbnailPath;

  bool get isDrawing => source == FarmLinkedFieldSource.drawing;
}

// Repository Provider
final fieldRepositoryProvider = Provider<FieldRepository>((ref) {
  return FieldRepository();
});

// Selected Farm ID for Map Context
// This state should be managed by the UI (e.g., when user selects a farm)
final selectedFarmIdProvider = StateProvider<String?>((ref) => null);

// Fields for Selected Farm
final mapFieldsProvider = FutureProvider.autoDispose<List<Talhao>>((ref) async {
  final farmId = ref.watch(selectedFarmIdProvider);
  final repo = ref.read(fieldRepositoryProvider);

  if (farmId == null) {
    return repo.getAllFields();
  }

  return repo.getFieldsByFarmId(farmId);
});

// Fields by Farm ID (Family)
final farmFieldsProvider = FutureProvider.family
    .autoDispose<List<Talhao>, String>((ref, farmId) async {
      final repo = ref.read(fieldRepositoryProvider);
      return repo.getFieldsByFarmId(farmId);
    });

final farmLinkedFieldsProvider = FutureProvider.family
    .autoDispose<List<FarmLinkedFieldSummary>, String>((ref, farmId) async {
      if (farmId.isEmpty) return const [];

      final repo = ref.read(fieldRepositoryProvider);
      final fields = await repo.getFieldsByFarmId(farmId);
      final drawingFields = await _loadDrawingFieldsByFarmId(farmId);

      return mergeFarmLinkedFieldSummaries(
        fieldSummaries: fields.map(_linkedSummaryFromField).toList(),
        drawingSummaries: drawingFields,
      );
    });

final clientDrawingFieldsProvider = FutureProvider.family
    .autoDispose<List<ClientDrawingFieldSummary>, String>((
      ref,
      clientId,
    ) async {
      final userId = LocalSessionIdentity.resolveUserId();
      if (userId.isEmpty || clientId.isEmpty) return const [];

      final Database db = await DatabaseHelper.instance.database;
      final maps = await db.query(
        'drawings',
        columns: [
          'id',
          'nome',
          'area_ha',
          'fazenda_id',
          'geojson',
          'updated_at',
          'sync_status',
        ],
        where:
            'user_id = ? AND cliente_id = ? AND deleted_at IS NULL AND ativo = 1',
        whereArgs: [userId, clientId],
        orderBy: 'updated_at DESC',
      );

      return maps.map((row) {
        final syncValue = row['sync_status'];
        return ClientDrawingFieldSummary(
          id: row['id'] as String,
          name: row['nome'] as String? ?? 'Talhão sem nome',
          areaHa: (row['area_ha'] as num?)?.toDouble() ?? 0,
          vertices: _verticesFromGeoJson(row['geojson'] as String?),
          farmId: row['fazenda_id'] as String?,
          updatedAt: row['updated_at'] != null
              ? DateTime.tryParse(row['updated_at'] as String)
              : null,
          syncStatus: syncValue is int ? syncValue : null,
        );
      }).toList();
    });

List<FarmLinkedFieldSummary> mergeFarmLinkedFieldSummaries({
  required List<FarmLinkedFieldSummary> fieldSummaries,
  required List<FarmLinkedFieldSummary> drawingSummaries,
}) {
  final seenIds = <String>{};
  final merged = <FarmLinkedFieldSummary>[];

  for (final summary in [...fieldSummaries, ...drawingSummaries]) {
    if (summary.id.isEmpty || !seenIds.add(summary.id)) continue;
    merged.add(summary);
  }

  return merged;
}

double totalFarmLinkedAreaHa(List<FarmLinkedFieldSummary> fields) {
  return fields.fold<double>(0, (sum, field) => sum + field.areaHa);
}

FarmLinkedFieldSummary _linkedSummaryFromField(Talhao field) {
  return FarmLinkedFieldSummary(
    id: field.id,
    name: field.name,
    areaHa: field.areaHa,
    source: FarmLinkedFieldSource.field,
    vertices: _verticesFromGeometry(field.geometry),
    crop: field.crop.isEmpty ? null : field.crop,
    harvest: field.harvest.isEmpty ? null : field.harvest,
    updatedAt: field.updatedAt,
    syncStatus: field.syncStatus,
    perimeter: field.perimeter,
    thumbnailPath: field.thumbnailPath,
  );
}

Future<List<FarmLinkedFieldSummary>> _loadDrawingFieldsByFarmId(
  String farmId,
) async {
  final userId = LocalSessionIdentity.resolveUserId();
  if (userId.isEmpty || farmId.isEmpty) return const [];

  final Database db = await DatabaseHelper.instance.database;
  final maps = await db.query(
    'drawings',
    columns: [
      'id',
      'nome',
      'area_ha',
      'geojson',
      'updated_at',
      'sync_status',
      'cultura',
      'safra',
    ],
    where:
        'user_id = ? AND fazenda_id = ? AND deleted_at IS NULL AND ativo = 1',
    whereArgs: [userId, farmId],
    orderBy: 'updated_at DESC',
  );

  return maps.map((row) {
    return FarmLinkedFieldSummary(
      id: row['id'] as String,
      name: row['nome'] as String? ?? 'Talhão sem nome',
      areaHa: (row['area_ha'] as num?)?.toDouble() ?? 0,
      source: FarmLinkedFieldSource.drawing,
      vertices: _verticesFromGeoJson(row['geojson'] as String?),
      crop: row['cultura'] as String?,
      harvest: row['safra'] as String?,
      updatedAt: row['updated_at'] != null
          ? DateTime.tryParse(row['updated_at'] as String)
          : null,
      syncStatus: _syncStatusFromValue(row['sync_status']),
    );
  }).toList();
}

int? _syncStatusFromValue(Object? value) {
  if (value is int) return value;
  if (value is String) return int.tryParse(value);
  return null;
}

List<LatLng> _verticesFromGeometry(Map<String, dynamic>? geometry) {
  if (geometry == null || geometry.isEmpty) return const [];
  return _verticesFromGeoJson(jsonEncode(geometry));
}

List<LatLng> _verticesFromGeoJson(String? rawGeoJson) {
  if (rawGeoJson == null || rawGeoJson.isEmpty) return const [];

  try {
    final json = jsonDecode(rawGeoJson) as Map<String, dynamic>;
    final type = json['type'] as String?;
    final coordinates = json['coordinates'];

    if (type == 'Polygon') {
      return _ringToLatLngs((coordinates as List).first as List);
    }

    if (type == 'MultiPolygon') {
      final firstPolygon = (coordinates as List).first as List;
      return _ringToLatLngs(firstPolygon.first as List);
    }
  } catch (_) {
    return const [];
  }

  return const [];
}

List<LatLng> _ringToLatLngs(List ring) {
  return ring
      .whereType<List>()
      .where((point) => point.length >= 2)
      .map((point) {
        final lng = (point[0] as num).toDouble();
        final lat = (point[1] as num).toDouble();
        return LatLng(lat, lng);
      })
      .toList(growable: false);
}

// Selected Talhao ID on Map
final selectedTalhaoIdProvider = StateProvider<String?>((ref) => null);
