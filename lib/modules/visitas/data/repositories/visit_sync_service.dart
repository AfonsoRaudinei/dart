import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:soloforte_app/core/session/local_session_identity.dart';
import 'package:soloforte_app/core/database/database_helper.dart';
import 'package:soloforte_app/core/utils/app_logger.dart';
import '../../../../core/network/network_policy.dart';
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
    final userId = LocalSessionIdentity.resolveUserId();
    if (userId.isEmpty) {
      AppLogger.warning(
        'Skipping visit push: userId is null',
        tag: 'VisitSync',
      );
      return;
    }
    final pendingVisits = await db.query(
      'visit_sessions',
      where: 'sync_status = ? AND user_id = ?',
      whereArgs: [1, userId],
    );

    for (final row in pendingVisits) {
      try {
        final visit = VisitSession.fromMap(row);
        final localId = visit.id;
        await _upsertRemoteVisit(visit, userId);

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

  Future<void> _upsertRemoteVisit(VisitSession visit, String userId) async {
    final payload = toSupabasePayload(visit, userId);

    try {
      await NetworkPolicy.withTimeout(
        () => _supabase.from('visit_sessions').upsert(payload),
      );
    } catch (e) {
      // Compatibilidade transitória: versões antigas do backend ainda não
      // possuem farm_id. Os demais campos continuam sincronizados.
      if (!e.toString().contains('farm_id')) rethrow;
      payload.remove('farm_id');
      await NetworkPolicy.withTimeout(
        () => _supabase.from('visit_sessions').upsert(payload),
      );
    }
  }

  Future<void> _syncVisitsPull() async {
    final db = await DatabaseHelper.instance.database;
    final userId = LocalSessionIdentity.resolveUserId();
    if (userId.isEmpty) {
      AppLogger.warning(
        'Skipping visit pull: userId is null',
        tag: 'VisitSync',
      );
      return;
    }

    try {
      final remoteVisits = await NetworkPolicy.withTimeout(
        () => _supabase
            .from('visit_sessions')
            .select()
            .eq('user_id', userId)
            .order('updated_at'),
      );

      for (final remote in remoteVisits) {
        final localResults = await db.query(
          'visit_sessions',
          where: 'id = ?',
          whereArgs: [remote['id']],
        );

        if (localResults.isEmpty) {
          final localData = fromSupabasePayload(remote);
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
            final localData = fromSupabasePayload(remote);
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

  @visibleForTesting
  static Map<String, dynamic> toSupabasePayload(
    VisitSession visit,
    String userId,
  ) {
    return {
      'id': visit.id,
      'user_id': userId,
      'producer_id': visit.producerId,
      'farm_id': visit.farmId,
      'area_id': visit.areaId,
      'activity_type': visit.activityType,
      'started_at': visit.startTime.toIso8601String(),
      'ended_at': visit.endTime?.toIso8601String(),
      'sync_status': 'synced',
      'updated_at': visit.updatedAt.toIso8601String(),
    };
  }

  @visibleForTesting
  static Map<String, dynamic> fromSupabasePayload(Map<String, dynamic> remote) {
    final startedAt = remote['started_at'] != null
        ? DateTime.parse(remote['started_at'] as String)
        : DateTime.now();
    final endedAt = remote['ended_at'] != null
        ? DateTime.parse(remote['ended_at'] as String)
        : null;

    return {
      'id': remote['id'],
      'user_id': remote['user_id'] ?? '',
      'producer_id': remote['producer_id'] ?? 'unknown',
      'farm_id': remote['farm_id'],
      'area_id': remote['area_id'],
      'activity_type': remote['activity_type'],
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
