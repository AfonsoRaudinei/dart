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

  Future<List<Occurrence>> getOccurrencesBySession(String sessionId) async {
    final db = await _databaseHelper.database;
    final userId = Supabase.instance.client.auth.currentUser?.id ?? '';
    final List<Map<String, dynamic>> maps = await db.query(
      'occurrences',
      where: 'visit_session_id = ? AND user_id = ?',
      whereArgs: [sessionId, userId],
    );
    return List.generate(maps.length, (i) => Occurrence.fromMap(maps[i]));
  }

  Future<List<Occurrence>> getAllOccurrences() async {
    final db = await _databaseHelper.database;
    final userId = Supabase.instance.client.auth.currentUser?.id ?? '';
    final List<Map<String, dynamic>> maps = await db.query(
      'occurrences',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'created_at DESC',
      limit: 50, // Safety limit
    );
    return List.generate(maps.length, (i) => Occurrence.fromMap(maps[i]));
  }

  Future<Map<String, int>> getStats({DateTime? start, DateTime? end}) async {
    final db = await _databaseHelper.database;
    final userId = Supabase.instance.client.auth.currentUser?.id ?? '';
    String where = 'WHERE user_id = ?';
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
