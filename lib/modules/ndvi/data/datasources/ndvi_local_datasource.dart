import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:soloforte_app/core/database/database_helper.dart';
import 'package:soloforte_app/modules/ndvi/data/models/ndvi_image_model.dart';

/// Datasource local — leitura/gravação do cache NDVI em SQLite.
///
/// Tabela: `ndvi_cache` (criada na migração v19 do [DatabaseHelper]).
/// Validade do cache: 24 horas por linha (area_id + date).
class NdviLocalDatasource {
  static const _table = 'ndvi_cache';
  static const _cacheValidityHours = 24;

  Future<Database> get _db async => DatabaseHelper.instance.database;

  // ── Leitura ───────────────────────────────────────────────────────────────

  /// Retorna a entrada em cache para [areaId] + [date] se válida (< 24h).
  Future<NdviImageModel?> get({
    required String areaId,
    required String date,
  }) async {
    final db = await _db;
    final rows = await db.query(
      _table,
      where: 'area_id = ? AND date = ?',
      whereArgs: [areaId, date],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    final model = NdviImageModel.fromSqliteRow(rows.first);

    // Verificar validade
    final cachedAt = DateTime.tryParse(model.cachedAt);
    if (cachedAt == null) return null;
    final age = DateTime.now().difference(cachedAt).inHours;
    if (age >= _cacheValidityHours) return null;

    return model;
  }

  /// Retorna a entrada mais recente em cache para [areaId], sem limite de validade.
  /// Usado para exibição offline quando não há conexão.
  Future<NdviImageModel?> getLatest(String areaId) async {
    final db = await _db;
    final rows = await db.query(
      _table,
      where: 'area_id = ?',
      whereArgs: [areaId],
      orderBy: 'date DESC',
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return NdviImageModel.fromSqliteRow(rows.first);
  }

  // ── Gravação ──────────────────────────────────────────────────────────────

  /// Persiste [model] no SQLite.
  ///
  /// Se [imageBase64] estiver presente, salva o PNG em arquivo local e
  /// registra o path em [imagePath].
  Future<NdviImageModel> save(NdviImageModel model) async {
    final db = await _db;

    String? localPath;
    if (model.imageBase64 != null && model.imageBase64!.isNotEmpty) {
      localPath = await _saveImageFile(
        areaId: model.areaId,
        date: model.date,
        base64Data: model.imageBase64!,
      );
    }

    final modelWithPath = NdviImageModel(
      areaId: model.areaId,
      date: model.date,
      imageBase64: null, // Não persiste base64 no SQLite
      imagePath: localPath ?? model.imagePath,
      source: model.source,
      cloudCoverage: model.cloudCoverage,
      availableDates: model.availableDates,
      cachedAt: model.cachedAt,
    );

    final id = '${model.areaId}_${model.date}';
    final row = modelWithPath.toSqliteRow(id);

    await db.insert(
      _table,
      row,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    return modelWithPath;
  }

  // ── Auxiliar: salvar PNG em arquivo local ─────────────────────────────────

  Future<String> _saveImageFile({
    required String areaId,
    required String date,
    required String base64Data,
  }) async {
    final dir = await getApplicationDocumentsDirectory();
    final ndviDir = Directory('${dir.path}/ndvi_cache');
    if (!ndviDir.existsSync()) ndviDir.createSync(recursive: true);

    final fileName = 'ndvi_${areaId}_$date.png';
    final file = File('${ndviDir.path}/$fileName');

    final Uint8List bytes = base64Decode(base64Data);
    await file.writeAsBytes(bytes);
    return file.path;
  }
}
