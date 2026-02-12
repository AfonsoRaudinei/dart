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

/// ✅ FIX-DRAW-FLOW-02 — Testes Unitários do Fluxo de Desenho
///
/// Valida que o fluxo de desenho respeita a sequência:
/// selectTool() → state = armed → tap no mapa → state = drawing
///
/// Este teste BLINDAGEM contra regressões no fluxo crítico.
void main() {
  group('FIX-DRAW-FLOW-02 — State Machine Flow', () {
    late DrawingController controller;

    setUp(() {
      controller = DrawingController(repository: MockDrawingRepository());
    });

    tearDown(() {
      controller.dispose();
    });

    test(
      '✅ Estado inicial deve ser idle',
      () {
        expect(controller.currentState, equals(DrawingState.idle));
        expect(controller.currentTool, equals(DrawingTool.none));
      },
    );

    test(
      '✅ selectTool(polygon) deve transicionar para armed',
      () {
        // Act
        controller.selectTool('polygon');

        // Assert
        expect(controller.currentState, equals(DrawingState.armed));
        expect(controller.currentTool, equals(DrawingTool.polygon));
      },
    );

    test(
      '✅ instructionText deve retornar mensagem correta no estado armed',
      () {
        // Arrange
        controller.selectTool('polygon');

        // Act
        final instruction = controller.instructionText;

        // Assert
        expect(
          instruction,
          equals('Toque no mapa para iniciar o desenho'),
        );
      },
    );

    test(
      '✅ appendDrawingPoint deve transicionar de armed para drawing',
      () {
        // Arrange
        controller.selectTool('polygon');
        expect(controller.currentState, equals(DrawingState.armed));

        // Act
        controller.appendDrawingPoint(const LatLng(-15.7801, -47.9292));

        // Assert
        expect(controller.currentState, equals(DrawingState.drawing));
      },
    );

    test(
      '✅ Múltiplos pontos devem permanecer em drawing',
      () {
        // Arrange
        controller.selectTool('polygon');
        controller.appendDrawingPoint(const LatLng(-15.7801, -47.9292));

        // Act
        controller.appendDrawingPoint(const LatLng(-15.7802, -47.9293));
        controller.appendDrawingPoint(const LatLng(-15.7803, -47.9294));

        // Assert
        expect(controller.currentState, equals(DrawingState.drawing));
      },
    );

    test(
      '✅ liveGeometry deve conter pontos após appendDrawingPoint',
      () {
        // Arrange
        controller.selectTool('polygon');

        // Act
        controller.appendDrawingPoint(const LatLng(-15.7801, -47.9292));
        controller.appendDrawingPoint(const LatLng(-15.7802, -47.9293));

        // Assert
        expect(controller.liveGeometry, isNotNull);
      },
    );

    test(
      '✅ liveAreaHa deve retornar > 0 após 3+ pontos',
      () {
        // Arrange
        controller.selectTool('polygon');

        // Act
        controller.appendDrawingPoint(const LatLng(-15.7801, -47.9292));
        controller.appendDrawingPoint(const LatLng(-15.7802, -47.9293));
        controller.appendDrawingPoint(const LatLng(-15.7803, -47.9291));
        controller.appendDrawingPoint(const LatLng(-15.7801, -47.9292));

        // Assert
        expect(controller.liveAreaHa, greaterThan(0.0));
      },
    );

    test(
      '🔁 Trocar ferramenta deve resetar estado corretamente',
      () {
        // Arrange
        controller.selectTool('polygon');
        controller.appendDrawingPoint(const LatLng(-15.7801, -47.9292));
        expect(controller.currentState, equals(DrawingState.drawing));

        // Act — trocar para outra ferramenta
        controller.selectTool('rectangle');

        // Assert
        expect(controller.currentState, equals(DrawingState.armed));
        expect(controller.currentTool, equals(DrawingTool.rectangle));
        expect(controller.liveGeometry, isNull); // Pontos anteriores limpos
      },
    );

    test(
      '🔁 Trocar ferramenta rapidamente não deve lançar erro',
      () {
        // Act — múltiplas trocas rápidas
        expect(
          () {
            controller.selectTool('polygon');
            controller.selectTool('rectangle');
            controller.selectTool('circle');
            controller.selectTool('freehand');
          },
          returnsNormally,
        );

        // Assert
        expect(controller.currentState, equals(DrawingState.armed));
        expect(controller.currentTool, equals(DrawingTool.freehand));
      },
    );

    test(
      '❌ selectTool(none) deve voltar para idle',
      () {
        // Arrange
        controller.selectTool('polygon');
        expect(controller.currentState, equals(DrawingState.armed));

        // Act
        controller.selectTool('none');

        // Assert
        expect(controller.currentState, equals(DrawingState.idle));
        expect(controller.currentTool, equals(DrawingTool.none));
      },
    );

    test(
      '❌ cancelOperation deve voltar para idle',
      () {
        // Arrange
        controller.selectTool('polygon');
        controller.appendDrawingPoint(const LatLng(-15.7801, -47.9292));
        expect(controller.currentState, equals(DrawingState.drawing));

        // Act
        controller.cancelOperation();

        // Assert
        expect(controller.currentState, equals(DrawingState.idle));
        expect(controller.liveGeometry, isNull);
      },
    );

    test(
      '🔄 Regressão: Rearmar após cancelar deve funcionar',
      () {
        // Arrange
        controller.selectTool('polygon');
        controller.appendDrawingPoint(const LatLng(-15.7801, -47.9292));
        controller.cancelOperation();
        expect(controller.currentState, equals(DrawingState.idle));

        // Act — rearmar com nova ferramenta
        controller.selectTool('circle');

        // Assert
        expect(controller.currentState, equals(DrawingState.armed));
        expect(controller.currentTool, equals(DrawingTool.circle));
      },
    );

    test(
      '🔄 Regressão: Múltiplos cancela e rearma não devem lançar erro',
      () {
        expect(
          () {
            for (var i = 0; i < 5; i++) {
              controller.selectTool('polygon');
              controller.appendDrawingPoint(LatLng(-15.78 + i * 0.001, -47.92));
              controller.cancelOperation();
            }
          },
          returnsNormally,
        );

        expect(controller.currentState, equals(DrawingState.idle));
      },
    );
  });

  group('FIX-DRAW-FLOW-02 — InstructionText Validation', () {
    late DrawingController controller;

    setUp(() {
      controller = DrawingController(repository: MockDrawingRepository());
    });

    tearDown(() {
      controller.dispose();
    });

    test(
      '📝 instructionText deve refletir estado idle',
      () {
        expect(
          controller.instructionText,
          equals('Selecione uma ferramenta ou toque no mapa'),
        );
      },
    );

    test(
      '📝 instructionText deve refletir estado armed',
      () {
        controller.selectTool('polygon');
        expect(
          controller.instructionText,
          equals('Toque no mapa para iniciar o desenho'),
        );
      },
    );

    test(
      '📝 instructionText deve mudar após primeiro ponto',
      () {
        controller.selectTool('polygon');
        controller.appendDrawingPoint(const LatLng(-15.7801, -47.9292));

        expect(
          controller.instructionText,
          isNot(equals('Toque no mapa para iniciar o desenho')),
        );
      },
    );

    test(
      '📝 instructionText deve guiar usuário com poucos pontos',
      () {
        controller.selectTool('polygon');
        controller.appendDrawingPoint(const LatLng(-15.7801, -47.9292));
        controller.appendDrawingPoint(const LatLng(-15.7802, -47.9293));

        expect(
          controller.instructionText,
          equals('Continue tocando para desenhar a área'),
        );
      },
    );

    test(
      '📝 instructionText deve mudar com 3+ pontos',
      () {
        controller.selectTool('polygon');
        controller.appendDrawingPoint(const LatLng(-15.7801, -47.9292));
        controller.appendDrawingPoint(const LatLng(-15.7802, -47.9293));
        controller.appendDrawingPoint(const LatLng(-15.7803, -47.9294));

        expect(
          controller.instructionText,
          equals('Toque para continuar ou no ponto inicial para fechar'),
        );
      },
    );
  });

  group('FIX-DRAW-FLOW-02 — Edge Cases', () {
    late DrawingController controller;

    setUp(() {
      controller = DrawingController(repository: MockDrawingRepository());
    });

    tearDown(() {
      controller.dispose();
    });

    test(
      '🚫 appendDrawingPoint em idle não deve fazer nada',
      () {
        // Act
        controller.appendDrawingPoint(const LatLng(-15.7801, -47.9292));

        // Assert
        expect(controller.currentState, equals(DrawingState.idle));
        expect(controller.liveGeometry, isNull);
      },
    );

    test(
      '🚫 appendDrawingPoint sem selectTool não deve adicionar ponto',
      () {
        // Act
        controller.appendDrawingPoint(const LatLng(-15.7801, -47.9292));

        // Assert
        expect(controller.liveGeometry, isNull);
      },
    );

    test(
      '🔐 selectTool com ferramenta inválida deve resultar em idle',
      () {
        // Act
        controller.selectTool('invalid_tool');

        // Assert
        expect(controller.currentState, equals(DrawingState.idle));
        expect(controller.currentTool, equals(DrawingTool.none));
      },
    );

    test(
      '🔐 Múltiplos taps no mesmo ponto devem funcionar',
      () {
        controller.selectTool('polygon');
        const point = LatLng(-15.7801, -47.9292);

        expect(
          () {
            controller.appendDrawingPoint(point);
            controller.appendDrawingPoint(point);
            controller.appendDrawingPoint(point);
          },
          returnsNormally,
        );
      },
    );
  });

  group('FIX-DRAW-FLOW-02 — Diferentes Ferramentas', () {
    late DrawingController controller;

    setUp(() {
      controller = DrawingController(repository: MockDrawingRepository());
    });

    tearDown(() {
      controller.dispose();
    });

    for (final tool in ['polygon', 'freehand', 'rectangle', 'circle', 'pivot']) {
      test(
        '🛠️ selectTool($tool) deve armar corretamente',
        () {
          controller.selectTool(tool);
          expect(controller.currentState, equals(DrawingState.armed));
        },
      );
    }

    test(
      '🛠️ Todas as ferramentas devem transicionar para drawing após ponto',
      () {
        for (final tool in ['polygon', 'freehand', 'rectangle', 'circle']) {
          controller.selectTool(tool);
          controller.appendDrawingPoint(const LatLng(-15.7801, -47.9292));
          expect(
            controller.currentState,
            equals(DrawingState.drawing),
            reason: 'Ferramenta $tool deve ir para drawing',
          );
          controller.cancelOperation();
        }
      },
    );
  });
}
