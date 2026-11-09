import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/modules/drawing/domain/drawing_state.dart';
import 'package:soloforte_app/modules/drawing/presentation/widgets/drawing_state_indicator.dart';

void main() {
  testWidgets('não exibe banner durante desenho com pontos no mapa', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: DrawingStateIndicator(
            state: DrawingState.drawing,
            tool: DrawingTool.polygon,
          ),
        ),
      ),
    );

    expect(find.textContaining('Desenhando'), findsNothing);
    expect(find.byType(AnimatedContainer), findsNothing);
  });

  testWidgets('não exibe banner no centro para feature selecionada', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: DrawingStateIndicator(
            state: DrawingState.selected,
            tool: DrawingTool.none,
          ),
        ),
      ),
    );

    expect(find.text('Feature selecionada'), findsNothing);
    expect(find.byType(AnimatedContainer), findsNothing);
  });
}
