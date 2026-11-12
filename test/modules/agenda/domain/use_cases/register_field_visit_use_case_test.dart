import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/core/contracts/i_agenda_session_bridge.dart';
import 'package:soloforte_app/core/contracts/i_visit_session_writer.dart';
import 'package:soloforte_app/core/contracts/visit_session_mirror_input.dart';
import 'package:soloforte_app/modules/agenda/domain/enums/event_status.dart';
import 'package:soloforte_app/modules/agenda/domain/use_cases/close_field_visit_use_case.dart';
import 'package:soloforte_app/modules/agenda/domain/use_cases/register_field_visit_use_case.dart';
import 'package:soloforte_app/modules/agenda/domain/use_cases/update_field_visit_place_use_case.dart';

import '../../helpers/fake_agenda_repository.dart';

class _RecordingWriter implements IVisitSessionWriter {
  String? finishedId;

  @override
  Future<void> createMirrorSession(VisitSessionMirrorInput input) async {}

  @override
  Future<void> finishMirrorSession(String sessionId, DateTime endTime) async {
    finishedId = sessionId;
  }
}

FieldVisitCheckIn _checkIn({DateTime? end}) {
  return FieldVisitCheckIn(
    sessionId: 'sess-campo',
    clientId: 'cli-1',
    farmId: 'farm-1',
    areaId: 'talhao-1',
    activityType: 'Visita técnica',
    startTime: DateTime(2026, 11, 12, 8),
    latitude: -15,
    longitude: -47,
    endTime: end,
  );
}

void main() {
  late FakeAgendaRepository repo;

  setUp(() {
    repo = FakeAgendaRepository();
  });

  test('check-in cria evento em andamento com o mesmo id da visita', () async {
    final created = await RegisterFieldVisitUseCase(
      repo,
    ).execute(_checkIn(), finished: false);

    expect(created, isNotNull);
    expect(created!.session.id, 'sess-campo');
    expect(created.event.visitSessionId, 'sess-campo');
    expect(created.event.status, EventStatus.emAndamento);
    expect(created.event.fazendaId, 'farm-1');
    expect(created.event.talhaoId, 'talhao-1');
    expect(created.session.endAtReal, isNull);

    final again = await RegisterFieldVisitUseCase(
      repo,
    ).execute(_checkIn(), finished: false);
    expect(again, isNull);
    expect(repo.events, hasLength(1));
  });

  test('visita já encerrada entra concluída e não recria evento', () async {
    final created = await RegisterFieldVisitUseCase(repo).execute(
      _checkIn(end: DateTime(2026, 11, 12, 10)),
      finished: true,
    );

    expect(created!.event.status, EventStatus.concluido);
    expect(created.session.endAtReal, DateTime(2026, 11, 12, 10));
    expect(created.session.id, 'sess-campo');

    final again = await RegisterFieldVisitUseCase(repo).execute(
      _checkIn(end: DateTime(2026, 11, 12, 10)),
      finished: true,
    );
    expect(again, isNull);
  });

  test('troca de fazenda limpa o talhão do evento', () async {
    await RegisterFieldVisitUseCase(repo).execute(_checkIn(), finished: false);

    final updated = await UpdateFieldVisitPlaceUseCase(repo).execute(
      sessionId: 'sess-campo',
      farmId: 'farm-2',
      clearArea: true,
    );

    expect(updated?.fazendaId, 'farm-2');
    expect(updated?.talhaoId, isNull);
  });

  test('encerrar visita conclui o evento e fecha a sessão', () async {
    await RegisterFieldVisitUseCase(repo).execute(_checkIn(), finished: false);
    final writer = _RecordingWriter();

    final closed = await CloseFieldVisitUseCase(
      repo,
      writer,
    ).execute(sessionId: 'sess-campo', endTime: DateTime(2026, 11, 12, 11));

    expect(closed?.event.status, EventStatus.concluido);
    expect(closed?.session.endAtReal, isNotNull);
    expect(writer.finishedId, 'sess-campo');
  });
}
