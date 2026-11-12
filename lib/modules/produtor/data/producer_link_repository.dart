import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/contracts/i_producer_invite_writer.dart';
import '../../../core/database/database_helper.dart';
import '../../../core/session/local_session_identity.dart';
import 'linked_consultant_geometry.dart';
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

  Future<ProducerInvite> createInvite(
    String clientId, {
    ProducerShareSelection share = const ProducerShareSelection(),
  }) async {
    if (!share.hasAny) {
      throw Exception('Escolha ao menos um tipo de dado para compartilhar.');
    }
    // Convite exige JWT autenticado: LocalSessionIdentity.lastKnown não
    // basta — a RLS de insert compara auth.uid() com consultor_user_id.
    final userId = _authenticatedUserId();
    await _assertConsultorCanInvite(userId, clientId);

    final token = generateInviteToken();
    final expiresAt = DateTime.now().toUtc().add(const Duration(days: 7));

    try {
      final row = await _client
          .from(_linkTable)
          .insert({
            'consultor_user_id': userId,
            'client_id': clientId,
            'token_hash': hashToken(token),
            'status': 'pending',
            'expires_at': expiresAt.toIso8601String(),
            'share_farms': share.farms,
            'share_fields': share.fields,
            'share_occurrences': share.occurrences,
            'share_reports': share.reports,
          })
          .select()
          .single();

      await _cacheLink(ProducerClientLink.fromRemote(row), syncStatus: 0);
      return ProducerInvite(token: token, expiresAt: expiresAt);
    } on PostgrestException catch (error) {
      throw Exception(mapCreateInviteError(error));
    }
  }

  /// Garante sessão JWT + papel consultor + cliente remoto do próprio usuário.
  Future<void> _assertConsultorCanInvite(String userId, String clientId) async {
    final perfil = await _client
        .from('perfis')
        .select('role')
        .eq('id', userId)
        .maybeSingle();
    final role = (perfil?['role'] as String?)?.trim().toLowerCase();
    if (role != 'consultor') {
      throw Exception(
        'Seu perfil remoto não está como consultor. Atualize o perfil e tente novamente.',
      );
    }

    final remoteClient = await _client
        .from('clients')
        .select('id')
        .eq('id', clientId)
        .eq('user_id', userId)
        .isFilter('deleted_at', null)
        .maybeSingle();
    if (remoteClient == null) {
      throw Exception(
        'Cliente ainda não sincronizado com a nuvem. Toque em Sincronizar no menu e tente novamente.',
      );
    }
  }

  String _authenticatedUserId() {
    final userId = _client.auth.currentUser?.id.trim() ?? '';
    if (userId.isEmpty) {
      throw Exception(
        'Sessão expirada. Faça login novamente para gerar o token.',
      );
    }
    return userId;
  }

  @visibleForTesting
  static String mapCreateInviteError(PostgrestException error) {
    final code = (error.code ?? '').trim();
    final message = error.message.toLowerCase();

    if (code == '42501' || message.contains('row-level security')) {
      return 'Sem permissão para gerar o convite. Confirme que o cliente está sincronizado e que sua conta é de consultor.';
    }
    if (code == '23503' || message.contains('foreign key')) {
      return 'Cliente ainda não sincronizado com a nuvem. Toque em Sincronizar no menu e tente novamente.';
    }
    if (code == '23505' || message.contains('duplicate')) {
      return 'Já existe um convite pendente semelhante. Gere um novo token em instantes.';
    }
    if (message.contains('jwt') || message.contains('not authenticated')) {
      return 'Sessão expirada. Faça login novamente para gerar o token.';
    }
    return 'Não foi possível gerar o convite agora. Verifique a conexão e tente novamente.';
  }

  Future<void> acceptToken(String token) async {
    final normalized = normalizeToken(token);
    try {
      final row = await _client.rpc(
        'accept_producer_link_token',
        params: {'p_token': normalized},
      );
      final map = linkRowFromRpc(row);
      if (map == null) {
        throw Exception('Token inválido, expirado ou já utilizado.');
      }
      await _cacheLink(ProducerClientLink.fromRemote(map), syncStatus: 0);
    } on PostgrestException catch (error) {
      throw Exception(mapAcceptTokenError(error));
    }
  }

  @visibleForTesting
  static Map<String, dynamic>? linkRowFromRpc(Object? row) {
    if (row is Map) {
      return Map<String, dynamic>.from(row);
    }
    if (row is List && row.isNotEmpty && row.first is Map) {
      return Map<String, dynamic>.from(row.first as Map);
    }
    return null;
  }

  @visibleForTesting
  static String mapAcceptTokenError(PostgrestException error) {
    final details = (error.details ?? '').toString().toLowerCase();
    final message = error.message.toLowerCase();
    final combined = '$message $details';

    if (combined.contains('producer_role_required') ||
        combined.contains('share_role_required')) {
      return 'Esta conta precisa ser de produtor ou consultor para aceitar o convite.';
    }
    if (combined.contains('not_authenticated')) {
      return 'Sessão expirada. Faça login novamente e tente outra vez.';
    }
    if (combined.contains('self_link_not_allowed')) {
      return 'Este convite foi gerado pela mesma conta. Use a conta do produtor.';
    }
    if (combined.contains('invalid_or_expired_token')) {
      return 'Token inválido, expirado ou já utilizado.';
    }
    if (message.contains('jwt') || message.contains('not authenticated')) {
      return 'Sessão expirada. Faça login novamente e tente outra vez.';
    }
    return 'Não foi possível vincular agora. Verifique o código e a conexão.';
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

  /// Vínculo `active` libera leitura enquanto não for revogado.
  /// `expires_at` vale só para aceitar o token pendente.
  Future<List<String>> loadAuthorizedClientIds() async {
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
      return links
          .where((link) => link.share.occurrences)
          .map((link) => link.clientId)
          .toList(growable: false);
    } catch (_) {
      final cached = await _loadCachedActiveLinks(userId);
      return cached
          .where((link) => link.share.occurrences)
          .map((link) => link.clientId)
          .toList(growable: false);
    }
  }

  /// Nome da ficha do consultor para cada `client_id` ativo.
  Future<Map<String, String>> loadLinkedClientNames() async {
    final links = await _loadActiveLinks();
    final names = <String, String>{};
    for (final link in links) {
      if (!link.share.occurrences) continue;
      try {
        final rows = await _client
            .from('clients')
            .select('nome, name')
            .eq('id', link.clientId)
            .limit(1);
        if ((rows as List).isEmpty) continue;
        final row = Map<String, dynamic>.from(rows.first as Map);
        final name = ((row['nome'] ?? row['name']) as String?)?.trim() ?? '';
        if (name.isNotEmpty) names[link.clientId] = name;
      } catch (_) {
        continue;
      }
    }
    return names;
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
    ProducerLinkedClient? client;
    try {
      client = await _loadLinkedClientRemote(link);
    } catch (_) {
      client = await _loadLinkedClientLocal(link);
    }
    if (client == null) return null;
    return _enrichLinkedClientFromRemote(client, link);
  }

  Future<ProducerLinkedClient> _enrichLinkedClientFromRemote(
    ProducerLinkedClient client,
    ProducerClientLink link,
  ) async {
    var occurrences = client.occurrences;
    var reports = client.reports;
  // Painel do produtor relê o Supabase: tenta de novo se o primeiro
  // caminho (v. g. cache local) não trouxe dados compartilhados.
    if (link.share.occurrences && occurrences.isEmpty) {
      occurrences = await _loadOccurrences(link.clientId);
    }
    if (link.share.reports && reports.isEmpty) {
      reports = await _loadReports(link.clientId);
    }
    if (identical(occurrences, client.occurrences) &&
        identical(reports, client.reports)) {
      return client;
    }
    return ProducerLinkedClient(
      link: client.link,
      name: client.name,
      phone: client.phone,
      email: client.email,
      city: client.city,
      state: client.state,
      farms: client.farms,
      reports: reports,
      occurrences: occurrences,
    );
  }

  Future<ProducerLinkedClient?> _loadLinkedClientRemote(
    ProducerClientLink link,
  ) async {
    final clientRows = await _client
        .from('clients')
        .select()
        .eq('id', link.clientId)
        .limit(1);
    if ((clientRows as List).isEmpty) return null;

    final client = Map<String, dynamic>.from(clientRows.first as Map);
    final farms = link.share.farms || link.share.fields
        ? await _loadFarms(link.clientId, includeFields: link.share.fields)
        : <ProducerLinkedFarm>[];
    final reports = link.share.reports
        ? await _loadReports(link.clientId)
        : const <ProducerLinkedReport>[];
    final occurrences = link.share.occurrences
        ? await _loadOccurrences(link.clientId)
        : const <ProducerLinkedOccurrence>[];

    return ProducerLinkedClient(
      link: link,
      name: (client['nome'] ?? client['name'] ?? 'Produtor') as String,
      phone: (client['telefone'] ?? client['phone']) as String?,
      email: client['email'] as String?,
      city: (client['cidade'] ?? client['city']) as String?,
      state: (client['uf'] ?? client['state']) as String?,
      farms: farms,
      reports: reports,
      occurrences: occurrences,
    );
  }

  /// Colunas canônicas no PostgREST (`lat`/`long` legados quebram o select).
  static const linkedOccurrenceColumns =
      'id, category, type, description, created_at, latitude, longitude, '
      'deleted_at, client_id, field_id';

  Future<List<ProducerLinkedOccurrence>> _loadOccurrences(
    String clientId,
  ) async {
    try {
      final byClient = await _client
          .from('occurrences')
          .select(linkedOccurrenceColumns)
          .eq('client_id', clientId)
          .isFilter('deleted_at', null)
          .order('created_at', ascending: false)
          .limit(50);
      final clientRows = occurrenceRowsFromRemote(byClient);
      if (clientRows.isNotEmpty) return clientRows;

      final fieldIds = await _fieldIdsForLinkedClient(clientId);
      if (fieldIds.isEmpty) return const [];

      final byField = await _client
          .from('occurrences')
          .select(linkedOccurrenceColumns)
          .inFilter('field_id', fieldIds)
          .isFilter('deleted_at', null)
          .order('created_at', ascending: false)
          .limit(50);
      return occurrenceRowsFromRemote(byField);
    } catch (_) {
      return const [];
    }
  }

  @visibleForTesting
  static List<ProducerLinkedOccurrence> occurrenceRowsFromRemote(
    Object? rows,
  ) {
    return (rows as List? ?? const [])
        .map(
          (row) => occurrenceFromRemote(Map<String, dynamic>.from(row as Map)),
        )
        .whereType<ProducerLinkedOccurrence>()
        .toList(growable: false);
  }

  Future<List<String>> _fieldIdsForLinkedClient(String clientId) async {
    try {
      final farmRows = await _client
          .from('farms')
          .select('id')
          .eq('cliente_id', clientId)
          .isFilter('deleted_at', null);
      final farmIds = (farmRows as List)
          .map((row) => (row as Map)['id'] as String?)
          .whereType<String>()
          .where((id) => id.isNotEmpty)
          .toList(growable: false);
      if (farmIds.isEmpty) return const [];

      final fieldRows = await _client
          .from('fields')
          .select('id')
          .inFilter('fazenda_id', farmIds)
          .isFilter('deleted_at', null);
      return (fieldRows as List)
          .map((row) => (row as Map)['id'] as String?)
          .whereType<String>()
          .where((id) => id.isNotEmpty)
          .toList(growable: false);
    } catch (_) {
      return const [];
    }
  }

  /// Título legível da ocorrência do consultor, no nome do cliente vinculado.
  @visibleForTesting
  static ProducerLinkedOccurrence? occurrenceFromRemote(
    Map<String, dynamic> row,
  ) {
    final id = (row['id'] as String?)?.trim() ?? '';
    if (id.isEmpty || row['deleted_at'] != null) return null;
    final createdRaw = row['created_at'] as String?;
    final createdAt = createdRaw == null
        ? DateTime.now()
        : DateTime.tryParse(createdRaw)?.toLocal() ?? DateTime.now();
    return ProducerLinkedOccurrence(
      id: id,
      title: occurrenceTitle(row),
      createdAt: createdAt,
      latitude: _asDoubleOrNull(row['latitude'] ?? row['lat']),
      longitude: _asDoubleOrNull(row['longitude'] ?? row['long']),
    );
  }

  @visibleForTesting
  static String occurrenceTitle(Map<String, dynamic> row) {
    final description = (row['description'] as String?)?.trim() ?? '';
    if (description.isNotEmpty) {
      return description.length > 80
          ? '${description.substring(0, 79)}…'
          : description;
    }
    final category = (row['category'] as String?)?.trim().toLowerCase() ?? '';
    return _occurrenceCategoryLabel[category] ?? 'Ocorrência';
  }

  Future<List<ProducerLinkedFarm>> _loadFarms(
    String clientId, {
    required bool includeFields,
  }) async {
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
          fields: includeFields
              ? await _loadFields(farmId)
              : const <ProducerLinkedField>[],
        ),
      );
    }
    return farms;
  }

  Future<ProducerLinkedClient> _loadLinkedClientLocal(
    ProducerClientLink link,
  ) async {
    final userId = _currentUserId();
    final db = await DatabaseHelper.instance.database;
    final clientRows = await db.query(
      'clients',
      where: 'id = ? AND user_id = ? AND deleted_at IS NULL',
      whereArgs: [link.clientId, userId],
      limit: 1,
    );
    final includeFarms = link.share.farms || link.share.fields;
    final farmRows = includeFarms
        ? await db.query(
            'farms',
            where: 'cliente_id = ? AND user_id = ? AND deleted_at IS NULL',
            whereArgs: [link.clientId, userId],
            orderBy: 'nome',
          )
        : <Map<String, Object?>>[];
    final fieldRows = <Map<String, Object?>>[];
    if (link.share.fields) {
      for (final farm in farmRows) {
        final farmId = farm['id'] as String?;
        if (farmId == null || farmId.isEmpty) continue;
        fieldRows.addAll(
          await db.query(
            'fields',
            where: 'fazenda_id = ? AND user_id = ? AND deleted_at IS NULL',
            whereArgs: [farmId, userId],
            orderBy: 'nome',
          ),
        );
      }
    }
    return linkedClientFromLocalRows(
      link: link,
      clientRow: clientRows.isEmpty ? null : clientRows.first,
      farmRows: farmRows,
      fieldRows: fieldRows,
    );
  }

  /// Vínculo do produtor com a fazenda já salva no SQLite, sem rede.
  @visibleForTesting
  static ProducerLinkedClient linkedClientFromLocalRows({
    required ProducerClientLink link,
    Map<String, Object?>? clientRow,
    List<Map<String, Object?>> farmRows = const [],
    List<Map<String, Object?>> fieldRows = const [],
  }) {
    final name = (clientRow?['nome'] as String?)?.trim();
    final farms = <ProducerLinkedFarm>[];
    for (final farm in farmRows) {
      final farmId = farm['id'] as String?;
      if (farmId == null || farmId.isEmpty) continue;
      final fields = fieldRows
          .where((field) => field['fazenda_id'] == farmId)
          .map(
            (field) => ProducerLinkedField(
              id: field['id'] as String,
              name: (field['nome'] as String?)?.trim().isNotEmpty == true
                  ? (field['nome'] as String).trim()
                  : 'Talhão',
              areaHa: _asDouble(field['area_produtiva']),
              geometryJson: linkedFieldGeometryJson(field['bordadura_geo']),
            ),
          )
          .toList(growable: false);
      farms.add(
        ProducerLinkedFarm(
          id: farmId,
          name: (farm['nome'] as String?)?.trim().isNotEmpty == true
              ? (farm['nome'] as String).trim()
              : 'Fazenda',
          city: farm['municipio'] as String?,
          state: farm['uf'] as String?,
          areaHa: _asDouble(farm['area_total']),
          fields: fields,
        ),
      );
    }

    return ProducerLinkedClient(
      link: link,
      name: (name == null || name.isEmpty) ? 'Produtor' : name,
      phone: clientRow?['telefone'] as String?,
      email: clientRow?['email'] as String?,
      city: clientRow?['cidade'] as String?,
      state: clientRow?['uf'] as String?,
      farms: farms,
      reports: const [],
    );
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
        geometryJson: linkedFieldGeometryJson(
          field['bordadura_geo'] ?? field['geometry'],
        ),
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
    return rows.map(ProducerClientLink.fromCache).toList();
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
    final userId = LocalSessionIdentity.resolveUserId();
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

  static final RegExp _inviteTokenPattern = RegExp(
    r'SF-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{4}',
    caseSensitive: false,
  );

  /// Aceita o token puro ou a mensagem do WhatsApp com o código no final.
  static String normalizeToken(String token) {
    final trimmed = token.trim();
    if (trimmed.isEmpty) {
      throw const FormatException('Informe o código enviado pelo consultor.');
    }

    final directMatch = _inviteTokenPattern.firstMatch(trimmed);
    if (directMatch != null) {
      return directMatch.group(0)!.toUpperCase();
    }

    final compact = trimmed.replaceAll(RegExp(r'\s+'), '').toUpperCase();
    final compactMatch = _inviteTokenPattern.firstMatch(compact);
    if (compactMatch != null) {
      return compactMatch.group(0)!;
    }

    throw const FormatException(
      'Cole o código SF-XXXX-XXXX-XXXX ou a mensagem completa do consultor.',
    );
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

  static const _occurrenceCategoryLabel = <String, String>{
    'doenca': 'Doença',
    'doença': 'Doença',
    'insetos': 'Insetos',
    'pragas': 'Insetos',
    'daninhas': 'Ervas daninhas',
    'ervas_daninhas': 'Ervas daninhas',
    'nutricional': 'Nutrientes',
    'nutrientes': 'Nutrientes',
    'agua': 'Água',
    'água': 'Água',
    'amostra_solo': 'Amostra de solo',
    'plantio': 'Plantio',
    'area_visitada': 'Área visitada',
    'área visitada': 'Área visitada',
  };

  static double? _asDoubleOrNull(Object? value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
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
