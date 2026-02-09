import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import '../../../../core/database/database_helper.dart';
import '../../domain/models/drawing_models.dart';

class DrawingLocalStore {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<void> insert(DrawingFeature feature) async {
    final db = await _dbHelper.database;
    await db.insert(
      'drawings',
      _toRow(feature),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> update(DrawingFeature feature) async {
    final db = await _dbHelper.database;
    await db.update(
      'drawings',
      _toRow(feature),
      where: 'id = ?',
      whereArgs: [feature.id],
    );
  }

  Future<void> delete(String id) async {
    final db = await _dbHelper.database;
    // Soft delete
    await db.update(
      'drawings',
      {'deleted_at': DateTime.now().toIso8601String(), 'ativo': 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<DrawingFeature?> getById(String id) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'drawings',
      where: 'id = ? AND deleted_at IS NULL',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return _fromRow(maps.first);
    }
    return null;
  }

  Future<List<DrawingFeature>> getAll() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'drawings',
      where: 'deleted_at IS NULL AND ativo = 1',
      orderBy: 'updated_at DESC',
    );

    return maps.map((e) => _fromRow(e)).toList();
  }

  Future<List<DrawingFeature>> getPendingSync() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'drawings',
      where: "sync_status != 'synced'",
    );
    return maps.map((e) => _fromRow(e)).toList();
  }

  Map<String, dynamic> _toRow(DrawingFeature f) {
    return {
      'id': f.id,
      'nome': f.properties.nome,
      'tipo': f.properties.tipo.toJson(),
      'origem': f.properties.origem.toJson(),
      'status': f.properties.status.toJson(),
      'geojson': jsonEncode(f.geometry.toJson()),
      'area_ha': f.properties.areaHa,
      'autor_id': f.properties.autorId,
      'autor_tipo': f.properties.autorTipo.toJson(),
      'sync_status': f.properties.syncStatus.toJson(),
      'versao': f.properties.versao,
      'subtipo': f.properties.subtipo,
      'raio_metros': f.properties.raioMetros,
      'created_at': f.properties.createdAt.toIso8601String(),
      'updated_at': f.properties.updatedAt.toIso8601String(),
      'versao_anterior_id': f.properties.versaoAnteriorId,
      'ativo': f.properties.ativo ? 1 : 0,
    };
  }

  DrawingFeature _fromRow(Map<String, dynamic> row) {
    // Reconstruct Geometry
    final geoJson = jsonDecode(row['geojson'] as String);
    final geometry = DrawingGeometry.fromJson(geoJson);

    // Reconstruct Properties
    final properties = DrawingProperties(
      nome: row['nome'],
      tipo: DrawingType.fromJson(row['tipo']),
      origem: DrawingOrigin.fromJson(row['origem']),
      status: DrawingStatus.fromJson(row['status']),
      autorId: row['autor_id'],
      autorTipo: AuthorType.fromJson(row['autor_tipo']),
      areaHa: row['area_ha'],
      versao: row['versao'],
      ativo: row['ativo'] == 1,
      createdAt: DateTime.parse(row['created_at']),
      updatedAt: DateTime.parse(row['updated_at']),
      syncStatus: SyncStatus.fromJson(row['sync_status']),
      subtipo: row['subtipo'],
      raioMetros: row['raio_metros'],
      versaoAnteriorId: row['versao_anterior_id'],
      // Missing fields in DB but present in model:
      // operacaoId, fazendaId -> Add columns if necessary or assume null
    );

    return DrawingFeature(
      id: row['id'],
      geometry: geometry,
      properties: properties,
    );
  }
}
