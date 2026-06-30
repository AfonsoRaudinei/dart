import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:soloforte_app/core/database/database_helper.dart';
import 'package:soloforte_app/core/utils/app_logger.dart';

class AgronomicSyncService {
  final SupabaseClient _supabase;
  final SharedPreferences _prefs;
  final String _userId;

  static const int statusSynced = 0;
  static const int statusDirty = 1;
  static const _lastPullKey = 'sync_agronomic_last_pull_at';

  AgronomicSyncService(this._supabase, this._prefs, this._userId);

  Future<void> syncNow() async {
    await _pushClients();
    await _pushFarms();
    await _pushFields();
    await _pullDeltas();
    await _prefs.setString(_lastPullKey, DateTime.now().toIso8601String());
  }

  Future<void> _pushClients() async {
    final db = await DatabaseHelper.instance.database;
    final dirtyClients = await db.query(
      'clients',
      where: 'sync_status = ?',
      whereArgs: [statusDirty],
    );

    for (final row in dirtyClients) {
      final data = Map<String, dynamic>.from(row);
      data.remove('sync_status');
      data['user_id'] = _userId;

      try {
        await _supabase.from('clients').upsert(data);
        await db.update(
          'clients',
          {'sync_status': statusSynced},
          where: 'id = ?',
          whereArgs: [row['id']],
        );
      } catch (e) {
        appLog('Error syncing client ${row['id']}: $e');
      }
    }
  }

  Future<void> _pushFarms() async {
    final db = await DatabaseHelper.instance.database;
    final dirtyFarms = await db.query(
      'farms',
      where: 'sync_status = ?',
      whereArgs: [statusDirty],
    );

    for (final row in dirtyFarms) {
      final data = Map<String, dynamic>.from(row);
      data.remove('sync_status');
      data['user_id'] = _userId;

      try {
        await _supabase.from('farms').upsert(data);
        await db.update(
          'farms',
          {'sync_status': statusSynced},
          where: 'id = ?',
          whereArgs: [row['id']],
        );
      } catch (e) {
        appLog('Error syncing farm ${row['id']}: $e');
      }
    }
  }

  Future<void> _pushFields() async {
    final db = await DatabaseHelper.instance.database;
    final dirtyFields = await db.query(
      'fields',
      where: 'sync_status = ?',
      whereArgs: [statusDirty],
    );

    for (final row in dirtyFields) {
      final data = Map<String, dynamic>.from(row);
      data.remove('sync_status');
      data['user_id'] = _userId;

      if (data['bordadura_geo'] is String) {
        // Supabase expects JSON — keep as string; PostgREST parses JSON strings
      }

      try {
        await _supabase.from('fields').upsert(data);
        await db.update(
          'fields',
          {'sync_status': statusSynced},
          where: 'id = ?',
          whereArgs: [row['id']],
        );
      } catch (e) {
        appLog('Error syncing field ${row['id']}: $e');
      }
    }
  }

  Future<void> _pullDeltas() async {
    final lastPull = _prefs.getString(_lastPullKey);

    var clientsQuery = _supabase.from('clients').select();
    var farmsQuery = _supabase.from('farms').select();
    var fieldsQuery = _supabase.from('fields').select();

    if (lastPull != null) {
      clientsQuery = clientsQuery.gt('updated_at', lastPull);
      farmsQuery = farmsQuery.gt('updated_at', lastPull);
      fieldsQuery = fieldsQuery.gt('updated_at', lastPull);
    }

    await _upsertLocalClients(await clientsQuery.order('updated_at'));
    await _upsertLocalFarms(await farmsQuery.order('updated_at'));
    await _upsertLocalFields(await fieldsQuery.order('updated_at'));
  }

  Future<void> _upsertLocalClients(List<dynamic> remoteList) async {
    final db = await DatabaseHelper.instance.database;
    for (final remote in remoteList) {
      final local = await db.query(
        'clients',
        where: 'id = ?',
        whereArgs: [remote['id']],
      );

      var shouldUpdate = true;
      if (local.isNotEmpty) {
        final localUpdatedAt = DateTime.parse(
          local.first['updated_at'] as String,
        );
        final remoteUpdatedAt = DateTime.parse(remote['updated_at'] as String);
        if (remoteUpdatedAt.isBefore(localUpdatedAt) &&
            (local.first['sync_status'] == statusDirty)) {
          shouldUpdate = false;
        }
      }

      if (shouldUpdate) {
        final data = Map<String, dynamic>.from(remote as Map);
        data.remove('user_id');
        data['sync_status'] = statusSynced;

        final exists = await db.query(
          'clients',
          where: 'id = ?',
          whereArgs: [data['id']],
        );
        if (exists.isNotEmpty) {
          await db.update(
            'clients',
            data,
            where: 'id = ?',
            whereArgs: [data['id']],
          );
        } else {
          await db.insert('clients', data);
        }
      }
    }
  }

  Future<void> _upsertLocalFarms(List<dynamic> remoteList) async {
    final db = await DatabaseHelper.instance.database;
    for (final remote in remoteList) {
      final local = await db.query(
        'farms',
        where: 'id = ?',
        whereArgs: [remote['id']],
      );

      var shouldUpdate = true;
      if (local.isNotEmpty) {
        final localUpdatedAt = DateTime.parse(
          local.first['updated_at'] as String,
        );
        final remoteUpdatedAt = DateTime.parse(remote['updated_at'] as String);
        if (remoteUpdatedAt.isBefore(localUpdatedAt) &&
            (local.first['sync_status'] == statusDirty)) {
          shouldUpdate = false;
        }
      }

      if (shouldUpdate) {
        final data = Map<String, dynamic>.from(remote as Map);
        data.remove('user_id');
        data['sync_status'] = statusSynced;

        final exists = await db.query(
          'farms',
          where: 'id = ?',
          whereArgs: [data['id']],
        );
        if (exists.isNotEmpty) {
          await db.update(
            'farms',
            data,
            where: 'id = ?',
            whereArgs: [data['id']],
          );
        } else {
          await db.insert('farms', data);
        }
      }
    }
  }

  Future<void> _upsertLocalFields(List<dynamic> remoteList) async {
    final db = await DatabaseHelper.instance.database;
    for (final remote in remoteList) {
      final local = await db.query(
        'fields',
        where: 'id = ?',
        whereArgs: [remote['id']],
      );

      var shouldUpdate = true;
      if (local.isNotEmpty) {
        final localUpdatedAt = DateTime.parse(
          local.first['updated_at'] as String,
        );
        final remoteUpdatedAt = DateTime.parse(remote['updated_at'] as String);
        if (remoteUpdatedAt.isBefore(localUpdatedAt) &&
            (local.first['sync_status'] == statusDirty)) {
          shouldUpdate = false;
        }
      }

      if (shouldUpdate) {
        final data = Map<String, dynamic>.from(remote as Map);
        data.remove('user_id');
        data['sync_status'] = statusSynced;
        if (data['bordadura_geo'] != null && data['bordadura_geo'] is! String) {
          data['bordadura_geo'] = data['bordadura_geo'].toString();
        }
        if (data['centro_geo'] != null && data['centro_geo'] is! String) {
          data['centro_geo'] = data['centro_geo'].toString();
        }

        final exists = await db.query(
          'fields',
          where: 'id = ?',
          whereArgs: [data['id']],
        );
        if (exists.isNotEmpty) {
          await db.update(
            'fields',
            data,
            where: 'id = ?',
            whereArgs: [data['id']],
          );
        } else {
          await db.insert('fields', data);
        }
      }
    }
  }
}
