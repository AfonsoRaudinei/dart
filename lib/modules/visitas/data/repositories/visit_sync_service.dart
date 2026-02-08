import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:soloforte_app/core/database/database_helper.dart';
import '../../domain/models/visit_session.dart';

class VisitSyncService {
  final SupabaseClient _supabase;

  VisitSyncService(this._supabase);

  Future<void> syncVisits() async {
    try {
      await _syncVisitsPush();
      await _syncVisitsPull();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> _syncVisitsPush() async {
    final db = await DatabaseHelper.instance.database;
    final pendingVisits = await db.query(
      'visit_sessions',
      where: 'sync_status = ?',
      whereArgs: [1],
    );

    for (final row in pendingVisits) {
      try {
        final visit = VisitSession.fromMap(row);
        final userId = _supabase.auth.currentUser?.id;
        if (userId == null) continue;

        final localId = visit.id;

        await _supabase.from('visit_sessions').upsert({
          'id': visit.id,
          'user_id': userId,
          'started_at': visit.startTime.toIso8601String(),
          'ended_at': visit.endTime?.toIso8601String(),
          'sync_status': 'synced',
          'updated_at': visit.updatedAt.toIso8601String(),
        });

        await db.update(
          'visit_sessions',
          {'sync_status': 0},
          where: 'id = ?',
          whereArgs: [localId],
        );
      } catch (e) {
        continue;
      }
    }
  }

  Future<void> _syncVisitsPull() async {
    final db = await DatabaseHelper.instance.database;
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    try {
      final remoteVisits = await _supabase
          .from('visit_sessions')
          .select()
          .eq('user_id', userId)
          .order('updated_at');

      for (final remote in remoteVisits) {
        final localResults = await db.query(
          'visit_sessions',
          where: 'id = ?',
          whereArgs: [remote['id']],
        );

        if (localResults.isEmpty) {
          final localData = _fromSupabasePayload(remote);
          await db.insert('visit_sessions', localData);
        } else {
          final local = localResults.first;
          final localSyncStatus = local['sync_status'] as int?;

          if (localSyncStatus == 1) {
            continue;
          }

          final localUpdatedAt = local['updated_at'] != null
              ? DateTime.parse(local['updated_at'] as String)
              : DateTime.now();
          final remoteUpdatedAt = remote['updated_at'] != null
              ? DateTime.parse(remote['updated_at'] as String)
              : DateTime.now();

          if (remoteUpdatedAt.isAfter(localUpdatedAt)) {
            final localData = _fromSupabasePayload(remote);
            await db.update(
              'visit_sessions',
              localData,
              where: 'id = ?',
              whereArgs: [remote['id']],
            );
          }
        }
      }
    } catch (e) {
      rethrow;
    }
  }

  Map<String, dynamic> _fromSupabasePayload(Map<String, dynamic> remote) {
    final startedAt = remote['started_at'] != null
        ? DateTime.parse(remote['started_at'] as String)
        : DateTime.now();
    final endedAt = remote['ended_at'] != null
        ? DateTime.parse(remote['ended_at'] as String)
        : null;

    return {
      'id': remote['id'],
      'producer_id': 'unknown',
      'area_id': 'unknown',
      'activity_type': 'Consultoria',
      'start_time': startedAt.toIso8601String(),
      'end_time': endedAt?.toIso8601String(),
      'initial_lat': 0.0,
      'initial_long': 0.0,
      'status': endedAt != null ? 'finished' : 'active',
      'created_at': startedAt.toIso8601String(),
      'updated_at': remote['updated_at'] ?? DateTime.now().toIso8601String(),
      'sync_status': 0,
    };
  }
}
