/*
════════════════════════════════════════════════════════════════════
DRAWING STATE MACHINE V3 — FASE 3 TESTS (AVANÇADOS)
════════════════════════════════════════════════════════════════════

FASE 3: UNDO/REDO AVANÇADO
- Undo = remove evento + replay (SEM snapshots)
- Redo = adiciona evento + replay
- Zero snapshots (apenas eventos)
- Edge cases complexos
- Performance de replay

════════════════════════════════════════════════════════════════════
*/

import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/modules/drawing/domain/drawing_state_machine_v3.dart';

void main() {
  group('🏭 DrawingStateMachineV3 — Fase 3: Undo/Redo Avançado', () {
    late DrawingStateMachineV3 machine;

    setUp(() {
      machine = DrawingStateMachineV3();
    });

    // ═══════════════════════════════════════════════════════════════
    // FASE 3.1: UNDO/REDO EM CENÁRIOS COMPLEXOS
    // ═══════════════════════════════════════════════════════════════

    group('🔥 Cenários Complexos', () {
      test('Undo/Redo através de múltiplas mudanças de ferramenta', () {
        // Trocar ferramentas múltiplas vezes
        machine.dispatch(DrawingEvent.selectTool(DrawingMode.polygon));
        machine.dispatch(DrawingEvent.selectTool(DrawingMode.circle));
        machine.dispatch(DrawingEvent.selectTool(DrawingMode.rectangle));

        expect(machine.currentMode, equals(DrawingMode.rectangle));

        // Undo volta para circle
        machine.undo();
        expect(machine.currentMode, equals(DrawingMode.circle));

        // Undo volta para polygon
        machine.undo();
        expect(machine.currentMode, equals(DrawingMode.polygon));

        // Redo avança para circle
        machine.redo();
        expect(machine.currentMode, equals(DrawingMode.circle));

        // Redo avança para rectangle
        machine.redo();
        expect(machine.currentMode, equals(DrawingMode.rectangle));
      });

      test('Undo/Redo durante operação booleana', () {
        // Setup: desenhar, completar, iniciar boolean op
        machine.dispatch(DrawingEvent.selectTool(DrawingMode.polygon));
        machine.dispatch(DrawingEvent.addPoint());
        machine.dispatch(DrawingEvent.complete());
        machine.dispatch(
          DrawingEvent.startBooleanOp(BooleanOperationType.union),
        );

        expect(machine.currentState, equals(DrawingState.booleanOperation));
        expect(machine.booleanOperation, equals(BooleanOperationType.union));

        // Undo remove boolean op
        machine.undo();
        expect(machine.currentState, equals(DrawingState.reviewing));

        // Undo remove complete
        machine.undo();
        expect(machine.currentState, equals(DrawingState.drawing));

        // Redo reaplica complete
        machine.redo();
        expect(machine.currentState, equals(DrawingState.reviewing));

        // Redo reaplica boolean op
        machine.redo();
        expect(machine.currentState, equals(DrawingState.booleanOperation));
        expect(machine.booleanOperation, equals(BooleanOperationType.union));
      });

      test('Undo/Redo com cancelamento no meio', () {
        machine.dispatch(DrawingEvent.selectTool(DrawingMode.polygon));
        machine.dispatch(DrawingEvent.addPoint());
        machine.dispatch(DrawingEvent.addPoint());
        machine.dispatch(DrawingEvent.cancel()); // Cancela tudo

        expect(machine.currentState, equals(DrawingState.idle));
        expect(machine.eventHistory.length, equals(4));

        // Undo remove cancel
        machine.undo();
        expect(machine.currentState, equals(DrawingState.drawing));
        expect(machine.currentContext.pointsCount, equals(2));

        // Redo reaplica cancel
        machine.redo();
        expect(machine.currentState, equals(DrawingState.idle));
      });

      test('Undo/Redo através de fluxo completo (idle → reviewing → idle)', () {
        // Fluxo completo
        machine.dispatch(DrawingEvent.selectTool(DrawingMode.circle));
        machine.dispatch(DrawingEvent.addPoint());
        machine.dispatch(DrawingEvent.complete());
        machine.dispatch(DrawingEvent.confirm());

        expect(machine.currentState, equals(DrawingState.idle));
        expect(machine.eventHistory.length, equals(4));

        // Desfazer tudo
        machine.undo(); // Remove confirm → reviewing
        machine.undo(); // Remove complete → drawing
        machine.undo(); // Remove addPoint → armed
        machine.undo(); // Remove selectTool → idle

        expect(machine.currentState, equals(DrawingState.idle));
        expect(machine.eventHistory.isEmpty, isTrue);

        // Refazer tudo
        machine.redo(); // selectTool
        machine.redo(); // addPoint
        machine.redo(); // complete
        machine.redo(); // confirm

        expect(machine.currentState, equals(DrawingState.idle));
        expect(machine.eventHistory.length, equals(4));
      });

      test('Undo após import preview deve funcionar corretamente', () {
        machine.dispatch(DrawingEvent.startImport());
        machine.dispatch(DrawingEvent.confirmImport());

        expect(machine.currentState, equals(DrawingState.reviewing));

        // Undo remove confirmImport
        machine.undo();
        expect(machine.currentState, equals(DrawingState.importPreview));

        // Undo remove startImport
        machine.undo();
        expect(machine.currentState, equals(DrawingState.idle));
      });
    });

    // ═══════════════════════════════════════════════════════════════
    // FASE 3.2: EDGE CASES EXTREMOS
    // ═══════════════════════════════════════════════════════════════

    group('🎢 Edge Cases', () {
      test('Undo até o início deve deixar máquina vazia', () {
        machine.dispatch(DrawingEvent.selectTool(DrawingMode.polygon));
        machine.dispatch(DrawingEvent.addPoint());

        // Undo até acabar
        while (machine.canUndo) {
          machine.undo();
        }

        expect(machine.eventHistory.isEmpty, isTrue);
        expect(machine.currentState, equals(DrawingState.idle));
        expect(machine.canUndo, isFalse);
      });

      test('Redo até o fim deve restaurar estado completo', () {
        // Criar histórico
        machine.dispatch(DrawingEvent.selectTool(DrawingMode.polygon));
        machine.dispatch(DrawingEvent.addPoint());
        machine.dispatch(DrawingEvent.addPoint());

        final expectedHistory = machine.eventHistory.length;
        final expectedState = machine.currentState;

        // Desfazer tudo
        while (machine.canUndo) {
          machine.undo();
        }

        expect(machine.eventHistory.isEmpty, isTrue);

        // Refazer tudo
        while (machine.canRedo) {
          machine.redo();
        }

        expect(machine.eventHistory.length, equals(expectedHistory));
        expect(machine.currentState, equals(expectedState));
      });

      test('Múltiplos undo/redo sem nova ação deve ser estável', () {
        machine.dispatch(DrawingEvent.selectTool(DrawingMode.circle));
        machine.dispatch(DrawingEvent.addPoint());

        // Undo → Redo → Undo → Redo múltiplas vezes
        for (int i = 0; i < 5; i++) {
          machine.undo();
          expect(machine.currentState, equals(DrawingState.armed));

          machine.redo();
          expect(machine.currentState, equals(DrawingState.drawing));
        }

        // Estado deve permanecer consistente
        expect(machine.currentState, equals(DrawingState.drawing));
        expect(machine.currentContext.pointsCount, equals(1));
      });

      test('Undo de evento inválido aplicado não deve quebrar', () {
        machine.dispatch(DrawingEvent.selectTool(DrawingMode.polygon));

        // Tentar dispatch inválido (não adiciona ao histórico)
        final result = machine.dispatch(DrawingEvent.complete());
        expect(result.isFailure, isTrue);
        expect(machine.eventHistory.length, equals(1)); // Só selectTool

        // Undo deve funcionar normalmente
        machine.undo();
        expect(machine.currentState, equals(DrawingState.idle));
      });

      test('Redo após reset não deve ter efeito', () {
        machine.dispatch(DrawingEvent.selectTool(DrawingMode.polygon));
        machine.undo();

        expect(machine.canRedo, isTrue);

        // Reset limpa redo stack
        machine.reset();

        expect(machine.canRedo, isFalse);

        final result = machine.redo();
        expect(result.isFailure, isTrue);
      });
    });

    // ═══════════════════════════════════════════════════════════════
    // FASE 3.3: VALIDAÇÃO DE ZERO SNAPSHOTS
    // ═══════════════════════════════════════════════════════════════

    group('📊 Zero Snapshots (Event Sourcing Puro)', () {
      test('Estado é sempre recalculado via replay, não via snapshots', () {
        // Adicionar muitos eventos
        machine.dispatch(DrawingEvent.selectTool(DrawingMode.polygon));
        for (int i = 0; i < 20; i++) {
          machine.dispatch(DrawingEvent.addPoint());
        }
        machine.dispatch(DrawingEvent.complete());

        // Undo deve recalcular via replay
        machine.undo(); // Remove complete
        expect(machine.currentState, equals(DrawingState.drawing));
        expect(machine.currentContext.pointsCount, equals(20));

        // Replay manual deve dar mesmo resultado
        final replayed = machine.replayUntilIndex(
          machine.eventHistory.length - 1,
        );
        expect(replayed.state, equals(machine.currentState));
        expect(
          replayed.pointsCount,
          equals(machine.currentContext.pointsCount),
        );
      });

      test('Undo massivo não deve degradar performance (< 100ms)', () {
        // Criar histórico grande
        machine.dispatch(DrawingEvent.selectTool(DrawingMode.polygon));
        for (int i = 0; i < 50; i++) {
          machine.dispatch(DrawingEvent.addPoint());
        }

        final stopwatch = Stopwatch()..start();

        // Undo massivo (50 undos)
        while (machine.canUndo) {
          machine.undo();
        }

        stopwatch.stop();

        // Deve completar em < 100ms (event sourcing é eficiente)
        expect(stopwatch.elapsedMilliseconds, lessThan(100));
      });

      test('Histórico de eventos é a única fonte da verdade', () {
        machine.dispatch(DrawingEvent.selectTool(DrawingMode.circle));
        machine.dispatch(DrawingEvent.addPoint());
        machine.dispatch(DrawingEvent.addPoint());

        final historySnapshot = List<DrawingEvent>.from(machine.eventHistory);

        // Undo e redo
        machine.undo();
        machine.redo();

        // Histórico deve ser igual ao snapshot
        expect(machine.eventHistory.length, equals(historySnapshot.length));

        for (int i = 0; i < historySnapshot.length; i++) {
          expect(machine.eventHistory[i].type, equals(historySnapshot[i].type));
        }
      });
    });

    // ═══════════════════════════════════════════════════════════════
    // FASE 3.4: PERFORMANCE E REPLAY
    // ═══════════════════════════════════════════════════════════════

    group('⚡ Performance de Replay', () {
      test('Replay de 100 eventos deve ser rápido (< 50ms)', () {
        // Criar 100 eventos
        machine.dispatch(DrawingEvent.selectTool(DrawingMode.polygon));
        for (int i = 0; i < 99; i++) {
          machine.dispatch(DrawingEvent.addPoint());
        }

        expect(machine.eventHistory.length, equals(100));

        final stopwatch = Stopwatch()..start();

        // Replay completo
        final replayed = machine.replayUntilIndex(99);

        stopwatch.stop();

        expect(replayed.pointsCount, equals(99));
        expect(stopwatch.elapsedMilliseconds, lessThan(50));
      });

      test('Replay parcial deve ser proporcional ao número de eventos', () {
        machine.dispatch(DrawingEvent.selectTool(DrawingMode.polygon));
        for (int i = 0; i < 50; i++) {
          machine.dispatch(DrawingEvent.addPoint());
        }

        // Replay de 10 eventos
        final sw10 = Stopwatch()..start();
        machine.replayUntilIndex(9);
        sw10.stop();

        // Replay de 50 eventos
        final sw50 = Stopwatch()..start();
        machine.replayUntilIndex(50);
        sw50.stop();

        // Tempo de replay deve ser proporcional (não exponencial)
        // 50 eventos não deve demorar 5x mais que 10 eventos
        // (na prática deve ser quase linear)
        expect(
          sw50.elapsedMicroseconds < sw10.elapsedMicroseconds * 10,
          isTrue,
        );
      });

      test('Undo não deve recalcular todo histórico desnecessariamente', () {
        machine.dispatch(DrawingEvent.selectTool(DrawingMode.polygon));
        machine.dispatch(DrawingEvent.addPoint());
        machine.dispatch(DrawingEvent.addPoint());
        machine.dispatch(DrawingEvent.addPoint());

        final stopwatch = Stopwatch()..start();

        // Undo (que faz replay de 2 eventos)
        machine.undo();

        stopwatch.stop();

        // Deve ser muito rápido (< 5ms)
        expect(stopwatch.elapsedMilliseconds, lessThan(5));
        expect(machine.currentContext.pointsCount, equals(2));
      });
    });

    // ═══════════════════════════════════════════════════════════════
    // FASE 3.5: CONSISTÊNCIA E INTEGRIDADE
    // ═══════════════════════════════════════════════════════════════

    group('🔒 Consistência', () {
      test('Estado após N undo + N redo deve ser idêntico ao original', () {
        // Estado inicial complexo
        machine.dispatch(DrawingEvent.selectTool(DrawingMode.rectangle));
        machine.dispatch(DrawingEvent.addPoint());
        machine.dispatch(DrawingEvent.addPoint());
        machine.dispatch(DrawingEvent.complete());
        machine.dispatch(DrawingEvent.startEdit());

        final originalState = machine.currentContext;
        final originalHistory = machine.eventHistory.length;

        // 5 undos
        for (int i = 0; i < 5; i++) {
          machine.undo();
        }

        // 5 redos
        for (int i = 0; i < 5; i++) {
          machine.redo();
        }

        // Estado deve ser idêntico
        expect(machine.currentContext.state, equals(originalState.state));
        expect(machine.currentContext.mode, equals(originalState.mode));
        expect(
          machine.currentContext.pointsCount,
          equals(originalState.pointsCount),
        );
        expect(machine.eventHistory.length, equals(originalHistory));
      });

      test('Replay em qualquer ponto do histórico deve ser determinístico', () {
        machine.dispatch(DrawingEvent.selectTool(DrawingMode.polygon));
        machine.dispatch(DrawingEvent.addPoint());
        machine.dispatch(DrawingEvent.addPoint());
        machine.dispatch(DrawingEvent.addPoint());

        // Replay até índice 2 múltiplas vezes
        for (int i = 0; i < 10; i++) {
          final replayed = machine.replayUntilIndex(2);
          expect(replayed.state, equals(DrawingState.drawing));
          expect(replayed.pointsCount, equals(2));
        }
      });

      test('Undo/redo não deve alterar eventos já existentes', () {
        machine.dispatch(DrawingEvent.selectTool(DrawingMode.circle));
        machine.dispatch(DrawingEvent.addPoint());

        final firstEventType = machine.eventHistory[0].type;
        final firstEventTimestamp = machine.eventHistory[0].timestamp;

        // Undo e redo
        machine.undo();
        machine.undo();
        machine.redo();
        machine.redo();

        // Primeiro evento deve ser o mesmo (mesmo timestamp)
        expect(machine.eventHistory[0].type, equals(firstEventType));
        expect(machine.eventHistory[0].timestamp, equals(firstEventTimestamp));
      });
    });
  });
}
