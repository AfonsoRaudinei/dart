import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:soloforte_app/core/database/database_helper.dart';

class AgronomicSyncService {
  final SupabaseClient _supabase;

  AgronomicSyncService(this._supabase);

  // Status Constants
  static const int statusSynced = 0;
  static const int statusDirty = 1;

  Future<void> syncNow() async {
    // 1. Push Pending Changes (Local -> Remote)
    await _pushClients();
    await _pushFarms();
    await _pushFields();

    // 2. Pull Remote Changes (Remote -> Local)
    // TODO: Implement LastPull tracking in SharedPrefs. For now, pull all recent or just full pull if optimization needed.
    // Given scope, we rely on updated_at
    await _pullDeltas();
  }

  // --- PUSH LOGIC ---

  Future<void> _pushClients() async {
    final db = await DatabaseHelper.instance.database;
    final dirtyClients = await db.query(
      'clients',
      where: 'sync_status = ?',
      whereArgs: [statusDirty],
    );

    for (final row in dirtyClients) {
      final data = Map<String, dynamic>.from(row);
      // Remove local-only columns
      data.remove('sync_status');

      try {
        await _supabase.from('clients').upsert(data);

        // Mark as synced
        await db.update(
          'clients',
          {'sync_status': statusSynced},
          where: 'id = ?',
          whereArgs: [row['id']],
        );
      } catch (e) {
        // Keep dirty. Log error ideally.
        debugPrint('Error syncing client ${row['id']}: $e');
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

      try {
        await _supabase.from('farms').upsert(data);
        await db.update(
          'farms',
          {'sync_status': statusSynced},
          where: 'id = ?',
          whereArgs: [row['id']],
        );
      } catch (e) {
        debugPrint('Error syncing farm ${row['id']}: $e');
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

      try {
        await _supabase.from('fields').upsert(data);
        await db.update(
          'fields',
          {'sync_status': statusSynced},
          where: 'id = ?',
          whereArgs: [row['id']],
        );
      } catch (e) {
        debugPrint('Error syncing field ${row['id']}: $e');
      }
    }
  }

  // --- PULL LOGIC ---

  Future<void> _pullDeltas() async {
    // In a real app, retrieve 'lastPullAt' timestamp from storage.
    // For this implementation, we will pull all changes that might be relevant (or all).
    // Optimization: Filter by user/tenant if applicable.

    // FETCH CLIENTS
    final remoteClients = await _supabase
        .from('clients')
        .select()
        .order('updated_at');
    await _upsertLocalClients(remoteClients);

    // FETCH FARMS
    final remoteFarms = await _supabase
        .from('farms')
        .select()
        .order('updated_at');
    await _upsertLocalFarms(remoteFarms);

    // FETCH FIELDS
    final remoteFields = await _supabase
        .from('fields')
        .select()
        .order('updated_at');
    await _upsertLocalFields(remoteFields);
  }

  Future<void> _upsertLocalClients(List<dynamic> remoteList) async {
    final db = await DatabaseHelper.instance.database;
    for (final remote in remoteList) {
      // Conflict Resolution: Last Write Wins
      // Check local updated_at
      final local = await db.query(
        'clients',
        where: 'id = ?',
        whereArgs: [remote['id']],
      );

      bool shouldUpdate = true;
      if (local.isNotEmpty) {
        final localUpdatedAt = DateTime.parse(
          local.first['updated_at'] as String,
        );
        final remoteUpdatedAt = DateTime.parse(remote['updated_at'] as String);
        // If local is newer and dirty, keep local (it will be pushed next time if push failed,
        // OR if pushed success then local is synced).
        // If remote is newer, overwrite.

        if (remoteUpdatedAt.isBefore(localUpdatedAt) &&
            (local.first['sync_status'] == statusDirty)) {
          shouldUpdate = false;
        }
      }

      if (shouldUpdate) {
        final data = Map<String, dynamic>.from(remote as Map);
        data['sync_status'] =
            statusSynced; // Coming from remote, so it is synced

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

      bool shouldUpdate = true;
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

      bool shouldUpdate = true;
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
        data['sync_status'] = statusSynced;

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
