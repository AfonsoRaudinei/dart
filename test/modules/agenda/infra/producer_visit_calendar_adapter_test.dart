import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/core/contracts/i_occurrence_access_reader.dart';
import 'package:soloforte_app/core/contracts/i_occurrence_read.dart';
import 'package:soloforte_app/core/contracts/i_producer_visit_calendar.dart';
import 'package:soloforte_app/core/services/sync_status_contract.dart';
import 'package:soloforte_app/modules/agenda/data/producer_visit_confirmation_store.dart';
import 'package:soloforte_app/modules/agenda/infra/producer_visit_calendar_adapter.dart';

class _MemoryStore extends ProducerVisitConfirmationStore {
  final Map<String, ProducerVisitConfirmationRow> rows = {};

  _MemoryStore() : super(databaseHelper: null);

  @override
  Future<void> save(ProducerVisitConfirmationRow row) async {
    rows[row.sessionId] = row;
  }

  @override
  Future<ProducerVisitConfirmationRow?> findBySession(String sessionId) async {
    return rows[sessionId];
  }

  @override
  Future<List<ProducerVisitConfirmationRow>> listByClients(
    Set<String> clientIds,
  ) async {
    return rows.values
        .where(
          (row) =>
              clientIds.contains(row.clientId) &&
              row.syncStatus != SyncStatusContract.deletedLocal,
        )
        .toList();
  }

  @override
  Future<List<ProducerVisitConfirmationRow>> pending() async => const [];

  @override
  Future<void> markSynced(String id) async {}
}

class _Occurrences implements IOccurrenceRead {
  @override
  Future<List<OccurrenceSummary>> getBySessionId(String sessionId) async {
    return const [];
  }

  @override
  Future<List<OccurrenceSummary>> getAuthorizedBySessionId(
    String sessionId,
    Set<String> authorizedClientIds,
  ) async {
    if (sessionId != 'sess-1' || !authorizedClientIds.contains('cli-1')) {
      return const [];
    }
    return const [
      OccurrenceSummary(
        id: 'occ-1',
        type: 'doenca',
        description: 'Ferrugem',
      ),
    ];
  }
}

class _Access implements IOccurrenceAccessReader {
  @override
  Future<Set<String>> loadActiveClientIds() async => {'cli-1'};

  @override
  Future<Set<String>> loadActiveFieldIdsForOccurrences() async => const {};

  @override
  Future<Map<String, String>> loadLinkedClientNames() async => {};
}

void main() {
  test('visita só entra no calendário do produtor depois da confirmação', () async {
    final store = _MemoryStore();
    final calendar = ProducerVisitCalendarAdapter(
      store: store,
      occurrences: _Occurrences(),
      access: _Access(),
    );

    expect(await calendar.listForProducer(), isEmpty);

    await calendar.confirmVisit(
      ProducerVisitConfirmationInput(
        sessionId: 'sess-1',
        clientId: 'cli-1',
        visitedAt: DateTime.utc(2026, 11, 12, 11),
        farmName: 'Fazenda X',
        fieldName: 'Talhão X',
      ),
    );

    final entries = await calendar.listForProducer();
    expect(entries, hasLength(1));
    expect(entries.single.farmName, 'Fazenda X');
    expect(entries.single.fieldName, 'Talhão X');
    expect(entries.single.occurrences.single.label, 'Ferrugem · Talhão X · Fazenda X');
    expect(await calendar.isConfirmed('sess-1'), isTrue);

    await calendar.confirmVisit(
      ProducerVisitConfirmationInput(
        sessionId: 'sess-1',
        clientId: 'cli-1',
        visitedAt: DateTime.utc(2026, 11, 12, 11),
      ),
    );
    expect(store.rows, hasLength(1));
  });
}
