import '../domain/client.dart';
import '../domain/agronomic_models.dart';
import '../domain/client_cultura.dart';
import 'package:sqflite/sqflite.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/database/database_helper.dart';

class ClientsRepository {
  Future<Database> get _db async => await DatabaseHelper.instance.database;

  // ── Clientes ──────────────────────────────────────────────────────

  Future<List<Client>> getClients() async {
    final userId = Supabase.instance.client.auth.currentUser?.id ?? '';
    if (userId.isEmpty) return [];
    final db = await _db;
    final maps = await db.query(
      'clients',
      where: 'user_id = ? AND deleted_at IS NULL',
      whereArgs: [userId],
      orderBy: 'nome ASC',
    );
    return maps.map((e) => Client.fromMap(e)).toList();
  }

  Future<Client?> getClientById(String id) async {
    final userId = Supabase.instance.client.auth.currentUser?.id ?? '';
    if (userId.isEmpty) return null;
    final db = await _db;
    final maps = await db.query(
      'clients',
      where: 'id = ? AND user_id = ? AND deleted_at IS NULL',
      whereArgs: [id, userId],
    );
    if (maps.isNotEmpty) {
      final client = Client.fromMap(maps.first);

      final farmMaps = await db.query(
        'farms',
        where: 'cliente_id = ? AND user_id = ? AND deleted_at IS NULL',
        whereArgs: [id, userId],
        orderBy: 'nome ASC',
      );

      final farms = <Farm>[];
      for (final farmMap in farmMaps) {
        final farmId = farmMap['id'] as String;
        final fieldMaps = await db.query(
          'fields',
          where: 'fazenda_id = ? AND user_id = ? AND deleted_at IS NULL',
          whereArgs: [farmId, userId],
          orderBy: 'nome ASC',
        );
        farms.add(
          Farm(
            id: farmId,
            name: farmMap['nome'] as String,
            city: farmMap['municipio'] as String? ?? '',
            state: farmMap['uf'] as String? ?? '',
            totalAreaHa: (farmMap['area_total'] as num?)?.toDouble() ?? 0.0,
            fields: fieldMaps
                .map(
                  (field) => Talhao(
                    id: field['id'] as String,
                    name: field['nome'] as String,
                    areaHa:
                        (field['area_produtiva'] as num?)?.toDouble() ?? 0.0,
                    crop: '',
                    harvest: '',
                  ),
                )
                .toList(),
          ),
        );
      }

      return client.copyWith(farms: farms);
    }
    return null;
  }

  /// Salva (insert) um novo cliente com suas culturas em transação única.
  Future<void> saveClient(
    Client client, {
    List<ClientCultura> culturas = const [],
  }) async {
    final userId = Supabase.instance.client.auth.currentUser?.id ?? '';
    if (userId.isEmpty) return;
    final db = await _db;
    await db.transaction((txn) async {
      await txn.insert('clients', {
        ...client.toMap(),
        'user_id': userId,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
      await _deleteCulturas(txn, client.id);
      await _saveCulturas(txn, culturas);
    });
  }

  /// Atualiza um cliente existente com suas culturas em transação única.
  Future<void> updateClient(
    Client client, {
    List<ClientCultura> culturas = const [],
  }) async {
    final userId = Supabase.instance.client.auth.currentUser?.id ?? '';
    if (userId.isEmpty) return;
    final db = await _db;
    await db.transaction((txn) async {
      await txn.insert('clients', {
        ...client.toMap(),
        'user_id': userId,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
      await _deleteCulturas(txn, client.id);
      await _saveCulturas(txn, culturas);
    });
  }

  /// Atualiza SOMENTE area_total do cliente.
  /// Não toca em nenhum outro campo.
  /// Chamado pelo drawing/ via callback — nunca importado diretamente.
  Future<void> updateClientAreaTotal(String clientId, double areaTotal) async {
    final userId = Supabase.instance.client.auth.currentUser?.id ?? '';
    if (userId.isEmpty) return;
    final db = await _db;
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

  Future<void> deleteClient(String id) async {
    final userId = Supabase.instance.client.auth.currentUser?.id ?? '';
    if (userId.isEmpty) return;
    final db = await _db;
    await db.update(
      'clients',
      {
        'deleted_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
        'sync_status': 1,
      },
      where: 'id = ? AND user_id = ?',
      whereArgs: [id, userId],
    );
  }

  // ── Culturas ──────────────────────────────────────────────────────

  Future<List<ClientCultura>> getCulturas(String clientId) async {
    final userId = Supabase.instance.client.auth.currentUser?.id ?? '';
    if (userId.isEmpty) return [];
    final db = await _db;
    final rows = await db.query(
      'client_culturas',
      where: 'client_id = ? AND user_id = ?',
      whereArgs: [clientId, userId],
    );
    return rows.map(ClientCultura.fromMap).toList();
  }

  Future<void> _saveCulturas(
    DatabaseExecutor txn,
    List<ClientCultura> culturas,
  ) async {
    final userId = Supabase.instance.client.auth.currentUser?.id ?? '';
    if (userId.isEmpty) return;
    for (final c in culturas) {
      await txn.insert('client_culturas', {
        ...c.toMap(),
        'user_id': userId,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
  }

  Future<void> _deleteCulturas(DatabaseExecutor txn, String clientId) async {
    final userId = Supabase.instance.client.auth.currentUser?.id ?? '';
    if (userId.isEmpty) return;
    await txn.delete(
      'client_culturas',
      where: 'client_id = ? AND user_id = ?',
      whereArgs: [clientId, userId],
    );
  }

  // ── Fazendas ──────────────────────────────────────────────────────

  Future<List<Farm>> getFarms(String clientId) async {
    final userId = Supabase.instance.client.auth.currentUser?.id ?? '';
    if (userId.isEmpty) return [];
    final db = await _db;
    final results = await db.query(
      'farms',
      where: 'cliente_id = ? AND user_id = ? AND deleted_at IS NULL',
      whereArgs: [clientId, userId],
      orderBy: 'nome ASC',
    );

    return results
        .map(
          (f) => Farm(
            id: f['id'] as String,
            name: f['nome'] as String,
            city: f['municipio'] as String? ?? '',
            state: f['uf'] as String? ?? '',
            totalAreaHa: (f['area_total'] as num?)?.toDouble() ?? 0.0,
            fields: [],
          ),
        )
        .toList();
  }

  Future<void> saveFarm(Farm farm, String clientId) async {
    final userId = Supabase.instance.client.auth.currentUser?.id ?? '';
    if (userId.isEmpty) return;
    final db = await _db;
    final data = {
      'id': farm.id,
      'user_id': userId,
      'cliente_id': clientId,
      'nome': farm.name,
      'municipio': farm.city,
      'uf': farm.state,
      'area_total': farm.totalAreaHa,
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
      'sync_status': 1,
      'deleted_at': null,
    };

    final count = await db.update(
      'farms',
      data,
      where: 'id = ? AND user_id = ?',
      whereArgs: [farm.id, userId],
    );
    if (count == 0) {
      await db.insert('farms', data);
    }
  }
}
