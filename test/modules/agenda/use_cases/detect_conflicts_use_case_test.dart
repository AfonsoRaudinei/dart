import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/modules/agenda/domain/entities/event.dart';
import 'package:soloforte_app/modules/agenda/domain/enums/event_status.dart';
import 'package:soloforte_app/modules/agenda/domain/rules/event_rules.dart';
import '../helpers/fake_agenda_repository.dart';

// =============================================================================
// Helpers locais
// =============================================================================

/// Cria dois eventos que se sobrepõem por 1 hora no mesmo dia
({Event a, Event b}) _overlappingPair({
  String idA = 'evt-a',
  String idB = 'evt-b',
}) {
  final base = DateTime.now().add(const Duration(days: 1)).copyWith(
        hour: 10,
        minute: 0,
        second: 0,
        millisecond: 0,
        microsecond: 0,
      );

  final a = makeEvent(
    id: idA,
    dataInicio: base,
    dataFim: base.add(const Duration(hours: 3)),
  );
  final b = makeEvent(
    id: idB,
    dataInicio: base.add(const Duration(hours: 2)),
    dataFim: base.add(const Duration(hours: 5)),
  );
  return (a: a, b: b);
}

/// Dois eventos sem sobreposição (sequenciais)
({Event first, Event second}) _sequentialPair() {
  final base = DateTime.now().add(const Duration(days: 1)).copyWith(
        hour: 8,
        minute: 0,
        second: 0,
        millisecond: 0,
        microsecond: 0,
      );

  final first = makeEvent(
    id: 'seq-1',
    dataInicio: base,
    dataFim: base.add(const Duration(hours: 2)),
  );
  final second = makeEvent(
    id: 'seq-2',
    dataInicio: base.add(const Duration(hours: 2)),
    dataFim: base.add(const Duration(hours: 4)),
  );
  return (first: first, second: second);
}

// =============================================================================
// Testes de EventRules.detectConflicts
// =============================================================================

