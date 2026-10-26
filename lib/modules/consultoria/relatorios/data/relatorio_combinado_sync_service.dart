import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:soloforte_app/core/database/database_helper.dart';
import 'package:soloforte_app/core/network/network_policy.dart';
import 'package:soloforte_app/core/services/sync_status_contract.dart';
import 'package:soloforte_app/core/session/local_session_identity.dart';
import 'package:soloforte_app/core/utils/app_logger.dart';
import 'package:soloforte_app/modules/consultoria/relatorios/models/relatorio_combinado.dart';

/// Push + pull de `relatorios_combinados` (ADR-052).
///
/// Sem JWT: no-op. Com JWT: push (upsert, inclusive tombstone) depois pull LWW.
class RelatorioCombinadoSyncService {
  RelatorioCombinadoSyncService({
    SupabaseClient? supabase,
    String? Function()? currentUserId,
    DatabaseHelper? dbHelper,
  }) : _supabase = supabase,
       _currentUserId = currentUserId,
       _dbHelper = dbHelper ?? DatabaseHelper.instance;

  final SupabaseClient? _supabase;
  final String? Function()? _currentUserId;
  final DatabaseHelper _dbHelper;

  static const tag = 'RelatorioCombinadoSync';
  static const table = relatoriosCombinadosTable;

  static const allowedColumns = <String>{
    'id',
    'user_id',
    'client_id',
    'title',
    'chapters_json',
    'created_at',
    'updated_at',
    'sync_status',
    'deleted_at',
  };

