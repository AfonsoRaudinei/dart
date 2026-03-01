import 'dart:async';
import 'package:sqflite/sqflite.dart';
import '../../../../core/database/database_helper.dart';
import '../domain/entities/relatorio.dart';
import '../domain/repositories/i_report_repository.dart';

class ReportRepositoryImpl implements IReportRepository {
  final _controller = StreamController<List<Relatorio>>.broadcast();
  static const String _tableName = 'relatorios_v2';

  Future<Database> get _db async => await DatabaseHelper.instance.database;

  Future<void> _ensureTable() async {
    final db = await _db;
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $_tableName (
        id TEXT PRIMARY KEY,
        titulo TEXT NOT NULL,
        descricao TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        created_by TEXT NOT NULL,
        sync_status TEXT NOT NULL,
        deleted_at TEXT,
        visit_session_id TEXT,
        occurrence_ids TEXT
      )
    ''');
  }

  @override
  Future<List<Relatorio>> getAll() async {
    await _ensureTable();
    final db = await _db;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'deleted_at IS NULL',
    );
    return maps.map((map) => Relatorio.fromMap(map)).toList();
  }

  @override
  Future<Relatorio?> getById(String id) async {
    await _ensureTable();
    final db = await _db;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'id = ? AND deleted_at IS NULL',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return Relatorio.fromMap(maps.first);
  }

  @override
  Future<void> save(Relatorio relatorio) async {
    await _ensureTable();
    final db = await _db;
    await db.insert(
      _tableName,
      relatorio.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    await _notifyWatchers();
  }

  @override
  Future<void> softDelete(String id) async {
    await _ensureTable();
    final db = await _db;
    final relatorio = await getById(id);
    if (relatorio == null) return;

    final deletedRelatorio = relatorio.copyWith(
      deletedAt: DateTime.now().toUtc(),
      syncStatus: SyncStatus.deleted_local,
    );

    await db.update(
      _tableName,
      deletedRelatorio.toMap(),
      where: 'id = ?',
      whereArgs: [id],
    );
    await _notifyWatchers();
  }

  @override
  Stream<List<Relatorio>> watchAll() {
    // Return stream and trigger an initial load
    _notifyWatchers();
    return _controller.stream;
  }

  Future<void> _notifyWatchers() async {
    final list = await getAll();
    _controller.add(list);
  }
}
