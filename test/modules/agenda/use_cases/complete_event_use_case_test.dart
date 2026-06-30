import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/modules/agenda/domain/enums/event_status.dart';
import 'package:soloforte_app/modules/agenda/domain/use_cases/complete_event_use_case.dart';
import '../helpers/fake_agenda_repository.dart';

void main() {
  late FakeAgendaRepository repo;
  late CompleteEventUseCase useCase;

  setUp(() {
    repo = FakeAgendaRepository();
    useCase = CompleteEventUseCase(repo);
  });

  // =========================================================================
  group('Happy Path — sem sessão', () {
    test('transiciona finalizando → concluido sem sessão', () async {
      final evento = makeEvent(
        status: EventStatus.finalizando,
        visitSessionId: null,
      );

      final (:updatedEvent, :updatedSession) = await useCase.execute(
        event: evento,
        sessions: [],
      );

      expect(updatedEvent.status, equals(EventStatus.concluido));
      expect(updatedSession, isNull);
    });

    test('persiste evento concluido no repositório', () async {
      final evento = makeEvent(
        id: 'evt-1',
        status: EventStatus.finalizando,
        visitSessionId: null,
      );

      await useCase.execute(event: evento, sessions: []);

      expect(
        repo.eventById('evt-1')?.status,
        equals(EventStatus.concluido),
      );
    });
  });

  // =========================================================================
  group('Happy Path — com sessão', () {
    test('fecha sessão com endAtReal preenchido', () async {
      final sess = makeSession(id: 'sess-1', eventoId: 'evt-1');
      final evento = makeEvent(
        id: 'evt-1',
        status: EventStatus.finalizando,
        visitSessionId: 'sess-1',
      );

      final (:updatedEvent, :updatedSession) = await useCase.execute(
        event: evento,
        sessions: [sess],
      );

      expect(updatedSession, isNotNull);
      expect(updatedSession!.endAtReal, isNotNull);
      expect(updatedSession.isActive, isFalse);
    });

    test('duração calculada é maior que zero', () async {
      final sess = makeSession(
        id: 'sess-1',
        eventoId: 'evt-1',
        startAtReal: DateTime.now().subtract(const Duration(minutes: 45)),
      );
      final evento = makeEvent(
        id: 'evt-1',
        status: EventStatus.finalizando,
        visitSessionId: 'sess-1',
      );

      final (:updatedEvent, :updatedSession) = await useCase.execute(
        event: evento,
        sessions: [sess],
      );

      expect(updatedSession!.duracaoMin, greaterThan(0));
    });

    test('notasFinais é propagado para a sessão', () async {
      final sess = makeSession(id: 'sess-1', eventoId: 'evt-1');
      final evento = makeEvent(
        id: 'evt-1',
        status: EventStatus.finalizando,
        visitSessionId: 'sess-1',
      );

      final (:updatedEvent, :updatedSession) = await useCase.execute(
        event: evento,
        sessions: [sess],
        notasFinais: 'Solo com problemas de drenagem.',
      );

      expect(updatedSession!.notasFinais, equals('Solo com problemas de drenagem.'));
    });

    test('sessão atualizada é persistida no repositório', () async {
      final sess = makeSession(id: 'sess-1', eventoId: 'evt-1');
      final evento = makeEvent(
        id: 'evt-1',
        status: EventStatus.finalizando,
        visitSessionId: 'sess-1',
      );

      await useCase.execute(event: evento, sessions: [sess]);

      final sessNoRepo = repo.sessionById('sess-1');
      expect(sessNoRepo?.endAtReal, isNotNull);
    });
  });

  // =========================================================================
  group('Transição inválida', () {
    test('lança StateError para evento agendado', () async {
      final evento = makeEvent(status: EventStatus.agendado);

      expect(
        () => useCase.execute(event: evento, sessions: []),
        throwsA(isA<StateError>()),
      );
    });

    test('lança StateError para evento emAndamento', () async {
      final evento = makeEvent(status: EventStatus.emAndamento);

      expect(
        () => useCase.execute(event: evento, sessions: []),
        throwsA(isA<StateError>()),
      );
    });

    test('lança StateError para evento já concluido', () async {
      final evento = makeEvent(status: EventStatus.concluido);

      expect(
        () => useCase.execute(event: evento, sessions: []),
        throwsA(isA<StateError>()),
      );
    });

    test('lança StateError para evento cancelado', () async {
      final evento = makeEvent(status: EventStatus.cancelado);

      expect(
        () => useCase.execute(event: evento, sessions: []),
        throwsA(isA<StateError>()),
      );
    });
  });

  // =========================================================================
  group('Estado inválido — sessão', () {
    test('lança ArgumentError quando visitSessionId não encontrado na lista', () async {
      final evento = makeEvent(
        id: 'evt-1',
        status: EventStatus.finalizando,
        visitSessionId: 'sess-inexistente',
      );

      expect(
        () => useCase.execute(event: evento, sessions: []),
        throwsA(isA<ArgumentError>()),
      );
    });
  });

  // =========================================================================
  group('Invariantes', () {
    test('ID do evento não muda após conclusão', () async {
      final evento = makeEvent(
        id: 'evt-fixo',
        status: EventStatus.finalizando,
        visitSessionId: null,
      );

      final (:updatedEvent, :updatedSession) =
          await useCase.execute(event: evento, sessions: []);

      expect(updatedEvent.id, equals('evt-fixo'));
    });

    test('repositório não modificado quando transição falha', () async {
      final evento = makeEvent(id: 'evt-1', status: EventStatus.agendado);
      repo.seedEvents([evento]);

      try {
        await useCase.execute(event: evento, sessions: []);
      } catch (_) {}

      expect(repo.eventById('evt-1')?.status, equals(EventStatus.agendado));
    });
  });
}
