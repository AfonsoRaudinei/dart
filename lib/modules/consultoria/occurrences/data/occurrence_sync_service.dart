import 'dart:convert';

import 'package:sqflite/sqflite.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:soloforte_app/core/contracts/i_occurrence_access_reader.dart';
import 'package:soloforte_app/core/database/database_helper.dart';
import 'package:soloforte_app/core/network/network_policy.dart';
import 'package:soloforte_app/core/utils/app_logger.dart';

import '../domain/occurrence.dart';

class OccurrenceSyncService {
  OccurrenceSyncService(this._supabase, this._accessReader);

  final SupabaseClient _supabase;
  final IOccurrenceAccessReader _accessReader;

  Future<void> syncOccurrences() async {
    await _syncOccurrencesPush();
    await _syncOccurrencesPull();
  }

  Future<void> _syncOccurrencesPush() async {
    final db = await DatabaseHelper.instance.database;
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    final pending = await db.query(
      'occurrences',
      where:
          "user_id = ? AND cached_by_user_id IS NULL "
          "AND sync_status IN ('local', 'local_only', 'updated', "
          "'pending_sync', 'deleted', 'deleted_local')",
      whereArgs: [userId],
    );

    for (final row in pending) {
      final occurrence = Occurrence.fromMap(row);
      try {
        final payload = OccurrenceRemoteMapper.toRemote(occurrence, userId);
        await NetworkPolicy.withTimeout(
          () => _supabase.from('occurrences').upsert(payload),
        );
        await db.update(
          'occurrences',
          {'sync_status': 'synced'},
          where: 'id = ? AND user_id = ?',
          whereArgs: [occurrence.id, userId],
        );
      } catch (error) {
        AppLogger.warning(
          'Falha ao enviar ocorrencia ${occurrence.id}: $error',
          tag: 'OccurrenceSync',
        );
      }
    }
  }

