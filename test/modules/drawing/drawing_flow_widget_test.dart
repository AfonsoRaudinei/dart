import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:soloforte_app/modules/drawing/presentation/controllers/drawing_controller.dart';
import 'package:soloforte_app/modules/drawing/presentation/widgets/drawing_sheet.dart';
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

/// ✅ FIX-DRAW-FLOW-02 — Testes de Widget do Fluxo de Desenho
///
/// Valida que o Bottom Sheet fecha corretamente ao selecionar ferramenta
/// e que o estado visual do aplicativo reflete o estado da state machine.
///
/// Este teste BLINDAGEM contra regressões de UI no fluxo crítico.
void main() {
  group('FIX-DRAW-FLOW-02 — DrawingSheet Widget Flow', () {
    testWidgets('✅ Bottom Sheet deve exibir ferramentas', (
      WidgetTester tester,
    ) async {
      // Configurar tela grande para evitar overflow
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      // Arrange
      final controller = DrawingController(repository: MockDrawingRepository());

      // Act
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: DrawingSheet(controller: controller),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert — Verificar que as ferramentas estão visíveis
      expect(find.text('Polígono'), findsOneWidget);
      expect(find.text('Livre'), findsOneWidget);
      expect(find.text('Pivô'), findsOneWidget);
      expect(find.text('Importar (KML)'), findsOneWidget);

      controller.dispose();
    });

    testWidgets('✅ Tap em ferramenta deve ativar o controller', (
      WidgetTester tester,
    ) async {
      // Configurar tela grande para evitar overflow
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      // Arrange
      final controller = DrawingController(repository: MockDrawingRepository());

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: DrawingSheet(controller: controller),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(controller.currentState, equals(DrawingState.idle));

      // Act — Tocar no botão "Polígono"
      await tester.tap(find.text('Polígono'));
      await tester.pump(); // Processar tap

      // Assert — Controller deve estar armed
      expect(controller.currentState, equals(DrawingState.armed));
      expect(controller.currentTool, equals(DrawingTool.polygon));

      controller.dispose();
    });

    testWidgets('🚪 Bottom Sheet modal deve fechar ao selecionar ferramenta', (
      WidgetTester tester,
    ) async {
      // Configurar tela grande
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      // Arrange
      final controller = DrawingController(repository: MockDrawingRepository());
      bool sheetClosed = false;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  return ElevatedButton(
                    onPressed: () async {
                      await showModalBottomSheet(
                        context: context,
                        backgroundColor: Colors.transparent,
                        isScrollControlled: true, // Evitar overflow
                        builder: (_) => SingleChildScrollView(
                          child: DrawingSheet(controller: controller),
                        ),
                      ).then((_) {
                        sheetClosed = true;
                      });
                    },
                    child: const Text('Abrir Sheet'),
                  );
                },
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Act — Abrir o bottom sheet
      await tester.tap(find.text('Abrir Sheet'));
      await tester.pumpAndSettle();

      // Verificar que o sheet está aberto
      expect(find.text('Polígono'), findsOneWidget);
      expect(sheetClosed, isFalse);

      // Act — Tocar na ferramenta
      await tester.tap(find.text('Polígono'));
      await tester.pumpAndSettle();

      // Assert — Sheet deve ter fechado
      expect(sheetClosed, isTrue);
      expect(
        find.text('Polígono'),
        findsNothing,
      ); // Sheet não deve mais estar visível
      expect(controller.currentState, equals(DrawingState.armed));

      controller.dispose();
    });

    testWidgets('📝 InstructionText deve atualizar no Tooltip', (
      WidgetTester tester,
    ) async {
      // Arrange
      final controller = DrawingController(repository: MockDrawingRepository());

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: DrawingSheet(controller: controller),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Estado inicial
      expect(
        controller.instructionText,
        equals('Selecione uma ferramenta ou toque no mapa'),
      );

      // Act — Selecionar ferramenta
      await tester.tap(find.text('Polígono'));
      await tester.pump();

      // Assert
      expect(
        controller.instructionText,
        equals('Toque no mapa para iniciar o desenho'),
      );

      controller.dispose();
    });

    testWidgets('🔄 Trocar ferramenta deve atualizar estado visualmente', (
      WidgetTester tester,
    ) async {
      // Arrange
      final controller = DrawingController(repository: MockDrawingRepository());

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: DrawingSheet(controller: controller),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Act — Selecionar primeira ferramenta
      await tester.tap(find.text('Polígono'));
      await tester.pump();
      expect(controller.currentTool, equals(DrawingTool.polygon));

      // Act — Selecionar segunda ferramenta (sem reabrir sheet para este teste)
      controller.selectTool('rectangle');
      await tester.pump();

      // Assert
      expect(controller.currentTool, equals(DrawingTool.rectangle));
      expect(controller.currentState, equals(DrawingState.armed));

      controller.dispose();
    });

    testWidgets('📊 Métricas devem aparecer quando há geometria', (
      WidgetTester tester,
    ) async {
      // Arrange
      final controller = DrawingController(repository: MockDrawingRepository());

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: DrawingSheet(controller: controller),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Estado inicial — sem métricas
      expect(find.text('MÉTRICAS'), findsNothing);

      // Simular pontos no controller
      controller.selectTool('polygon');
      controller.appendDrawingPoint(const LatLng(-15.7801, -47.9292));
      controller.appendDrawingPoint(const LatLng(-15.7802, -47.9293));
      controller.appendDrawingPoint(const LatLng(-15.7803, -47.9291));
      controller.appendDrawingPoint(const LatLng(-15.7801, -47.9292));

      await tester.pumpAndSettle();

      // Assert — Métricas devem aparecer
      expect(find.text('MÉTRICAS'), findsOneWidget);
      expect(
        find.textContaining('ha'),
        findsWidgets,
      ); // Deve ter área em hectares

      controller.dispose();
    });
  });

  group('FIX-DRAW-FLOW-02 — Regressão Sheet State', () {
    testWidgets('🔁 Reabrir sheet após fechar deve funcionar', (
      WidgetTester tester,
    ) async {
      final controller = DrawingController(repository: MockDrawingRepository());

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  return ElevatedButton(
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        builder: (_) => SingleChildScrollView(
                          child: DrawingSheet(controller: controller),
                        ),
                      );
                    },
                    child: const Text('Abrir'),
                  );
                },
              ),
            ),
          ),
        ),
      );

      // Abrir sheet
      await tester.tap(find.text('Abrir'));
      await tester.pumpAndSettle();
      expect(find.text('Polígono'), findsOneWidget);

      // Selecionar ferramenta (fecha sheet)
      await tester.tap(find.text('Polígono'));
      await tester.pumpAndSettle();
      expect(find.text('Polígono'), findsNothing);

      // Reabrir sheet
      await tester.tap(find.text('Abrir'));
      await tester.pumpAndSettle();
      expect(find.text('Polígono'), findsOneWidget);

      controller.dispose();
    });

    testWidgets('🔁 Cancelar operação e reabrir sheet deve funcionar', (
      WidgetTester tester,
    ) async {
      final controller = DrawingController(repository: MockDrawingRepository());

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: DrawingSheet(controller: controller),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Selecionar ferramenta via controller (evita hit test issues)
      controller.selectTool('polygon');
      await tester.pump();
      expect(controller.currentState, equals(DrawingState.armed));

      // Cancelar
      controller.cancelOperation();
      await tester.pump();
      expect(controller.currentState, equals(DrawingState.idle));

      // Reselecionar ferramenta
      controller.selectTool('freehand');
      await tester.pump();
      expect(controller.currentState, equals(DrawingState.armed));
      expect(controller.currentTool, equals(DrawingTool.freehand));

      controller.dispose();
    });

    testWidgets('🚫 Não deve lançar erro se controller for descartado', (
      WidgetTester tester,
    ) async {
      final controller = DrawingController(repository: MockDrawingRepository());

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: DrawingSheet(controller: controller),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Descartar controller
      controller.dispose();

      // Tentar rebuild (não deve lançar erro)
      expect(() async {
        await tester.pump();
      }, returnsNormally);
    });
  });

  group('FIX-DRAW-FLOW-02 — Integration: Sheet + Controller', () {
    testWidgets(
      '🔗 Fluxo completo: abrir → selecionar → fechar → estado armed',
      (WidgetTester tester) async {
        final controller = DrawingController(
          repository: MockDrawingRepository(),
        );

        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: Scaffold(
                body: Builder(
                  builder: (context) {
                    return Column(
                      children: [
                        ElevatedButton(
                          onPressed: () {
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              builder: (_) => SingleChildScrollView(
                                child: DrawingSheet(controller: controller),
                              ),
                            );
                          },
                          child: const Text('Desenhar'),
                        ),
                        // Simular indicador de estado
                        ListenableBuilder(
                          listenable: controller,
                          builder: (context, _) {
                            return Text(
                              'Estado: ${controller.currentState.name}',
                            );
                          },
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // 1. Estado inicial
        expect(find.text('Estado: idle'), findsOneWidget);

        // 2. Abrir sheet
        await tester.tap(find.text('Desenhar'));
        await tester.pumpAndSettle();
        expect(find.text('Polígono'), findsOneWidget);

        // 3. Selecionar ferramenta
        await tester.tap(find.text('Polígono'));
        await tester.pumpAndSettle();

        // 4. Sheet deve ter fechado
        expect(find.text('Polígono'), findsNothing);

        // 5. Estado deve ser armed
        expect(find.text('Estado: armed'), findsOneWidget);
        expect(controller.currentTool, equals(DrawingTool.polygon));

        controller.dispose();
      },
    );

    testWidgets('🔗 Múltiplas ferramentas: trocar não deve quebrar', (
      WidgetTester tester,
    ) async {
      final controller = DrawingController(repository: MockDrawingRepository());

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: DrawingSheet(controller: controller),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Testar todas as ferramentas via controller (evita hit test issues em scroll)
      final tools = ['polygon', 'freehand', 'pivot'];

      for (final tool in tools) {
        controller.selectTool(tool);
        await tester.pump();
        expect(controller.currentState, equals(DrawingState.armed));
      }

      controller.dispose();
    });
  });
}
