import 'package:sqflite/sqflite.dart';
import '../../../../core/database/database_helper.dart';
import '../domain/occurrence.dart';

class OccurrenceRepository {
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;

  Future<void> saveOccurrence(Occurrence occurrence) async {
    final db = await _databaseHelper.database;
    await db.insert(
      'occurrences',
      occurrence.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Occurrence?> getOccurrenceById(String id) async {
    final db = await _databaseHelper.database;
    final maps = await db.query(
      'occurrences',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return Occurrence.fromMap(maps.first);
  }

  Future<void> updateOccurrence(Occurrence occurrence) async {
    final db = await _databaseHelper.database;
    final updated = occurrence.copyWith(
      updatedAt: DateTime.now(),
      syncStatus: occurrence.syncStatus == 'synced' ? 'updated' : occurrence.syncStatus,
    );
    await db.update(
      'occurrences',
      updated.toMap(),
      where: 'id = ?',
      whereArgs: [occurrence.id],
    );
  }

  Future<List<Occurrence>> getOccurrencesBySession(String sessionId) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'occurrences',
      where: 'visit_session_id = ?',
      whereArgs: [sessionId],
    );
    return List.generate(maps.length, (i) => Occurrence.fromMap(maps[i]));
  }

  Future<List<Occurrence>> getAllOccurrences() async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'occurrences',
      orderBy: 'created_at DESC',
      limit: 50,
    );
    return List.generate(maps.length, (i) => Occurrence.fromMap(maps[i]));
  }

  Future<Map<String, int>> getStats({DateTime? start, DateTime? end}) async {
    final db = await _databaseHelper.database;
    String where = '';
    List<dynamic> args = [];

    if (start != null && end != null) {
      final endInclusive = end
          .add(const Duration(days: 1))
          .subtract(const Duration(seconds: 1));
      where = 'WHERE created_at BETWEEN ? AND ?';
      args = [start.toIso8601String(), endInclusive.toIso8601String()];
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

    final linkedWhere = where.isEmpty
        ? 'WHERE visit_session_id IS NOT NULL'
        : '$where AND visit_session_id IS NOT NULL';
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