void main() {
  group('EventRules.detectConflicts', () {
    test('detecta sobreposição de intervalo entre dois eventos', () {
      final (:a, :b) = _overlappingPair();
      final conflicts = EventRules.detectConflicts(a, [b]);
      expect(conflicts.length, equals(1));
      expect(conflicts.first.id, equals('b' == b.id ? b.id : 'evt-b'));
    });

    test('não detecta conflito entre eventos sequenciais (adjacentes)', () {
      final (:first, :second) = _sequentialPair();
      final conflicts = EventRules.detectConflicts(first, [second]);
      expect(conflicts, isEmpty);
    });

    test('ignora o próprio evento na detecção (mesmo ID)', () {
      final (:a, :b) = _overlappingPair(idA: 'same', idB: 'same');
      final conflicts = EventRules.detectConflicts(a, [a]);
      expect(conflicts, isEmpty);
    });

    test('ignora eventos com status concluido', () {
      final (:a, :b) = _overlappingPair();
      final concluido = b.copyWith(status: EventStatus.concluido);
      final conflicts = EventRules.detectConflicts(a, [concluido]);
      expect(conflicts, isEmpty);
    });

    test('ignora eventos com status cancelado', () {
      final (:a, :b) = _overlappingPair();
      final cancelado = b.copyWith(status: EventStatus.cancelado);
      final conflicts = EventRules.detectConflicts(a, [cancelado]);
      expect(conflicts, isEmpty);
    });

    test('detecta múltiplos conflitos simultâneos', () {
      final (:a, :b) = _overlappingPair(idA: 'nova', idB: 'b1');
      final c = b.copyWith(id: 'b2');
      final conflicts = EventRules.detectConflicts(a, [b, c]);
      expect(conflicts.length, equals(2));
    });

    test('retorna lista vazia quando não há eventos para comparar', () {
      final evento = makeEvent();
      final conflicts = EventRules.detectConflicts(evento, []);
      expect(conflicts, isEmpty);
    });
  });

  // =========================================================================
  group('EventRules.findTimeConflict', () {
    final baseDate = DateTime.now().add(const Duration(days: 1)).copyWith(
          hour: 0,
          minute: 0,
          second: 0,
          millisecond: 0,
          microsecond: 0,
        );

    Event eventWithTime({
      String id = 'evt-t',
      required int startHour,
      required int endHour,
      EventStatus status = EventStatus.agendado,
    }) {
      return makeEvent(
        id: id,
        dataInicio: baseDate,
        dataFim: baseDate.add(const Duration(hours: 8)),
        status: status,
      ).copyWith(
        startTime: TimeOfDay(hour: startHour, minute: 0),
        endTime: TimeOfDay(hour: endHour, minute: 0),
      );
    }

    test('detecta sobreposição de horário no mesmo dia', () {
      final existente = eventWithTime(startHour: 9, endHour: 11);
      final result = EventRules.findTimeConflict(
        currentEvents: [existente],
        date: baseDate,
        startTime: const TimeOfDay(hour: 10, minute: 0),
        endTime: const TimeOfDay(hour: 12, minute: 0),
      );
      expect(result, isNotNull);
      expect(result!.id, equals('evt-t'));
    });

    test('não detecta conflito em dias diferentes', () {
      final existente = eventWithTime(startHour: 9, endHour: 11);
      final result = EventRules.findTimeConflict(
        currentEvents: [existente],
        date: baseDate.add(const Duration(days: 1)), // dia diferente
        startTime: const TimeOfDay(hour: 10, minute: 0),
        endTime: const TimeOfDay(hour: 12, minute: 0),
      );
      expect(result, isNull);
    });

    test('ignora evento cancelado no conflito de horário', () {
      final cancelado = eventWithTime(
        startHour: 9,
        endHour: 11,
        status: EventStatus.cancelado,
      );
      final result = EventRules.findTimeConflict(
        currentEvents: [cancelado],
        date: baseDate,
        startTime: const TimeOfDay(hour: 10, minute: 0),
        endTime: const TimeOfDay(hour: 12, minute: 0),
      );
      expect(result, isNull);
    });

    test('ignora evento concluido no conflito de horário', () {
      final concluido = eventWithTime(
        startHour: 9,
        endHour: 11,
        status: EventStatus.concluido,
      );
      final result = EventRules.findTimeConflict(
        currentEvents: [concluido],
        date: baseDate,
        startTime: const TimeOfDay(hour: 10, minute: 0),
        endTime: const TimeOfDay(hour: 12, minute: 0),
      );
      expect(result, isNull);
    });

    test('excludeEventId exclui o próprio evento da verificação', () {
      final existente =
          eventWithTime(id: 'editando', startHour: 9, endHour: 11);
      final result = EventRules.findTimeConflict(
        currentEvents: [existente],
        date: baseDate,
        startTime: const TimeOfDay(hour: 10, minute: 0),
        endTime: const TimeOfDay(hour: 12, minute: 0),
        excludeEventId: 'editando',
      );
      expect(result, isNull);
    });

    test('ignora eventos sem startTime/endTime definidos', () {
      final semHorario = makeEvent(
        dataInicio: baseDate,
        dataFim: baseDate.add(const Duration(hours: 8)),
      );
      // sem startTime/endTime → não deve acusar conflito
      final result = EventRules.findTimeConflict(
        currentEvents: [semHorario],
        date: baseDate,
        startTime: const TimeOfDay(hour: 10, minute: 0),
        endTime: const TimeOfDay(hour: 12, minute: 0),
      );
      expect(result, isNull);
    });

    test('retorna null quando lista de eventos está vazia', () {
      final result = EventRules.findTimeConflict(
        currentEvents: [],
        date: baseDate,
        startTime: const TimeOfDay(hour: 9, minute: 0),
        endTime: const TimeOfDay(hour: 11, minute: 0),
      );
      expect(result, isNull);
    });
  });

  // =========================================================================
  group('Event.hasConflictWith — método da entidade', () {
    test('retorna false para o mesmo evento (ID igual)', () {
      final a = makeEvent(id: 'same');
      expect(a.hasConflictWith(a), isFalse);
    });

    test('retorna true para eventos que se sobrepõem', () {
      final (:a, :b) = _overlappingPair();
      expect(a.hasConflictWith(b), isTrue);
    });

    test('retorna false para eventos sequenciais (fim == início do próximo)', () {
      final (:first, :second) = _sequentialPair();
      expect(first.hasConflictWith(second), isFalse);
    });
  });
}
