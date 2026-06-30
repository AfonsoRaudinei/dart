import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/app_config.dart';
import '../database/database_helper.dart';
import '../sync/sync_constants.dart';
import '../utils/app_logger.dart';
import '../../modules/consultoria/services/agronomic_sync_service.dart';

/// Orquestra sync bidirecional silencioso com Supabase.
/// Ordem: agronômico → visitas → ocorrências → relatórios → agenda.
class RemoteSyncService {
  static const _lastPullKey = 'sync_last_pull_at';

  final SupabaseClient _supabase;
  final SharedPreferences _prefs;

  RemoteSyncService(this._supabase, this._prefs);

  String? get _userId => _supabase.auth.currentUser?.id;

  Future<void> syncAll() async {
    if (!AppConfig.hasSupabaseConfig) return;
    if (_userId == null) return;

    final agronomic = AgronomicSyncService(_supabase, _prefs, _userId!);
    await agronomic.syncNow();

    await _pushTable('visit_sessions');
    await _pullTable('visit_sessions');

    await _pushTable('occurrences', transform: _transformOccurrence);
    await _pullTable('occurrences', transform: _transformOccurrenceLocal);

    await _pushTable('visit_reports');
    await _pullTable('visit_reports');

    await _pushTable('agenda_events');
    await _pullTable('agenda_events');

    await _prefs.setString(_lastPullKey, DateTime.now().toIso8601String());
    appLog('🔄 Remote sync completo');
  }

  Future<int> countPending() async {
    final db = await DatabaseHelper.instance.database;
    var total = 0;
    for (final table in [
      'clients',
      'farms',
      'fields',
      'visit_sessions',
      'occurrences',
      'visit_reports',
      'agenda_events',
    ]) {
      final result = await db.rawQuery(
        'SELECT COUNT(*) as c FROM $table WHERE sync_status = ?',
        [SyncConstants.statusDirty],
      );
      total += (result.first['c'] as int?) ?? 0;
    }
    return total;
  }

  Future<void> _pushTable(
    String table, {
    Map<String, dynamic> Function(Map<String, dynamic> row)? transform,
  }) async {
    final db = await DatabaseHelper.instance.database;
    final dirtyRows = await db.query(
      table,
      where: 'sync_status = ?',
      whereArgs: [SyncConstants.statusDirty],
    );

    for (final row in dirtyRows) {
      final data = Map<String, dynamic>.from(row);
      data.remove('sync_status');
      data['user_id'] = _userId;
      transform?.call(data);

      try {
        await _supabase.from(table).upsert(data);
        await db.update(
          table,
          {'sync_status': SyncConstants.statusSynced},
          where: 'id = ?',
          whereArgs: [row['id']],
        );
      } catch (e) {
        appLog('⚠️ Sync push $table ${row['id']}: $e');
      }
    }
  }

  Future<void> _pullTable(
    String table, {
    Map<String, dynamic> Function(Map<String, dynamic> remote)? transform,
  }) async {
    final db = await DatabaseHelper.instance.database;
    final lastPull = _prefs.getString(_lastPullKey);
    var query = _supabase.from(table).select();

    if (lastPull != null) {
      query = query.gt('updated_at', lastPull);
    }

    final remoteRows = await query.order('updated_at');
    for (final remote in remoteRows) {
      final remoteMap = Map<String, dynamic>.from(remote as Map);
      transform?.call(remoteMap);

      final local = await db.query(
        table,
        where: 'id = ?',
        whereArgs: [remoteMap['id']],
      );

      var shouldUpdate = true;
      if (local.isNotEmpty) {
        final localUpdated = DateTime.parse(local.first['updated_at'] as String);
        final remoteUpdated = DateTime.parse(remoteMap['updated_at'] as String);
        if (remoteUpdated.isBefore(localUpdated) &&
            local.first['sync_status'] == SyncConstants.statusDirty) {
          shouldUpdate = false;
        }
      }

      if (!shouldUpdate) continue;

      final data = Map<String, dynamic>.from(remoteMap);
      data.remove('user_id');
      data['sync_status'] = SyncConstants.statusSynced;

      if (local.isNotEmpty) {
        await db.update(
          table,
          data,
          where: 'id = ?',
          whereArgs: [data['id']],
        );
      } else {
        await db.insert(table, data);
      }
    }
  }

  void _transformOccurrence(Map<String, dynamic> data) {
    // JSON fields already plain; ensure updated_at exists
    data['updated_at'] ??= data['created_at'];
  }

  void _transformOccurrenceLocal(Map<String, dynamic> data) {
    data['updated_at'] ??= data['created_at'];
    data['status'] ??= 'draft';
  }
}
