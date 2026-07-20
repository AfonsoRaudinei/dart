import 'dart:async';
import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/database/database_helper.dart';
import '../../../../core/infra/preferences_service.dart';
import '../../../../core/utils/app_logger.dart';
import '../../domain/models/drawing_models.dart';

class DrawingOwnershipPolicy {
  const DrawingOwnershipPolicy._();

  static const orphanUserId = '';

  static String normalizeSyncStatusForWrite({
    required String persistedUserId,
    required SyncStatus currentSyncStatus,
  }) {
    if (persistedUserId.isNotEmpty) return currentSyncStatus.toJson();
    if (currentSyncStatus == SyncStatus.synced) {
      return SyncStatus.local_only.toJson();
    }
    if (currentSyncStatus == SyncStatus.pending_sync) {
      return SyncStatus.local_only.toJson();
    }
    return currentSyncStatus.toJson();
  }

  static String buildOwnedOrOrphanWhereClause(String scopedUserId) {
    if (scopedUserId.isEmpty) {
      return "user_id = '$orphanUserId'";
    }
    return "(user_id = ? OR user_id = '$orphanUserId')";
  }

  static List<Object?> buildOwnedOrOrphanWhereArgs(String scopedUserId) {
    if (scopedUserId.isEmpty) return const <Object?>[];
    return [scopedUserId];
  }
}

class DrawingLocalIdentityStore {
  DrawingLocalIdentityStore({PreferencesService? preferences})
    : _preferences = preferences;

  static const _lastKnownUserIdKey = 'drawing_last_known_user_id_v1';
  static String? _ephemeralLastKnownUserId;

  final PreferencesService? _preferences;

  String resolveScopedUserId({required String? currentUserId}) {
    final normalizedCurrent = currentUserId?.trim() ?? '';
    if (normalizedCurrent.isNotEmpty) {
      _persistLastKnownUserId(normalizedCurrent);
      return normalizedCurrent;
    }

    final lastKnownUserId = _readLastKnownUserId();
    if (lastKnownUserId.isNotEmpty) {
      return lastKnownUserId;
    }

    return DrawingOwnershipPolicy.orphanUserId;
  }

  static void resetEphemeralStateForTest() {
    _ephemeralLastKnownUserId = null;
  }

  String _readLastKnownUserId() {
    final persisted =
        _preferences?.getString(_lastKnownUserIdKey)?.trim() ?? '';
    if (persisted.isNotEmpty) return persisted;
    return _ephemeralLastKnownUserId?.trim() ?? '';
  }

  void _persistLastKnownUserId(String userId) {
    _ephemeralLastKnownUserId = userId;
    if (_preferences == null) return;
    unawaited(_preferences.setString(_lastKnownUserIdKey, userId));
  }
}

class DrawingLocalStore {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final DrawingLocalIdentityStore _identityStore;

  DrawingLocalStore({DrawingLocalIdentityStore? identityStore})
    : _identityStore = identityStore ?? DrawingLocalIdentityStore();

