import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/services/sync_retry_runner.dart';
import '../core/session/local_session_identity.dart';
import '../core/utils/app_logger.dart';
import '../modules/drawing/data/data_sources/drawing_local_store.dart';
import '../modules/drawing/data/data_sources/drawing_remote_store.dart';
import '../modules/produtor/data/producer_link_repository.dart';

/// Baixa desenhos do consultor concedidos por vínculo (`share_fields`) para o
/// SQLite local do produtor — alimenta [DrawingLayerWidget] offline.
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

    final clientIds = await _linkRepository.loadAuthorizedClientIdsForDrawings();
    if (clientIds.isEmpty) return;

    var pulled = 0;
    for (final clientId in clientIds) {
      try {
        final rows = await SyncRetryRunner.execute(
          operation: () => _client
              .from('drawings')
              .select(
                'id, geometry, properties, deleted_at, created_at, updated_at',
              )
              .eq('properties->>cliente_id', clientId)
              .order('updated_at', ascending: false),
          tag: 'ProducerLinkedDrawingSync',
          stage: 'drawing_pull_linked_client',
          entityId: clientId,
        );
        for (final raw in rows as List) {
          final row = Map<String, dynamic>.from(raw as Map);
          if (row['deleted_at'] != null) {
            final id = row['id'] as String?;
            if (id != null && id.isNotEmpty) {
              await _localStore.delete(id);
            }
            continue;
          }
          final feature = _remoteStore.featureFromRemoteRow(row);
          await _localStore.insert(feature);
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
