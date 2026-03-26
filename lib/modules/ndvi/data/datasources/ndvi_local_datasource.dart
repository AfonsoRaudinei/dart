import 'package:sqflite/sqflite.dart';
import 'package:soloforte_app/core/database/database_helper.dart';
import 'package:soloforte_app/modules/ndvi/data/models/ndvi_image_model.dart';
import 'package:soloforte_app/modules/ndvi/domain/entities/ndvi_image.dart';

class NdviLocalDatasource {
  static const _table = 'ndvi_cache';

  Future<Database> get _db async => DatabaseHelper.instance.database;

  Future<NdviImageModel?> getLatest(String fieldId) async {
    final db = await _db;
    final rows = await db.query(
      _table,
      where: 'field_id = ?',
      whereArgs: [fieldId],
      orderBy: 'image_date DESC',
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return NdviImageModel.fromMap(rows.first);
  }

  Future<List<NdviImageModel>> getAll(String fieldId) async {
    final db = await _db;
    final rows = await db.query(
      _table,
      where: 'field_id = ?',
      whereArgs: [fieldId],
      orderBy: 'image_date DESC',
    );
    return rows.map((r) => NdviImageModel.fromMap(r)).toList();
  }

  Future<void> save(NdviImage image) async {
    final db = await _db;
    final model = NdviImageModel.fromEntity(image);
    await db.insert(
      _table,
      model.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deleteAll(String fieldId) async {
    final db = await _db;
    await db.delete(
      _table,
      where: 'field_id = ?',
      whereArgs: [fieldId],
    );
  }
}