  Future<void> _syncOccurrencesPull() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      AppLogger.warning(
        'Skipping occurrence pull: userId is null',
        tag: 'OccurrenceSync',
      );
      return;
    }

    final activeClientIds = await _accessReader.loadActiveClientIds();
    final ownRows = await NetworkPolicy.withTimeout(
      () => _supabase
          .from('occurrences')
          .select()
          .eq('user_id', userId)
          .order('updated_at'),
    );

    final sharedRows = activeClientIds.isEmpty
        ? const <Map<String, dynamic>>[]
        : await NetworkPolicy.withTimeout(
            () => _supabase
                .from('occurrences')
                .select()
                .inFilter('client_id', activeClientIds.toList())
                .order('updated_at'),
          );

    final rowsById = <String, Map<String, dynamic>>{};
    for (final raw in [...ownRows, ...sharedRows]) {
      final row = Map<String, dynamic>.from(raw);
      rowsById[row['id'] as String] = row;
    }

    final db = await DatabaseHelper.instance.database;
    await db.transaction((txn) async {
      await _removeRevokedCache(txn, userId, activeClientIds);
      for (final remote in rowsById.values) {
        await _cacheRemote(txn, remote, userId);
      }
    });
  }

  Future<void> _cacheRemote(
    DatabaseExecutor db,
    Map<String, dynamic> remote,
    String currentUserId,
  ) async {
    final ownerUserId = remote['user_id'] as String;
    final isOwned = ownerUserId == currentUserId;
    final remoteId = remote['id'] as String;
    final localId = isOwned ? remoteId : '${remoteId}_cache_$currentUserId';

    if (!isOwned) {
      await _removeLegacySharedCache(db, remoteId, currentUserId);
    }

    if (remote['deleted_at'] != null) {
      await db.delete('occurrences', where: 'id = ?', whereArgs: [localId]);
      return;
    }

    if (isOwned) {
      final existing = await db.query(
        'occurrences',
        columns: ['sync_status', 'updated_at'],
        where: 'id = ?',
        whereArgs: [localId],
        limit: 1,
      );
      if (existing.isNotEmpty &&
          !OccurrenceCachePolicy.shouldReplaceOwnedLocal(
            existing.single,
            remote,
          )) {
        return;
      }
    }

    final localData = OccurrenceRemoteMapper.fromRemote(
      remote,
      localId: localId,
      cachedByUserId: isOwned ? null : currentUserId,
    );
    await db.insert(
      'occurrences',
      localData,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> _removeLegacySharedCache(
    DatabaseExecutor db,
    String remoteId,
    String currentUserId,
  ) async {
    await db.delete(
      'occurrences',
      where:
          'id = ? AND user_id = ? AND cached_by_user_id IS NULL '
          "AND sync_status = 'synced'",
      whereArgs: [remoteId, currentUserId],
    );
  }

  Future<void> _removeRevokedCache(
    DatabaseExecutor db,
    String userId,
    Set<String> activeClientIds,
  ) async {
    final cached = await db.query(
      'occurrences',
      columns: ['id', 'client_id'],
      where: 'cached_by_user_id = ?',
      whereArgs: [userId],
    );
    final revokedIds = OccurrenceCachePolicy.revokedLocalIds(
      cached,
      activeClientIds,
    );
    for (final id in revokedIds) {
      await db.delete('occurrences', where: 'id = ?', whereArgs: [id]);
    }
  }
}

class OccurrenceCachePolicy {
  const OccurrenceCachePolicy._();

  static List<String> revokedLocalIds(
    Iterable<Map<String, Object?>> cachedRows,
    Set<String> activeClientIds,
  ) {
    return cachedRows
        .where((row) {
          final clientId = row['client_id'] as String?;
          return clientId == null || !activeClientIds.contains(clientId);
        })
        .map((row) => row['id'] as String)
        .toList(growable: false);
  }

  static bool shouldReplaceOwnedLocal(
    Map<String, Object?> local,
    Map<String, dynamic> remote,
  ) {
    const pendingStatuses = {
      'local',
      'local_only',
      'updated',
      'pending_sync',
      'deleted',
      'deleted_local',
    };
    if (pendingStatuses.contains(local['sync_status'])) return false;

    final localUpdatedAt = DateTime.tryParse(
      local['updated_at']?.toString() ?? '',
    );
    final remoteUpdatedAt = DateTime.tryParse(
      remote['updated_at']?.toString() ?? '',
    );
    if (localUpdatedAt == null || remoteUpdatedAt == null) return true;
    return remoteUpdatedAt.isAfter(localUpdatedAt);
  }
}

class OccurrenceRemoteMapper {
  const OccurrenceRemoteMapper._();

  static Map<String, dynamic> toRemote(
    Occurrence occurrence,
    String ownerUserId,
  ) {
    final coordinates = resolveCoordinates(
      latitude: occurrence.lat,
      longitude: occurrence.long,
      geometry: occurrence.geometry,
    );
    final isDeleted =
        occurrence.syncStatus == 'deleted_local' ||
        occurrence.syncStatus == 'deleted';
    return {
      'id': occurrence.remoteId ?? occurrence.id,
      'user_id': ownerUserId,
      'visit_session_id': occurrence.visitSessionId,
      'client_id': occurrence.clientId,
      'type': occurrence.type,
      'description': occurrence.description,
      'photo_path': occurrence.photoPath,
      'latitude': coordinates?.latitude,
      'longitude': coordinates?.longitude,
      'geometry': coordinates?.geometry,
      'sync_status': isDeleted ? 'deleted_local' : 'synced',
      'updated_at': occurrence.updatedAt.toUtc().toIso8601String(),
      'category': occurrence.category,
      'status': occurrence.status,
      'cultivar': occurrence.cultivar,
      'data_plantio': occurrence.dataPlantio,
      'estadio_fenologico': occurrence.estadioFenologico,
      'tipo_ocorrencia': occurrence.tipoOcorrencia,
      'amostra_solo': occurrence.amostraSolo,
      'recomendacoes': occurrence.recomendacoes,
      'metricas_json': _decodeJson(occurrence.metricasJson),
      'nutrientes_json': _decodeJson(occurrence.nutrientesJson),
      'categorias_json': _decodeJson(occurrence.categoriasJson),
      'notas_categorias_json': _decodeJson(occurrence.notasCategoriasJson),
      'fotos_categorias_json': _decodeJson(occurrence.fotosCategoriasJson),
      'external_source': occurrence.externalSource,
      'external_analysis_id': occurrence.externalAnalysisId,
      'analysis_payload': _decodeJson(occurrence.analysisPayloadJson),
      'deleted_at': isDeleted ? DateTime.now().toUtc().toIso8601String() : null,
    };
  }

  static Map<String, dynamic> fromRemote(
    Map<String, dynamic> remote, {
    required String localId,
    required String? cachedByUserId,
  }) {
    final geometry = _geometryJson(remote['geometry']);
    final coordinates = resolveCoordinates(
      latitude: _asDouble(remote['latitude']),
      longitude: _asDouble(remote['longitude']),
      geometry: geometry,
    );
    return {
      'id': localId,
      'remote_id': remote['id'],
      'user_id': remote['user_id'],
      'cached_by_user_id': cachedByUserId,
      'visit_session_id': remote['visit_session_id'],
      'client_id': remote['client_id'],
      'type': remote['type'] ?? 'Info',
      'description': remote['description'] ?? '',
      'photo_path': remote['photo_path'],
      'lat': coordinates?.latitude,
      'long': coordinates?.longitude,
      'geometry': geometry,
      'created_at': remote['created_at'] ?? DateTime.now().toIso8601String(),
      'updated_at': remote['updated_at'] ?? DateTime.now().toIso8601String(),
      'sync_status': 'synced',
      'category': remote['category'],
      'status': remote['status'] ?? 'confirmed',
      'cultivar': remote['cultivar'],
      'data_plantio': remote['data_plantio'],
      'estadio_fenologico': remote['estadio_fenologico'],
      'tipo_ocorrencia': remote['tipo_ocorrencia'],
      'amostra_solo': _asSqliteBool(remote['amostra_solo']),
      'recomendacoes': remote['recomendacoes'],
      'metricas_json': _encodeJson(remote['metricas_json']),
      'nutrientes_json': _encodeJson(remote['nutrientes_json']),
      'categorias_json': _encodeJson(remote['categorias_json']),
      'notas_categorias_json': _encodeJson(remote['notas_categorias_json']),
      'fotos_categorias_json': _encodeJson(remote['fotos_categorias_json']),
      'external_source': remote['external_source'],
      'external_analysis_id': remote['external_analysis_id'],
      'analysis_payload_json': _encodeJson(remote['analysis_payload']),
      'deleted_at': remote['deleted_at'],
    };
  }

  static OccurrenceCoordinates? resolveCoordinates({
    required double? latitude,
    required double? longitude,
    required String? geometry,
  }) {
    if (_valid(latitude, longitude)) {
      return OccurrenceCoordinates(latitude: latitude!, longitude: longitude!);
    }
    if (geometry == null || geometry.isEmpty) return null;
    try {
      final decoded = jsonDecode(geometry);
      final coordinates = decoded is Map && decoded['type'] == 'Point'
          ? decoded['coordinates']
          : null;
      if (coordinates is! List || coordinates.length < 2) return null;
      final fallbackLongitude = _asDouble(coordinates[0]);
      final fallbackLatitude = _asDouble(coordinates[1]);
      if (!_valid(fallbackLatitude, fallbackLongitude)) return null;
      return OccurrenceCoordinates(
        latitude: fallbackLatitude!,
        longitude: fallbackLongitude!,
      );
    } catch (_) {
      return null;
    }
  }

  static bool _valid(double? latitude, double? longitude) {
    if (latitude == null || longitude == null) return false;
    if (!latitude.isFinite || !longitude.isFinite) return false;
    if (latitude < -90 || latitude > 90) return false;
    if (longitude < -180 || longitude > 180) return false;
    return latitude != 0 || longitude != 0;
  }

  static Object? _decodeJson(String? value) {
    if (value == null || value.isEmpty) return null;
    try {
      return jsonDecode(value);
    } catch (_) {
      return value;
    }
  }

  static String? _encodeJson(Object? value) {
    if (value == null) return null;
    return value is String ? value : jsonEncode(value);
  }

  static String? _geometryJson(Object? value) {
    if (value == null) return null;
    return value is String ? value : jsonEncode(value);
  }

  static double? _asDouble(Object? value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '');
  }

  static int _asSqliteBool(Object? value) {
    return value == true || value == 1 ? 1 : 0;
  }
}

class OccurrenceCoordinates {
  OccurrenceCoordinates({required this.latitude, required this.longitude});

  final double latitude;
  final double longitude;

  Map<String, dynamic> get geometry => {
    'type': 'Point',
    'coordinates': [longitude, latitude],
  };
}
