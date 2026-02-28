import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import '../../../../core/database/database_helper.dart';
import '../data/publicacao_table.dart';
import '../models/publicacao_tecnica.dart';
import '../models/publicacao_tema.dart';
import 'i_publicacao_repository.dart';

/// Implementação SQLite de [IPublicacaoRepository] — ADR-009
///
/// Usa o singleton [DatabaseHelper.instance] como fonte de dados (padrão
/// do projeto). Segue as convenções offline-first:
///
///   - Criação sempre com [PublicacaoSyncStatus.local_only].
///   - Listas de paths persistidas como JSON TEXT via [dart:convert].
///   - Soft delete: preenche [deleted_at] e muda sync_status —
///     DELETE físico é proibido (ADR-009).
///   - Filtros de leitura excluem registros com [deleted_at IS NOT NULL].
class PublicacaoRepositoryImpl implements IPublicacaoRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // ── ESCRITA ───────────────────────────────────────────────────────────

  @override
  Future<void> save(PublicacaoTecnica publicacao) async {
    final db = await _dbHelper.database;
    await db.insert(
      PublicacaoTable.tableName,
      _toMap(publicacao),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> update(PublicacaoTecnica publicacao) async {
    final db = await _dbHelper.database;
    final updated = publicacao.copyWith(updatedAt: DateTime.now().toUtc());
    await db.update(
      PublicacaoTable.tableName,
      _toMap(updated),
      where: '${PublicacaoTable.colId} = ?',
      whereArgs: [publicacao.id],
    );
  }

  // ── LEITURA ───────────────────────────────────────────────────────────

  @override
  Future<PublicacaoTecnica?> getById(String id) async {
    final db = await _dbHelper.database;
    final rows = await db.query(
      PublicacaoTable.tableName,
      where: '${PublicacaoTable.colId} = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return _fromMap(rows.first);
  }

  @override
  Future<List<PublicacaoTecnica>> getAll() async {
    final db = await _dbHelper.database;
    final rows = await db.query(
      PublicacaoTable.tableName,
      where: '${PublicacaoTable.colDeletedAt} IS NULL',
      orderBy: '${PublicacaoTable.colCreatedAt} DESC',
    );
    return rows.map(_fromMap).toList();
  }

  @override
  Future<List<PublicacaoTecnica>> getByAuthorId(String authorId) async {
    final db = await _dbHelper.database;
    final rows = await db.query(
      PublicacaoTable.tableName,
      where:
          '${PublicacaoTable.colAuthorId} = ?'
          ' AND ${PublicacaoTable.colDeletedAt} IS NULL',
      whereArgs: [authorId],
      orderBy: '${PublicacaoTable.colCreatedAt} DESC',
    );
    return rows.map(_fromMap).toList();
  }

  @override
  Future<List<PublicacaoTecnica>> getByTema(PublicacaoTema tema) async {
    final db = await _dbHelper.database;
    final rows = await db.query(
      PublicacaoTable.tableName,
      where:
          '${PublicacaoTable.colTema} = ?'
          ' AND ${PublicacaoTable.colDeletedAt} IS NULL',
      whereArgs: [tema.toJson()],
      orderBy: '${PublicacaoTable.colCreatedAt} DESC',
    );
    return rows.map(_fromMap).toList();
  }

  @override
  Future<List<PublicacaoTecnica>> getPublicas() async {
    final db = await _dbHelper.database;
    final rows = await db.query(
      PublicacaoTable.tableName,
      where:
          '${PublicacaoTable.colVisibility} = ?'
          ' AND ${PublicacaoTable.colDeletedAt} IS NULL',
      whereArgs: [PublicacaoVisibility.publica.toJson()],
      orderBy: '${PublicacaoTable.colCreatedAt} DESC',
    );
    return rows.map(_fromMap).toList();
  }

  /// Retorna todos os registros que ainda não foram enviados ao servidor:
  /// [local_only], [pending_sync] e [deleted_local].
  @override
  Future<List<PublicacaoTecnica>> getPendingSync() async {
    final db = await _dbHelper.database;
    final statuses = [
      PublicacaoSyncStatus.local_only.name,
      PublicacaoSyncStatus.pending_sync.name,
      PublicacaoSyncStatus.deleted_local.name,
    ];
    final placeholders = statuses.map((_) => '?').join(', ');
    final rows = await db.query(
      PublicacaoTable.tableName,
      where: '${PublicacaoTable.colSyncStatus} IN ($placeholders)',
      whereArgs: statuses,
    );
    return rows.map(_fromMap).toList();
  }

  // ── SOFT DELETE ───────────────────────────────────────────────────────

  @override
  Future<void> softDelete(String id) async {
    final db = await _dbHelper.database;
    final now = DateTime.now().toUtc().toIso8601String();
    await db.update(
      PublicacaoTable.tableName,
      {
        PublicacaoTable.colDeletedAt: now,
        PublicacaoTable.colSyncStatus: PublicacaoSyncStatus.deleted_local.name,
        PublicacaoTable.colUpdatedAt: now,
      },
      where: '${PublicacaoTable.colId} = ?',
      whereArgs: [id],
    );
  }

  // ── SINCRONIZAÇÃO ─────────────────────────────────────────────────────

  @override
  Future<void> markAsSynced(String id) async {
    final db = await _dbHelper.database;
    await db.update(
      PublicacaoTable.tableName,
      {
        PublicacaoTable.colSyncStatus: PublicacaoSyncStatus.synced.name,
        PublicacaoTable.colUpdatedAt: DateTime.now().toUtc().toIso8601String(),
      },
      where: '${PublicacaoTable.colId} = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<void> markAsPendingSync(String id) async {
    final db = await _dbHelper.database;
    await db.update(
      PublicacaoTable.tableName,
      {
        PublicacaoTable.colSyncStatus: PublicacaoSyncStatus.pending_sync.name,
        PublicacaoTable.colUpdatedAt: DateTime.now().toUtc().toIso8601String(),
      },
      where: '${PublicacaoTable.colId} = ?',
      whereArgs: [id],
    );
  }

  // ── SERIALIZAÇÃO PRIVADA ──────────────────────────────────────────────

  /// Converte [PublicacaoTecnica] em [Map] para inserção/atualização SQLite.
  ///
  /// [fotoPaths] é serializado como JSON TEXT.
  Map<String, dynamic> _toMap(PublicacaoTecnica p) => {
    PublicacaoTable.colId: p.id,
    PublicacaoTable.colAuthorId: p.authorId,
    PublicacaoTable.colTema: p.tema.toJson(),
    PublicacaoTable.colTitulo: p.titulo,
    PublicacaoTable.colConteudo: p.conteudo,
    PublicacaoTable.colVisibility: p.visibility.toJson(),
    PublicacaoTable.colSyncStatus: p.syncStatus.toJson(),
    PublicacaoTable.colCreatedAt: p.createdAt.toIso8601String(),
    PublicacaoTable.colUpdatedAt: p.updatedAt.toIso8601String(),
    PublicacaoTable.colDeletedAt: p.deletedAt?.toIso8601String(),
    PublicacaoTable.colFotoPaths: jsonEncode(p.fotoPaths),
    PublicacaoTable.colTalhaoRef: p.talhaoRef,
    PublicacaoTable.colFazendaRef: p.fazendaRef,
    PublicacaoTable.colSafra: p.safra,
  };

  /// Reconstrói uma [PublicacaoTecnica] a partir de uma linha SQLite.
  PublicacaoTecnica _fromMap(Map<String, dynamic> m) => PublicacaoTecnica(
    id: m[PublicacaoTable.colId] as String,
    authorId: m[PublicacaoTable.colAuthorId] as String,
    tema: PublicacaoTema.fromJson(m[PublicacaoTable.colTema] as String),
    titulo: m[PublicacaoTable.colTitulo] as String,
    conteudo: m[PublicacaoTable.colConteudo] as String,
    visibility: PublicacaoVisibility.fromJson(
      m[PublicacaoTable.colVisibility] as String,
    ),
    syncStatus: PublicacaoSyncStatus.fromJson(
      m[PublicacaoTable.colSyncStatus] as String,
    ),
    createdAt: DateTime.parse(m[PublicacaoTable.colCreatedAt] as String),
    updatedAt: DateTime.parse(m[PublicacaoTable.colUpdatedAt] as String),
    deletedAt: m[PublicacaoTable.colDeletedAt] != null
        ? DateTime.parse(m[PublicacaoTable.colDeletedAt] as String)
        : null,
    fotoPaths: _decodeStringList(m[PublicacaoTable.colFotoPaths]),
    talhaoRef: m[PublicacaoTable.colTalhaoRef] as String?,
    fazendaRef: m[PublicacaoTable.colFazendaRef] as String?,
    safra: m[PublicacaoTable.colSafra] as String?,
  );

  /// Decodifica um campo TEXT JSON em `List<String>`.
  ///
  /// Retorna `[]` se o campo for [null] ou não for uma lista JSON válida.
  List<String> _decodeStringList(Object? raw) {
    if (raw == null) return const [];
    final decoded = jsonDecode(raw as String);
    if (decoded is! List) return const [];
    return decoded.cast<String>();
  }
}
