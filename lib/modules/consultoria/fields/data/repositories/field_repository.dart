import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:soloforte_app/core/database/database_helper.dart';
import 'package:soloforte_app/modules/consultoria/clients/domain/agronomic_models.dart';

class FieldRepository {
  Future<Database> get _db async => await DatabaseHelper.instance.database;

  Future<List<Talhao>> getAllFields() async {
    final db = await _db;
    final maps = await db.query(
      'fields',
      where: 'deleted_at IS NULL',
      orderBy: 'nome ASC',
    );
    return maps.map((e) => _fromMap(e)).toList();
  }

  Future<List<Talhao>> getFieldsByFarmId(String farmId) async {
    final db = await _db;
    final maps = await db.query(
      'fields',
      where: 'fazenda_id = ? AND deleted_at IS NULL',
      whereArgs: [farmId],
      orderBy: 'nome ASC',
    );
    return maps.map((e) => _fromMap(e)).toList();
  }

  Future<Talhao?> getFieldById(String id) async {
    final db = await _db;
    final maps = await db.query(
      'fields',
      where: 'id = ? AND deleted_at IS NULL',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return _fromMap(maps.first);
    }
    return null;
  }

  Future<void> saveField(Talhao field, String farmId) async {
    final db = await _db;

    final exists = await db.query(
      'fields',
      columns: ['id'],
      where: 'id = ?',
      whereArgs: [field.id],
    );

    final data = _toMap(field, farmId);

    if (exists.isNotEmpty) {
      await db.update(
        'fields',
        data..remove('created_at'),
        where: 'id = ?',
        whereArgs: [field.id],
      );
    } else {
      await db.insert('fields', data);
    }
  }

  Future<void> deleteField(String id) async {
    final db = await _db;
    await db.update(
      'fields',
      {'deleted_at': DateTime.now().toIso8601String(), 'sync_status': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Mapper
  Talhao _fromMap(Map<String, Object?> map) {
    return Talhao(
      id: map['id'] as String,
      name: map['nome'] as String,
      areaHa: (map['area_produtiva'] as num?)?.toDouble() ?? 0.0,
      crop: '', // Property not supported in DB schema
      harvest: '', // Property not supported in DB schema
      updatedAt: map['updated_at'] != null
          ? DateTime.tryParse(map['updated_at'] as String)
          : null,
      geometry: map['bordadura_geo'] != null
          ? jsonDecode(map['bordadura_geo'] as String)
          : null,
    );
  }

  Map<String, Object?> _toMap(Talhao field, String farmId) {
    return {
      'id': field.id,
      'fazenda_id': farmId,
      'codigo': null,
      'nome': field.name,
      'area_produtiva': field.areaHa,
      'bordadura_geo': field.geometry != null
          ? jsonEncode(field.geometry)
          : null,
      'centro_geo': null,
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
      'deleted_at': null,
      'sync_status': 1,
    };
  }
}
