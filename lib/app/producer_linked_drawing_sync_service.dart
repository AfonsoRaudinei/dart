import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/services/sync_retry_runner.dart';
import '../core/session/local_session_identity.dart';
import '../core/utils/app_logger.dart';
import '../modules/drawing/data/data_sources/drawing_local_store.dart';
import '../modules/drawing/data/data_sources/drawing_remote_store.dart';
import '../modules/drawing/domain/drawing_utils.dart';
import '../modules/drawing/domain/models/drawing_models.dart';
import '../modules/produtor/data/producer_link_repository.dart';

/// O que fazer com um desenho do consultor no SQLite deste aparelho.
enum LinkedDrawingWrite { leave, restoreOwner, insertMirror }

/// Não troca o `user_id` do consultor. Se o vínculo já tomou a linha,
/// devolve ao dono remoto. Sem linha local, grava uma cópia com outro id.
@visibleForTesting
LinkedDrawingWrite decideLinkedDrawingWrite({
  required String currentUserId,
  required String remoteOwnerId,
  required String? localOwnerId,
}) {
  final current = currentUserId.trim();
  final remote = remoteOwnerId.trim();
  final local = localOwnerId?.trim() ?? '';
  if (local.isEmpty) return LinkedDrawingWrite.insertMirror;
  if (remote.isNotEmpty && local == current && remote != current) {
    return LinkedDrawingWrite.restoreOwner;
  }
  return LinkedDrawingWrite.leave;
}

/// Um MultiPolygon compartilhado vira um desenho por parte.
/// Cada parte guarda o próprio id para o NDVI. Polígono único não muda.
@visibleForTesting
List<DrawingFeature> linkedMirrorSources(DrawingFeature feature) {
  final parts = DrawingUtils.explodeToPolygons(feature.geometry);
  if (parts.length <= 1) return [feature];
  final names = DrawingUtils.buildSequentialFieldNames(
    feature.properties.nome,
    parts.length,
  );
  return [
    for (var i = 0; i < parts.length; i++)
      DrawingFeature(
        id: '${feature.id}__parte_${i + 1}',
        geometry: parts[i],
        properties: feature.properties.copyWith(
          nome: names[i],
          areaHa: DrawingUtils.calculateGeometryArea(parts[i]),
        ),
      ),
  ];
}

/// Baixa desenhos do consultor concedidos por vínculo (`share_fields`).
///
/// A linha original continua do consultor. O produtor só ganha uma cópia
/// de leitura, com outro id, quando o aparelho ainda não tem o desenho.
class ProducerLinkedDrawingSyncService {
  ProducerLinkedDrawingSyncService({
    required SupabaseClient supabase,
    required ProducerLinkRepository linkRepository,
    DrawingLocalStore? localStore,
    DrawingRemoteStore? remoteStore,
  }) : _client = supabase,
       _linkRepository = linkRepository,
       _localStore = localStore ?? DrawingLocalStore(),
       _remoteStore = remoteStore ?? DrawingRemoteStore(supabase: supabase);

  final SupabaseClient _client;
  final ProducerLinkRepository _linkRepository;
  final DrawingLocalStore _localStore;
  final DrawingRemoteStore _remoteStore;

  Future<void> pullLinkedDrawings() async {
    final userId = LocalSessionIdentity.resolveUserId();
    if (userId.isEmpty) return;

    final clientIds = await _linkRepository
        .loadAuthorizedClientIdsForDrawings();
    if (clientIds.isEmpty) return;

    var pulled = 0;
    for (final clientId in clientIds) {
      try {
        final rows = await SyncRetryRunner.execute(
          operation: () => _client
              .from('drawings')
              .select(
                'id, user_id, geometry, properties, deleted_at, created_at, updated_at',
              )
              .eq('properties->>cliente_id', clientId)
              .order('updated_at', ascending: false),
          tag: 'ProducerLinkedDrawingSync',
          stage: 'drawing_pull_linked_client',
          entityId: clientId,
        );
        for (final raw in rows as List) {
          final row = Map<String, dynamic>.from(raw as Map);
          final id = (row['id'] as String?)?.trim() ?? '';
          if (id.isEmpty) continue;
          if (row['deleted_at'] != null) {
            await _localStore.deleteLinkedMirrorsForSource(id);
            continue;
          }
          final feature = _remoteStore.featureFromRemoteRow(row);
          final remoteOwner = (row['user_id'] as String?)?.trim() ?? '';
          final sources = linkedMirrorSources(feature);
          if (sources.length > 1) {
            await _localStore.deleteLinkedMirrorsForSource(feature.id);
          }
          for (final source in sources) {
            final action = decideLinkedDrawingWrite(
              currentUserId: userId,
              remoteOwnerId: remoteOwner,
              localOwnerId: await _localStore.ownerOf(source.id),
            );
            switch (action) {
              case LinkedDrawingWrite.leave:
                break;
              case LinkedDrawingWrite.restoreOwner:
                await _localStore.restoreDrawingOwner(
                  id: source.id,
                  ownerUserId: remoteOwner,
                );
              case LinkedDrawingWrite.insertMirror:
                await _localStore.insertLinkedMirror(source);
            }
          }
          pulled++;
        }
      } catch (error) {
        AppLogger.warning(
          'Falha ao baixar desenhos vinculados [client=$clientId]: $error',
          tag: 'ProducerLinkedDrawingSync',
          error: error,
        );
      }
    }

    if (pulled > 0) {
      AppLogger.debug(
        'Desenhos vinculados gravados localmente: $pulled',
        tag: 'ProducerLinkedDrawingSync',
      );
    }
  }
}
