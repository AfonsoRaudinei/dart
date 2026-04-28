import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/models/drawing_models.dart';

/// Sincronização remota de [DrawingFeature] via Supabase.
///
/// Tabela: `drawings` — schema aprovado ADR-027/PROMPT-04.
/// Colunas remotas: id, user_id, geometry (JSONB), properties (JSONB),
///                  deleted_at, created_at, updated_at.
///
/// [sync_status] NÃO existe na tabela remota — é controle local (SQLite) apenas.
/// Padrão: offline-first idêntico a MarketingCaseRepositoryImpl.
class DrawingRemoteStore {
  final SupabaseClient _supabase;

  DrawingRemoteStore({SupabaseClient? supabase})
      : _supabase = supabase ?? Supabase.instance.client;

  /// PUSH — upsert idempotente com [onConflict: 'id'].
  ///
  /// Se o registro já existe no Supabase → atualiza.
  /// Se não existe → insere.
  /// [sync_status] NÃO é enviado — esse campo é controle local apenas.
  Future<void> push(DrawingFeature feature) async {
    try {
      await _supabase.from('drawings').upsert(
        _toRemoteRow(feature),
        onConflict: 'id',
      );
    } catch (e, st) {
      debugPrint('DrawingRemoteStore.push error [id=${feature.id}]: $e\n$st');
      rethrow;
    }
  }

  /// PULL — busca apenas registros atualizados após [lastSync].
  ///
  /// Usa índice composto (user_id, updated_at DESC) da tabela remota.
  /// [lastSync] null → primeiro sync, traz todos os registros do usuário.
  /// Registros soft-deleted (deleted_at NOT NULL) são incluídos
  /// para que o local possa aplicar a deleção.
  Future<List<DrawingFeature>> fetchUpdates(DateTime? lastSync) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null || userId.isEmpty) return [];

      var query = _supabase
          .from('drawings')
          .select(
            'id, geometry, properties, deleted_at, created_at, updated_at',
          )
          .eq('user_id', userId);

      if (lastSync != null) {
        query = query.gt('updated_at', lastSync.toUtc().toIso8601String());
      }

      final rows = await query.order('updated_at', ascending: false);

      return rows
          .map((row) => _fromRemoteRow(row))
          .whereType<DrawingFeature>()
          .toList();
    } catch (e, st) {
      debugPrint('DrawingRemoteStore.fetchUpdates error: $e\n$st');
      rethrow;
    }
  }

  // ─── Serialização ──────────────────────────────────────────────────────────

  /// Monta o payload remoto — exclui [sync_status] (controle local).
  Map<String, dynamic> _toRemoteRow(DrawingFeature f) {
    final p = f.properties;
    return {
      'id': f.id,
      'user_id': _supabase.auth.currentUser!.id,
      'geometry': f.geometry.toJson(),
      'properties': {
        'nome': p.nome,
        'tipo': p.tipo.toJson(),
        'origem': p.origem.toJson(),
        'status': p.status.toJson(),
        'autor_id': p.autorId,
        'autor_tipo': p.autorTipo.toJson(),
        'operacao_id': p.operacaoId,
        'cliente_id': p.clienteId,
        'fazenda_id': p.fazendaId,
        'area_ha': p.areaHa,
        'versao': p.versao,
        'ativo': p.ativo,
        'subtipo': p.subtipo,
        'raio_metros': p.raioMetros,
        'grupo': p.grupo,
        'cor': p.cor,
        'versao_anterior_id': p.versaoAnteriorId,
        'cultura': p.cultura,
        'safra': p.safra,
        'soil_sampling_scheme': p.soilSamplingScheme,
        'rec_by_nutrient': p.recByNutrient,
      },
      'deleted_at': null,
      'created_at': p.createdAt.toUtc().toIso8601String(),
      'updated_at': p.updatedAt.toUtc().toIso8601String(),
    };
  }

  /// Reconstrói [DrawingFeature] a partir de uma linha remota.
  /// Retorna null se a linha estiver corrompida — ignorada silenciosamente.
  DrawingFeature? _fromRemoteRow(Map<String, dynamic> row) {
    try {
      final rawGeometry = row['geometry'];
      final geometryMap = rawGeometry is String
          ? jsonDecode(rawGeometry) as Map<String, dynamic>
          : Map<String, dynamic>.from(rawGeometry as Map);

      final geometry = DrawingGeometry.fromJson(geometryMap);

      final rawProps = row['properties'];
      final props = rawProps is String
          ? jsonDecode(rawProps) as Map<String, dynamic>
          : Map<String, dynamic>.from(rawProps as Map);

      final recRaw = props['rec_by_nutrient'];
      final recByNutrient = recRaw is Map
          ? Map<String, double>.from(
              recRaw.map(
                (k, v) => MapEntry(k.toString(), (v as num).toDouble()),
              ),
            )
          : null;

      final properties = DrawingProperties(
        nome: props['nome'] as String,
        tipo: DrawingType.fromJson(props['tipo'] as String),
        origem: DrawingOrigin.fromJson(props['origem'] as String),
        status: DrawingStatus.fromJson(props['status'] as String),
        autorId: props['autor_id'] as String,
        autorTipo: AuthorType.fromJson(props['autor_tipo'] as String),
        operacaoId: props['operacao_id'] as String?,
        clienteId: props['cliente_id'] as String?,
        fazendaId: props['fazenda_id'] as String?,
        areaHa: (props['area_ha'] as num).toDouble(),
        versao: props['versao'] as int,
        ativo: props['ativo'] as bool,
        subtipo: props['subtipo'] as String?,
        raioMetros: props['raio_metros'] != null
            ? (props['raio_metros'] as num).toDouble()
            : null,
        grupo: props['grupo'] as String?,
        cor: props['cor'] as int?,
        versaoAnteriorId: props['versao_anterior_id'] as String?,
        cultura: props['cultura'] as String?,
        safra: props['safra'] as String?,
        soilSamplingScheme: props['soil_sampling_scheme'] as String?,
        recByNutrient: recByNutrient,
        syncStatus: SyncStatus.synced, // vindo do remoto = sempre synced
        createdAt: DateTime.parse(row['created_at'] as String),
        updatedAt: DateTime.parse(row['updated_at'] as String),
      );

      return DrawingFeature(
        id: row['id'] as String,
        geometry: geometry,
        properties: properties,
      );
    } catch (e, st) {
      debugPrint(
        'DrawingRemoteStore._fromRemoteRow parse error [id=${row['id']}]: $e\n$st',
      );
      return null;
    }
  }
}
