import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/database/database_helper.dart';
import 'producer_link_models.dart';

final producerLinkRepositoryProvider = Provider<ProducerLinkRepository>((ref) {
  return ProducerLinkRepository(Supabase.instance.client);
});

abstract interface class ProducerLinkReader {
  Future<List<ProducerLinkedClient>> loadLinkedConsultantData();
}

class ProducerLinkRepository implements ProducerLinkReader {
  ProducerLinkRepository(this._client);

  final SupabaseClient _client;

  static const _linkTable = 'producer_client_links';
  static const linkedReportsTable = 'relatorios_v2';
  static const _tokenBytes = 6;

  Future<ProducerInvite> createInvite(String clientId) async {
    final userId = _currentUserId();
    final token = generateInviteToken();
    final expiresAt = DateTime.now().toUtc().add(const Duration(days: 7));

    final row = await _client
        .from(_linkTable)
        .insert({
          'consultor_user_id': userId,
          'client_id': clientId,
          'token_hash': hashToken(token),
          'status': 'pending',
          'expires_at': expiresAt.toIso8601String(),
        })
        .select()
        .single();

    await _cacheLink(ProducerClientLink.fromRemote(row), syncStatus: 0);
    return ProducerInvite(token: token, expiresAt: expiresAt);
  }

  Future<void> acceptToken(String token) async {
    final row = await _client.rpc(
      'accept_producer_link_token',
      params: {'p_token': normalizeToken(token)},
    );
    if (row is! Map) {
      throw Exception('Token inválido ou expirado.');
    }
    await _cacheLink(
      ProducerClientLink.fromRemote(Map<String, dynamic>.from(row)),
      syncStatus: 0,
    );
  }

  @override
  Future<List<ProducerLinkedClient>> loadLinkedConsultantData() async {
    final links = await _loadActiveLinks();
    final clients = <ProducerLinkedClient>[];

    for (final link in links) {
      final client = await _loadLinkedClient(link);
      if (client != null) clients.add(client);
    }

    return clients;
  }

  Future<List<String>> loadActiveProducerClientIds() async {
    final links = await _loadActiveLinks();
    return links.map((link) => link.clientId).toList(growable: false);
  }

  /// Resolucao de autorizacao para dados compartilhados: falha fechada.
  Future<List<String>> loadAuthorizedClientIds() async {
    final userId = _currentUserId();
    try {
      final rows = await _client
          .from(_linkTable)
          .select()
          .eq('producer_user_id', userId)
          .eq('status', 'active')
          .gt('expires_at', DateTime.now().toUtc().toIso8601String())
          .order('updated_at', ascending: false);
      final links = (rows as List)
          .map((row) => ProducerClientLink.fromRemote(row))
          .toList();
      for (final link in links) {
        await _cacheLink(link, syncStatus: 0);
      }
      await _removeStaleCachedProducerLinks(userId, links);
      return links.map((link) => link.clientId).toList(growable: false);
    } catch (_) {
      return const [];
    }
  }

  Future<List<ProducerClientLink>> _loadActiveLinks() async {
    final userId = _currentUserId();
    try {
      final rows = await _client
          .from(_linkTable)
          .select()
          .eq('producer_user_id', userId)
          .eq('status', 'active')
          .order('updated_at', ascending: false);
      final links = (rows as List)
          .map((row) => ProducerClientLink.fromRemote(row))
          .toList();
      for (final link in links) {
        await _cacheLink(link, syncStatus: 0);
      }
      await _removeStaleCachedProducerLinks(userId, links);
      return links;
    } catch (_) {
      return _loadCachedActiveLinks(userId);
    }
  }

  Future<ProducerLinkedClient?> _loadLinkedClient(
    ProducerClientLink link,
  ) async {
    final clientRows = await _client
        .from('clients')
        .select()
        .eq('id', link.clientId)
        .limit(1);
    if ((clientRows as List).isEmpty) return null;

    final client = Map<String, dynamic>.from(clientRows.first as Map);
    final farms = await _loadFarms(link.clientId);
    final reports = await _loadReports(link.clientId);

    return ProducerLinkedClient(
      link: link,
      name: (client['nome'] ?? client['name'] ?? 'Produtor') as String,
      phone: (client['telefone'] ?? client['phone']) as String?,
      email: client['email'] as String?,
      city: (client['cidade'] ?? client['city']) as String?,
      state: (client['uf'] ?? client['state']) as String?,
      farms: farms,
      reports: reports,
    );
  }

