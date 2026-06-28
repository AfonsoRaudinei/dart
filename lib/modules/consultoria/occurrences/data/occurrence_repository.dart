import 'package:sqflite/sqflite.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/database/database_helper.dart';
import '../domain/occurrence.dart';

class OccurrenceRepository {
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;

  Future<void> saveOccurrence(Occurrence occurrence) async {
    final db = await _databaseHelper.database;
    final userId = Supabase.instance.client.auth.currentUser?.id ?? '';
    final map = occurrence.toMap();
    map['user_id'] = userId;
    await db.insert(
      'occurrences',
      map,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateOccurrence(Occurrence occurrence) async {
    if (occurrence.cachedByUserId != null) {
      throw StateError('Ocorrencia compartilhada e somente leitura.');
    }
    final db = await _databaseHelper.database;
    final userId = Supabase.instance.client.auth.currentUser?.id ?? '';
    final map = occurrence
        .copyWith(updatedAt: DateTime.now(), syncStatus: 'updated')
        .toMap();
    map['user_id'] = userId;
    await db.insert(
      'occurrences',
      map,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> softDeleteOccurrence(String id) async {
    final db = await _databaseHelper.database;
    final userId = Supabase.instance.client.auth.currentUser?.id ?? '';
    final deletedAt = DateTime.now().toUtc().toIso8601String();
    await db.update(
      'occurrences',
      {
        'sync_status': 'deleted_local',
        'deleted_at': deletedAt,
        'updated_at': deletedAt,
      },
      where: 'id = ? AND user_id = ?',
      whereArgs: [id, userId],
    );
  }

  Future<List<Occurrence>> getOccurrencesBySession(String sessionId) async {
    final db = await _databaseHelper.database;
    final userId = Supabase.instance.client.auth.currentUser?.id ?? '';
    final List<Map<String, dynamic>> maps = await db.query(
      'occurrences',
      where:
          "visit_session_id = ? AND user_id = ? "
          "AND sync_status NOT IN ('deleted', 'deleted_local') "
          'AND deleted_at IS NULL',
      whereArgs: [sessionId, userId],
    );
    return List.generate(maps.length, (i) => Occurrence.fromMap(maps[i]));
  }

  Future<List<Occurrence>> getAllOccurrences() {
    return getAllAuthorizedOccurrences();
  }

  Future<List<Occurrence>> getAllAuthorizedOccurrences({
    Set<String> authorizedClientIds = const {},
  }) async {
    final db = await _databaseHelper.database;
    final userId = Supabase.instance.client.auth.currentUser?.id ?? '';
    final placeholders = List.filled(authorizedClientIds.length, '?').join(',');
    final sharedClause = authorizedClientIds.isEmpty
        ? ''
        : ' OR (cached_by_user_id = ? AND client_id IN ($placeholders))';
    final args = <Object?>[
      userId,
      if (authorizedClientIds.isNotEmpty) userId,
      ...authorizedClientIds,
    ];
    final List<Map<String, dynamic>> maps = await db.query(
      'occurrences',
      where:
          '(user_id = ?$sharedClause) '
          "AND sync_status NOT IN ('deleted', 'deleted_local') "
          'AND deleted_at IS NULL',
      whereArgs: args,
      orderBy: 'created_at DESC',
    );
    return List.generate(maps.length, (i) => Occurrence.fromMap(maps[i]));
  }

  Future<Map<String, int>> getStats({DateTime? start, DateTime? end}) async {
    final db = await _databaseHelper.database;
    final userId = Supabase.instance.client.auth.currentUser?.id ?? '';
    String where =
        "WHERE user_id = ? AND sync_status NOT IN ('deleted', 'deleted_local') "
        'AND deleted_at IS NULL';
    List<dynamic> args = [userId];

    if (start != null && end != null) {
      final endInclusive = end
          .add(const Duration(days: 1))
          .subtract(const Duration(seconds: 1));
      where += ' AND created_at BETWEEN ? AND ?';
      args = [userId, start.toIso8601String(), endInclusive.toIso8601String()];
    }

    final totalResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM occurrences $where',
      args,
    );
    final total = Sqflite.firstIntValue(totalResult) ?? 0;

    final typeResult = await db.rawQuery(
      'SELECT type, COUNT(*) as count FROM occurrences $where GROUP BY type',
      args,
    );

    final linkedWhere = '$where AND visit_session_id IS NOT NULL';
    final linkedResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM occurrences $linkedWhere',
      args,
    );
    final linked = Sqflite.firstIntValue(linkedResult) ?? 0;

    final Map<String, int> stats = {
      'total': total,
      'linked': linked,
      'avulso': total - linked,
    };
    for (var row in typeResult) {
      stats[row['type'] as String] = row['count'] as int;
    }
    return stats;
  }
}
