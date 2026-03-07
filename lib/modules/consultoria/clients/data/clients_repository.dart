import '../domain/client.dart';
import '../domain/agronomic_models.dart';
import '../domain/client_cultura.dart';
import 'package:sqflite/sqflite.dart';
import '../../../../core/database/database_helper.dart';

class ClientsRepository {
  Future<Database> get _db async => await DatabaseHelper.instance.database;

  // ── Clientes ──────────────────────────────────────────────────────

  Future<List<Client>> getClients() async {
    final db = await _db;
    final maps = await db.query(
      'clients',
      where: 'deleted_at IS NULL',
      orderBy: 'nome ASC',
    );
    return maps.map((e) => Client.fromMap(e)).toList();
  }

  Future<Client?> getClientById(String id) async {
    final db = await _db;
    final maps = await db.query(
      'clients',
      where: 'id = ? AND deleted_at IS NULL',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      final client = Client.fromMap(maps.first);

      final farmMaps = await db.query(
        'farms',
        where: 'cliente_id = ? AND deleted_at IS NULL',
        whereArgs: [id],
        orderBy: 'nome ASC',
      );

      final farms = farmMaps
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

      return client.copyWith(farms: farms);
    }
    return null;
  }

  /// Salva (insert) um novo cliente com suas culturas em transação única.
  Future<void> saveClient(
    Client client, {
    List<ClientCultura> culturas = const [],
  }) async {
    final db = await _db;
    await db.transaction((txn) async {
      await txn.insert(
        'clients',
        client.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      await _deleteCulturas(txn, client.id);
      await _saveCulturas(txn, culturas);
    });
  }

  /// Atualiza um cliente existente com suas culturas em transação única.
  Future<void> updateClient(
    Client client, {
    List<ClientCultura> culturas = const [],
  }) async {
    final db = await _db;
    await db.transaction((txn) async {
      await txn.insert(
        'clients',
        client.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      await _deleteCulturas(txn, client.id);
      await _saveCulturas(txn, culturas);
    });
  }

  Future<void> deleteClient(String id) async {
    final db = await _db;
    await db.update(
      'clients',
      {
        'deleted_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
        'sync_status': 1,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ── Culturas ──────────────────────────────────────────────────────

  Future<List<ClientCultura>> getCulturas(String clientId) async {
    final db = await _db;
    final rows = await db.query(
      'client_culturas',
      where: 'client_id = ?',
      whereArgs: [clientId],
    );
    return rows.map(ClientCultura.fromMap).toList();
  }

  Future<void> _saveCulturas(
    DatabaseExecutor txn,
    List<ClientCultura> culturas,
  ) async {
    for (final c in culturas) {
      await txn.insert(
        'client_culturas',
        c.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  Future<void> _deleteCulturas(
    DatabaseExecutor txn,
    String clientId,
  ) async {
    await txn.delete(
      'client_culturas',
      where: 'client_id = ?',
      whereArgs: [clientId],
    );
  }

  // ── Fazendas ──────────────────────────────────────────────────────

  Future<List<Farm>> getFarms(String clientId) async {
    final db = await _db;
    final results = await db.query(
      'farms',
      where: 'cliente_id = ? AND deleted_at IS NULL',
      whereArgs: [clientId],
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
    final db = await _db;
    final data = {
      'id': farm.id,
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
      where: 'id = ?',
      whereArgs: [farm.id],
    );
    if (count == 0) {
      await db.insert('farms', data);
    }
  }
}
