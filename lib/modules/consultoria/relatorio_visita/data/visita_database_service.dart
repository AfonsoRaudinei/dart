import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';
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

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future<void> _createDB(Database db, int version) async {
    const idType = 'TEXT PRIMARY KEY';
    const textType = 'TEXT';
    const textTypeNotNull = 'TEXT NOT NULL';

    await db.execute('''
      CREATE TABLE IF NOT EXISTS visitas ( 
        id $idType, 
        produtor $textType,
        propriedade $textType,
        data_visita $textTypeNotNull,
        area $textType,
        cultivar $textType,
        estagio $textType,
        tecnico $textType,
        json_data $textTypeNotNull,
        created_at $textTypeNotNull
      )
    ''');
  }

  Future<void> save(VisitaModel visita) async {
    final db = await instance.database;

    final id = await db.insert('visitas', {
      'id': visita.id,
      'produtor': visita.produtor,
      'propriedade': visita.propriedade,
      'data_visita': visita.dataVisita.toIso8601String(),
      'area': visita.area?.toString(),
      'cultivar': visita.cultivar,
      'estagio': visita.estagioCodigo,
      'tecnico': visita.tecnico,
      'json_data': jsonEncode(visita.toJson()),
      'created_at': visita.createdAt.toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);

    debugPrint('✅ Visita persistida em SQLite (ID: $id)');
  }

  Future<List<VisitaModel>> readAllVisitas() async {
    final db = await instance.database;

    final orderBy = 'created_at DESC';
    final result = await db.query('visitas', orderBy: orderBy);

    return result
        .map(
          (json) =>
              VisitaModel.fromJson(jsonDecode(json['json_data'] as String)),
        )
        .toList();
  }

  Future<void> delete(String id) async {
    final db = await instance.database;
    await db.delete('visitas', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> close() async {
    final db = await instance.database;
    db.close();
  }
}
