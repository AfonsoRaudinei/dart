import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/modules/agenda/domain/enums/event_status.dart';
import 'package:soloforte_app/modules/agenda/domain/use_cases/start_event_use_case.dart';
import '../helpers/fake_agenda_repository.dart';

void main() {
  late FakeAgendaRepository repo;
  late StartEventUseCase useCase;

  setUp(() {
    repo = FakeAgendaRepository();
    useCase = StartEventUseCase(repo);
  });

  // =========================================================================
  group('Happy Path', () {
    test('transiciona agendado → emAndamento', () async {
      final evento = makeEvent(status: EventStatus.agendado);

      final (:updatedEvent, :session) = await useCase.execute(
        event: evento,
        currentUserId: 'user-42',
      );

      expect(updatedEvent.status, equals(EventStatus.emAndamento));
    });

    test('cria VisitSession com eventoId correto', () async {
      final evento = makeEvent(id: 'evt-99', status: EventStatus.agendado);

      final (:updatedEvent, :session) = await useCase.execute(
        event: evento,
        currentUserId: 'user-1',
      );

      expect(session.eventoId, equals('evt-99'));
      expect(session.endAtReal, isNull); // sessão em aberto
    });

    test('evento.visitSessionId aponta para id da sessão criada', () async {
      final evento = makeEvent(status: EventStatus.agendado);

      final (:updatedEvent, :session) = await useCase.execute(
        event: evento,
        currentUserId: 'user-1',
      );

      expect(updatedEvent.visitSessionId, equals(session.id));
    });

    test('createdBy é o currentUserId fornecido', () async {
      final evento = makeEvent(status: EventStatus.agendado);

      final (:updatedEvent, :session) = await useCase.execute(
        event: evento,
        currentUserId: 'consultor-7',
      );

      expect(session.createdBy, equals('consultor-7'));
    });

    test('persiste evento atualizado e sessão no repositório', () async {
      final evento = makeEvent(id: 'evt-1', status: EventStatus.agendado);

      final (:updatedEvent, :session) = await useCase.execute(
        event: evento,
        currentUserId: 'user-1',
      );

      expect(repo.eventById('evt-1')?.status, equals(EventStatus.emAndamento));
      expect(repo.sessionById(session.id), isNotNull);
    });

    test('syncStatus do evento atualizado é pending', () async {
      final evento = makeEvent(status: EventStatus.agendado);

      final (:updatedEvent, :session) = await useCase.execute(
        event: evento,
        currentUserId: 'user-1',
      );

      expect(updatedEvent.syncStatus, equals('pending'));
    });
  });

  // =========================================================================
  group('Transição inválida', () {
    test('lança StateError ao tentar iniciar evento já emAndamento', () async {
      final evento = makeEvent(status: EventStatus.emAndamento);

      expect(
        () => useCase.execute(event: evento, currentUserId: 'u'),
        throwsA(isA<StateError>()),
      );
    });

    test('lança StateError ao tentar iniciar evento concluido', () async {
      final evento = makeEvent(status: EventStatus.concluido);

      expect(
        () => useCase.execute(event: evento, currentUserId: 'u'),
        throwsA(isA<StateError>()),
      );
    });

    test('lança StateError ao tentar iniciar evento cancelado', () async {
      final evento = makeEvent(status: EventStatus.cancelado);

      expect(
        () => useCase.execute(event: evento, currentUserId: 'u'),
        throwsA(isA<StateError>()),
      );
    });

    test('permite rollback de finalizando → emAndamento (regra explícita)', () async {
      // EventRules.canTransitionTo(finalizando, emAndamento) == true (rollback autorizado)
      final evento = makeEvent(status: EventStatus.finalizando);

      final (:updatedEvent, :session) = await useCase.execute(
        event: evento,
        currentUserId: 'u',
      );

      expect(updatedEvent.status, equals(EventStatus.emAndamento));
    });
  });

  // =========================================================================
  group('Invariantes', () {
    test('ID do evento original não muda após início', () async {
      final evento = makeEvent(id: 'evt-fixo', status: EventStatus.agendado);

      final (:updatedEvent, :session) = await useCase.execute(
        event: evento,
        currentUserId: 'u',
      );

      expect(updatedEvent.id, equals('evt-fixo'));
    });

    test('sessão é ativa (endAtReal nulo) logo após criação', () async {
      final evento = makeEvent(status: EventStatus.agendado);

      final (:updatedEvent, :session) = await useCase.execute(
        event: evento,
        currentUserId: 'u',
      );

      expect(session.isActive, isTrue);
    });

    test('repositório não é modificado quando transição falha', () async {
      final evento = makeEvent(id: 'evt-1', status: EventStatus.concluido);
      repo.seedEvents([evento]);

      try {
        await useCase.execute(event: evento, currentUserId: 'u');
      } catch (_) {}

      // Status não pode ter mudado
      expect(repo.eventById('evt-1')?.status, equals(EventStatus.concluido));
      expect(repo.sessions, isEmpty);
    });
  });
}
