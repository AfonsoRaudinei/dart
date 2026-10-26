import 'dart:convert';

import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/database/database_helper.dart';
import '../../../../core/services/sync_status_contract.dart';
import '../../../../core/session/local_session_identity.dart';
import '../models/relatorio_combinado.dart';

/// Persistência local de combinações. Sem hard delete.
abstract class RelatorioCombinadoRepository {
  Future<List<RelatorioCombinado>> listByClient(String clientId);

  Future<RelatorioCombinado> insert({
    required String clientId,
    required List<String> chapterKeys,
  });

  /// Tira uma chave. `null` quando a combinação foi soft-deleted (zero capítulos).
  Future<RelatorioCombinado?> removeChapter(String id, String chapterKey);

  Future<void> softDelete(String id);
}

class RelatorioCombinadoRepositoryImpl implements RelatorioCombinadoRepository {
  RelatorioCombinadoRepositoryImpl({
    Future<Database> Function()? openDatabase,
    String Function()? resolveUserId,
    DateTime Function()? clock,
    String Function()? newId,
  }) : _openDatabase = openDatabase ?? (() => DatabaseHelper.instance.database),
       _resolveUserId = resolveUserId ?? LocalSessionIdentity.resolveUserId,
       _clock = clock ?? DateTime.now,
       _newId = newId ?? (() => const Uuid().v4());

  final Future<Database> Function() _openDatabase;
  final String Function() _resolveUserId;
  final DateTime Function() _clock;
  final String Function() _newId;

  String get _userId => _resolveUserId().trim();

  @override
  Future<List<RelatorioCombinado>> listByClient(String clientId) async {
    final db = await _openDatabase();
    final rows = await db.query(
      relatoriosCombinadosTable,
      where: 'user_id = ? AND client_id = ? AND deleted_at IS NULL',
      whereArgs: [_userId, clientId],
      orderBy: 'updated_at DESC',
    );
    return rows.map(RelatorioCombinado.fromRow).toList();
  }

  @override
  Future<RelatorioCombinado> insert({
    required String clientId,
    required List<String> chapterKeys,
  }) async {
    final now = _clock().toUtc();
    final saved = RelatorioCombinado(
      id: _newId(),
      userId: _userId,
      clientId: clientId,
      title: relatorioCombinadoTitle(now, chapterKeys.length),
      chapterKeys: List<String>.unmodifiable(chapterKeys),
      createdAt: now,
      updatedAt: now,
      syncStatus: SyncStatusContract.pendingSync,
    );
    final db = await _openDatabase();
    await db.insert(
      relatoriosCombinadosTable,
      saved.toRow(),
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
    return saved;
  }

  @override
  Future<RelatorioCombinado?> removeChapter(
    String id,
    String chapterKey,
  ) async {
    final current = await _findActive(id);
    if (current == null || !current.chapterKeys.contains(chapterKey)) {
      return current;
    }
    final nextKeys = current.chapterKeys
        .where((key) => key != chapterKey)
        .toList();
    if (nextKeys.isEmpty) {
      await softDelete(id);
      return null;
    }
    final now = _clock().toUtc();
    final db = await _openDatabase();
    await db.update(
      relatoriosCombinadosTable,
      {
        'chapters_json': jsonEncode(nextKeys),
        'updated_at': now.toIso8601String(),
        'sync_status': SyncStatusContract.pendingSync,
      },
      where: 'id = ? AND user_id = ?',
      whereArgs: [id, _userId],
    );
    return current.copyWith(
      chapterKeys: nextKeys,
      updatedAt: now,
      syncStatus: SyncStatusContract.pendingSync,
    );
  }

  @override
  Future<void> softDelete(String id) async {
    final now = _clock().toUtc().toIso8601String();
    final db = await _openDatabase();
    await db.update(
      relatoriosCombinadosTable,
      {
        'deleted_at': now,
        'updated_at': now,
        'sync_status': SyncStatusContract.pendingSync,
      },
      where: 'id = ? AND user_id = ?',
      whereArgs: [id, _userId],
    );
  }

  Future<RelatorioCombinado?> _findActive(String id) async {
    final db = await _openDatabase();
    final rows = await db.query(
      relatoriosCombinadosTable,
      where: 'id = ? AND user_id = ? AND deleted_at IS NULL',
      whereArgs: [id, _userId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return RelatorioCombinado.fromRow(rows.first);
  }
}
