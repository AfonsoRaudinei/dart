import 'package:sqflite/sqflite.dart';
import '../../../../../core/database/database_helper.dart';
import '../../domain/models/agenda_event.dart';

class AgendaRepository {
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;

  Future<void> saveEvent(AgendaEvent event) async {
    final db = await _databaseHelper.database;
    await db.insert(
      'agenda_events',
      event.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<AgendaEvent?> getEvent(String id) async {
    final db = await _databaseHelper.database;
    final maps = await db.query(
      'agenda_events',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return AgendaEvent.fromMap(maps.first);
    }
    return null;
  }

  Future<AgendaEvent?> getEventBySessionId(String sessionId) async {
    final db = await _databaseHelper.database;
    final maps = await db.query(
      'agenda_events',
      where: 'visit_session_id = ?',
      whereArgs: [sessionId],
    );
    if (maps.isNotEmpty) {
      return AgendaEvent.fromMap(maps.first);
    }
    return null;
  }

  /// Finds planned events for a specific producer and area, usually strictly today or in general.
  /// For "Automatic Linking", we usually look for events scheduled for TODAY.
  Future<List<AgendaEvent>> getPlannedEvents({
    required String producerId,
    required String areaId,
    DateTime? date,
  }) async {
    final db = await _databaseHelper.database;
    String where = 'producer_id = ? AND area_id = ? AND status = ?';
    List<dynamic> args = [producerId, areaId, AgendaStatus.planned.name];

    if (date != null) {
      // Assuming date string yyyy-MM-dd match or range.
      // For simplicity, we match the exact string prefix of scheduled_date if it stores ISO full string.
      // But typically scheduled_date might be just YYYY-MM-DD. Let's assume ISO string in DB.
      // So we check effectively "Starts on this day".
      final start = DateTime(date.year, date.month, date.day).toIso8601String();
      final end = DateTime(
        date.year,
        date.month,
        date.day,
        23,
        59,
        59,
      ).toIso8601String();
      where += ' AND scheduled_date BETWEEN ? AND ?';
      args.addAll([start, end]);
    }

    final maps = await db.query(
      'agenda_events',
      where: where,
      whereArgs: args,
      orderBy: 'scheduled_date ASC',
    );
    return List.generate(maps.length, (i) => AgendaEvent.fromMap(maps[i]));
  }

  Future<List<AgendaEvent>> getEvents({
    required DateTime start,
    required DateTime end,
  }) async {
    final db = await _databaseHelper.database;
    final maps = await db.query(
      'agenda_events',
      where: 'scheduled_date BETWEEN ? AND ?',
      whereArgs: [start.toIso8601String(), end.toIso8601String()],
      orderBy: 'scheduled_date ASC',
    );
    return List.generate(maps.length, (i) => AgendaEvent.fromMap(maps[i]));
  }
}
