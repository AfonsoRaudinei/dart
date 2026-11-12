import 'package:sqflite/sqflite.dart';
import 'package:soloforte_app/core/database/database_helper.dart';
import 'package:soloforte_app/core/services/sync_status_contract.dart';

class ProducerVisitConfirmationRow {
  const ProducerVisitConfirmationRow({
    required this.id,
    required this.sessionId,
    required this.clientId,
    required this.consultorUserId,
    required this.confirmedAt,
    required this.visitedAt,
    required this.syncStatus,
    required this.userId,
    this.farmName,
    this.fieldName,
  });

  final String id;
  final String sessionId;
  final String clientId;
  final String consultorUserId;
  final DateTime confirmedAt;
  final DateTime visitedAt;
  final String? farmName;
  final String? fieldName;
  final String syncStatus;
  final String userId;

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'visit_session_id': sessionId,
      'client_id': clientId,
      'consultor_user_id': consultorUserId,
      'confirmed_at': confirmedAt.toUtc().toIso8601String(),
      'visited_at': visitedAt.toUtc().toIso8601String(),
      'farm_name': farmName,
      'field_name': fieldName,
      'sync_status': syncStatus,
      'user_id': userId,
    };
  }

  factory ProducerVisitConfirmationRow.fromMap(Map<String, Object?> map) {
    return ProducerVisitConfirmationRow(
      id: map['id'] as String,
      sessionId: map['visit_session_id'] as String,
      clientId: map['client_id'] as String,
      consultorUserId: map['consultor_user_id'] as String,
      confirmedAt: DateTime.parse(map['confirmed_at'] as String),
      visitedAt: DateTime.parse(map['visited_at'] as String),
      farmName: map['farm_name'] as String?,
      fieldName: map['field_name'] as String?,
      syncStatus: map['sync_status'] as String? ?? SyncStatusContract.pendingSync,
      userId: map['user_id'] as String? ?? '',
    );
  }
}

class ProducerVisitConfirmationStore {
  ProducerVisitConfirmationStore({DatabaseHelper? databaseHelper})
    : _databaseHelper = databaseHelper ?? DatabaseHelper.instance;

  final DatabaseHelper _databaseHelper;

  Future<void> save(ProducerVisitConfirmationRow row) async {
    final db = await _databaseHelper.database;
    await db.insert(
      'visit_producer_confirmations',
      row.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<ProducerVisitConfirmationRow?> findBySession(String sessionId) async {
    final db = await _databaseHelper.database;
    final rows = await db.query(
      'visit_producer_confirmations',
      where: 'visit_session_id = ?',
      whereArgs: [sessionId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return ProducerVisitConfirmationRow.fromMap(rows.first);
  }

  Future<List<ProducerVisitConfirmationRow>> listByClients(
    Set<String> clientIds,
  ) async {
    if (clientIds.isEmpty) return const [];
    final db = await _databaseHelper.database;
    final placeholders = List.filled(clientIds.length, '?').join(',');
    final rows = await db.query(
      'visit_producer_confirmations',
      where:
          'client_id IN ($placeholders) AND sync_status != ?',
      whereArgs: [...clientIds, SyncStatusContract.deletedLocal],
      orderBy: 'visited_at DESC',
    );
    return rows.map(ProducerVisitConfirmationRow.fromMap).toList();
  }

  Future<List<ProducerVisitConfirmationRow>> pending() async {
    final db = await _databaseHelper.database;
    final rows = await db.query(
      'visit_producer_confirmations',
      where: 'sync_status = ?',
      whereArgs: [SyncStatusContract.pendingSync],
    );
    return rows.map(ProducerVisitConfirmationRow.fromMap).toList();
  }

  Future<void> markSynced(String id) async {
    final db = await _databaseHelper.database;
    await db.update(
      'visit_producer_confirmations',
      {'sync_status': SyncStatusContract.synced},
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
