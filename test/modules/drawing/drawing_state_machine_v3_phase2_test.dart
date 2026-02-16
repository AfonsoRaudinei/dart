/*
════════════════════════════════════════════════════════════════════
DRAWING STATE MACHINE V3 — FASE 2 TESTS
════════════════════════════════════════════════════════════════════

FASE 2: STATE APPLICATION
- applyEvent(context, event) → newContext
- replayEvents(events) → finalContext  
- Validação antes de aplicar
- Undo/Redo com Event Sourcing
- Cobertura completa estado×evento

════════════════════════════════════════════════════════════════════
*/

import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/modules/drawing/domain/drawing_state_machine_v3.dart';

void main() {
  group('🏭 DrawingStateMachineV3 — Fase 2: State Application', () {
    late DrawingStateMachineV3 machine;

    setUp(() {
      machine = DrawingStateMachineV3();
    });

    // ═══════════════════════════════════════════════════════════════
    // FASE 2.1: UNDO/REDO COM EVENT SOURCING
    // ═══════════════════════════════════════════════════════════════

    group('🔁 Undo/Redo — Event Sourcing', () {
      test('undo() deve remover último evento e recalcular estado', () {
        machine.dispatch(DrawingEvent.selectTool(DrawingMode.polygon));
        machine.dispatch(DrawingEvent.addPoint());

        expect(machine.currentState, equals(DrawingState.drawing));
        expect(machine.eventHistory.length, equals(2));

        // Undo
        final result = machine.undo();

        expect(result.isSuccess, isTrue);
        expect(
          machine.currentState,
          equals(DrawingState.armed),
        ); // Replay sem addPoint
        expect(machine.eventHistory.length, equals(1)); // 1 evento removido
      });

      test('undo em sequência deve voltar estados corretamente', () {
        // idle
        machine.dispatch(DrawingEvent.selectTool(DrawingMode.polygon));
        // armed
        machine.dispatch(DrawingEvent.addPoint());
        // drawing (1 ponto)
        machine.dispatch(DrawingEvent.addPoint());
        // drawing (2 pontos)

        expect(machine.currentState, equals(DrawingState.drawing));
        expect(machine.currentContext.pointsCount, equals(2));

        // Undo #1: Remove segundo addPoint
        machine.undo();
        expect(machine.currentState, equals(DrawingState.drawing));
        expect(machine.currentContext.pointsCount, equals(1));

        // Undo #2: Remove primeiro addPoint
        machine.undo();
        expect(machine.currentState, equals(DrawingState.armed));
        expect(machine.currentContext.pointsCount, equals(0));

        // Undo #3: Remove selectTool
        machine.undo();
        expect(machine.currentState, equals(DrawingState.idle));
        expect(machine.currentMode, equals(DrawingMode.none));
      });

      test('undo sem histórico deve falhar gracefully', () {
        final result = machine.undo();

        expect(result.isFailure, isTrue);
        expect(result.errorMessage, contains('Nada para desfazer'));
      });

      test('redo() deve reaplicar evento removido', () {
        machine.dispatch(DrawingEvent.selectTool(DrawingMode.polygon));
        machine.dispatch(DrawingEvent.addPoint());

        // Undo
        machine.undo();
        expect(machine.currentState, equals(DrawingState.armed));
        expect(machine.canRedo, isTrue);

        // Redo
        final result = machine.redo();

        expect(result.isSuccess, isTrue);
        expect(machine.currentState, equals(DrawingState.drawing));
        expect(machine.currentContext.pointsCount, equals(1));
      });

      test('redo em sequência deve refazer múltiplas ações', () {
        machine.dispatch(DrawingEvent.selectTool(DrawingMode.circle));
        machine.dispatch(DrawingEvent.addPoint());
        machine.dispatch(DrawingEvent.complete());

        // Undo 2x
        machine.undo(); // Remove complete
        machine.undo(); // Remove addPoint

        expect(machine.currentState, equals(DrawingState.armed));

        // Redo 2x
        machine.redo(); // Reaplica addPoint
        expect(machine.currentState, equals(DrawingState.drawing));

        machine.redo(); // Reaplica complete
        expect(machine.currentState, equals(DrawingState.reviewing));
      });

      test('redo sem histórico deve falhar gracefully', () {
        final result = machine.redo();

        expect(result.isFailure, isTrue);
        expect(result.errorMessage, contains('Nada para refazer'));
      });

      test('nova ação após undo deve limpar redo stack', () {
        machine.dispatch(DrawingEvent.selectTool(DrawingMode.polygon));
        machine.dispatch(DrawingEvent.addPoint());

        machine.undo();
        expect(machine.canRedo, isTrue);

        // Nova ação
        machine.dispatch(DrawingEvent.addPoint());

        expect(machine.canRedo, isFalse); // Redo limpo
      });

      test('undo/redo devem manter integridade do histórico', () {
        machine.dispatch(DrawingEvent.selectTool(DrawingMode.polygon));
        machine.dispatch(DrawingEvent.addPoint());
        machine.dispatch(DrawingEvent.addPoint());

        final initialHistory = machine.eventHistory.length;

        // Undo
        machine.undo();
        expect(machine.eventHistory.length, equals(initialHistory - 1));

        // Redo
        machine.redo();
        expect(machine.eventHistory.length, equals(initialHistory));

        // Estado final deve ser idêntico
        expect(machine.currentState, equals(DrawingState.drawing));
        expect(machine.currentContext.pointsCount, equals(2));
      });
    });

    // ═══════════════════════════════════════════════════════════════
    // FASE 2.2: COBERTURA COMPLETA ESTADO×EVENTO
    // ═══════════════════════════════════════════════════════════════

    group('🎯 Cobertura Estado×Evento', () {
      // ─────────────────────────────────────────────────────────────
      // De IDLE
      // ─────────────────────────────────────────────────────────────

      group('❌ De IDLE', () {
        test('✅ idle + selectTool → armed', () {
          final result = machine.dispatch(
            DrawingEvent.selectTool(DrawingMode.polygon),
          );

          expect(result.isSuccess, isTrue);
          expect(machine.currentState, equals(DrawingState.armed));
          expect(machine.currentMode, equals(DrawingMode.polygon));
        });

        test('✅ idle + startEdit → editing', () {
          final result = machine.dispatch(DrawingEvent.startEdit());

          expect(result.isSuccess, isTrue);
          expect(machine.currentState, equals(DrawingState.editing));
        });

        test('✅ idle + startImport → importPreview', () {
          final result = machine.dispatch(DrawingEvent.startImport());

          expect(result.isSuccess, isTrue);
          expect(machine.currentState, equals(DrawingState.importPreview));
        });

        test('❌ idle + addPoint → INVÁLIDO', () {
          final result = machine.dispatch(DrawingEvent.addPoint());

          expect(result.isFailure, isTrue);
          expect(machine.currentState, equals(DrawingState.idle));
        });

        test('❌ idle + complete → INVÁLIDO', () {
          final result = machine.dispatch(DrawingEvent.complete());

          expect(result.isFailure, isTrue);
          expect(machine.currentState, equals(DrawingState.idle));
        });
      });

      // ─────────────────────────────────────────────────────────────
      // De ARMED
      // ─────────────────────────────────────────────────────────────

      group('🔫 De ARMED', () {
        setUp(() {
          machine.dispatch(DrawingEvent.selectTool(DrawingMode.polygon));
        });

        test('✅ armed + addPoint → drawing', () {
          final result = machine.dispatch(DrawingEvent.addPoint());

          expect(result.isSuccess, isTrue);
          expect(machine.currentState, equals(DrawingState.drawing));
          expect(machine.currentContext.pointsCount, equals(1));
        });

        test('✅ armed + selectTool → armed (trocar ferramenta)', () {
          final result = machine.dispatch(
            DrawingEvent.selectTool(DrawingMode.circle),
          );

          expect(result.isSuccess, isTrue);
          expect(machine.currentState, equals(DrawingState.armed));
          expect(machine.currentMode, equals(DrawingMode.circle));
        });

        test('✅ armed + cancel → idle', () {
          final result = machine.dispatch(DrawingEvent.cancel());

          expect(result.isSuccess, isTrue);
          expect(machine.currentState, equals(DrawingState.idle));
          expect(machine.currentMode, equals(DrawingMode.none));
        });

        test('❌ armed + complete → INVÁLIDO', () {
          final result = machine.dispatch(DrawingEvent.complete());

          expect(result.isFailure, isTrue);
          expect(machine.currentState, equals(DrawingState.armed));
        });
      });

      // ─────────────────────────────────────────────────────────────
      // De DRAWING
      // ─────────────────────────────────────────────────────────────

      group('✏️ De DRAWING', () {
        setUp(() {
          machine.dispatch(DrawingEvent.selectTool(DrawingMode.polygon));
          machine.dispatch(DrawingEvent.addPoint());
        });

        test('✅ drawing + addPoint → drawing (mais pontos)', () {
          final result = machine.dispatch(DrawingEvent.addPoint());

          expect(result.isSuccess, isTrue);
          expect(machine.currentState, equals(DrawingState.drawing));
          expect(machine.currentContext.pointsCount, equals(2));
        });

        test('✅ drawing + complete → reviewing', () {
          final result = machine.dispatch(DrawingEvent.complete());

          expect(result.isSuccess, isTrue);
          expect(machine.currentState, equals(DrawingState.reviewing));
        });

        test('✅ drawing + cancel → idle', () {
          final result = machine.dispatch(DrawingEvent.cancel());

          expect(result.isSuccess, isTrue);
          expect(machine.currentState, equals(DrawingState.idle));
        });

        test('❌ drawing + startEdit → INVÁLIDO', () {
          final result = machine.dispatch(DrawingEvent.startEdit());

          expect(result.isFailure, isTrue);
          expect(machine.currentState, equals(DrawingState.drawing));
        });
      });

      // ─────────────────────────────────────────────────────────────
      // De REVIEWING
      // ─────────────────────────────────────────────────────────────

      group('👁️ De REVIEWING', () {
        setUp(() {
          machine.dispatch(DrawingEvent.selectTool(DrawingMode.polygon));
          machine.dispatch(DrawingEvent.addPoint());
          machine.dispatch(DrawingEvent.complete());
        });

        test('✅ reviewing + startEdit → editing', () {
          final result = machine.dispatch(DrawingEvent.startEdit());

          expect(result.isSuccess, isTrue);
          expect(machine.currentState, equals(DrawingState.editing));
        });

        test('✅ reviewing + confirm → idle', () {
          final result = machine.dispatch(DrawingEvent.confirm());

          expect(result.isSuccess, isTrue);
          expect(machine.currentState, equals(DrawingState.idle));
        });

        test('✅ reviewing + cancel → idle', () {
          final result = machine.dispatch(DrawingEvent.cancel());

          expect(result.isSuccess, isTrue);
          expect(machine.currentState, equals(DrawingState.idle));
        });

        test('✅ reviewing + startBooleanOp → booleanOperation', () {
          final result = machine.dispatch(
            DrawingEvent.startBooleanOp(BooleanOperationType.union),
          );

          expect(result.isSuccess, isTrue);
          expect(machine.currentState, equals(DrawingState.booleanOperation));
          expect(machine.booleanOperation, equals(BooleanOperationType.union));
        });

        test('❌ reviewing + addPoint → INVÁLIDO', () {
          final result = machine.dispatch(DrawingEvent.addPoint());

          expect(result.isFailure, isTrue);
          expect(machine.currentState, equals(DrawingState.reviewing));
        });
      });

      // ─────────────────────────────────────────────────────────────
      // De EDITING
      // ─────────────────────────────────────────────────────────────

      group('📝 De EDITING', () {
        setUp(() {
          machine.dispatch(DrawingEvent.startEdit());
        });

        test('✅ editing + saveEdit → reviewing', () {
          final result = machine.dispatch(DrawingEvent.saveEdit());

          expect(result.isSuccess, isTrue);
          expect(machine.currentState, equals(DrawingState.reviewing));
        });

        test('✅ editing + cancel → reviewing', () {
          final result = machine.dispatch(DrawingEvent.cancel());

          expect(result.isSuccess, isTrue);
          expect(machine.currentState, equals(DrawingState.reviewing));
        });

        test('❌ editing + addPoint → INVÁLIDO', () {
          final result = machine.dispatch(DrawingEvent.addPoint());

          expect(result.isFailure, isTrue);
          expect(machine.currentState, equals(DrawingState.editing));
        });
      });

      // ─────────────────────────────────────────────────────────────
      // De IMPORTPREVIEW
      // ─────────────────────────────────────────────────────────────

      group('📥 De IMPORTPREVIEW', () {
        setUp(() {
          machine.dispatch(DrawingEvent.startImport());
        });

        test('✅ importPreview + confirmImport → reviewing', () {
          final result = machine.dispatch(DrawingEvent.confirmImport());

          expect(result.isSuccess, isTrue);
          expect(machine.currentState, equals(DrawingState.reviewing));
        });

        test('✅ importPreview + cancel → idle', () {
          final result = machine.dispatch(DrawingEvent.cancel());

          expect(result.isSuccess, isTrue);
          expect(machine.currentState, equals(DrawingState.idle));
        });

        test('❌ importPreview + addPoint → INVÁLIDO', () {
          final result = machine.dispatch(DrawingEvent.addPoint());

          expect(result.isFailure, isTrue);
          expect(machine.currentState, equals(DrawingState.importPreview));
        });
      });

      // ─────────────────────────────────────────────────────────────
      // De BOOLEANOPERATION
      // ─────────────────────────────────────────────────────────────

      group('🔀 De BOOLEANOPERATION', () {
        setUp(() {
          machine.dispatch(DrawingEvent.selectTool(DrawingMode.polygon));
          machine.dispatch(DrawingEvent.addPoint());
          machine.dispatch(DrawingEvent.complete());
          machine.dispatch(
            DrawingEvent.startBooleanOp(BooleanOperationType.union),
          );
        });

        test('✅ booleanOp + completeBooleanOp → reviewing', () {
          final result = machine.dispatch(DrawingEvent.completeBooleanOp());

          expect(result.isSuccess, isTrue);
          expect(machine.currentState, equals(DrawingState.reviewing));
        });

        test('✅ booleanOp + cancel → idle', () {
          final result = machine.dispatch(DrawingEvent.cancel());

          expect(result.isSuccess, isTrue);
          expect(machine.currentState, equals(DrawingState.idle));
        });

        test('❌ booleanOp + addPoint → INVÁLIDO', () {
          final result = machine.dispatch(DrawingEvent.addPoint());

          expect(result.isFailure, isTrue);
          expect(machine.currentState, equals(DrawingState.booleanOperation));
        });
      });
    });

    // ═══════════════════════════════════════════════════════════════
    // FASE 2.3: REPLAY DETERMINÍSTICO
    // ═══════════════════════════════════════════════════════════════

    group('🔄 Replay Determinístico', () {
      test('Replay deve ser determinístico (mesmo resultado sempre)', () {
        machine.dispatch(DrawingEvent.selectTool(DrawingMode.polygon));
        machine.dispatch(DrawingEvent.addPoint());
        machine.dispatch(DrawingEvent.addPoint());
        machine.dispatch(DrawingEvent.complete());

        final state1 = machine.currentContext;

        // Replay completo
        final state2 = machine.replayUntilIndex(
          machine.eventHistory.length - 1,
        );

        expect(state2.state, equals(state1.state));
        expect(state2.mode, equals(state1.mode));
        expect(state2.pointsCount, equals(state1.pointsCount));
      });

      test('Replay após undo/redo deve ser consistente', () {
        machine.dispatch(DrawingEvent.selectTool(DrawingMode.circle));
        machine.dispatch(DrawingEvent.addPoint());
        machine.dispatch(DrawingEvent.complete());

        final stateBeforeUndo = machine.currentContext;

        // Undo + Redo
        machine.undo();
        machine.redo();

        final stateAfterRedo = machine.currentContext;

        expect(stateAfterRedo.state, equals(stateBeforeUndo.state));
        expect(stateAfterRedo.mode, equals(stateBeforeUndo.mode));
      });

      test(
        'Replay parcial seguido de replay completo deve ser idempotente',
        () {
          machine.dispatch(DrawingEvent.selectTool(DrawingMode.polygon));
          machine.dispatch(DrawingEvent.addPoint());
          machine.dispatch(DrawingEvent.addPoint());

          // Replay parcial (até índice 1)
          final partial = machine.replayUntilIndex(1);
          expect(partial.state, equals(DrawingState.drawing));
          expect(partial.pointsCount, equals(1));

          // Replay completo não deve ser afetado
          final full = machine.replayUntilIndex(2);
          expect(full.state, equals(DrawingState.drawing));
          expect(full.pointsCount, equals(2));

          // Estado atual não muda
          expect(machine.currentState, equals(DrawingState.drawing));
          expect(machine.currentContext.pointsCount, equals(2));
        },
      );
    });
  });
}
