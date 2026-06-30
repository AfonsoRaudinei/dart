import 'dart:convert';

import 'package:sqflite/sqflite.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/database/database_helper.dart';
import '../data/relatorio_table.dart';
import '../models/relatorio_status.dart';
import '../models/relatorio_tecnico.dart';
import '../models/visit_session_snapshot.dart';
import 'i_relatorio_repository.dart';

/// Implementação SQLite de [IRelatorioRepository] — ADR-009
///
/// Usa o singleton [DatabaseHelper.instance] como fonte de dados (padrão
/// do projeto). Segue as convenções offline-first:
///
///   - Criação sempre com [RelatorioSyncStatus.local_only].
///   - Listas de objetos persistidas como JSON TEXT via [dart:convert].
///   - Soft delete: preenche [deleted_at] e muda sync_status —
///     DELETE físico é proibido (ADR-009).
///   - Filtros de leitura excluem registros com [deleted_at IS NOT NULL].
class RelatorioRepositoryImpl implements IRelatorioRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // ── ESCRITA ───────────────────────────────────────────────────────────

  @override
  Future<void> save(RelatorioTecnico relatorio) async {
    final db = await _dbHelper.database;
    await db.insert(
      RelatorioTable.tableName,
      _toMap(relatorio),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> update(RelatorioTecnico relatorio) async {
    final db = await _dbHelper.database;
    final updated = relatorio.copyWith(updatedAt: DateTime.now().toUtc());
    await db.update(
      RelatorioTable.tableName,
      _toMap(updated),
      where: '${RelatorioTable.colId} = ?',
      whereArgs: [relatorio.id],
    );
  }

  // ── LEITURA ───────────────────────────────────────────────────────────

  @override
  Future<RelatorioTecnico?> getById(String id) async {
    final db = await _dbHelper.database;
    final agronomistId = Supabase.instance.client.auth.currentUser?.id ?? '';
    final rows = await db.query(
      RelatorioTable.tableName,
      where:
          '${RelatorioTable.colId} = ?'
          ' AND ${RelatorioTable.colAgronomistId} = ?',
      whereArgs: [id, agronomistId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return _fromMap(rows.first);
  }

  @override
  Future<List<RelatorioTecnico>> getAll() async {
    final db = await _dbHelper.database;
    final agronomistId = Supabase.instance.client.auth.currentUser?.id ?? '';
    final rows = await db.query(
      RelatorioTable.tableName,
      where:
          '${RelatorioTable.colAgronomistId} = ?'
          ' AND ${RelatorioTable.colDeletedAt} IS NULL',
      whereArgs: [agronomistId],
      orderBy: '${RelatorioTable.colCreatedAt} DESC',
    );
    return rows.map(_fromMap).toList();
  }

  @override
  Future<List<RelatorioTecnico>> getByClientId(String clientId) async {
    final db = await _dbHelper.database;
    final agronomistId = Supabase.instance.client.auth.currentUser?.id ?? '';
    final rows = await db.query(
      RelatorioTable.tableName,
      where:
          '${RelatorioTable.colClientId} = ?'
          ' AND ${RelatorioTable.colAgronomistId} = ?'
          ' AND ${RelatorioTable.colDeletedAt} IS NULL',
      whereArgs: [clientId, agronomistId],
      orderBy: '${RelatorioTable.colCreatedAt} DESC',
    );
    return rows.map(_fromMap).toList();
  }

  @override
  Future<List<RelatorioTecnico>> getByAgronomistId(String agronomistId) async {
    final db = await _dbHelper.database;
    final rows = await db.query(
      RelatorioTable.tableName,
      where:
          '${RelatorioTable.colAgronomistId} = ?'
          ' AND ${RelatorioTable.colDeletedAt} IS NULL',
      whereArgs: [agronomistId],
      orderBy: '${RelatorioTable.colCreatedAt} DESC',
    );
    return rows.map(_fromMap).toList();
  }

  @override
  Future<List<RelatorioTecnico>> getByStatus(RelatorioStatus status) async {
    final db = await _dbHelper.database;
    final agronomistId = Supabase.instance.client.auth.currentUser?.id ?? '';
    final rows = await db.query(
      RelatorioTable.tableName,
      where:
          '${RelatorioTable.colStatus} = ?'
          ' AND ${RelatorioTable.colAgronomistId} = ?'
          ' AND ${RelatorioTable.colDeletedAt} IS NULL',
      whereArgs: [status.toJson(), agronomistId],
      orderBy: '${RelatorioTable.colCreatedAt} DESC',
    );
    return rows.map(_fromMap).toList();
  }

  /// Retorna todos os registros que ainda não foram enviados ao servidor:
  /// [local_only], [pending_sync] e [deleted_local].
  @override
  Future<List<RelatorioTecnico>> getPendingSync() async {
    final db = await _dbHelper.database;
    final agronomistId = Supabase.instance.client.auth.currentUser?.id ?? '';
    final statuses = [
      RelatorioSyncStatus.local_only.name,
      RelatorioSyncStatus.pending_sync.name,
      RelatorioSyncStatus.deleted_local.name,
    ];
    final placeholders = statuses.map((_) => '?').join(', ');
    final rows = await db.query(
      RelatorioTable.tableName,
      where:
          '${RelatorioTable.colSyncStatus} IN ($placeholders)'
          ' AND ${RelatorioTable.colAgronomistId} = ?',
      whereArgs: [...statuses, agronomistId],
    );
    return rows.map(_fromMap).toList();
  }

  // ── SOFT DELETE ───────────────────────────────────────────────────────

  @override
  Future<void> softDelete(String id) async {
    final db = await _dbHelper.database;
    final now = DateTime.now().toUtc().toIso8601String();
    await db.update(
      RelatorioTable.tableName,
      {
        RelatorioTable.colDeletedAt: now,
        RelatorioTable.colSyncStatus: RelatorioSyncStatus.deleted_local.name,
        RelatorioTable.colUpdatedAt: now,
      },
      where: '${RelatorioTable.colId} = ?',
      whereArgs: [id],
    );
  }

  // ── SINCRONIZAÇÃO ─────────────────────────────────────────────────────

  @override
  Future<void> markAsSynced(String id) async {
    final db = await _dbHelper.database;
    await db.update(
      RelatorioTable.tableName,
      {
        RelatorioTable.colSyncStatus: RelatorioSyncStatus.synced.name,
        RelatorioTable.colUpdatedAt: DateTime.now().toUtc().toIso8601String(),
      },
      where: '${RelatorioTable.colId} = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<void> markAsPendingSync(String id) async {
    final db = await _dbHelper.database;
    await db.update(
      RelatorioTable.tableName,
      {
        RelatorioTable.colSyncStatus: RelatorioSyncStatus.pending_sync.name,
        RelatorioTable.colUpdatedAt: DateTime.now().toUtc().toIso8601String(),
      },
      where: '${RelatorioTable.colId} = ?',
      whereArgs: [id],
    );
  }

  // ── SERIALIZAÇÃO PRIVADA ──────────────────────────────────────────────

  /// Converte [RelatorioTecnico] em [Map] para inserção/atualização SQLite.
  ///
  /// Campos de lista são serializados como JSON TEXT.
  Map<String, dynamic> _toMap(RelatorioTecnico r) => {
    RelatorioTable.colId: r.id,
    RelatorioTable.colVisitSessionId: r.visitSessionId,
    RelatorioTable.colClientId: r.clientId,
    RelatorioTable.colAgronomistId: r.agronomistId,
    RelatorioTable.colFarmName: r.farmName,
    RelatorioTable.colPeriodStart: r.periodStart.toIso8601String(),
    RelatorioTable.colPeriodEnd: r.periodEnd.toIso8601String(),
    RelatorioTable.colStatus: r.status.toJson(),
    RelatorioTable.colSyncStatus: r.syncStatus.toJson(),
    RelatorioTable.colCreatedAt: r.createdAt.toIso8601String(),
    RelatorioTable.colUpdatedAt: r.updatedAt.toIso8601String(),
    RelatorioTable.colDeletedAt: r.deletedAt?.toIso8601String(),
    RelatorioTable.colTitle: r.title,
    RelatorioTable.colCustomNotes: r.customNotes,
    RelatorioTable.colPublicacoesRefs: jsonEncode(r.publicacoesRefs),
    RelatorioTable.colOcorrencias: jsonEncode(
      r.ocorrencias.map((e) => e.toJson()).toList(),
    ),
    RelatorioTable.colTalhoes: jsonEncode(
      r.talhoes.map((e) => e.toJson()).toList(),
    ),
    RelatorioTable.colFotos: jsonEncode(r.fotos),
    RelatorioTable.colMonitoramentos: jsonEncode(
      r.monitoramentos.map((e) => e.toJson()).toList(),
    ),
    'user_id': Supabase.instance.client.auth.currentUser?.id ?? '',
  };

  /// Reconstrói um [RelatorioTecnico] a partir de uma linha SQLite.
  RelatorioTecnico _fromMap(Map<String, dynamic> m) => RelatorioTecnico(
    id: m[RelatorioTable.colId] as String,
    visitSessionId: m[RelatorioTable.colVisitSessionId] as String,
    clientId: m[RelatorioTable.colClientId] as String,
    agronomistId: m[RelatorioTable.colAgronomistId] as String,
    farmName: m[RelatorioTable.colFarmName] as String,
    periodStart: DateTime.parse(m[RelatorioTable.colPeriodStart] as String),
    periodEnd: DateTime.parse(m[RelatorioTable.colPeriodEnd] as String),
    status: RelatorioStatus.fromJson(m[RelatorioTable.colStatus] as String),
    syncStatus: RelatorioSyncStatus.fromJson(
      m[RelatorioTable.colSyncStatus] as String,
    ),
    createdAt: DateTime.parse(m[RelatorioTable.colCreatedAt] as String),
    updatedAt: DateTime.parse(m[RelatorioTable.colUpdatedAt] as String),
    deletedAt: m[RelatorioTable.colDeletedAt] != null
        ? DateTime.parse(m[RelatorioTable.colDeletedAt] as String)
        : null,
    title: m[RelatorioTable.colTitle] as String?,
    customNotes: m[RelatorioTable.colCustomNotes] as String?,
    publicacoesRefs: _decodeList<String>(
      m[RelatorioTable.colPublicacoesRefs],
      (e) => e as String,
    ),
    ocorrencias: _decodeList<OcorrenciaSnapshot>(
      m[RelatorioTable.colOcorrencias],
      (e) => OcorrenciaSnapshot.fromJson(e as Map<String, dynamic>),
    ),
    talhoes: _decodeList<TalhaoVisitado>(
      m[RelatorioTable.colTalhoes],
      (e) => TalhaoVisitado.fromJson(e as Map<String, dynamic>),
    ),
    fotos: _decodeList<String>(m[RelatorioTable.colFotos], (e) => e as String),
    monitoramentos: _decodeList<MonitoramentoSnapshot>(
      m[RelatorioTable.colMonitoramentos],
      (e) => MonitoramentoSnapshot.fromJson(e as Map<String, dynamic>),
    ),
  );

  /// Decodifica um campo TEXT JSON em lista tipada.
  ///
  /// Retorna `[]` se o campo for [null] ou não for uma lista JSON válida.
  List<T> _decodeList<T>(Object? raw, T Function(dynamic) mapper) {
    if (raw == null) return const [];
    final decoded = jsonDecode(raw as String);
    if (decoded is! List) return const [];
    return decoded.map(mapper).toList();
  }
}
