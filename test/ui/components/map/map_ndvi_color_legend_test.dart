import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/ui/components/map/map_ndvi_color_legend.dart';

void main() {
  Future<void> pumpLegend(
    WidgetTester tester, {
    bool labelsToTheRight = true,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 480,
              height: 160,
              child: MapNdviColorLegend(
                key: ValueKey(labelsToTheRight),
                labelsToTheRight: labelsToTheRight,
              ),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('recolhida mostra as três cores e nenhum rótulo', (tester) async {
    await pumpLegend(tester);

    expect(
      find.byKey(const Key('map_ndvi_legend_swatch_alto')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('map_ndvi_legend_swatch_intermediario')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('map_ndvi_legend_swatch_baixo')),
      findsOneWidget,
    );
    expect(find.text('Alto'), findsNothing);
    expect(find.text('Intermediário'), findsNothing);
    expect(find.text('Baixo'), findsNothing);
  });

  testWidgets('arrasto horizontal abre e o segundo gesto recolhe', (
    tester,
  ) async {
    await pumpLegend(tester);

    await tester.fling(
      find.byKey(const Key('map_ndvi_legend')),
      const Offset(80, 0),
      800,
    );
    await tester.pump();

    expect(find.text('Alto'), findsOneWidget);
    expect(find.text('Intermediário'), findsOneWidget);
    expect(find.text('Baixo'), findsOneWidget);

    await tester.fling(
      find.byKey(const Key('map_ndvi_legend')),
      const Offset(-80, 0),
      800,
    );
    await tester.pump();

    expect(find.text('Alto'), findsNothing);
    expect(find.text('Intermediário'), findsNothing);
    expect(find.text('Baixo'), findsNothing);
  });

  testWidgets('os dois lados abrem sem overflow', (tester) async {
    for (final labelsToTheRight in const [false, true]) {
      await pumpLegend(tester, labelsToTheRight: labelsToTheRight);
      await tester.tap(find.byKey(const Key('map_ndvi_legend')));
      await tester.pump();

      expect(find.text('Alto'), findsOneWidget);
      expect(find.text('Intermediário'), findsOneWidget);
      expect(find.text('Baixo'), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  });
}
