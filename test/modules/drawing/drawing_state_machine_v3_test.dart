/*
════════════════════════════════════════════════════════════════════
DRAWING STATE MACHINE V3 — EVENT SOURCING TESTS
════════════════════════════════════════════════════════════════════

FASE 1: EVENT MODEL TESTS
- Eventos com payload
- Histórico de eventos
- Replay function
- Time-travel debugging

════════════════════════════════════════════════════════════════════
*/

import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/modules/drawing/domain/drawing_state_machine_v3.dart';

void main() {
  group('🏭 DrawingStateMachineV3 — Event Sourcing (Fase 1)', () {
    late DrawingStateMachineV3 machine;

    setUp(() {
      machine = DrawingStateMachineV3();
    });

    // ═══════════════════════════════════════════════════════════════
    // FASE 1.1: EVENTOS COM PAYLOAD
    // ═══════════════════════════════════════════════════════════════

    group('📦 Event Model — Payload', () {
      test('DrawingEvent.selectTool deve criar evento com mode', () {
        final event = DrawingEvent.selectTool(DrawingMode.polygon);

        expect(event.type, equals(DrawingEventType.selectTool));
        expect(event.mode, equals(DrawingMode.polygon));
        expect(event.timestamp, isNotNull);
      });

      test('DrawingEvent.addPoint deve aceitar metadata', () {
        final event = DrawingEvent.addPoint({'x': 10.0, 'y': 20.0});

        expect(event.type, equals(DrawingEventType.addPoint));
        expect(event.metadata, isNotNull);
        expect(event.metadata!['x'], equals(10.0));
        expect(event.metadata!['y'], equals(20.0));
      });

      test('DrawingEvent.startBooleanOp deve criar evento com operação', () {
        final event = DrawingEvent.startBooleanOp(BooleanOperationType.union);

        expect(event.type, equals(DrawingEventType.startBooleanOp));
        expect(event.booleanOp, equals(BooleanOperationType.union));
      });

      test('DrawingEvent.complete deve criar evento sem payload', () {
        final event = DrawingEvent.complete();

        expect(event.type, equals(DrawingEventType.complete));
        expect(event.mode, isNull);
        expect(event.booleanOp, isNull);
        expect(event.metadata, isNull);
      });

      test('Eventos devem ter timestamp automático', () {
        final before = DateTime.now();
        final event = DrawingEvent.selectTool(DrawingMode.circle);
        final after = DateTime.now();

        expect(
          event.timestamp.isAfter(before.subtract(const Duration(seconds: 1))),
          isTrue,
        );
        expect(
          event.timestamp.isBefore(after.add(const Duration(seconds: 1))),
          isTrue,
        );
      });
    });

    // ═══════════════════════════════════════════════════════════════
    // FASE 1.2: HISTÓRICO DE EVENTOS
    // ═══════════════════════════════════════════════════════════════

    group('📚 Event History', () {
      test('Máquina deve iniciar com histórico vazio', () {
        expect(machine.eventHistory, isEmpty);
      });

      test('dispatch() deve adicionar evento ao histórico', () {
        final event = DrawingEvent.selectTool(DrawingMode.polygon);
        machine.dispatch(event);

        expect(machine.eventHistory.length, equals(1));
        expect(
          machine.eventHistory.first.type,
          equals(DrawingEventType.selectTool),
        );
      });

      test('Múltiplos dispatches devem acumular eventos', () {
        machine.dispatch(DrawingEvent.selectTool(DrawingMode.polygon));
        machine.dispatch(DrawingEvent.addPoint());
        machine.dispatch(DrawingEvent.addPoint());
        machine.dispatch(DrawingEvent.complete());

        expect(machine.eventHistory.length, equals(4));
        expect(
          machine.eventHistory[0].type,
          equals(DrawingEventType.selectTool),
        );
        expect(machine.eventHistory[1].type, equals(DrawingEventType.addPoint));
        expect(machine.eventHistory[2].type, equals(DrawingEventType.addPoint));
        expect(machine.eventHistory[3].type, equals(DrawingEventType.complete));
      });

      test('Histórico deve ser imutável (não pode modificar de fora)', () {
        machine.dispatch(DrawingEvent.selectTool(DrawingMode.polygon));

        final history = machine.eventHistory;

        // Tentar modificar não deve afetar o histórico interno
        expect(
          () => history.add(DrawingEvent.complete()),
          throwsUnsupportedError,
        );
      });

      test('Eventos inválidos NÃO devem ser adicionados ao histórico', () {
        // Tentar adicionar ponto sem estar armed
        final result = machine.dispatch(DrawingEvent.addPoint());

        expect(result.isFailure, isTrue);
        expect(machine.eventHistory, isEmpty);
      });

      test('Histórico deve respeitar limite máximo (100 eventos)', () {
        // Adicionar 105 eventos válidos
        machine.dispatch(DrawingEvent.selectTool(DrawingMode.polygon));

        for (int i = 0; i < 104; i++) {
          machine.dispatch(DrawingEvent.addPoint());
        }

        // Deve ter no máximo 100
        expect(machine.eventHistory.length <= 100, isTrue);
      });
    });

    // ═══════════════════════════════════════════════════════════════
    // FASE 1.3: REPLAY FUNCTION
    // ═══════════════════════════════════════════════════════════════

    group('🔄 Event Replay', () {
      test('Replay vazio deve retornar estado inicial', () {
        // Não dispatch nada
        final context = machine.replayUntilIndex(-1);

        expect(context.state, equals(DrawingState.idle));
        expect(context.mode, equals(DrawingMode.none));
        expect(context.pointsCount, equals(0));
      });

      test('Replay deve reconstruir estado corretamente', () {
        // Criar sequência de eventos
        machine.dispatch(DrawingEvent.selectTool(DrawingMode.polygon));
        machine.dispatch(DrawingEvent.addPoint());
        machine.dispatch(DrawingEvent.addPoint());

        // Replay até o primeiro evento (selectTool)
        final contextAt0 = machine.replayUntilIndex(0);
        expect(contextAt0.state, equals(DrawingState.armed));
        expect(contextAt0.mode, equals(DrawingMode.polygon));

        // Replay até o segundo evento (addPoint)
        final contextAt1 = machine.replayUntilIndex(1);
        expect(contextAt1.state, equals(DrawingState.drawing));
        expect(contextAt1.pointsCount, equals(1));

        // Replay até o terceiro evento (addPoint)
        final contextAt2 = machine.replayUntilIndex(2);
        expect(contextAt2.state, equals(DrawingState.drawing));
        expect(contextAt2.pointsCount, equals(2));
      });

      test('Replay completo deve corresponder ao estado atual', () {
        machine.dispatch(DrawingEvent.selectTool(DrawingMode.circle));
        machine.dispatch(DrawingEvent.addPoint());
        machine.dispatch(DrawingEvent.complete());

        // Estado atual
        final current = machine.currentContext;

        // Replay completo (index = último)
        final replayed = machine.replayUntilIndex(
          machine.eventHistory.length - 1,
        );

        expect(replayed.state, equals(current.state));
        expect(replayed.mode, equals(current.mode));
        expect(replayed.pointsCount, equals(current.pointsCount));
      });

      test('Replay intermediário deve mostrar estado passado', () {
        machine.dispatch(DrawingEvent.selectTool(DrawingMode.polygon));
        machine.dispatch(DrawingEvent.addPoint());
        machine.dispatch(DrawingEvent.complete());
        machine.dispatch(DrawingEvent.confirm());

        // Estado atual é idle
        expect(machine.currentState, equals(DrawingState.idle));

        // Replay até evento 1 (após addPoint) deve estar em drawing
        final pastContext = machine.replayUntilIndex(1);
        expect(pastContext.state, equals(DrawingState.drawing));
        expect(pastContext.pointsCount, equals(1));
      });
    });

    // ═══════════════════════════════════════════════════════════════
    // FASE 1.4: TIME-TRAVEL DEBUGGING
    // ═══════════════════════════════════════════════════════════════

    group('⏰ Time-Travel', () {
      test(
        'replayUntil(timestamp) deve reconstruir estado até tempo específico',
        () async {
          final timestamp1 = DateTime.now();
          await Future.delayed(
            const Duration(milliseconds: 10),
          ); // ⚡ Garantir que evento ocorre DEPOIS de t1

          machine.dispatch(DrawingEvent.selectTool(DrawingMode.polygon));

          await Future.delayed(const Duration(milliseconds: 10));
          final timestamp2 = DateTime.now();
          await Future.delayed(
            const Duration(milliseconds: 10),
          ); // ⚡ Garantir que próximo evento ocorre DEPOIS de t2

          machine.dispatch(DrawingEvent.addPoint());
          machine.dispatch(DrawingEvent.complete());

          // Replay até timestamp1 (antes de qualquer evento)
          final contextBefore = machine.replayUntil(timestamp1);
          expect(contextBefore.state, equals(DrawingState.idle));

          // Replay até timestamp2 (depois de selectTool, antes de addPoint)
          final contextMiddle = machine.replayUntil(timestamp2);
          expect(contextMiddle.state, equals(DrawingState.armed));

          // Estado atual (depois de tudo)
          expect(machine.currentState, equals(DrawingState.reviewing));
        },
      );

      test('Time-travel não deve modificar histórico', () {
        machine.dispatch(DrawingEvent.selectTool(DrawingMode.polygon));
        machine.dispatch(DrawingEvent.addPoint());

        final historyLength = machine.eventHistory.length;
        final currentState = machine.currentState;

        // Fazer time-travel
        final pastContext = machine.replayUntilIndex(0);

        // Histórico e estado atual não devem mudar
        expect(machine.eventHistory.length, equals(historyLength));
        expect(machine.currentState, equals(currentState));
        expect(pastContext.state, equals(DrawingState.armed)); // Passado
      });
    });

    // ═══════════════════════════════════════════════════════════════
    // FASE 1.5: VALIDAÇÃO DE EVENTOS
    // ═══════════════════════════════════════════════════════════════

    group('✅ Event Validation', () {
      test('canDispatch deve validar antes de adicionar ao histórico', () {
        expect(machine.canDispatch(DrawingEventType.selectTool), isTrue);
        expect(machine.canDispatch(DrawingEventType.addPoint), isFalse);
      });

      test('getNextState deve prever próximo estado', () {
        expect(
          machine.getNextState(DrawingEventType.selectTool),
          equals(DrawingState.armed),
        );

        machine.dispatch(DrawingEvent.selectTool(DrawingMode.polygon));
        expect(
          machine.getNextState(DrawingEventType.addPoint),
          equals(DrawingState.drawing),
        );
      });

      test('Eventos inválidos devem retornar failure sem alterar estado', () {
        final initialState = machine.currentState;

        final result = machine.dispatch(
          DrawingEvent.complete(),
        ); // Inválido em idle

        expect(result.isFailure, isTrue);
        expect(machine.currentState, equals(initialState));
        expect(machine.eventHistory, isEmpty);
      });
    });

    // ═══════════════════════════════════════════════════════════════
    // FASE 1.6: RESET
    // ═══════════════════════════════════════════════════════════════

    group('🔄 Reset', () {
      test('reset() deve limpar histórico e voltar ao inicial', () {
        machine.dispatch(DrawingEvent.selectTool(DrawingMode.polygon));
        machine.dispatch(DrawingEvent.addPoint());
        machine.dispatch(DrawingEvent.complete());

        machine.reset();

        expect(machine.eventHistory, isEmpty);
        expect(machine.currentState, equals(DrawingState.idle));
        expect(machine.canUndo, isFalse);
        expect(machine.canRedo, isFalse);
      });
    });
  });
}
