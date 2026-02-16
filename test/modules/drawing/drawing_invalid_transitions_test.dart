/*
════════════════════════════════════════════════════════════════════
DRAWING STATE MACHINE — INVALID TRANSITIONS TESTS
════════════════════════════════════════════════════════════════════

Testes críticos que garantem que a máquina de estados NÃO aceita
transições inválidas. Se estes testes falharem, a máquina está
aceitando bypassess perigosos.

REGRA: Transições inválidas DEVEM retornar false e não alterar estado.
🔧 FIX-DRAW-REDSCREEN: Anteriormente lançava StateError, agora retorna
false para evitar red screen na UI.
════════════════════════════════════════════════════════════════════
*/

import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/modules/drawing/domain/drawing_state.dart';

void main() {
  group('🚫 INVALID TRANSITIONS — State Machine', () {
    late DrawingStateMachine machine;

    setUp(() {
      machine = DrawingStateMachine();
    });

    group('❌ De idle (transições bloqueadas)', () {
      test('idle → drawing deve retornar false', () {
        expect(machine.currentState, equals(DrawingState.idle));

        final result = machine.transitionTo(DrawingState.drawing);
        expect(result, isFalse);

        // Estado deve permanecer inalterado
        expect(machine.currentState, equals(DrawingState.idle));
      });

      test('idle → reviewing deve retornar false', () {
        final result = machine.transitionTo(DrawingState.reviewing);
        expect(result, isFalse);
        expect(machine.currentState, equals(DrawingState.idle));
      });

      test('idle → booleanOperation deve retornar false', () {
        final result = machine.transitionTo(DrawingState.booleanOperation);
        expect(result, isFalse);
        expect(machine.currentState, equals(DrawingState.idle));
      });
    });

    group('❌ De armed (transições bloqueadas)', () {
      setUp(() {
        machine.startDrawing(DrawingTool.polygon);
        expect(machine.currentState, equals(DrawingState.armed));
      });

      test('armed → reviewing deve retornar false', () {
        final result = machine.transitionTo(DrawingState.reviewing);
        expect(result, isFalse);
        expect(machine.currentState, equals(DrawingState.armed));
      });

      test('armed → editing deve retornar false', () {
        final result = machine.transitionTo(DrawingState.editing);
        expect(result, isFalse);
        expect(machine.currentState, equals(DrawingState.armed));
      });

      test('armed → booleanOperation deve retornar false', () {
        final result = machine.transitionTo(DrawingState.booleanOperation);
        expect(result, isFalse);
        expect(machine.currentState, equals(DrawingState.armed));
      });

      test('armed → importPreview deve retornar false', () {
        final result = machine.transitionTo(DrawingState.importPreview);
        expect(result, isFalse);
        expect(machine.currentState, equals(DrawingState.armed));
      });
    });

    group('❌ De drawing (transições bloqueadas)', () {
      setUp(() {
        machine.startDrawing(DrawingTool.polygon);
        machine.beginAddingPoints();
        expect(machine.currentState, equals(DrawingState.drawing));
      });

      test('drawing → armed deve retornar false', () {
        final result = machine.transitionTo(DrawingState.armed);
        expect(result, isFalse);
        expect(machine.currentState, equals(DrawingState.drawing));
      });

      test('drawing → editing deve retornar false', () {
        final result = machine.transitionTo(DrawingState.editing);
        expect(result, isFalse);
        expect(machine.currentState, equals(DrawingState.drawing));
      });

      test('drawing → booleanOperation deve retornar false', () {
        final result = machine.transitionTo(DrawingState.booleanOperation);
        expect(result, isFalse);
        expect(machine.currentState, equals(DrawingState.drawing));
      });

      test('drawing → importPreview deve retornar false', () {
        final result = machine.transitionTo(DrawingState.importPreview);
        expect(result, isFalse);
        expect(machine.currentState, equals(DrawingState.drawing));
      });
    });

    group('❌ De reviewing (transições bloqueadas)', () {
      setUp(() {
        machine.startDrawing(DrawingTool.polygon);
        machine.beginAddingPoints();
        machine.completeDrawing();
        expect(machine.currentState, equals(DrawingState.reviewing));
      });

      test('reviewing → armed deve retornar false', () {
        final result = machine.transitionTo(DrawingState.armed);
        expect(result, isFalse);
        expect(machine.currentState, equals(DrawingState.reviewing));
      });

      test('reviewing → drawing deve retornar false', () {
        final result = machine.transitionTo(DrawingState.drawing);
        expect(result, isFalse);
        expect(machine.currentState, equals(DrawingState.reviewing));
      });

      test('reviewing → importPreview deve retornar false', () {
        final result = machine.transitionTo(DrawingState.importPreview);
        expect(result, isFalse);
        expect(machine.currentState, equals(DrawingState.reviewing));
      });
    });

    group('❌ De editing (transições bloqueadas)', () {
      setUp(() {
        machine.startEditing();
        expect(machine.currentState, equals(DrawingState.editing));
      });

      test('editing → armed deve retornar false', () {
        final result = machine.transitionTo(DrawingState.armed);
        expect(result, isFalse);
        expect(machine.currentState, equals(DrawingState.editing));
      });

      test('editing → drawing deve retornar false', () {
        final result = machine.transitionTo(DrawingState.drawing);
        expect(result, isFalse);
        expect(machine.currentState, equals(DrawingState.editing));
      });

      test('editing → booleanOperation deve retornar false', () {
        final result = machine.transitionTo(DrawingState.booleanOperation);
        expect(result, isFalse);
        expect(machine.currentState, equals(DrawingState.editing));
      });

      test('editing → importPreview deve retornar false', () {
        final result = machine.transitionTo(DrawingState.importPreview);
        expect(result, isFalse);
        expect(machine.currentState, equals(DrawingState.editing));
      });
    });

    group('❌ De importPreview (transições bloqueadas)', () {
      setUp(() {
        machine.startImportPreview();
        expect(machine.currentState, equals(DrawingState.importPreview));
      });

      test('importPreview → armed deve retornar false', () {
        final result = machine.transitionTo(DrawingState.armed);
        expect(result, isFalse);
        expect(machine.currentState, equals(DrawingState.importPreview));
      });

      test('importPreview → drawing deve retornar false', () {
        final result = machine.transitionTo(DrawingState.drawing);
        expect(result, isFalse);
        expect(machine.currentState, equals(DrawingState.importPreview));
      });

      test('importPreview → editing deve retornar false', () {
        final result = machine.transitionTo(DrawingState.editing);
        expect(result, isFalse);
        expect(machine.currentState, equals(DrawingState.importPreview));
      });

      test('importPreview → booleanOperation deve retornar false', () {
        final result = machine.transitionTo(DrawingState.booleanOperation);
        expect(result, isFalse);
        expect(machine.currentState, equals(DrawingState.importPreview));
      });
    });

    group('❌ De booleanOperation (transições bloqueadas)', () {
      setUp(() {
        // Precisamos estar em reviewing para iniciar boolean op
        machine.startDrawing(DrawingTool.polygon);
        machine.beginAddingPoints();
        machine.completeDrawing();
        machine.startBooleanOperation(BooleanOperationType.union);
        expect(machine.currentState, equals(DrawingState.booleanOperation));
      });

      test('booleanOperation → armed deve retornar false', () {
        final result = machine.transitionTo(DrawingState.armed);
        expect(result, isFalse);
        expect(machine.currentState, equals(DrawingState.booleanOperation));
      });

      test('booleanOperation → drawing deve retornar false', () {
        final result = machine.transitionTo(DrawingState.drawing);
        expect(result, isFalse);
        expect(machine.currentState, equals(DrawingState.booleanOperation));
      });

      test('booleanOperation → editing deve retornar false', () {
        final result = machine.transitionTo(DrawingState.editing);
        expect(result, isFalse);
        expect(machine.currentState, equals(DrawingState.booleanOperation));
      });

      test('booleanOperation → importPreview deve retornar false', () {
        final result = machine.transitionTo(DrawingState.importPreview);
        expect(result, isFalse);
        expect(machine.currentState, equals(DrawingState.booleanOperation));
      });
    });

    group('✅ Idle sempre permitido (regra especial)', () {
      test('de qualquer estado pode voltar para idle', () {
        final allStates = [
          DrawingState.armed,
          DrawingState.drawing,
          DrawingState.reviewing,
          DrawingState.editing,
          DrawingState.importPreview,
          DrawingState.booleanOperation,
        ];

        for (final state in allStates) {
          final testMachine = DrawingStateMachine();

          // Preparar estado
          switch (state) {
            case DrawingState.armed:
              testMachine.startDrawing(DrawingTool.polygon);
              break;
            case DrawingState.drawing:
              testMachine.startDrawing(DrawingTool.polygon);
              testMachine.beginAddingPoints();
              break;
            case DrawingState.reviewing:
              testMachine.startDrawing(DrawingTool.polygon);
              testMachine.beginAddingPoints();
              testMachine.completeDrawing();
              break;
            case DrawingState.editing:
              testMachine.startEditing();
              break;
            case DrawingState.importPreview:
              testMachine.startImportPreview();
              break;
            case DrawingState.booleanOperation:
              testMachine.startDrawing(DrawingTool.polygon);
              testMachine.beginAddingPoints();
              testMachine.completeDrawing();
              testMachine.startBooleanOperation(BooleanOperationType.union);
              break;
            default:
              break;
          }

          expect(testMachine.currentState, equals(state));

          // Deve permitir transição para idle e retornar true
          final result = testMachine.transitionTo(DrawingState.idle);
          expect(result, isTrue);
          expect(testMachine.currentState, equals(DrawingState.idle));
        }
      });
    });

    group('🔒 canTransitionTo() deve prever corretamente', () {
      test('canTransitionTo deve retornar false para transição inválida', () {
        expect(machine.currentState, equals(DrawingState.idle));

        // Deve prever que transição vai falhar
        expect(machine.canTransitionTo(DrawingState.drawing), isFalse);

        // E de fato deve retornar false (sem lançar exceção)
        final result = machine.transitionTo(DrawingState.drawing);
        expect(result, isFalse);
        expect(machine.currentState, equals(DrawingState.idle));
      });

      test('canTransitionTo deve retornar true antes de transição válida', () {
        expect(machine.currentState, equals(DrawingState.idle));

        // Deve prever que transição vai funcionar
        expect(machine.canTransitionTo(DrawingState.armed), isTrue);

        // E de fato deve funcionar e retornar true
        final result = machine.transitionTo(DrawingState.armed);
        expect(result, isTrue);
        expect(machine.currentState, equals(DrawingState.armed));
      });
    });

    group('🔧 tryTransitionTo() deve ser equivalente a transitionTo()', () {
      test('tryTransitionTo retorna false para transição inválida', () {
        expect(machine.currentState, equals(DrawingState.idle));

        final result = machine.tryTransitionTo(DrawingState.drawing);
        expect(result, isFalse);
        expect(machine.currentState, equals(DrawingState.idle));
      });

      test('tryTransitionTo retorna true para transição válida', () {
        expect(machine.currentState, equals(DrawingState.idle));

        final result = machine.tryTransitionTo(
          DrawingState.armed,
          tool: DrawingTool.polygon,
        );
        expect(result, isTrue);
        expect(machine.currentState, equals(DrawingState.armed));
      });
    });

    group('🔧 Métodos de conveniência retornam bool', () {
      test('startDrawing retorna true quando válido', () {
        final result = machine.startDrawing(DrawingTool.polygon);
        expect(result, isTrue);
        expect(machine.currentState, equals(DrawingState.armed));
      });

      test('beginAddingPoints retorna true quando em armed', () {
        machine.startDrawing(DrawingTool.polygon);
        final result = machine.beginAddingPoints();
        expect(result, isTrue);
        expect(machine.currentState, equals(DrawingState.drawing));
      });

      test('beginAddingPoints retorna false quando em idle', () {
        // Este era o cenário exato do bug (red screen)
        final result = machine.beginAddingPoints();
        expect(result, isFalse);
        expect(machine.currentState, equals(DrawingState.idle));
      });

      test('completeDrawing retorna true quando em drawing', () {
        machine.startDrawing(DrawingTool.polygon);
        machine.beginAddingPoints();
        final result = machine.completeDrawing();
        expect(result, isTrue);
        expect(machine.currentState, equals(DrawingState.reviewing));
      });

      test('cancel retorna true de qualquer estado', () {
        machine.startDrawing(DrawingTool.polygon);
        final result = machine.cancel();
        expect(result, isTrue);
        expect(machine.currentState, equals(DrawingState.idle));
      });
    });
  });
}
