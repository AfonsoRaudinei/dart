import 'package:sqflite/sqflite.dart';
import '../../../../core/database/database_helper.dart';
import '../../domain/models/visit_session.dart';
import '../../domain/models/visit_stats.dart';

class VisitRepository {
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;

  Future<VisitSession?> getActiveSession() async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'visit_sessions',
      where: 'status = ?',
      whereArgs: ['active'],
      limit: 1,
    );

    if (maps.isNotEmpty) {
      return VisitSession.fromMap(maps.first);
    }
    return null;
  }

  Future<void> saveSession(VisitSession session) async {
    final db = await _databaseHelper.database;
    await db.insert(
      'visit_sessions',
      session.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> endSession(String sessionId, DateTime endTime) async {
    final db = await _databaseHelper.database;
    await db.update(
      'visit_sessions',
      {
        'status': 'finished',
        'end_time': endTime.toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
        'sync_status': 1,
      },
      where: 'id = ?',
      whereArgs: [sessionId],
    );
  }

  // --- QUERY ESTATÍSTICAS DASHBOARD ---
  Future<DashboardStats> getDashboardStats() async {
    final db = await _databaseHelper.database;
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day).toIso8601String();
    final todayEnd = DateTime(
      now.year,
      now.month,
      now.day,
      23,
      59,
      59,
    ).toIso8601String();

    // 1. Finished visits today
    // Calc duration in seconds: strftime('%s', end) - strftime('%s', start)
    final finishedResult = await db.rawQuery(
      '''
      SELECT 
        COUNT(*) as count,
        SUM(strftime('%s', end_time) - strftime('%s', start_time)) as total_seconds
      FROM visit_sessions
      WHERE status = 'finished' 
        AND start_time BETWEEN ? AND ?
    ''',
      [todayStart, todayEnd],
    );

    final finishedCount = Sqflite.firstIntValue(finishedResult) ?? 0;
    final finishedSeconds =
        (finishedResult.first['total_seconds'] as int?) ?? 0;

    // 2. Active visit
    final activeSession = await getActiveSession();
    int activeDuration = 0;
    if (activeSession != null) {
      activeDuration = now.difference(activeSession.startTime).inMinutes;
    }

    return DashboardStats(
      totalVisitsToday: finishedCount + (activeSession != null ? 1 : 0),
      totalMinutesToday: (finishedSeconds / 60).round() + activeDuration,
      activeVisits: activeSession != null ? 1 : 0,
      activeProducerId: activeSession?.producerId,
      activeDurationMinutes: activeDuration,
    );
  }

  // --- QUERY ESTATÍSTICAS KPI ---
  Future<VisitStats> getVisitStats(DateTime start, DateTime end) async {
    final db = await _databaseHelper.database;
    // Ensure inclusive filtering
    final startStr = start.toIso8601String();
    final endStr = end
        .add(const Duration(days: 1))
        .subtract(const Duration(seconds: 1))
        .toIso8601String();

    final result = await db.rawQuery(
      '''
      SELECT 
        COUNT(*) as count,
        SUM(strftime('%s', end_time) - strftime('%s', start_time)) as total_seconds
      FROM visit_sessions
      WHERE status = 'finished' 
        AND start_time BETWEEN ? AND ?
    ''',
      [startStr, endStr],
    );

    final count = Sqflite.firstIntValue(result) ?? 0;
    final totalSeconds = (result.first['total_seconds'] as int?) ?? 0;

    // Group By Producer
    final producerResult = await db.rawQuery(
      '''
      SELECT producer_id, COUNT(*) as count
      FROM visit_sessions
      WHERE status = 'finished' AND start_time BETWEEN ? AND ?
      GROUP BY producer_id
    ''',
      [startStr, endStr],
    );

    final byProducer = {
      for (var r in producerResult)
        r['producer_id'] as String: r['count'] as int,
    };

    // Group By Activity
    final activityResult = await db.rawQuery(
      '''
      SELECT activity_type, COUNT(*) as count
      FROM visit_sessions
      WHERE status = 'finished' AND start_time BETWEEN ? AND ?
      GROUP BY activity_type
    ''',
      [startStr, endStr],
    );

    final byActivity = {
      for (var r in activityResult)
        r['activity_type'] as String: r['count'] as int,
    };

    return VisitStats(
      totalVisits: count,
      totalDurationMinutes: (totalSeconds / 60).round(),
      averageDurationMinutes: count > 0 ? (totalSeconds / 60) / count : 0,
      visitsByProducer: byProducer,
      visitsByActivity: byActivity,
    );
  }

  // --- QUERY HISTÓRICO ---
  Future<List<VisitSession>> getHistory({
    required DateTime start,
    required DateTime end,
    String? producerId,
    String? activityType,
  }) async {
    final db = await _databaseHelper.database;

    // Ensure inclusive filtering
    final startStr = start.toIso8601String();
    final endStr = end
        .add(const Duration(days: 1))
        .subtract(const Duration(seconds: 1))
        .toIso8601String();

    String whereClause = 'status = ? AND start_time BETWEEN ? AND ?';
    List<dynamic> args = ['finished', startStr, endStr];

    if (producerId != null) {
      whereClause += ' AND producer_id = ?';
      args.add(producerId);
    }
    if (activityType != null) {
      whereClause += ' AND activity_type = ?';
      args.add(activityType);
    }

    final maps = await db.query(
      'visit_sessions',
      where: whereClause,
      whereArgs: args,
      orderBy: 'start_time DESC',
    );

    return List.generate(maps.length, (i) => VisitSession.fromMap(maps[i]));
  }
}
