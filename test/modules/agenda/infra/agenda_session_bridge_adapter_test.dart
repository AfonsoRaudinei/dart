import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/core/services/sync_status_contract.dart';
import 'package:soloforte_app/modules/agenda/domain/enums/event_status.dart';
import 'package:soloforte_app/modules/agenda/infra/agenda_session_bridge_adapter.dart';
import '../helpers/fake_agenda_repository.dart';

void main() {
  late FakeAgendaRepository repo;
  late AgendaSessionBridgeAdapter adapter;

  setUp(() {
    repo = FakeAgendaRepository();
    adapter = AgendaSessionBridgeAdapter(repo);
  });

  test('linkSessionToEvent marca emAndamento e pending_sync', () async {
    repo.seedEvents([
      makeEvent(
        id: 'evt-bridge-1',
        status: EventStatus.agendado,
        syncStatus: SyncStatusContract.synced,
      ),
    ]);

    await adapter.linkSessionToEvent(
      agendaEventId: 'evt-bridge-1',
      sessionId: 'sess-bridge-1',
    );

    final saved = repo.eventById('evt-bridge-1');
    expect(saved?.status, EventStatus.emAndamento);
    expect(saved?.visitSessionId, 'sess-bridge-1');
    expect(saved?.syncStatus, SyncStatusContract.pendingSync);
  });

  test('markEventAsDone marca concluido e pending_sync', () async {
    repo.seedEvents([
      makeEvent(
        id: 'evt-bridge-2',
        status: EventStatus.emAndamento,
        visitSessionId: 'sess-bridge-2',
        syncStatus: SyncStatusContract.synced,
      ),
    ]);

    await adapter.markEventAsDone('sess-bridge-2');

    final saved = repo.eventById('evt-bridge-2');
    expect(saved?.status, EventStatus.concluido);
    expect(saved?.syncStatus, SyncStatusContract.pendingSync);
  });
}
