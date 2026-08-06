import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/core/services/sync_status_contract.dart';
import 'package:soloforte_app/modules/agenda/domain/enums/event_status.dart';
import 'package:soloforte_app/modules/agenda/domain/use_cases/delete_event_use_case.dart';
import '../helpers/fake_agenda_repository.dart';

void main() {
  late FakeAgendaRepository repo;
  late DeleteEventUseCase useCase;

  setUp(() {
    repo = FakeAgendaRepository();
    useCase = DeleteEventUseCase(repo);
  });

  test('execute marca deleted_local e remove das listagens', () async {
    repo.seedEvents([
      makeEvent(id: 'evt-del-1', status: EventStatus.agendado),
    ]);

    await useCase.execute('evt-del-1');

    expect(
      SyncStatusContract.normalize(repo.eventById('evt-del-1')?.syncStatus),
      SyncStatusContract.deletedLocal,
    );
    expect(await repo.getAllEvents(), isEmpty);
    final pending = await repo.getPendingSyncEvents();
    expect(pending.map((e) => e.id), contains('evt-del-1'));
  });

  test('execute bloqueia exclusão com sessão ativa em andamento', () async {
    repo.seedEvents([
      makeEvent(
        id: 'evt-active',
        status: EventStatus.emAndamento,
        visitSessionId: 'sess-1',
      ),
    ]);

    expect(
      () => useCase.execute('evt-active'),
      throwsA(isA<StateError>()),
    );
  });
}