  Future<void> insert(DrawingFeature feature) async {
    final userId = _resolveScopedUserId();
    final db = await _dbHelper.database;
    await db.insert('drawings', {
      ..._toRow(feature),
      'user_id': userId,
      'sync_status': DrawingOwnershipPolicy.normalizeSyncStatusForWrite(
        persistedUserId: userId,
        currentSyncStatus: feature.properties.syncStatus,
      ),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
    _logFallbackIdentityIfNeeded('insert', feature.id, userId);
  }

  Future<void> update(DrawingFeature feature) async {
    final userId = _resolveScopedUserId();
    final db = await _dbHelper.database;
    final payload = {
      ..._toRow(feature),
      'user_id': userId,
      'sync_status': DrawingOwnershipPolicy.normalizeSyncStatusForWrite(
        persistedUserId: userId,
        currentSyncStatus: feature.properties.syncStatus,
      ),
    };
    final affected = await db.update(
      'drawings',
      payload,
      where:
          'id = ? AND ${DrawingOwnershipPolicy.buildOwnedOrOrphanWhereClause(userId)}',
      whereArgs: [
        feature.id,
        ...DrawingOwnershipPolicy.buildOwnedOrOrphanWhereArgs(userId),
      ],
    );
    if (affected == 0) {
      await db.insert(
        'drawings',
        payload,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    _logFallbackIdentityIfNeeded('update', feature.id, userId);
  }

  Future<void> delete(String id) async {
    final userId = _resolveScopedUserId();
    final db = await _dbHelper.database;
    // Soft delete
    final affected = await db.update(
      'drawings',
      {'deleted_at': DateTime.now().toIso8601String(), 'ativo': 0},
      where:
          'id = ? AND ${DrawingOwnershipPolicy.buildOwnedOrOrphanWhereClause(userId)}',
      whereArgs: [
        id,
        ...DrawingOwnershipPolicy.buildOwnedOrOrphanWhereArgs(userId),
      ],
    );
    if (affected == 0) {
      AppLogger.warning(
        'DrawingLocalStore.delete encontrou 0 registros [id=$id scopedUser=$userId]',
        tag: 'DrawingLocalStore',
      );
    }
  }

  Future<DrawingFeature?> getById(String id) async {
    final userId = _resolveScopedUserId();
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'drawings',
      where:
          'id = ? AND ${DrawingOwnershipPolicy.buildOwnedOrOrphanWhereClause(userId)} '
          'AND deleted_at IS NULL',
      whereArgs: [
        id,
        ...DrawingOwnershipPolicy.buildOwnedOrOrphanWhereArgs(userId),
      ],
    );

    if (maps.isNotEmpty) {
      return _fromRow(maps.first);
    }
    return null;
  }

  Future<List<DrawingFeature>> getAll() async {
    final userId = _resolveScopedUserId();
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'drawings',
      where:
          '${DrawingOwnershipPolicy.buildOwnedOrOrphanWhereClause(userId)} '
          'AND deleted_at IS NULL AND ativo = 1',
      whereArgs: DrawingOwnershipPolicy.buildOwnedOrOrphanWhereArgs(userId),
      orderBy: 'updated_at DESC',
    );

    return maps.map((e) => _fromRow(e)).toList();
  }

  Future<List<DrawingFeature>> getPendingSync() async {
    final userId = _resolveScopedUserId();
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'drawings',
      where:
          "${DrawingOwnershipPolicy.buildOwnedOrOrphanWhereClause(userId)} "
          "AND sync_status != 'synced'",
      whereArgs: DrawingOwnershipPolicy.buildOwnedOrOrphanWhereArgs(userId),
    );
    return maps.map((e) => _fromRow(e)).toList();
  }

  /// Retorna a soma de area_ha de todos os drawings vinculados a [clienteId].
  /// Drawings com area_ha NULL são ignorados na soma.
  /// Retorna 0.0 se não houver nenhum drawing vinculado.
  Future<double> getTotalAreaByClienteId(String clienteId) async {
    final userId = _resolveScopedUserId();
    final db = await _dbHelper.database;
    final result = await db.rawQuery(
      'SELECT COALESCE(SUM(area_ha), 0.0) AS total '
      'FROM drawings '
      'WHERE ${DrawingOwnershipPolicy.buildOwnedOrOrphanWhereClause(userId)} '
      'AND cliente_id = ? AND deleted_at IS NULL',
      [
        ...DrawingOwnershipPolicy.buildOwnedOrOrphanWhereArgs(userId),
        clienteId,
      ],
    );
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  /// Atualiza SOMENTE area_total do cliente no banco local.
  Future<void> updateClientAreaTotal(String clientId, double areaTotal) async {
    final userId = _resolveScopedUserId();
    final db = await _dbHelper.database;
    final affected = await db.update(
      'clients',
      {
        'area_total': areaTotal,
        'updated_at': DateTime.now().toIso8601String(),
        'sync_status': 1,
      },
      where:
          'id = ? AND ${DrawingOwnershipPolicy.buildOwnedOrOrphanWhereClause(userId)}',
      whereArgs: [
        clientId,
        ...DrawingOwnershipPolicy.buildOwnedOrOrphanWhereArgs(userId),
      ],
    );
    if (affected == 0) {
      AppLogger.warning(
        'DrawingLocalStore.updateClientAreaTotal encontrou 0 clientes [clientId=$clientId scopedUser=$userId]',
        tag: 'DrawingLocalStore',
      );
    }
  }

  String _resolveScopedUserId() {
    return _identityStore.resolveScopedUserId(
      currentUserId: Supabase.instance.client.auth.currentUser?.id,
    );
  }

  void _logFallbackIdentityIfNeeded(
    String action,
    String featureId,
    String userId,
  ) {
    final currentUserId = Supabase.instance.client.auth.currentUser?.id ?? '';
    if (currentUserId.isNotEmpty || userId.isEmpty) {
      if (userId.isEmpty) {
        AppLogger.warning(
          'DrawingLocalStore.$action persisted orphan local drawing [id=$featureId]',
          tag: 'DrawingLocalStore',
        );
      }
      return;
    }
    AppLogger.warning(
      'DrawingLocalStore.$action usando last known user sem sessao hidratada '
      '[id=$featureId scopedUser=$userId]',
      tag: 'DrawingLocalStore',
    );
  }

  Map<String, dynamic> _toRow(DrawingFeature f) {
    return {
      'id': f.id,
      'nome': f.properties.nome,
      'tipo': f.properties.tipo.toJson(),
      'origem': f.properties.origem.toJson(),
      'status': f.properties.status.toJson(),
      'geojson': jsonEncode(f.geometry.toJson()),
      'area_ha': f.properties.areaHa,
      'autor_id': f.properties.autorId,
      'autor_tipo': f.properties.autorTipo.toJson(),
      'cliente_id': f.properties.clienteId,
      'fazenda_id': f.properties.fazendaId,
      'sync_status': f.properties.syncStatus.toJson(),
      'versao': f.properties.versao,
      'subtipo': f.properties.subtipo,
      'raio_metros': f.properties.raioMetros,
      'created_at': f.properties.createdAt.toIso8601String(),
      'updated_at': f.properties.updatedAt.toIso8601String(),
      'versao_anterior_id': f.properties.versaoAnteriorId,
      'ativo': f.properties.ativo ? 1 : 0,
      // 🌱 Sprint 6
      'cultura': f.properties.cultura,
      'safra': f.properties.safra,
      'soil_sampling_scheme': f.properties.soilSamplingScheme,
      'rec_by_nutrient': f.properties.recByNutrient != null
          ? jsonEncode(f.properties.recByNutrient)
          : null,
    };
  }

  DrawingFeature _fromRow(Map<String, dynamic> row) {
    // Reconstruct Geometry
    final geoJson = jsonDecode(row['geojson'] as String);
    final geometry = DrawingGeometry.fromJson(geoJson);

    // Reconstruct Properties
    final properties = DrawingProperties(
      nome: row['nome'],
      tipo: DrawingType.fromJson(row['tipo']),
      origem: DrawingOrigin.fromJson(row['origem']),
      status: DrawingStatus.fromJson(row['status']),
      autorId: row['autor_id'],
      autorTipo: AuthorType.fromJson(row['autor_tipo']),
      areaHa: row['area_ha'],
      versao: row['versao'],
      ativo: row['ativo'] == 1,
      createdAt: DateTime.parse(row['created_at']),
      updatedAt: DateTime.parse(row['updated_at']),
      syncStatus: SyncStatus.fromJson(row['sync_status']),
      subtipo: row['subtipo'],
      raioMetros: row['raio_metros'],
      versaoAnteriorId: row['versao_anterior_id'],
      clienteId: row['cliente_id'] as String?,
      fazendaId: row['fazenda_id'] as String?,
      // 🌱 Sprint 6
      cultura: row['cultura'] as String?,
      safra: row['safra'] as String?,
      soilSamplingScheme: row['soil_sampling_scheme'] as String?,
      recByNutrient: row['rec_by_nutrient'] != null
          ? Map<String, double>.from(
              (jsonDecode(row['rec_by_nutrient'] as String) as Map).map(
                (k, v) => MapEntry(k.toString(), (v as num).toDouble()),
              ),
            )
          : null,
    );

    return DrawingFeature(
      id: row['id'],
      geometry: geometry,
      properties: properties,
    );
  }
}
