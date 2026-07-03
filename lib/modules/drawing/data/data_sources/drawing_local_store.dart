import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/database/database_helper.dart';
import '../../domain/models/drawing_models.dart';

class DrawingLocalStore {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<void> insert(DrawingFeature feature) async {
    final userId = Supabase.instance.client.auth.currentUser?.id ?? '';
    if (userId.isEmpty) return;
    final db = await _dbHelper.database;
    await db.insert('drawings', {
      ..._toRow(feature),
      'user_id': userId,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> update(DrawingFeature feature) async {
    final userId = Supabase.instance.client.auth.currentUser?.id ?? '';
    if (userId.isEmpty) return;
    final db = await _dbHelper.database;
    await db.update(
      'drawings',
      {..._toRow(feature), 'user_id': userId},
      where: 'id = ? AND user_id = ?',
      whereArgs: [feature.id, userId],
    );
  }

  Future<void> delete(String id) async {
    final userId = Supabase.instance.client.auth.currentUser?.id ?? '';
    if (userId.isEmpty) return;
    final db = await _dbHelper.database;
    // Soft delete
    await db.update(
      'drawings',
      {'deleted_at': DateTime.now().toIso8601String(), 'ativo': 0},
      where: 'id = ? AND user_id = ?',
      whereArgs: [id, userId],
    );
  }

  Future<DrawingFeature?> getById(String id) async {
    final userId = Supabase.instance.client.auth.currentUser?.id ?? '';
    if (userId.isEmpty) return null;
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'drawings',
      where: 'id = ? AND user_id = ? AND deleted_at IS NULL',
      whereArgs: [id, userId],
    );

    if (maps.isNotEmpty) {
      return _fromRow(maps.first);
    }
    return null;
  }

  Future<List<DrawingFeature>> getAll() async {
    final userId = Supabase.instance.client.auth.currentUser?.id ?? '';
    if (userId.isEmpty) return [];
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'drawings',
      where: 'user_id = ? AND deleted_at IS NULL AND ativo = 1',
      whereArgs: [userId],
      orderBy: 'updated_at DESC',
    );

    return maps.map((e) => _fromRow(e)).toList();
  }

  Future<List<DrawingFeature>> getPendingSync() async {
    final userId = Supabase.instance.client.auth.currentUser?.id ?? '';
    if (userId.isEmpty) return [];
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'drawings',
      where: "user_id = ? AND sync_status != 'synced'",
      whereArgs: [userId],
    );
    return maps.map((e) => _fromRow(e)).toList();
  }

  /// Retorna a soma de area_ha de todos os drawings vinculados a [clienteId].
  /// Drawings com area_ha NULL são ignorados na soma.
  /// Retorna 0.0 se não houver nenhum drawing vinculado.
  Future<double> getTotalAreaByClienteId(String clienteId) async {
    final userId = Supabase.instance.client.auth.currentUser?.id ?? '';
    if (userId.isEmpty) return 0.0;
    final db = await _dbHelper.database;
    final result = await db.rawQuery(
      'SELECT COALESCE(SUM(area_ha), 0.0) AS total '
      'FROM drawings '
      'WHERE user_id = ? AND cliente_id = ? AND deleted_at IS NULL',
      [userId, clienteId],
    );
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  /// Atualiza SOMENTE area_total do cliente no banco local.
  Future<void> updateClientAreaTotal(String clientId, double areaTotal) async {
    final userId = Supabase.instance.client.auth.currentUser?.id ?? '';
    if (userId.isEmpty) return;
    final db = await _dbHelper.database;
    await db.update(
      'clients',
      {
        'area_total': areaTotal,
        'updated_at': DateTime.now().toIso8601String(),
        'sync_status': 1,
      },
      where: 'id = ? AND user_id = ?',
      whereArgs: [clientId, userId],
    );
  }

  /// Soma area_ha dos drawings ativos vinculados a [fazendaId].
  Future<double> getTotalAreaByFarmId(String fazendaId) async {
    final userId = Supabase.instance.client.auth.currentUser?.id ?? '';
    if (userId.isEmpty || fazendaId.isEmpty) return 0.0;
    final db = await _dbHelper.database;
    final result = await db.rawQuery(
      'SELECT COALESCE(SUM(area_ha), 0.0) AS total '
      'FROM drawings '
      'WHERE user_id = ? AND fazenda_id = ? AND deleted_at IS NULL AND ativo = 1',
      [userId, fazendaId],
    );
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  /// Atualiza area_total da fazenda no banco local.
  Future<void> updateFarmAreaTotal(String farmId, double areaTotal) async {
    final userId = Supabase.instance.client.auth.currentUser?.id ?? '';
    if (userId.isEmpty || farmId.isEmpty) return;
    final db = await _dbHelper.database;
    await db.update(
      'farms',
      {
        'area_total': areaTotal,
        'updated_at': DateTime.now().toIso8601String(),
        'sync_status': 1,
      },
      where: 'id = ? AND user_id = ?',
      whereArgs: [farmId, userId],
    );
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
      'cliente_id': f.properties.clienteId,
      'fazenda_id': f.properties.fazendaId,
      'sync_status': f.properties.syncStatus.toJson(),
      'versao': f.properties.versao,
      'subtipo': f.properties.subtipo,
      'raio_metros': f.properties.raioMetros,
      'created_at': f.properties.createdAt.toIso8601String(),
      'updated_at': f.properties.updatedAt.toIso8601String(),
      'versao_anterior_id': f.properties.versaoAnteriorId,
      'ativo': f.properties.ativo ? 1 : 0,
      // 🌱 Sprint 6
      'cultura': f.properties.cultura,
      'safra': f.properties.safra,
      'soil_sampling_scheme': f.properties.soilSamplingScheme,
      'rec_by_nutrient': f.properties.recByNutrient != null
          ? jsonEncode(f.properties.recByNutrient)
          : null,
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
      clienteId: row['cliente_id'] as String?,
      fazendaId: row['fazenda_id'] as String?,
      // 🌱 Sprint 6
      cultura: row['cultura'] as String?,
      safra: row['safra'] as String?,
      soilSamplingScheme: row['soil_sampling_scheme'] as String?,
      recByNutrient: row['rec_by_nutrient'] != null
          ? Map<String, double>.from(
              (jsonDecode(row['rec_by_nutrient'] as String) as Map).map(
                (k, v) => MapEntry(k.toString(), (v as num).toDouble()),
              ),
            )
          : null,
    );

    return DrawingFeature(
      id: row['id'],
      geometry: geometry,
      properties: properties,
    );
  }
}
