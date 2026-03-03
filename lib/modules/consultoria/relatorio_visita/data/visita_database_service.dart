import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:convert';
import '../../../../core/utils/app_logger.dart';
import 'visita_model.dart';

class VisitaDatabaseService {
  static final VisitaDatabaseService instance = VisitaDatabaseService._init();
  static Database? _database;

  VisitaDatabaseService._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('visitas_tecnicas.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getApplicationDocumentsDirectory();
    final path = join(dbPath.path, filePath);

    return await openDatabase(
      path,
      version: 2, // WS-6: V2 adiciona cliente_id
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS visitas (
        id TEXT PRIMARY KEY,
        produtor TEXT,
        propriedade TEXT,
        data_visita TEXT NOT NULL,
        area TEXT,
        cultivar TEXT,
        estagio TEXT,
        tecnico TEXT,
        cliente_id TEXT,
        json_data TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');
    AppLogger.debug('VisitaDB criada (v$version)', tag: 'VisitaDB');
  }

  /// V2 — Adiciona `cliente_id` em `visitas` (WS-6).
  /// Idempotente: ALTER TABLE em try/catch.
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      try {
        await db.execute('ALTER TABLE visitas ADD COLUMN cliente_id TEXT');
        AppLogger.debug(
          'V2: cliente_id adicionado em visitas',
          tag: 'VisitaDB',
        );
      } catch (_) {
        AppLogger.debug(
          'V2: cliente_id já existe em visitas — ignorado',
          tag: 'VisitaDB',
        );
      }
    }
  }

  Future<void> save(VisitaModel visita) async {
    final db = await instance.database;

    await db.insert(
      'visitas',
      {
        'id': visita.id,
        'produtor': visita.produtor,
        'propriedade': visita.propriedade,
        'data_visita': visita.dataVisita.toIso8601String(),
        'area': visita.area?.toString(),
        'cultivar': visita.cultivar,
        'estagio': visita.estagioCodigo,
        'tecnico': visita.tecnico,
        'cliente_id': visita.clienteId,
        'json_data': jsonEncode(visita.toJson()),
        'created_at': visita.createdAt.toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    AppLogger.debug('Visita persistida (ID: ${visita.id})', tag: 'VisitaDB');
  }

  Future<List<VisitaModel>> readAllVisitas() async {
    final db = await instance.database;
    final result = await db.query('visitas', orderBy: 'created_at DESC');
    return result
        .map((row) => VisitaModel.fromJson(jsonDecode(row['json_data'] as String)))
        .toList();
  }

  /// Retorna visitas vinculadas a um cliente específico (Hub do Cliente — WS-6).
  Future<List<VisitaModel>> getByClientId(String clienteId) async {
    final db = await instance.database;
    final result = await db.query(
      'visitas',
      where: 'cliente_id = ?',
      whereArgs: [clienteId],
      orderBy: 'created_at DESC',
    );
    return result
        .map((row) => VisitaModel.fromJson(jsonDecode(row['json_data'] as String)))
        .toList();
  }

  Future<void> delete(String id) async {
    final db = await instance.database;
    await db.delete('visitas', where: 'id = ?', whereArgs: [id]);
    AppLogger.debug('Visita deletada (ID: $id)', tag: 'VisitaDB');
  }

  Future<void> close() async {
    final db = await instance.database;
    db.close();
  }
}
