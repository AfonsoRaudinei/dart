import '../domain/report_model.dart';
import '../domain/kpi_metrics.dart';
import '../../../../core/database/database_helper.dart';
import 'package:sqflite/sqflite.dart';
import 'dart:convert';

class SQLiteReportRepository {
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;

  Future<void> saveReport(Report report, String sessionId) async {
    final db = await _databaseHelper.database;
    await db.insert('visit_reports', {
      'id': report.id,
      'visit_session_id': sessionId,
      'content': jsonEncode({
        'title': report.title,
        'type': report.type.index,
        'clientId': report.clientId,
        'startDate': report.startDate.toIso8601String(),
        'endDate': report.endDate.toIso8601String(),
        'content': report.content,
        'author': report.author,
        'observations': report.observations,
      }), // Snapshot
      'created_at': DateTime.now().toIso8601String(),
      'sync_status': 1,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Report>> getReports({
    DateTime? start,
    DateTime? end,
    String? producerId,
  }) async {
    final db = await _databaseHelper.database;
    String sql = '''
      SELECT r.*, s.producer_id, s.start_time 
      FROM visit_reports r
      JOIN visit_sessions s ON r.visit_session_id = s.id
      WHERE 1=1
    ''';
    List<dynamic> args = [];

    if (producerId != null) {
      sql += ' AND s.producer_id = ?';
      args.add(producerId);
    }
    if (start != null && end != null) {
      // Ensure inclusive end date
      final endInclusive = end
          .add(const Duration(days: 1))
          .subtract(const Duration(seconds: 1));
      sql += ' AND s.start_time BETWEEN ? AND ?';
      args.add(start.toIso8601String());
      args.add(endInclusive.toIso8601String());
    }

    sql += ' ORDER BY s.start_time DESC';

    final result = await db.rawQuery(sql, args);

    return result.map((row) {
      final contentJson = jsonDecode(row['content'] as String);
      return Report(
        id: row['id'] as String,
        title: contentJson['title'],
        type: ReportType.values[contentJson['type']],
        clientId: contentJson['clientId'],
        startDate: DateTime.parse(contentJson['startDate']),
        endDate: DateTime.parse(contentJson['endDate']),
        content: contentJson['content'],
        createdAt: DateTime.parse(row['created_at'] as String),
        author: contentJson['author'],
        observations: contentJson['observations'],
        images: [],
      );
    }).toList();
  }

  Future<KpiMetrics> getKpiMetrics({DateTime? start, DateTime? end}) async {
    final db = await _databaseHelper.database;

    // Base SQL filter
    String whereClause = "WHERE s.status = 'finished'";
    List<dynamic> args = [];

    // Only check params if they exist (nullable)
    if (start != null && end != null) {
      final endInclusive = end
          .add(const Duration(days: 1))
          .subtract(const Duration(seconds: 1));
      whereClause += " AND s.start_time BETWEEN ? AND ?";
      args.add(start.toIso8601String());
      args.add(endInclusive.toIso8601String());
    }

    // Determine query with explicit joins
    final tableJoin = '''
      FROM visit_reports r
      JOIN visit_sessions s ON r.visit_session_id = s.id
    ''';

    // 1. General Metrics
    final generalStats = await db.rawQuery('''
      SELECT 
        COUNT(*) as total_visits,
        COUNT(DISTINCT substr(s.start_time, 1, 10)) as days_worked,
        SUM(strftime('%s', s.end_time) - strftime('%s', s.start_time)) as total_seconds,
        COUNT(DISTINCT s.producer_id) as unique_clients
      $tableJoin
      $whereClause
    ''', args);

    // 2. Long Visits (> 4h = 14400s)
    final longVisitsStats = await db.rawQuery('''
      SELECT COUNT(*) as count 
      $tableJoin
      $whereClause
      AND (strftime('%s', s.end_time) - strftime('%s', s.start_time)) > 14400
    ''', args);

    // 3. Most Visited Client
    // We iterate to find top client. rawQuery returns List<Map>
    final topClientStats = await db.rawQuery('''
      SELECT s.producer_id, COUNT(*) as c
      $tableJoin
      $whereClause
      GROUP BY s.producer_id
      ORDER BY c DESC
      LIMIT 1
    ''', args);

    // 4. Activity Type breakdown
    final activityStats = await db.rawQuery('''
      SELECT s.activity_type, COUNT(*) as c
      $tableJoin
      $whereClause
      GROUP BY s.activity_type
    ''', args);

    // --- Parse Results ---

    if (generalStats.isEmpty) return KpiMetrics.empty();

    final row = generalStats.first;
    final totalVisits = (row['total_visits'] as int?) ?? 0;

    if (totalVisits == 0) return KpiMetrics.empty();

    final totalDays = (row['days_worked'] as int?) ?? 0;
    final totalSeconds = (row['total_seconds'] as int?) ?? 0;
    final uniqueClients = (row['unique_clients'] as int?) ?? 0;

    final totalHours = totalSeconds / 3600.0;
    final avgDurationMin = (totalSeconds / 60.0) / totalVisits;
    final avgVisitsPerDay = totalDays > 0
        ? (totalVisits / totalDays).toDouble()
        : 0.0;
    final avgVisitsPerClient = uniqueClients > 0
        ? (totalVisits / uniqueClients).toDouble()
        : 0.0;

    final longVisits = Sqflite.firstIntValue(longVisitsStats) ?? 0;
    final pctLong = (longVisits / totalVisits) * 100;

    String? topClient;
    if (topClientStats.isNotEmpty) {
      topClient = topClientStats.first['producer_id'] as String;
    }

    final Map<String, int> activities = {};
    for (var r in activityStats) {
      activities[r['activity_type'] as String] = r['c'] as int;
    }

    return KpiMetrics(
      totalVisits: totalVisits,
      totalDaysWorked: totalDays,
      averageVisitsPerDay: avgVisitsPerDay,
      totalHoursInField: totalHours,
      averageVisitDurationMinutes: avgDurationMin,
      uniqueClientsVisited: uniqueClients,
      averageVisitsPerClient: avgVisitsPerClient,
      mostVisitedClientId: topClient,
      percentageLongVisits: pctLong,
      visitsByActivityType: activities,
    );
  }
}
