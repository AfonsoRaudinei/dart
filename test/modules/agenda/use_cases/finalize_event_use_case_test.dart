import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/modules/agenda/domain/enums/event_status.dart';
import 'package:soloforte_app/modules/agenda/domain/use_cases/finalize_event_use_case.dart';
import '../helpers/fake_agenda_repository.dart';

void main() {
  late FakeAgendaRepository repo;
  late FinalizeEventUseCase useCase;

  setUp(() {
    repo = FakeAgendaRepository();
    useCase = FinalizeEventUseCase(repo);
  });

  // =========================================================================
  group('Happy Path', () {
    test('transiciona emAndamento → finalizando', () async {
      final evento = makeEvent(status: EventStatus.emAndamento);

      final updated = await useCase.execute(evento);

      expect(updated.status, equals(EventStatus.finalizando));
    });

    test('persiste evento com status finalizando no repositório', () async {
      final evento = makeEvent(id: 'evt-1', status: EventStatus.emAndamento);
      repo.seedEvents([evento]);

      await useCase.execute(evento);

      expect(
        repo.eventById('evt-1')?.status,
        equals(EventStatus.finalizando),
      );
    });

    test('mantém id original após finalizar', () async {
      final evento = makeEvent(id: 'evt-xyz', status: EventStatus.emAndamento);

      final updated = await useCase.execute(evento);

      expect(updated.id, equals('evt-xyz'));
    });

    test('syncStatus é pending após finalizar', () async {
      final evento = makeEvent(status: EventStatus.emAndamento);

      final updated = await useCase.execute(evento);

      expect(updated.syncStatus, equals('pending'));
    });
  });

  // =========================================================================
  group('Transição inválida', () {
    test('lança StateError para evento agendado', () async {
      final evento = makeEvent(status: EventStatus.agendado);

      expect(
        () => useCase.execute(evento),
        throwsA(isA<StateError>()),
      );
    });

    test('lança StateError para evento concluido', () async {
      final evento = makeEvent(status: EventStatus.concluido);

      expect(
        () => useCase.execute(evento),
        throwsA(isA<StateError>()),
      );
    });

    test('lança StateError para evento cancelado', () async {
      final evento = makeEvent(status: EventStatus.cancelado);

      expect(
        () => useCase.execute(evento),
        throwsA(isA<StateError>()),
      );
    });

    test('lança StateError para evento finalizando (sem duplo finalize)', () async {
      final evento = makeEvent(status: EventStatus.finalizando);

      expect(
        () => useCase.execute(evento),
        throwsA(isA<StateError>()),
      );
    });
  });

  // =========================================================================
  group('Invariantes', () {
    test('repositório não é modificado quando transição falha', () async {
      final evento = makeEvent(id: 'evt-1', status: EventStatus.agendado);
      repo.seedEvents([evento]);

      try {
        await useCase.execute(evento);
      } catch (_) {}

      expect(repo.eventById('evt-1')?.status, equals(EventStatus.agendado));
    });

    test('não cria sessão durante finalização', () async {
      final evento = makeEvent(status: EventStatus.emAndamento);

      await useCase.execute(evento);

      expect(repo.sessions, isEmpty);
    });
  });
}
