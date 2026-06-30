import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/modules/agenda/domain/enums/event_status.dart';
import 'package:soloforte_app/modules/agenda/domain/enums/event_type.dart';
import 'package:soloforte_app/modules/agenda/domain/use_cases/cancel_event_use_case.dart';
import 'package:soloforte_app/modules/agenda/domain/use_cases/create_event_use_case.dart';
import '../helpers/fake_agenda_repository.dart';
import '../helpers/fake_notification_service.dart';

void main() {
  late FakeAgendaRepository repo;
  late FakeAgendaNotificationService notifService;
  late CreateEventUseCase createUseCase;
  late CancelEventUseCase cancelUseCase;

  final baseInicio = DateTime.now().add(const Duration(days: 1)).copyWith(
        hour: 9,
        minute: 0,
        second: 0,
        millisecond: 0,
        microsecond: 0,
      );
  final baseFim = baseInicio.add(const Duration(hours: 2));

  setUp(() {
    repo = FakeAgendaRepository();
    notifService = FakeAgendaNotificationService();
    createUseCase = CreateEventUseCase(repo, notifService);
    cancelUseCase = CancelEventUseCase(repo, notifService);
  });

  // =========================================================================
  group('CreateEventUseCase — agendamento de notificação', () {
    test('scheduleEventNotifications é chamado após criação bem-sucedida', () async {
      await createUseCase.execute(
        tipo: EventType.visitaTecnica,
        clienteId: 'cli-1',
        titulo: 'Evento com Notif',
        dataInicioPlanejada: baseInicio,
        dataFimPlanejada: baseFim,
        currentEvents: [],
      );

      expect(notifService.scheduledIds.length, equals(1));
    });

    test('notificação é agendada com o ID correto do evento criado', () async {
      final (:event, :conflicts) = await createUseCase.execute(
        tipo: EventType.visitaTecnica,
        clienteId: 'cli-1',
        titulo: 'Evento Notif ID',
        dataInicioPlanejada: baseInicio,
        dataFimPlanejada: baseFim,
        currentEvents: [],
      );

      expect(notifService.scheduledIds.first, equals(event.id));
    });

    test('cada evento criado gera exatamente 1 chamada de schedule', () async {
      for (var i = 0; i < 3; i++) {
        await createUseCase.execute(
          tipo: EventType.visitaTecnica,
          clienteId: 'cli-1',
          titulo: 'Evento $i',
          dataInicioPlanejada: baseInicio.add(Duration(days: i + 1)),
          dataFimPlanejada: baseFim.add(Duration(days: i + 1)),
          currentEvents: [],
        );
      }

      expect(notifService.scheduledIds.length, equals(3));
    });

    test('notificação NÃO é agendada quando criação falha (título inválido)', () async {
      try {
        await createUseCase.execute(
          tipo: EventType.visitaTecnica,
          clienteId: 'cli-1',
          titulo: 'XX', // inválido
          dataInicioPlanejada: baseInicio,
          dataFimPlanejada: baseFim,
          currentEvents: [],
        );
      } catch (_) {}

      expect(notifService.scheduledIds, isEmpty);
    });

    test('notificações de eventos distintos têm IDs distintos', () async {
      for (var i = 0; i < 2; i++) {
        await createUseCase.execute(
          tipo: EventType.visitaTecnica,
          clienteId: 'cli-1',
          titulo: 'Evento Distinto $i',
          dataInicioPlanejada: baseInicio.add(Duration(days: i + 1)),
          dataFimPlanejada: baseFim.add(Duration(days: i + 1)),
          currentEvents: [],
        );
      }

      final ids = notifService.scheduledIds;
      expect(ids.toSet().length, equals(ids.length)); // todos únicos
    });
  });

  // =========================================================================
  group('CancelEventUseCase — cancelamento de notificação', () {
    test('cancelEventNotifications é chamado com o ID do evento cancelado', () async {
      final evento = makeEvent(
        id: 'evt-cancel',
        status: EventStatus.agendado,
      );

      await cancelUseCase.execute(
        event: evento,
        sessions: [],
      );

      expect(notifService.cancelledIds.length, equals(1));
      expect(notifService.cancelledIds.first, equals('evt-cancel'));
    });

    test('cancelamento de notificação acontece mesmo sem sessão ativa', () async {
      final evento = makeEvent(
        id: 'evt-sem-sess',
        status: EventStatus.agendado,
        visitSessionId: null,
      );

      await cancelUseCase.execute(event: evento, sessions: []);

      expect(notifService.cancelledIds, contains('evt-sem-sess'));
    });

    test('cancelamento de notificação NÃO ocorre quando evento não pode ser cancelado', () async {
      final evento = makeEvent(status: EventStatus.concluido);

      try {
        await cancelUseCase.execute(event: evento, sessions: []);
      } catch (_) {}

      expect(notifService.cancelledIds, isEmpty);
    });
  });

  // =========================================================================
  group('Invariante — isolamento entre fakes', () {
    test('IDs agendados e cancelados são rastreados separadamente', () async {
      // Cria e depois cancela o mesmo evento
      final (:event, :conflicts) = await createUseCase.execute(
        tipo: EventType.visitaTecnica,
        clienteId: 'cli-1',
        titulo: 'Evento Ciclo',
        dataInicioPlanejada: baseInicio,
        dataFimPlanejada: baseFim,
        currentEvents: [],
      );

      await cancelUseCase.execute(
        event: event.copyWith(status: EventStatus.agendado),
        sessions: [],
      );

      expect(notifService.scheduledIds.length, equals(1));
      expect(notifService.cancelledIds.length, equals(1));
      // São o mesmo ID
      expect(notifService.scheduledIds.first, equals(notifService.cancelledIds.first));
    });
  });
}
