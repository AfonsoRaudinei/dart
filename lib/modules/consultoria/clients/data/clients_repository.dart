import '../domain/client.dart';
import '../domain/agronomic_models.dart';
import 'package:sqflite/sqflite.dart';
import '../../../../core/database/database_helper.dart';

class ClientsRepository {
  Future<Database> get _db async => await DatabaseHelper.instance.database;

  Future<List<Client>> getClients() async {
    final db = await _db;
    final maps = await db.query(
      'clients',
      where: 'deleted_at IS NULL',
      orderBy: 'nome ASC',
    );
    return maps.map((e) => _fromMap(e)).toList();
  }

  Future<Client?> getClientById(String id) async {
    final db = await _db;
    final maps = await db.query(
      'clients',
      where: 'id = ? AND deleted_at IS NULL',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      final client = _fromMap(maps.first);

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

  Future<void> saveClient(Client client) async {
    final db = await _db;

    final data = _toMap(client);

    final count = await db.update(
      'clients',
      data,
      where: 'id = ?',
      whereArgs: [client.id],
    );
    if (count == 0) {
      await db.insert('clients', data);
    }
  }

  Future<void> deleteClient(String id) async {
    final db = await _db;
    await db.update(
      'clients',
      {
        'deleted_at': DateTime.now().toIso8601String(),
        'sync_status': 1, // Mark dirty
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Client _fromMap(Map<String, Object?> map) {
    return Client(
      id: map['id'] as String,
      name: map['nome'] as String,
      phone: (map['telefone'] as String?) ?? '',
      email: map['email'] as String?,
      city: '',
      state: '',
      active: map['deleted_at'] == null,
      createdAt: DateTime.parse(map['created_at'] as String),
      farms: [],
    );
  }

  Map<String, dynamic> _toMap(Client client) {
    return {
      'id': client.id,
      'nome': client.name,
      'documento': null,
      'telefone': client.phone,
      'email': client.email,
      'created_at': client.createdAt.toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
      'deleted_at': client.active ? null : DateTime.now().toIso8601String(),
      'sync_status': 1, // Dirty
    };
  }

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
      'created_at': DateTime.now()
          .toIso8601String(), // Ideally keep original if exists
      'updated_at': DateTime.now().toIso8601String(),
      'sync_status': 1, // pending sync
      'deleted_at': null,
    };

    // Upsert logic
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
