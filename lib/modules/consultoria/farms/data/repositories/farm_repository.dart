import 'package:sqflite/sqflite.dart';
import 'package:soloforte_app/core/database/database_helper.dart';
import 'package:soloforte_app/core/session/local_session_identity.dart';
import 'package:soloforte_app/modules/consultoria/clients/domain/agronomic_models.dart';

class FarmRepository {
  Future<Database> get _db async => await DatabaseHelper.instance.database;

  Future<List<Farm>> getFarmsByClientId(String clientId) async {
    final userId = LocalSessionIdentity.resolveUserId();
    if (userId.isEmpty) return [];
    final db = await _db;
    final maps = await db.query(
      'farms',
      where: 'cliente_id = ? AND user_id = ? AND deleted_at IS NULL',
      whereArgs: [clientId, userId],
      orderBy: 'nome ASC',
    );
    return maps.map((e) => _fromMap(e)).toList();
  }

  Future<Farm?> getFarmById(String id) async {
    final userId = LocalSessionIdentity.resolveUserId();
    if (userId.isEmpty) return null;
    final db = await _db;
    final maps = await db.query(
      'farms',
      where: 'id = ? AND user_id = ? AND deleted_at IS NULL',
      whereArgs: [id, userId],
    );
    if (maps.isNotEmpty) {
      return _fromMap(maps.first);
    }
    return null;
  }

  Future<void> saveFarm(Farm farm, String clientId) async {
    final userId = LocalSessionIdentity.resolveUserId();
    if (userId.isEmpty) return;
    final db = await _db;

    // Check if exists to determine insert/update
    final exists = await db.query(
      'farms',
      columns: ['id'],
      where: 'id = ? AND user_id = ?',
      whereArgs: [farm.id, userId],
    );

    final data = _toMap(farm, clientId, userId);

    if (exists.isNotEmpty) {
      await db.update(
        'farms',
        data..remove('created_at'), // Do not update created_at
        where: 'id = ? AND user_id = ?',
        whereArgs: [farm.id, userId],
      );
    } else {
      await db.insert('farms', data);
    }
  }

  Future<void> deleteFarm(String id) async {
    final userId = LocalSessionIdentity.resolveUserId();
    if (userId.isEmpty) return;
    final db = await _db;
    await db.update(
      'farms',
      {'deleted_at': DateTime.now().toIso8601String(), 'sync_status': 1},
      where: 'id = ? AND user_id = ?',
      whereArgs: [id, userId],
    );
  }

  // Mapper
  Farm _fromMap(Map<String, Object?> map) {
    return Farm(
      id: map['id'] as String,
      name: map['nome'] as String,
      city: map['municipio'] as String? ?? '',
      state: map['uf'] as String? ?? '',
      totalAreaHa: (map['area_total'] as num?)?.toDouble() ?? 0.0,
      fields: [], // Lazy load
    );
  }

  Map<String, Object?> _toMap(Farm farm, String clientId, String userId) {
    return {
      'id': farm.id,
      'user_id': userId,
      'cliente_id': clientId,
      'nome': farm.name,
      'area_total': farm.totalAreaHa,
      'municipio': farm.city,
      'uf': farm.state,
      'created_at': DateTime.now().toIso8601String(), // Used only on Insert
      'updated_at': DateTime.now().toIso8601String(),
      'deleted_at': null,
      'sync_status': 1, // Dirty
    };
  }
}
