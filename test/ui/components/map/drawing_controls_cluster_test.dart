import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/ui/components/map/widgets/map_controls_overlay.dart';

void main() {
  testWidgets('renderiza backplate sólido e ações principais do desenho', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: DrawingControlsCluster(
            primaryColor: Colors.green,
            hasSelfIntersection: false,
            onFinishDrawing: _noop,
            onUndoDrawing: _noop,
            onCancelDrawing: _noop,
            canUndo: true,
          ),
        ),
      ),
    );

    expect(find.byKey(const Key('drawing_controls_backplate')), findsOneWidget);
    expect(find.byIcon(Icons.undo_rounded), findsOneWidget);
    expect(find.byType(InkWell), findsNWidgets(3));
  });
}

void _noop() {}
