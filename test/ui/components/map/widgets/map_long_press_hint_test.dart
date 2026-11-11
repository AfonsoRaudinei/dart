import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/ui/components/map/widgets/map_long_press_hint.dart';
import 'package:soloforte_app/ui/screens/map/utils/map_long_press_prefs.dart';

void main() {
  testWidgets('390x844 — Entendi tocável, sem overflow', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    var acknowledged = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Stack(
            children: [
              MapLongPressHint(
                visible: true,
                onAcknowledged: () => acknowledged = true,
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(tester.takeException(), isNull);
    expect(find.text(kMapLongPressHintAcknowledgeLabel), findsOneWidget);

    await tester.tap(find.text(kMapLongPressHintAcknowledgeLabel));
    await tester.pump();

    expect(acknowledged, isTrue);
    expect(tester.takeException(), isNull);
  });
}
