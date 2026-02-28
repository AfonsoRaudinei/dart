import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/modules/agenda/domain/enums/event_status.dart';
import 'package:soloforte_app/modules/agenda/domain/enums/event_type.dart';
import 'package:soloforte_app/modules/agenda/domain/use_cases/create_event_use_case.dart';
import '../helpers/fake_agenda_repository.dart';
import '../helpers/fake_notification_service.dart';

void main() {
  late FakeAgendaRepository repo;
  late FakeAgendaNotificationService notifService;
  late CreateEventUseCase useCase;

  // Datas auxiliares — sempre no futuro
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
    useCase = CreateEventUseCase(repo, notifService);
  });

  // =========================================================================
  group('Happy Path', () {
    test('cria evento com status agendado e persiste no repositório', () async {
      final (:event, :conflicts) = await useCase.execute(
        tipo: EventType.visitaTecnica,
        clienteId: 'cli-1',
        titulo: 'Visita Técnica Alfa',
        dataInicioPlanejada: baseInicio,
        dataFimPlanejada: baseFim,
        currentEvents: [],
      );

      expect(event.status, equals(EventStatus.agendado));
      expect(event.titulo, equals('Visita Técnica Alfa'));
      expect(event.clienteId, equals('cli-1'));
      expect(event.id, isNotEmpty);
      expect(repo.eventById(event.id), isNotNull);
    });

    test('cada chamada gera ID único', () async {
      final r1 = await useCase.execute(
        tipo: EventType.visitaTecnica,
        clienteId: 'cli-1',
        titulo: 'Evento A',
        dataInicioPlanejada: baseInicio,
        dataFimPlanejada: baseFim,
        currentEvents: [],
      );
      final r2 = await useCase.execute(
        tipo: EventType.consultoria,
        clienteId: 'cli-1',
        titulo: 'Evento B',
        dataInicioPlanejada: baseInicio.add(const Duration(days: 1)),
        dataFimPlanejada: baseFim.add(const Duration(days: 1)),
        currentEvents: [],
      );

      expect(r1.event.id, isNot(equals(r2.event.id)));
    });

    test('retorna lista vazia de conflitos quando não há sobreposição', () async {
      final outro = makeEvent(
        id: 'evt-existente',
        dataInicio: baseInicio.subtract(const Duration(days: 2)),
        dataFim: baseInicio.subtract(const Duration(days: 1)),
      );

      final (:event, :conflicts) = await useCase.execute(
        tipo: EventType.visitaTecnica,
        clienteId: 'cli-1',
        titulo: 'Novo Evento',
        dataInicioPlanejada: baseInicio,
        dataFimPlanejada: baseFim,
        currentEvents: [outro],
      );

      expect(conflicts, isEmpty);
    });

    test('detecta conflito de data/hora mas NÃO bloqueia (sem startTime)', () async {
      final sobreposicao = makeEvent(
        id: 'evt-overlap',
        dataInicio: baseInicio,
        dataFim: baseFim,
      );

      final (:event, :conflicts) = await useCase.execute(
        tipo: EventType.visitaTecnica,
        clienteId: 'cli-1',
        titulo: 'Evento Conflitante',
        dataInicioPlanejada: baseInicio,
        dataFimPlanejada: baseFim,
        currentEvents: [sobreposicao],
      );

      // Cria o evento mesmo com conflito de data (aviso, não erro)
      expect(event.id, isNotEmpty);
      expect(conflicts.length, equals(1));
      expect(conflicts.first.id, equals('evt-overlap'));
    });
  });

  // =========================================================================
  group('Validação de Datas', () {
    test('lança ArgumentError quando dataFim < dataInicio', () async {
      expect(
        () => useCase.execute(
          tipo: EventType.visitaTecnica,
          clienteId: 'cli-1',
          titulo: 'Evento Inválido',
          dataInicioPlanejada: baseFim, // invertido
          dataFimPlanejada: baseInicio,
          currentEvents: [],
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('lança ArgumentError quando dataFim == dataInicio', () async {
      expect(
        () => useCase.execute(
          tipo: EventType.visitaTecnica,
          clienteId: 'cli-1',
          titulo: 'Evento Igual',
          dataInicioPlanejada: baseInicio,
          dataFimPlanejada: baseInicio,
          currentEvents: [],
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('lança ArgumentError quando duração < 5 minutos', () async {
      expect(
        () => useCase.execute(
          tipo: EventType.visitaTecnica,
          clienteId: 'cli-1',
          titulo: 'Evento Curto',
          dataInicioPlanejada: baseInicio,
          dataFimPlanejada: baseInicio.add(const Duration(minutes: 3)),
          currentEvents: [],
        ),
        throwsA(isA<ArgumentError>()),
      );
    });
  });

  // =========================================================================
  group('Validação de Título', () {
    test('lança ArgumentError para título vazio', () async {
      expect(
        () => useCase.execute(
          tipo: EventType.visitaTecnica,
          clienteId: 'cli-1',
          titulo: '',
          dataInicioPlanejada: baseInicio,
          dataFimPlanejada: baseFim,
          currentEvents: [],
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('lança ArgumentError para título com menos de 3 caracteres', () async {
      expect(
        () => useCase.execute(
          tipo: EventType.visitaTecnica,
          clienteId: 'cli-1',
          titulo: 'AB',
          dataInicioPlanejada: baseInicio,
          dataFimPlanejada: baseFim,
          currentEvents: [],
        ),
        throwsA(isA<ArgumentError>()),
      );
    });
  });

  // =========================================================================
  group('Conflito de Horário (startTime + endTime)', () {
    test('lança StateError quando horário se sobrepõe ao de outro evento', () async {
      final existente = makeEvent(
        id: 'evt-blocker',
        dataInicio: baseInicio,
        dataFim: baseFim,
      );
      // Mesmo dia, mesmo horário

      expect(
        () => useCase.execute(
          tipo: EventType.visitaTecnica,
          clienteId: 'cli-1',
          titulo: 'Novo Conflitante',
          dataInicioPlanejada: baseInicio,
          dataFimPlanejada: baseFim,
          startTime: const TimeOfDay(hour: 9, minute: 0),
          endTime: const TimeOfDay(hour: 11, minute: 0),
          currentEvents: [
            existente.copyWith(
              startTime: const TimeOfDay(hour: 9, minute: 0),
              endTime: const TimeOfDay(hour: 11, minute: 0),
            ),
          ],
        ),
        throwsA(isA<StateError>()),
      );
    });
  });

  // =========================================================================
  group('Invariantes de Estado', () {
    test('evento não é persistido quando validação falha', () async {
      try {
        await useCase.execute(
          tipo: EventType.visitaTecnica,
          clienteId: 'cli-1',
          titulo: 'XX', // inválido
          dataInicioPlanejada: baseInicio,
          dataFimPlanejada: baseFim,
          currentEvents: [],
        );
      } catch (_) {}

      expect(repo.events, isEmpty);
    });

    test('syncStatus inicial é pending', () async {
      final (:event, :conflicts) = await useCase.execute(
        tipo: EventType.visitaTecnica,
        clienteId: 'cli-1',
        titulo: 'Evento Sync',
        dataInicioPlanejada: baseInicio,
        dataFimPlanejada: baseFim,
        currentEvents: [],
      );

      expect(event.syncStatus, equals('pending'));
    });
  });
}
