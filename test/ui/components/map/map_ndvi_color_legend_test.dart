import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/ui/components/map/map_ndvi_color_legend.dart';

void main() {
  const classes = <({String label, String key, Color color})>[
    (label: 'Alto', key: 'alto', color: MapNdviColorLegend.alto),
    (label: 'Bom', key: 'bom', color: MapNdviColorLegend.bom),
    (
      label: 'Intermediário',
      key: 'intermediario',
      color: MapNdviColorLegend.intermediario,
    ),
    (label: 'Baixo', key: 'baixo', color: MapNdviColorLegend.baixo),
    (
      label: 'Muito Baixo',
      key: 'muito_baixo',
      color: MapNdviColorLegend.muitoBaixo,
    ),
  ];

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

  void expectAllLabels({required bool visible}) {
    for (final c in classes) {
      expect(
        find.text(c.label),
        visible ? findsOneWidget : findsNothing,
        reason: c.label,
      );
    }
  }

  testWidgets('recolhida mostra as cinco cores e nenhum rótulo', (
    tester,
  ) async {
    await pumpLegend(tester);

    for (final c in classes) {
      final swatch = find.byKey(Key('map_ndvi_legend_swatch_${c.key}'));
      expect(swatch, findsOneWidget, reason: c.key);
      final paint = tester.widget<CustomPaint>(
        find.descendant(of: swatch, matching: find.byType(CustomPaint)),
      );
      // ignore: avoid_dynamic_calls
      expect((paint.painter! as dynamic).color, c.color, reason: c.key);
    }
    expectAllLabels(visible: false);
  });

  testWidgets('aberta mostra os cinco rótulos, cada um na cor da classe', (
    tester,
  ) async {
    await pumpLegend(tester);
    await tester.tap(find.byKey(const Key('map_ndvi_legend')));
    await tester.pump();

    expectAllLabels(visible: true);
    double? previousSwatchTop;
    double? previousLabelTop;
    for (final c in classes) {
      final swatchTop = tester
          .getTopLeft(find.byKey(Key('map_ndvi_legend_swatch_${c.key}')))
          .dy;
      final labelTop = tester.getTopLeft(find.text(c.label)).dy;
      if (previousSwatchTop != null) {
        expect(swatchTop, greaterThan(previousSwatchTop), reason: c.key);
        expect(labelTop, greaterThan(previousLabelTop!), reason: c.label);
      }
      previousSwatchTop = swatchTop;
      previousLabelTop = labelTop;
      final text = tester.widget<Text>(find.text(c.label));
      expect(text.style?.color, c.color, reason: c.label);
      expect(text.style?.fontWeight, FontWeight.w700, reason: c.label);
    }
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

    expectAllLabels(visible: true);

    await tester.fling(
      find.byKey(const Key('map_ndvi_legend')),
      const Offset(-80, 0),
      800,
    );
    await tester.pump();

    expectAllLabels(visible: false);
  });

  testWidgets('os dois lados abrem sem overflow', (tester) async {
    for (final labelsToTheRight in const [false, true]) {
      await pumpLegend(tester, labelsToTheRight: labelsToTheRight);
      await tester.tap(find.byKey(const Key('map_ndvi_legend')));
      await tester.pump();

      expectAllLabels(visible: true);
      expect(tester.takeException(), isNull);
    }
  });
}
