import 'package:soloforte_app/core/contracts/i_occurrence_access_reader.dart';
import 'package:soloforte_app/core/contracts/i_occurrence_read.dart';
import 'package:soloforte_app/core/contracts/i_producer_visit_calendar.dart';
import 'package:soloforte_app/core/services/sync_status_contract.dart';
import 'package:soloforte_app/core/session/local_session_identity.dart';
import 'package:uuid/uuid.dart';

import '../data/producer_visit_confirmation_store.dart';
import '../data/services/producer_visit_confirmation_sync.dart';

class ProducerVisitCalendarAdapter implements IProducerVisitCalendar {
  ProducerVisitCalendarAdapter({
    required ProducerVisitConfirmationStore store,
    required IOccurrenceRead occurrences,
    required IOccurrenceAccessReader access,
    ProducerVisitConfirmationSync? sync,
  }) : _store = store,
       _occurrences = occurrences,
       _access = access,
       _sync = sync;

  final ProducerVisitConfirmationStore _store;
  final IOccurrenceRead _occurrences;
  final IOccurrenceAccessReader _access;
  final ProducerVisitConfirmationSync? _sync;

  @override
  Future<void> confirmVisit(ProducerVisitConfirmationInput input) async {
    final existing = await _store.findBySession(input.sessionId);
    if (existing != null) return;

    final userId = LocalSessionIdentity.resolveUserId();
    final row = ProducerVisitConfirmationRow(
      id: const Uuid().v4(),
      sessionId: input.sessionId,
      clientId: input.clientId,
      consultorUserId: userId,
      confirmedAt: DateTime.now().toUtc(),
      visitedAt: input.visitedAt.toUtc(),
      farmName: _name(input.farmName),
      fieldName: _name(input.fieldName),
      syncStatus: SyncStatusContract.pendingSync,
      userId: userId,
    );
    await _store.save(row);
    await _sync?.pushPending();
  }

  @override
  Future<bool> isConfirmed(String sessionId) async {
    final row = await _store.findBySession(sessionId);
    return row != null;
  }

  @override
  Future<List<ProducerVisitCalendarEntry>> listForProducer() async {
    try {
      await _sync?.pull();
    } catch (_) {}

    final clientIds = await _access.loadActiveClientIds();
    final rows = await _store.listByClients(clientIds);
    final entries = <ProducerVisitCalendarEntry>[];
    for (final row in rows) {
      final occurrences = await _occurrences.getAuthorizedBySessionId(
        row.sessionId,
        clientIds,
      );
      final farm = _name(row.farmName) ?? 'Fazenda';
      final field = _name(row.fieldName) ?? 'Talhão';
      entries.add(
        ProducerVisitCalendarEntry(
          sessionId: row.sessionId,
          clientId: row.clientId,
          visitedAt: row.visitedAt.toLocal(),
          confirmedAt: row.confirmedAt.toLocal(),
          farmName: farm,
          fieldName: field,
          occurrences: [
            for (final occurrence in occurrences)
              ProducerVisitOccurrenceLine(
                id: occurrence.id,
                label: _occurrenceLabel(occurrence, field, farm),
              ),
          ],
        ),
      );
    }
    return entries;
  }
}

String? _name(String? value) {
  final trimmed = value?.trim() ?? '';
  if (trimmed.isEmpty || trimmed == '…') return null;
  if (trimmed == 'Fazenda não encontrada' ||
      trimmed == 'Talhão não encontrado') {
    return null;
  }
  return trimmed;
}

String _occurrenceLabel(
  OccurrenceSummary occurrence,
  String fieldName,
  String farmName,
) {
  final description = occurrence.description.trim();
  final title = description.isEmpty ? occurrence.type : description;
  return '$title · $fieldName · $farmName';
}