  Future<List<ProducerLinkedFarm>> _loadFarms(String clientId) async {
    final rows = await _client
        .from('farms')
        .select()
        .eq('cliente_id', clientId)
        .isFilter('deleted_at', null)
        .order('nome');

    final farms = <ProducerLinkedFarm>[];
    for (final row in rows as List) {
      final farm = Map<String, dynamic>.from(row as Map);
      final farmId = farm['id'] as String;
      farms.add(
        ProducerLinkedFarm(
          id: farmId,
          name: (farm['nome'] ?? farm['name'] ?? 'Fazenda') as String,
          city: (farm['municipio'] ?? farm['city']) as String?,
          state: (farm['uf'] ?? farm['state']) as String?,
          areaHa: _asDouble(farm['area_total'] ?? farm['area_ha']),
          fields: await _loadFields(farmId),
        ),
      );
    }
    return farms;
  }

  Future<List<ProducerLinkedField>> _loadFields(String farmId) async {
    final rows = await _client
        .from('fields')
        .select()
        .eq('fazenda_id', farmId)
        .isFilter('deleted_at', null)
        .order('nome');

    return (rows as List).map((row) {
      final field = Map<String, dynamic>.from(row as Map);
      return ProducerLinkedField(
        id: field['id'] as String,
        name: (field['nome'] ?? field['name'] ?? 'Talhão') as String,
        areaHa: _asDouble(field['area_produtiva'] ?? field['area_ha']),
      );
    }).toList();
  }

  Future<List<ProducerLinkedReport>> _loadReports(String clientId) async {
    try {
      final rows = await _client
          .from(linkedReportsTable)
          .select('id, client_id, titulo, created_at, deleted_at')
          .eq('client_id', clientId)
          .isFilter('deleted_at', null)
          .order('created_at', ascending: false);

      return (rows as List)
          .map((row) => reportFromRemote(Map<String, dynamic>.from(row as Map)))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  Future<void> _cacheLink(
    ProducerClientLink link, {
    required int syncStatus,
  }) async {
    final db = await DatabaseHelper.instance.database;
    await db.insert(
      _linkTable,
      link.toCache(syncStatus: syncStatus),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<ProducerClientLink>> _loadCachedActiveLinks(String userId) async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query(
      _linkTable,
      where: 'producer_user_id = ? AND status = ?',
      whereArgs: [userId, 'active'],
      orderBy: 'updated_at DESC',
    );
    final now = DateTime.now().toUtc();
    return rows
        .map(ProducerClientLink.fromCache)
        .where((link) => link.expiresAt.toUtc().isAfter(now))
        .toList();
  }

  Future<void> _removeStaleCachedProducerLinks(
    String userId,
    List<ProducerClientLink> remoteLinks,
  ) async {
    final db = await DatabaseHelper.instance.database;
    final activeIds = remoteLinks.map((link) => link.id).toSet();
    final cached = await db.query(
      _linkTable,
      columns: ['id'],
      where: 'producer_user_id = ? AND status = ?',
      whereArgs: [userId, 'active'],
    );
    for (final row in cached) {
      final id = row['id'] as String;
      if (!activeIds.contains(id)) {
        // Hard delete permitido: tabela é cache espelho do remoto (fonte da
        // verdade é o Supabase) — evicção de cache, não dado sincronizável.
        await db.delete(_linkTable, where: 'id = ?', whereArgs: [id]);
      }
    }
  }

  String _currentUserId() {
    final userId = _client.auth.currentUser?.id ?? '';
    if (userId.isEmpty) throw Exception('Usuário não autenticado.');
    return userId;
  }

  static String generateInviteToken({Random? random}) {
    final source = random ?? Random.secure();
    final bytes = List<int>.generate(_tokenBytes, (_) => source.nextInt(256));
    final hex = bytes
        .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
        .join()
        .toUpperCase();
    return 'SF-${hex.substring(0, 4)}-${hex.substring(4, 8)}-${hex.substring(8)}';
  }

  static String normalizeToken(String token) {
    return token.replaceAll(RegExp(r'\s+'), '').toUpperCase();
  }

  static String hashToken(String token) {
    final bytes = utf8.encode(normalizeToken(token));
    return sha256.convert(bytes).toString();
  }

  static ProducerLinkedReport reportFromRemote(Map<String, dynamic> report) {
    final title = (report['titulo'] as String?)?.trim();
    final createdAt = DateTime.parse(report['created_at'] as String).toLocal();
    return ProducerLinkedReport(
      id: report['id'] as String,
      title: title?.isNotEmpty == true ? title! : 'Relatório técnico',
      farmName: 'Criado em ${_formatDate(createdAt)}',
      createdAt: createdAt,
    );
  }

  static double _asDouble(Object? value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  static String _formatDate(DateTime value) {
    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    return '$day/$month/${value.year}';
  }
}
