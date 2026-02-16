import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:soloforte_app/modules/drawing/presentation/controllers/drawing_controller.dart';
import 'package:soloforte_app/modules/drawing/domain/drawing_state.dart';
import 'package:soloforte_app/modules/drawing/domain/models/drawing_models.dart';
import 'package:soloforte_app/modules/drawing/data/repositories/drawing_repository.dart';

/// Mock repository que não acessa banco de dados
class MockDrawingRepository extends DrawingRepository {
  @override
  Future<List<DrawingFeature>> getAllFeatures() async {
    return [];
  }

  @override
  Future<void> saveFeature(DrawingFeature feature) async {
    return;
  }

  @override
  Future<void> deleteFeature(String id) async {
    return;
  }
}

/// ✅ FIX-DRAW-FLOW-02 — Testes de Regressão Crítica
///
/// Testa cenários complexos e edge cases que podem causar falhas no fluxo:
/// - Trocas rápidas de ferramenta
/// - Múltiplos cancelamentos
/// - Transições inválidas
/// - Race conditions
/// - Estado inconsistente
///
/// Este teste BLINDAGEM contra bugs sutis e difíceis de reproduzir.
void main() {
  group('FIX-DRAW-FLOW-02 — Regressão: Trocas Rápidas', () {
    late DrawingController controller;

    setUp(() {
      controller = DrawingController(repository: MockDrawingRepository());
    });

    tearDown(() {
      controller.dispose();
    });

    test('⚡ Trocar ferramenta 10x seguidas não deve lançar erro', () {
      expect(() {
        for (var i = 0; i < 10; i++) {
          controller.selectTool('polygon');
          controller.selectTool('rectangle');
          controller.selectTool('circle');
        }
      }, returnsNormally);

      expect(controller.currentState, equals(DrawingState.armed));
    });

    test('⚡ Alternar entre armed e idle rapidamente', () {
      expect(() {
        for (var i = 0; i < 20; i++) {
          controller.selectTool('polygon');
          expect(controller.currentState, equals(DrawingState.armed));
          controller.selectTool('none');
          expect(controller.currentState, equals(DrawingState.idle));
        }
      }, returnsNormally);
    });

    test('⚡ Trocar ferramenta durante drawing não deve corromper estado', () {
      controller.selectTool('polygon');
      controller.appendDrawingPoint(const LatLng(-15.7801, -47.9292));
      controller.appendDrawingPoint(const LatLng(-15.7802, -47.9293));
      expect(controller.currentState, equals(DrawingState.drawing));

      // Tentar trocar ferramenta no meio do desenho (deve ser bloqueado)
      controller.selectTool('rectangle');

      // Deve MANTER estado drawing (segurança contra perda de dados)
      expect(controller.currentState, equals(DrawingState.drawing));
      expect(controller.errorMessage, contains("Conclua ou cancele"));

      // Fluxo correto: Cancelar primeiro, depois trocar
      controller.cancelOperation();
      controller.selectTool('rectangle');

      // Agora sim deve estar em armed com nova ferramenta
      expect(controller.currentState, equals(DrawingState.armed));
      expect(controller.currentTool, equals(DrawingTool.rectangle));
      expect(controller.liveGeometry, isNull);
    });

    test('⚡ Múltiplas trocas com pontos requer cancelamento explícito', () {
      for (var i = 0; i < 50; i++) {
        controller.selectTool('polygon');
        controller.appendDrawingPoint(LatLng(-15.78 + i * 0.001, -47.92));

        // Tentar trocar direto (será bloqueado)
        controller.selectTool('rectangle');
        expect(controller.currentState, equals(DrawingState.drawing));

        // Cancelar para permitir troca na próxima iteração
        controller.cancelOperation();
      }

      expect(controller.currentState, equals(DrawingState.idle));
      expect(controller.liveGeometry, isNull);
    });
  });

  group('FIX-DRAW-FLOW-02 — Regressão: Cancelamentos', () {
    late DrawingController controller;

    setUp(() {
      controller = DrawingController(repository: MockDrawingRepository());
    });

    tearDown(() {
      controller.dispose();
    });

    test('❌ Cancelar sem ter iniciado não deve quebrar', () {
      expect(() => controller.cancelOperation(), returnsNormally);

      expect(controller.currentState, equals(DrawingState.idle));
    });

    test('❌ Cancelar múltiplas vezes não deve lançar erro', () {
      controller.selectTool('polygon');
      controller.appendDrawingPoint(const LatLng(-15.7801, -47.9292));

      expect(() {
        controller.cancelOperation();
        controller.cancelOperation();
        controller.cancelOperation();
      }, returnsNormally);

      expect(controller.currentState, equals(DrawingState.idle));
    });

    test('❌ Cancelar durante armed deve voltar para idle', () {
      controller.selectTool('polygon');
      expect(controller.currentState, equals(DrawingState.armed));

      controller.cancelOperation();

      expect(controller.currentState, equals(DrawingState.idle));
      expect(controller.currentTool, equals(DrawingTool.none));
    });

    test('❌ Cancelar e rearmar 100x não deve falhar', () {
      expect(() {
        for (var i = 0; i < 100; i++) {
          controller.selectTool('polygon');
          controller.appendDrawingPoint(LatLng(-15.78 + i * 0.0001, -47.92));
          controller.cancelOperation();
        }
      }, returnsNormally);

      expect(controller.currentState, equals(DrawingState.idle));
    });
  });

  group('FIX-DRAW-FLOW-02 — Regressão: Tap Behaviors', () {
    late DrawingController controller;

    setUp(() {
      controller = DrawingController(repository: MockDrawingRepository());
    });

    tearDown(() {
      controller.dispose();
    });

    test('🖱️ appendDrawingPoint sem selectTool não deve mudar estado', () {
      controller.appendDrawingPoint(const LatLng(-15.7801, -47.9292));

      expect(controller.currentState, equals(DrawingState.idle));
      expect(controller.liveGeometry, isNull);
    });

    test('🖱️ appendDrawingPoint em idle não deve fazer nada', () {
      expect(controller.currentState, equals(DrawingState.idle));

      controller.appendDrawingPoint(const LatLng(-15.7801, -47.9292));
      controller.appendDrawingPoint(const LatLng(-15.7802, -47.9293));

      expect(controller.currentState, equals(DrawingState.idle));
      expect(controller.liveGeometry, isNull);
    });

    test('🖱️ Adicionar 1000 pontos não deve travar', () {
      controller.selectTool('polygon');

      expect(() {
        for (var i = 0; i < 1000; i++) {
          controller.appendDrawingPoint(
            LatLng(-15.78 + i * 0.00001, -47.92 + i * 0.00001),
          );
        }
      }, returnsNormally);

      expect(controller.currentState, equals(DrawingState.drawing));
      expect(controller.liveGeometry, isNotNull);
    });

    test('🖱️ Adicionar pontos idênticos não deve quebrar', () {
      controller.selectTool('polygon');
      const point = LatLng(-15.7801, -47.9292);

      expect(() {
        for (var i = 0; i < 50; i++) {
          controller.appendDrawingPoint(point);
        }
      }, returnsNormally);

      expect(controller.currentState, equals(DrawingState.drawing));
    });
  });

  group('FIX-DRAW-FLOW-02 — Regressão: Estado Inconsistente', () {
    late DrawingController controller;

    setUp(() {
      controller = DrawingController(repository: MockDrawingRepository());
    });

    tearDown(() {
      controller.dispose();
    });

    test('🔐 selectTool com valor inválido deve resultar em idle', () {
      controller.selectTool('invalid_tool_xyz');

      expect(controller.currentState, equals(DrawingState.idle));
      expect(controller.currentTool, equals(DrawingTool.none));
    });

    test('🔐 selectTool com string vazia deve resultar em idle', () {
      controller.selectTool('');

      expect(controller.currentState, equals(DrawingState.idle));
      expect(controller.currentTool, equals(DrawingTool.none));
    });

    test('🔐 Alternar entre tools válidas e inválidas não deve quebrar', () {
      expect(() {
        controller.selectTool('polygon');
        controller.selectTool('invalid');
        controller.selectTool('rectangle');
        controller.selectTool('');
        controller.selectTool('circle');
      }, returnsNormally);

      expect(controller.currentState, equals(DrawingState.armed));
      expect(controller.currentTool, equals(DrawingTool.circle));
    });

    test('🔐 Estado armed com pontos zerados deve ser consistente', () {
      controller.selectTool('polygon');
      expect(controller.currentState, equals(DrawingState.armed));
      expect(controller.liveGeometry, isNull);
      expect(controller.liveAreaHa, equals(0.0));
    });
  });

  group('FIX-DRAW-FLOW-02 — Regressão: InstructionText Consistency', () {
    late DrawingController controller;

    setUp(() {
      controller = DrawingController(repository: MockDrawingRepository());
    });

    tearDown(() {
      controller.dispose();
    });

    test('📝 instructionText nunca deve retornar vazio', () {
      // Testar em todos os estados possíveis
      expect(controller.instructionText, isNotEmpty);

      controller.selectTool('polygon');
      expect(controller.instructionText, isNotEmpty);

      controller.appendDrawingPoint(const LatLng(-15.7801, -47.9292));
      expect(controller.instructionText, isNotEmpty);

      controller.appendDrawingPoint(const LatLng(-15.7802, -47.9293));
      expect(controller.instructionText, isNotEmpty);

      controller.cancelOperation();
      expect(controller.instructionText, isNotEmpty);
    });

    test('📝 instructionText deve mudar com transições de estado', () {
      final idleText = controller.instructionText;

      controller.selectTool('polygon');
      final armedText = controller.instructionText;

      expect(armedText, isNot(equals(idleText)));

      controller.appendDrawingPoint(const LatLng(-15.7801, -47.9292));
      controller.appendDrawingPoint(const LatLng(-15.7802, -47.9293));
      controller.appendDrawingPoint(const LatLng(-15.7803, -47.9294));
      final drawingText = controller.instructionText;

      expect(drawingText, isNot(equals(armedText)));
    });

    test('📝 instructionText deve ser específico para estado armed', () {
      controller.selectTool('polygon');

      expect(
        controller.instructionText,
        equals('Toque no mapa para iniciar o desenho'),
      );
    });
  });

  group('FIX-DRAW-FLOW-02 — Regressão: Lifecycle', () {
    test('♻️ Criar e descartar controller não deve lançar erro', () {
      expect(() {
        final controller = DrawingController(
          repository: MockDrawingRepository(),
        );
        controller.dispose();
      }, returnsNormally);
    });

    test('♻️ Usar controller após dispose não deve travar (silent fail)', () {
      final controller = DrawingController(repository: MockDrawingRepository());
      controller.dispose();

      // Operações após dispose não devem lançar exceções críticas
      expect(() {
        controller.selectTool('polygon');
      }, returnsNormally);
    });

    test('♻️ Múltiplos dispose não devem lançar erro', () {
      final controller = DrawingController(repository: MockDrawingRepository());

      expect(() {
        controller.dispose();
        controller.dispose();
        controller.dispose();
      }, returnsNormally);
    });
  });

  group('FIX-DRAW-FLOW-02 — Regressão: Concurrency Simulation', () {
    late DrawingController controller;

    setUp(() {
      controller = DrawingController(repository: MockDrawingRepository());
    });

    tearDown(() {
      controller.dispose();
    });

    test('⚡ Simulação: usuário indeciso trocando ferramentas', () {
      expect(() {
        controller.selectTool('polygon');
        controller.selectTool('rectangle');
        controller.selectTool('polygon');
        controller.appendDrawingPoint(const LatLng(-15.7801, -47.9292));
        controller.selectTool('circle');
        controller.appendDrawingPoint(const LatLng(-15.7802, -47.9293));
        controller.cancelOperation();
        controller.selectTool('freehand');
      }, returnsNormally);

      expect(controller.currentState, equals(DrawingState.armed));
      expect(controller.currentTool, equals(DrawingTool.freehand));
    });

    test('⚡ Simulação: cancelar e rearmar imediatamente', () {
      for (var i = 0; i < 50; i++) {
        controller.selectTool('polygon');
        controller.appendDrawingPoint(LatLng(-15.78 + i * 0.001, -47.92));
        controller.cancelOperation();
        controller.selectTool('rectangle');
        controller.cancelOperation();
      }

      expect(controller.currentState, equals(DrawingState.idle));
    });

    test('⚡ Simulação: desenhar, cancelar, redesenhar', () {
      // Primeiro desenho
      controller.selectTool('polygon');
      controller.appendDrawingPoint(const LatLng(-15.7801, -47.9292));
      controller.appendDrawingPoint(const LatLng(-15.7802, -47.9293));
      controller.appendDrawingPoint(const LatLng(-15.7803, -47.9294));
      expect(controller.liveGeometry, isNotNull);

      // Cancelar
      controller.cancelOperation();
      expect(controller.liveGeometry, isNull);

      // Segundo desenho
      controller.selectTool('circle');
      controller.appendDrawingPoint(const LatLng(-15.7801, -47.9292));
      expect(controller.currentState, equals(DrawingState.drawing));
    });
  });

  group('FIX-DRAW-FLOW-02 — Regressão: Geometria Validity', () {
    late DrawingController controller;

    setUp(() {
      controller = DrawingController(repository: MockDrawingRepository());
    });

    tearDown(() {
      controller.dispose();
    });

    test('📐 liveGeometry deve ser null em idle', () {
      expect(controller.liveGeometry, isNull);
    });

    test('📐 liveGeometry deve ser null em armed', () {
      controller.selectTool('polygon');
      expect(controller.liveGeometry, isNull);
    });

    test('📐 liveGeometry deve ter pontos após appendDrawingPoint', () {
      controller.selectTool('polygon');
      controller.appendDrawingPoint(const LatLng(-15.7801, -47.9292));
      controller.appendDrawingPoint(const LatLng(-15.7802, -47.9293));

      expect(controller.liveGeometry, isNotNull);
    });

    test('📐 liveAreaHa deve ser 0 sem geometria', () {
      expect(controller.liveAreaHa, equals(0.0));

      controller.selectTool('polygon');
      expect(controller.liveAreaHa, equals(0.0));
    });

    test('📐 liveAreaHa deve ser > 0 com polígono válido', () {
      controller.selectTool('polygon');
      controller.appendDrawingPoint(const LatLng(-15.7801, -47.9292));
      controller.appendDrawingPoint(const LatLng(-15.7802, -47.9293));
      controller.appendDrawingPoint(const LatLng(-15.7803, -47.9291));
      controller.appendDrawingPoint(const LatLng(-15.7801, -47.9292));

      expect(controller.liveAreaHa, greaterThan(0.0));
    });
  });
}
