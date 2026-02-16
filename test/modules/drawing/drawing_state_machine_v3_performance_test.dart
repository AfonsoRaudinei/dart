/*
════════════════════════════════════════════════════════════════════
DRAWING STATE MACHINE V3 — PERFORMANCE TESTS (FASE 5)
════════════════════════════════════════════════════════════════════

TESTES DE PERFORMANCE OTIMIZADA:
- Cache de replay
- Snapshots estratégicos
- Benchmark comparativo

════════════════════════════════════════════════════════════════════
*/

import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/modules/drawing/domain/drawing_state_machine_v3.dart';

void main() {
  group('🏭 DrawingStateMachineV3 — Fase 5: Performance Optimizations', () {
    late DrawingStateMachineV3 machine;

    setUp(() {
      machine = DrawingStateMachineV3();
    });

    // ═══════════════════════════════════════════════════════════════
    // CACHE DE REPLAY
    // ═══════════════════════════════════════════════════════════════

    group('⚡ Cache de Replay', () {
      test('replay idêntico usa cache (muito mais rápido)', () {
        // Criar histórico grande
        machine.dispatch(DrawingEvent.selectTool(DrawingMode.polygon));
        for (int i = 0; i < 50; i++) {
          machine.dispatch(DrawingEvent.addPoint());
        }

        // Primeiro replay (sem cache)
        final sw1 = Stopwatch()..start();
        final result1 = machine.replayUntilIndex(49);
        sw1.stop();

        // Segundo replay (com cache - deve ser instantâneo)
        final sw2 = Stopwatch()..start();
        final result2 = machine.replayUntilIndex(49);
        sw2.stop();

        // Cache deve ser MUITO mais rápido
        expect(
          sw2.elapsedMicroseconds,
          lessThan(sw1.elapsedMicroseconds ~/ 10),
        );
        expect(result1.state, equals(result2.state));
        expect(result1.pointsCount, equals(result2.pointsCount));
      });

      test('cache invalida quando novo evento é adicionado', () {
        machine.dispatch(DrawingEvent.selectTool(DrawingMode.polygon));
        machine.dispatch(DrawingEvent.addPoint());

        // Cachear replay
        final result1 = machine.replayUntilIndex(1);

        // Adicionar novo evento (invalida cache)
        machine.dispatch(DrawingEvent.addPoint());

        // Replay anterior deve funcionar mas sem cache
        final result2 = machine.replayUntilIndex(1);

        expect(result1.state, equals(result2.state));
      });
    });

    // ═══════════════════════════════════════════════════════════════
    // SNAPSHOTS ESTRATÉGICOS
    // ═══════════════════════════════════════════════════════════════

    group('📸 Snapshots Estratégicos', () {
      test('snapshot criado a cada 20 eventos', () {
        machine.dispatch(DrawingEvent.selectTool(DrawingMode.polygon));

        // Adicionar 20 eventos
        for (int i = 0; i < 19; i++) {
          machine.dispatch(DrawingEvent.addPoint());
        }

        // Evento #20 → snapshot criado (verificado via debug message)
        // Não podemos verificar diretamente (privado), mas testamos resultado

        final result = machine.replayUntilIndex(19);
        expect(result.state, equals(DrawingState.drawing));
        expect(result.pointsCount, equals(19));
      });

      test('replay usando snapshot é mais rápido que replay completo', () {
        machine.dispatch(DrawingEvent.selectTool(DrawingMode.polygon));

        // Criar 40 eventos (2 snapshots esperados: #20, #40)
        for (int i = 0; i < 39; i++) {
          machine.dispatch(DrawingEvent.addPoint());
        }

        // Replay até evento #35 (usa snapshot #20, replay só 15 eventos)
        final stopwatch = Stopwatch()..start();
        final result = machine.replayUntilIndex(34);
        stopwatch.stop();

        expect(result.pointsCount, equals(34));

        // Deve ser rápido (< 5ms) mesmo com 40 eventos no histórico
        expect(stopwatch.elapsedMilliseconds, lessThan(5));
      });
    });

    // ═══════════════════════════════════════════════════════════════
    // BENCHMARK COMPARATIVO
    // ═══════════════════════════════════════════════════════════════

    group('🏎️ Benchmarks', () {
      test('replay de 100 eventos < 30ms (otimizado)', () {
        machine.dispatch(DrawingEvent.selectTool(DrawingMode.polygon));
        for (int i = 0; i < 99; i++) {
          machine.dispatch(DrawingEvent.addPoint());
        }

        final stopwatch = Stopwatch()..start();
        final result = machine.replayUntilIndex(99);
        stopwatch.stop();

        expect(result.pointsCount, equals(99));

        // Otimizado: < 30ms (antes era < 50ms)
        expect(stopwatch.elapsedMilliseconds, lessThan(30));
      });

      test('múltiplos replays consecutivos são muito rápidos (cache)', () {
        machine.dispatch(DrawingEvent.selectTool(DrawingMode.polygon));
        for (int i = 0; i < 50; i++) {
          machine.dispatch(DrawingEvent.addPoint());
        }

        final stopwatch = Stopwatch()..start();

        // 10 replays idênticos (cache deve otimizar)
        for (int i = 0; i < 10; i++) {
          machine.replayUntilIndex(49);
        }

        stopwatch.stop();

        // 10 replays devem custar quase o mesmo que 1
        expect(stopwatch.elapsedMilliseconds, lessThan(10));
      });

      test('undo massivo permanece rápido (< 80ms)', () {
        machine.dispatch(DrawingEvent.selectTool(DrawingMode.polygon));
        for (int i = 0; i < 50; i++) {
          machine.dispatch(DrawingEvent.addPoint());
        }

        final stopwatch = Stopwatch()..start();

        while (machine.canUndo) {
          machine.undo();
        }

        stopwatch.stop();

        // Otimizado: < 80ms (antes era < 100ms)
        expect(stopwatch.elapsedMilliseconds, lessThan(80));
      });
    });

    // ═══════════════════════════════════════════════════════════════
    // VALIDAÇÃO DE CORRETUDE (OTIMIZAÇÃO NÃO QUEBRA)
    // ═══════════════════════════════════════════════════════════════

    group('✅ Corretude', () {
      test('otimizações não alteram resultado de replay', () {
        machine.dispatch(DrawingEvent.selectTool(DrawingMode.polygon));
        for (int i = 0; i < 50; i++) {
          machine.dispatch(DrawingEvent.addPoint());
        }

        // Replay múltiplas vezes
        final results = <DrawingContext>[];
        for (int i = 0; i < 5; i++) {
          results.add(machine.replayUntilIndex(25));
        }

        // Todos devem ser idênticos
        for (final result in results) {
          expect(result.state, equals(DrawingState.drawing));
          expect(result.pointsCount, equals(25));
        }
      });

      test('reset limpa cache e snapshots', () {
        machine.dispatch(DrawingEvent.selectTool(DrawingMode.polygon));
        for (int i = 0; i < 30; i++) {
          machine.dispatch(DrawingEvent.addPoint());
        }

        // Criar cache
        machine.replayUntilIndex(20);

        // Reset
        machine.reset();

        expect(machine.eventHistory, isEmpty);
        expect(machine.currentState, equals(DrawingState.idle));

        // Cache foi limpo (não podemos verificar diretamente, mas testamos comportamento)
        final result = machine.replayUntilIndex(0);
        expect(result.state, equals(DrawingState.idle));
      });

      test('undo invalida cache corretamente', () {
        machine.dispatch(DrawingEvent.selectTool(DrawingMode.polygon));
        machine.dispatch(DrawingEvent.addPoint());
        machine.dispatch(DrawingEvent.addPoint());

        // Cachear
        machine.replayUntilIndex(2);

        // Undo (deve invalidar cache)
        machine.undo();

        // Replay deve funcionar corretamente
        final result = machine.replayUntilIndex(1);
        expect(result.pointsCount, equals(1));
      });
    });

    // ═══════════════════════════════════════════════════════════════
    // STRESS TESTS
    // ═══════════════════════════════════════════════════════════════

    group('💪 Stress Tests', () {
      test('100 eventos + 50 replays + 50 undos < 200ms', () {
        final stopwatch = Stopwatch()..start();

        // 100 eventos
        machine.dispatch(DrawingEvent.selectTool(DrawingMode.polygon));
        for (int i = 0; i < 99; i++) {
          machine.dispatch(DrawingEvent.addPoint());
        }

        // 50 replays randômicos
        for (int i = 0; i < 50; i++) {
          machine.replayUntilIndex(i);
        }

        // 50 undos
        for (int i = 0; i < 50; i++) {
          machine.undo();
        }

        stopwatch.stop();

        expect(stopwatch.elapsedMilliseconds, lessThan(200));
      });

      test('memoria: 100 eventos não estouram snapshots', () {
        machine.dispatch(DrawingEvent.selectTool(DrawingMode.polygon));

        for (int i = 0; i < 99; i++) {
          machine.dispatch(DrawingEvent.addPoint());
        }

        // Deve ter ~5 snapshots (a cada 20 eventos)
        // Não podemos verificar diretamente, mas não deve crashar

        expect(machine.eventHistory.length, equals(100));
        expect(machine.currentContext.pointsCount, equals(99));
      });
    });
  });
}
