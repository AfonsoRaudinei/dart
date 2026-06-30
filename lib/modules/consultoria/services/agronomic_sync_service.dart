import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:soloforte_app/core/database/database_helper.dart';
import 'package:soloforte_app/core/network/network_policy.dart';
import 'package:soloforte_app/core/utils/app_logger.dart';

class AgronomicSyncService {
  final SupabaseClient _supabase;

  AgronomicSyncService(this._supabase);

  static const int statusSynced = 0;
  static const int statusDirty = 1;

  Future<void> syncNow() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null || userId.isEmpty) {
      AppLogger.warning(
        'Sync agronomico ignorado: usuario nao autenticado',
        tag: 'AgronomicSync',
      );
      return;
    }

    await _pushClients(userId);
    await _pushFarms(userId);
    await _pushFields(userId);
    await _pullDeltas(userId);
  }

  Future<void> _pushClients(String userId) async {
    final db = await DatabaseHelper.instance.database;
    final dirtyClients = await db.query(
      'clients',
      where: 'user_id = ? AND sync_status = ?',
      whereArgs: [userId, statusDirty],
    );

    for (final row in dirtyClients) {
      try {
        await NetworkPolicy.withTimeout(
          () => _supabase.from('clients').upsert(clientLocalToRemote(row)),
        );
        await _replaceRemoteClientCulturas(row['id'] as String, userId);
        await db.update(
          'clients',
          {'sync_status': statusSynced},
          where: 'id = ? AND user_id = ?',
          whereArgs: [row['id'], userId],
        );
      } catch (e) {
        AppLogger.warning(
          'Erro ao sincronizar client ${row["id"]}',
          tag: 'AgronomicSync',
          error: e,
        );
      }
    }
  }

  Future<void> _replaceRemoteClientCulturas(
    String clientId,
    String userId,
  ) async {
    final db = await DatabaseHelper.instance.database;
    final culturas = await db.query(
      'client_culturas',
      where: 'client_id = ? AND user_id = ?',
      whereArgs: [clientId, userId],
    );

    await NetworkPolicy.withTimeout(
      () => _supabase
          .from('client_culturas')
          .delete()
          .eq('user_id', userId)
          .eq('client_id', clientId),
    );

    if (culturas.isEmpty) return;

    await NetworkPolicy.withTimeout(
      () => _supabase
          .from('client_culturas')
          .upsert(culturas.map(clientCulturaLocalToRemote).toList()),
    );
  }

  Future<void> _pushFarms(String userId) async {
    final db = await DatabaseHelper.instance.database;
    final dirtyFarms = await db.query(
      'farms',
      where: 'user_id = ? AND sync_status = ?',
      whereArgs: [userId, statusDirty],
    );

    for (final row in dirtyFarms) {
      try {
        await NetworkPolicy.withTimeout(
          () => _supabase.from('farms').upsert(farmLocalToRemote(row)),
        );
        await db.update(
          'farms',
          {'sync_status': statusSynced},
          where: 'id = ? AND user_id = ?',
          whereArgs: [row['id'], userId],
        );
      } catch (e) {
        AppLogger.warning(
          'Erro ao sincronizar farm ${row["id"]}',
          tag: 'AgronomicSync',
          error: e,
        );
      }
    }
  }

  Future<void> _pushFields(String userId) async {
    final db = await DatabaseHelper.instance.database;
    final dirtyFields = await db.query(
      'fields',
      where: 'user_id = ? AND sync_status = ?',
      whereArgs: [userId, statusDirty],
    );

    for (final row in dirtyFields) {
      try {
        await NetworkPolicy.withTimeout(
          () => _supabase.from('fields').upsert(fieldLocalToRemote(row)),
        );
        await db.update(
          'fields',
          {'sync_status': statusSynced},
          where: 'id = ? AND user_id = ?',
          whereArgs: [row['id'], userId],
        );
      } catch (e) {
        AppLogger.warning(
          'Erro ao sincronizar field ${row["id"]}',
          tag: 'AgronomicSync',
          error: e,
        );
      }
    }
  }

  Future<void> _pullDeltas(String userId) async {
    final remoteClients = await NetworkPolicy.withTimeout(
      () => _supabase
          .from('clients')
          .select()
          .eq('user_id', userId)
          .order('updated_at'),
    );
    await _upsertLocalRows(
      table: 'clients',
      remoteList: remoteClients,
      mapper: clientRemoteToLocal,
    );

    final remoteFarms = await NetworkPolicy.withTimeout(
      () => _supabase
          .from('farms')
          .select()
          .eq('user_id', userId)
          .order('updated_at'),
    );
    await _upsertLocalRows(
      table: 'farms',
      remoteList: remoteFarms,
      mapper: farmRemoteToLocal,
    );

    final remoteFields = await NetworkPolicy.withTimeout(
      () => _supabase
          .from('fields')
          .select()
          .eq('user_id', userId)
          .order('updated_at'),
    );
    await _upsertLocalRows(
      table: 'fields',
      remoteList: remoteFields,
      mapper: fieldRemoteToLocal,
    );

    final remoteCulturas = await NetworkPolicy.withTimeout(
      () => _supabase
          .from('client_culturas')
          .select()
          .eq('user_id', userId)
          .order('updated_at'),
    );
    await _upsertLocalCulturas(remoteCulturas);
  }

  Future<void> _upsertLocalRows({
    required String table,
    required List<dynamic> remoteList,
    required Map<String, dynamic> Function(Map<String, dynamic>) mapper,
  }) async {
    final db = await DatabaseHelper.instance.database;

    for (final remote in remoteList) {
      final remoteMap = Map<String, dynamic>.from(remote as Map);
      final data = mapper(remoteMap);
      final id = data['id'];
      if (id == null) continue;

      final local = await db.query(table, where: 'id = ?', whereArgs: [id]);
      if (local.isNotEmpty && !shouldApplyRemote(local.first, data)) {
        continue;
      }

      if (local.isNotEmpty) {
        await db.update(table, data, where: 'id = ?', whereArgs: [id]);
      } else {
        await db.insert(table, data);
      }
    }
  }

  Future<void> _upsertLocalCulturas(List<dynamic> remoteList) async {
    final db = await DatabaseHelper.instance.database;

    for (final remote in remoteList) {
      final data = clientCulturaRemoteToLocal(
        Map<String, dynamic>.from(remote as Map),
      );
      final id = data['id'];
      if (id == null) continue;

      final exists = await db.query(
        'client_culturas',
        where: 'id = ?',
        whereArgs: [id],
      );
      if (exists.isNotEmpty) {
        await db.update(
          'client_culturas',
          data,
          where: 'id = ?',
          whereArgs: [id],
        );
      } else {
        await db.insert('client_culturas', data);
      }
    }
  }

  @visibleForTesting
  static bool shouldApplyRemote(
    Map<String, Object?> local,
    Map<String, dynamic> remoteLocalShape,
  ) {
    final localUpdatedAt = _parseDate(local['updated_at']);
    final remoteUpdatedAt = _parseDate(remoteLocalShape['updated_at']);
    final localIsDirty = local['sync_status'] == statusDirty;

    if (localUpdatedAt == null || remoteUpdatedAt == null) return true;
    return !(localIsDirty && remoteUpdatedAt.isBefore(localUpdatedAt));
  }

  @visibleForTesting
  static Map<String, dynamic> clientLocalToRemote(Map<String, Object?> row) {
    final nome = row['nome'];
    final telefone = row['telefone'];
    final documento = row['documento'] ?? row['cpf_cnpj'];
    final cidade = row['cidade'];
    final uf = row['uf'];

    return _withoutNulls({
      'id': row['id'],
      'user_id': row['user_id'],
      'nome': nome,
      'name': nome,
      'documento': row['documento'],
      'document': documento,
      'telefone': telefone,
      'phone': telefone,
      'email': row['email'],
      'cidade': cidade,
      'city': cidade,
      'uf': uf,
      'state': uf,
      'foto_path': row['foto_path'],
      'observacoes': row['observacoes'],
      'data_nascimento': row['data_nascimento'],
      'cpf_cnpj': row['cpf_cnpj'],
      'area_total': row['area_total'],
      'area_ha': row['area_total'],
      'tipo_propriedade': row['tipo_propriedade'],
      'sistema_irrigacao': row['sistema_irrigacao'],
      'solo_tipo': row['solo_tipo'],
      'regiao_agricola': row['regiao_agricola'],
      'safra_atual': row['safra_atual'],
      'usa_assistencia_tecnica': row['usa_assistencia_tecnica'],
      'tecnico_responsavel': row['tecnico_responsavel'],
      'ativo': row['ativo'],
      'created_at': row['created_at'],
      'updated_at': row['updated_at'],
      'deleted_at': row['deleted_at'],
    });
  }

  @visibleForTesting
  static Map<String, dynamic> farmLocalToRemote(Map<String, Object?> row) {
    final nome = row['nome'];
    final clienteId = row['cliente_id'];
    final municipio = row['municipio'];
    final uf = row['uf'];
    final area = row['area_total'];

    return _withoutNulls({
      'id': row['id'],
      'user_id': row['user_id'],
      'cliente_id': clienteId,
      'client_id': clienteId,
      'nome': nome,
      'name': nome,
      'municipio': municipio,
      'city': municipio,
      'uf': uf,
      'state': uf,
      'area_total': area,
      'area_ha': area,
      'created_at': row['created_at'],
      'updated_at': row['updated_at'],
      'deleted_at': row['deleted_at'],
    });
  }

  @visibleForTesting
  static Map<String, dynamic> fieldLocalToRemote(Map<String, Object?> row) {
    final nome = row['nome'];
    final fazendaId = row['fazenda_id'];
    final area = row['area_produtiva'];
    final geometry = row['bordadura_geo'];

    return _withoutNulls({
      'id': row['id'],
      'user_id': row['user_id'],
      'fazenda_id': fazendaId,
      'farm_id': fazendaId,
      'codigo': row['codigo'],
      'nome': nome,
      'name': nome,
      'area_produtiva': area,
      'area_ha': area,
      'bordadura_geo': geometry,
      'geometry': _localGeometryToRemote(geometry),
      'centro_geo': row['centro_geo'],
      'created_at': row['created_at'],
      'updated_at': row['updated_at'],
      'deleted_at': row['deleted_at'],
    });
  }

  @visibleForTesting
  static Map<String, dynamic> clientCulturaLocalToRemote(
    Map<String, Object?> row,
  ) {
    return _withoutNulls({
      'id': row['id'],
      'user_id': row['user_id'],
      'client_id': row['client_id'],
      'cultura': row['cultura'],
      'area_ha': row['area_ha'],
      'variedade': row['variedade'],
      'safra': row['safra'],
      'observacao': row['observacao'],
      'created_at': row['created_at'],
      'updated_at': row['updated_at'],
    });
  }

  @visibleForTesting
  static Map<String, dynamic> clientRemoteToLocal(Map<String, dynamic> row) {
    final now = DateTime.now().toIso8601String();
    final nome = _first(row, ['nome', 'name']) ?? '';
    final telefone = _first(row, ['telefone', 'phone']) ?? '';
    final cidade = _first(row, ['cidade', 'city']) ?? '';
    final uf = _first(row, ['uf', 'state']) ?? '';
    final documento = _first(row, ['documento', 'document']);

    return _withoutNulls({
      'id': row['id'],
      'user_id': row['user_id'] ?? '',
      'nome': nome,
      'documento': documento,
      'telefone': telefone,
      'email': row['email'],
      'cidade': cidade,
      'uf': uf,
      'foto_path': row['foto_path'],
      'observacoes': row['observacoes'],
      'data_nascimento': row['data_nascimento'],
      'cpf_cnpj': row['cpf_cnpj'] ?? documento,
      'area_total': _first(row, ['area_total', 'area_ha']),
      'tipo_propriedade': row['tipo_propriedade'],
      'sistema_irrigacao': row['sistema_irrigacao'],
      'solo_tipo': row['solo_tipo'],
      'regiao_agricola': row['regiao_agricola'],
      'safra_atual': row['safra_atual'],
      'usa_assistencia_tecnica': row['usa_assistencia_tecnica'],
      'tecnico_responsavel': row['tecnico_responsavel'],
      'ativo': row['ativo'] ?? 1,
      'created_at': row['created_at'] ?? now,
      'updated_at': row['updated_at'] ?? now,
      'deleted_at': row['deleted_at'],
      'sync_status': statusSynced,
    });
  }

  @visibleForTesting
  static Map<String, dynamic> farmRemoteToLocal(Map<String, dynamic> row) {
    final now = DateTime.now().toIso8601String();

    return _withoutNulls({
      'id': row['id'],
      'user_id': row['user_id'] ?? '',
      'cliente_id': _first(row, ['cliente_id', 'client_id']),
      'nome': _first(row, ['nome', 'name']) ?? '',
      'area_total': _first(row, ['area_total', 'area_ha']),
      'municipio': _first(row, ['municipio', 'city']),
      'uf': _first(row, ['uf', 'state']),
      'created_at': row['created_at'] ?? now,
      'updated_at': row['updated_at'] ?? now,
      'deleted_at': row['deleted_at'],
      'sync_status': statusSynced,
    });
  }

  @visibleForTesting
  static Map<String, dynamic> fieldRemoteToLocal(Map<String, dynamic> row) {
    final now = DateTime.now().toIso8601String();

    return _withoutNulls({
      'id': row['id'],
      'user_id': row['user_id'] ?? '',
      'fazenda_id': _first(row, ['fazenda_id', 'farm_id']),
      'codigo': row['codigo'],
      'nome': _first(row, ['nome', 'name']) ?? '',
      'area_produtiva': _first(row, ['area_produtiva', 'area_ha']),
      'bordadura_geo': _remoteGeometryToLocalString(
        _first(row, ['bordadura_geo', 'geometry']),
      ),
      'centro_geo': row['centro_geo'],
      'created_at': row['created_at'] ?? now,
      'updated_at': row['updated_at'] ?? now,
      'deleted_at': row['deleted_at'],
      'sync_status': statusSynced,
    });
  }

  @visibleForTesting
  static Map<String, dynamic> clientCulturaRemoteToLocal(
    Map<String, dynamic> row,
  ) {
    final now = DateTime.now().toIso8601String();

    return _withoutNulls({
      'id': row['id'],
      'user_id': row['user_id'] ?? '',
      'client_id': row['client_id'],
      'cultura': row['cultura'],
      'area_ha': row['area_ha'],
      'variedade': row['variedade'],
      'safra': row['safra'],
      'observacao': row['observacao'],
      'created_at': row['created_at'] ?? now,
      'updated_at': row['updated_at'] ?? now,
    });
  }

  static Object? _first(Map<String, dynamic> row, List<String> keys) {
    for (final key in keys) {
      final value = row[key];
      if (value != null) return value;
    }
    return null;
  }

  static DateTime? _parseDate(Object? value) {
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  static Object? _localGeometryToRemote(Object? value) {
    if (value is! String || value.isEmpty) return value;
    try {
      return jsonDecode(value);
    } catch (_) {
      return value;
    }
  }

  static String? _remoteGeometryToLocalString(Object? value) {
    if (value == null) return null;
    if (value is String) return value;
    return jsonEncode(value);
  }

  static Map<String, dynamic> _withoutNulls(Map<String, dynamic> data) {
    return Map<String, dynamic>.from(data)
      ..removeWhere((_, value) => value == null);
  }
}
