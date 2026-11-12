import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:soloforte_app/core/contracts/i_occurrence_access_reader.dart';
import 'package:soloforte_app/core/services/sync_status_contract.dart';
import 'package:soloforte_app/core/session/local_session_identity.dart';
import 'package:soloforte_app/core/utils/app_logger.dart';

import '../producer_visit_confirmation_store.dart';

class ProducerVisitConfirmationSync {
  ProducerVisitConfirmationSync(
    this._supabase,
    this._store,
    this._access,
  );

  final SupabaseClient _supabase;
  final ProducerVisitConfirmationStore _store;
  final IOccurrenceAccessReader _access;

  static const _table = 'visit_producer_confirmations';

  Future<void> pushPending() async {
    final pending = await _store.pending();
    for (final row in pending) {
      try {
        await _supabase.from(_table).upsert({
          'id': row.id,
          'visit_session_id': row.sessionId,
          'client_id': row.clientId,
          'consultor_user_id': row.consultorUserId,
          'confirmed_at': row.confirmedAt.toUtc().toIso8601String(),
          'visited_at': row.visitedAt.toUtc().toIso8601String(),
          'farm_name': row.farmName,
          'field_name': row.fieldName,
        });
        await _store.markSynced(row.id);
      } catch (error) {
        AppLogger.warning(
          'Falha ao enviar confirmação da visita ${row.sessionId}',
          tag: 'ProducerVisitConfirmation',
          error: error,
        );
      }
    }
  }

  Future<void> pull() async {
    final userId = LocalSessionIdentity.resolveUserId();
    if (userId.isEmpty) return;

    final clientIds = await _access.loadActiveClientIds();
    final rows = <Map<String, dynamic>>[];

    try {
      final own = await _supabase
          .from(_table)
          .select()
          .eq('consultor_user_id', userId);
      rows.addAll(own.map(Map<String, dynamic>.from));
    } catch (error) {
      AppLogger.warning(
        'Falha ao baixar confirmações do consultor',
        tag: 'ProducerVisitConfirmation',
        error: error,
      );
    }

    if (clientIds.isNotEmpty) {
      try {
        final shared = await _supabase
            .from(_table)
            .select()
            .inFilter('client_id', clientIds.toList());
        rows.addAll(shared.map(Map<String, dynamic>.from));
      } catch (error) {
        AppLogger.warning(
          'Falha ao baixar confirmações do produtor',
          tag: 'ProducerVisitConfirmation',
          error: error,
        );
      }
    }

    final seen = <String>{};
    for (final remote in rows) {
      final sessionId = remote['visit_session_id']?.toString() ?? '';
      if (sessionId.isEmpty || !seen.add(sessionId)) continue;
      await _store.save(
        ProducerVisitConfirmationRow(
          id: remote['id'].toString(),
          sessionId: sessionId,
          clientId: remote['client_id'].toString(),
          consultorUserId: remote['consultor_user_id'].toString(),
          confirmedAt: DateTime.parse(remote['confirmed_at'].toString()),
          visitedAt: DateTime.parse(remote['visited_at'].toString()),
          farmName: remote['farm_name']?.toString(),
          fieldName: remote['field_name']?.toString(),
          syncStatus: SyncStatusContract.synced,
          userId: userId,
        ),
      );
    }
  }
}
