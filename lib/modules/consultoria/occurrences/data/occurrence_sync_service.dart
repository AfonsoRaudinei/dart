import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:soloforte_app/core/database/database_helper.dart';
import '../domain/occurrence.dart';
import 'dart:convert';

class OccurrenceSyncService {
  final SupabaseClient _supabase;

  OccurrenceSyncService(this._supabase);

  Future<void> syncOccurrences() async {
    try {
      await _syncOccurrencesPush();
      await _syncOccurrencesPull();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> _syncOccurrencesPush() async {
    final db = await DatabaseHelper.instance.database;
    final pendingOccurrences = await db.query(
      'occurrences',
      where: "sync_status = ?",
      whereArgs: ['local'],
    );

    for (final row in pendingOccurrences) {
      try {
        final occurrence = Occurrence.fromMap(row);
        final payload = _toSupabasePayload(occurrence);

        final userId = _supabase.auth.currentUser?.id;
        if (userId == null) continue;

        await _supabase.from('occurrences').upsert({
          'id': occurrence.id,
          'user_id': userId,
          'visit_session_id': occurrence.visitSessionId,
          'geometry': payload['geometry'],
          'sync_status': 'synced',
          'updated_at': occurrence.updatedAt.toIso8601String(),
        });

        await db.update(
          'occurrences',
          {'sync_status': 'synced'},
          where: 'id = ?',
          whereArgs: [occurrence.id],
        );
      } catch (e) {
        continue;
      }
    }
  }

  Future<void> _syncOccurrencesPull() async {
    final db = await DatabaseHelper.instance.database;
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    try {
      final remoteOccurrences = await _supabase
          .from('occurrences')
          .select()
          .eq('user_id', userId)
          .order('updated_at');

      for (final remote in remoteOccurrences) {
        final localResults = await db.query(
          'occurrences',
          where: 'id = ?',
          whereArgs: [remote['id']],
        );

        if (localResults.isEmpty) {
          final localData = _fromSupabasePayload(remote);
          await db.insert('occurrences', localData);
        } else {
          final local = localResults.first;
          final localSyncStatus = local['sync_status'] as String?;

          if (localSyncStatus == 'local') {
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
              'occurrences',
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

  Map<String, dynamic> _toSupabasePayload(Occurrence occurrence) {
    String geometryJson;

    if (occurrence.geometry != null) {
      geometryJson = occurrence.geometry!;
    } else if (occurrence.lat != null && occurrence.long != null) {
      final geometry = {
        'type': 'Point',
        'coordinates': [occurrence.long, occurrence.lat],
      };
      geometryJson = jsonEncode(geometry);
    } else {
      final geometry = {
        'type': 'Point',
        'coordinates': [0.0, 0.0],
      };
      geometryJson = jsonEncode(geometry);
    }

    return {'geometry': geometryJson};
  }

  Map<String, dynamic> _fromSupabasePayload(Map<String, dynamic> remote) {
    String? geometryJson;
    double? lat;
    double? long;

    if (remote['geometry'] != null) {
      if (remote['geometry'] is String) {
        geometryJson = remote['geometry'] as String;
        try {
          final decoded = jsonDecode(geometryJson);
          if (decoded['type'] == 'Point' && decoded['coordinates'] != null) {
            final coords = decoded['coordinates'] as List?;
            if (coords != null && coords.length >= 2) {
              long = (coords[0] as num).toDouble();
              lat = (coords[1] as num).toDouble();
            }
          }
        } catch (_) {}
      } else {
        final geometry = remote['geometry'] as Map<String, dynamic>;
        geometryJson = jsonEncode(geometry);

        if (geometry['type'] == 'Point' && geometry['coordinates'] != null) {
          final coords = geometry['coordinates'] as List?;
          if (coords != null && coords.length >= 2) {
            long = (coords[0] as num).toDouble();
            lat = (coords[1] as num).toDouble();
          }
        }
      }
    }

    return {
      'id': remote['id'],
      'visit_session_id': remote['visit_session_id'],
      'type': 'Info',
      'description': '',
      'photo_path': null,
      'lat': lat,
      'long': long,
      'geometry': geometryJson,
      'created_at': remote['created_at'] ?? DateTime.now().toIso8601String(),
      'updated_at': remote['updated_at'] ?? DateTime.now().toIso8601String(),
      'sync_status': 'synced',
      'category': null,
      'status': 'confirmed',
    };
  }
}