  Future<void> syncNow() async {
    final userId = _resolveUserId();
    if (userId.isEmpty) {
      AppLogger.warning(
        'Sync de relatórios combinados ignorado: sessão JWT ausente',
        tag: tag,
      );
      return;
    }
    final client = _supabase;
    if (client == null) {
      AppLogger.warning(
        'Sync de relatórios combinados ignorado: cliente remoto ausente',
        tag: tag,
      );
      return;
    }

    try {
      await _push(client, userId);
    } catch (error, stackTrace) {
      AppLogger.error(
        'RelatorioCombinadoSync push stage aborted',
        tag: tag,
        error: error,
        stackTrace: stackTrace,
      );
    }

    try {
      await _pull(client, userId);
    } catch (error, stackTrace) {
      AppLogger.error(
        'RelatorioCombinadoSync pull stage aborted',
        tag: tag,
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  String _resolveUserId() {
    final resolveUserId = _currentUserId;
    if (resolveUserId != null) {
      return (resolveUserId() ?? '').trim();
    }
    return LocalSessionIdentity.resolveUserId(allowLastKnown: false).trim();
  }

  Future<void> _push(SupabaseClient client, String userId) async {
    final db = await _dbHelper.database;
    final pending = await db.query(
      table,
      where: 'user_id = ? AND sync_status IN (?, ?)',
      whereArgs: [
        userId,
        SyncStatusContract.pendingSync,
        SyncStatusContract.localOnly,
      ],
    );
    for (final row in pending) {
      try {
        final payload = rowToRemote(row, userId: userId);
        await NetworkPolicy.withTimeout(
          () => client.from(table).upsert(payload, onConflict: 'id'),
        );
        await db.update(
          table,
          {'sync_status': SyncStatusContract.synced},
          where: 'id = ? AND user_id = ?',
          whereArgs: [row['id'], userId],
        );
      } catch (error, stackTrace) {
        AppLogger.warning(
          'Falha ao enviar combinado ${row['id']}; pendência local preservada',
          tag: tag,
          error: error,
        );
        AppLogger.debug('$stackTrace', tag: tag);
      }
    }
  }

  Future<void> _pull(SupabaseClient client, String userId) async {
    final db = await _dbHelper.database;
    final remoteRows = await NetworkPolicy.withTimeout(
      () => client.from(table).select().eq('user_id', userId),
    );
    for (final raw in remoteRows) {
      Map<String, dynamic>? row;
      try {
        row = Map<String, dynamic>.from(raw as Map);
        final pulled = remoteToLocal(row);
        final id = pulled['id'];
        if (id == null) continue;
        final localRows = await db.query(
          table,
          where: 'id = ? AND user_id = ?',
          whereArgs: [id, userId],
          limit: 1,
        );
        final local = localRows.isEmpty ? null : localRows.first;
        final merged = mergePulled(local: local, pulled: pulled);
        if (merged == null) continue;
        if (local != null) {
          await db.update(
            table,
            merged,
            where: 'id = ? AND user_id = ?',
            whereArgs: [id, userId],
          );
        } else {
          await db.insert(
            table,
            merged,
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      } catch (error, stackTrace) {
        AppLogger.error(
          'RelatorioCombinadoSync pull persist failed [id=${row?['id'] ?? '?'}]',
          tag: tag,
          error: error,
          stackTrace: stackTrace,
        );
      }
    }
  }

  /// Copia só colunas do contrato. `user_id` é o do JWT. `chapters_json` sai como JSON.
  @visibleForTesting
  static Map<String, dynamic> rowToRemote(
    Map<String, Object?> local, {
    required String userId,
  }) {
    final payload = <String, dynamic>{};
    for (final key in allowedColumns) {
      if (key == 'user_id') {
        payload[key] = userId;
        continue;
      }
      if (!local.containsKey(key) && key != 'sync_status') continue;
      if (key == 'sync_status') {
        payload[key] = SyncStatusContract.synced;
        continue;
      }
      if (key == 'chapters_json') {
        payload[key] = chaptersForRemote(local[key]);
        continue;
      }
      payload[key] = asIsoOrSelf(local[key]);
    }
    return payload;
  }

  @visibleForTesting
  static Object? chaptersForRemote(Object? value) {
    if (value is String) {
      if (value.trim().isEmpty) return <String>[];
      return jsonDecode(value);
    }
    return value;
  }

  @visibleForTesting
  static Map<String, Object?> remoteToLocal(Map<String, dynamic> remote) {
    final local = <String, Object?>{};
    for (final key in allowedColumns) {
      if (!remote.containsKey(key) && key != 'sync_status') continue;
      if (key == 'sync_status') {
        local[key] = SyncStatusContract.synced;
        continue;
      }
      if (key == 'chapters_json') {
        local[key] = chaptersForLocal(remote[key]);
        continue;
      }
      local[key] = asIsoOrSelf(remote[key]);
    }
    local['sync_status'] = SyncStatusContract.synced;
    return local;
  }

  @visibleForTesting
  static String chaptersForLocal(Object? value) {
    if (value is String) return value;
    return jsonEncode(value ?? const <String>[]);
  }

  /// LWW por `updated_at`. Pendência local não é sobrescrita.
  @visibleForTesting
  static bool shouldApplyRemote(
    Map<String, Object?> local,
    Map<String, Object?> pulled,
  ) {
    final localStatus = SyncStatusContract.normalize(
      local['sync_status'] as String?,
    );
    if (localStatus == SyncStatusContract.pendingSync ||
        localStatus == SyncStatusContract.localOnly) {
      return false;
    }
    final localUpdated =
        parseDate(local['updated_at']) ?? parseDate(local['created_at']);
    final remoteUpdated =
        parseDate(pulled['updated_at']) ?? parseDate(pulled['created_at']);
    if (localUpdated == null || remoteUpdated == null) return true;
    return !remoteUpdated.isBefore(localUpdated);
  }

  /// `null` = manter local. Nunca apaga a linha no pull.
  /// Remoto com `deleted_at` grava o tombstone — a listagem não o reexibe.
  @visibleForTesting
  static Map<String, Object?>? mergePulled({
    Map<String, Object?>? local,
    required Map<String, Object?> pulled,
  }) {
    if (local == null) return pulled;
    if (!shouldApplyRemote(local, pulled)) return null;
    final merged = Map<String, Object?>.from(pulled);
    merged['sync_status'] = SyncStatusContract.synced;
    if (pulled['deleted_at'] != null) {
      merged['deleted_at'] = asIsoOrSelf(pulled['deleted_at']);
    }
    return merged;
  }

  @visibleForTesting
  static bool shouldHardDeleteOnPull(Map<String, Object?> remote) => false;

  @visibleForTesting
  static Object? asIsoOrSelf(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value.toUtc().toIso8601String();
    return value;
  }

  @visibleForTesting
  static DateTime? parseDate(Object? value) {
    if (value == null) return null;
    if (value is DateTime) return value.toUtc();
    if (value is String && value.isNotEmpty) {
      return DateTime.tryParse(value)?.toUtc();
    }
    return null;
  }
}
