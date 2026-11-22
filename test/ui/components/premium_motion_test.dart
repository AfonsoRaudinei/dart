import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/ui/components/premium/premium_motion.dart';

Widget _host(Widget child, {bool reduceMotion = false}) => MaterialApp(
  home: MediaQuery(
    data: MediaQueryData(disableAnimations: reduceMotion),
    child: Scaffold(body: Center(child: child)),
  ),
);

void main() {
  group('AnimatedCount', () {
    testWidgets('sobe de 0 até o valor', (tester) async {
      await tester.pumpWidget(_host(const AnimatedCount(value: 12)));
      expect(find.text('0'), findsOneWidget);
      await tester.pumpAndSettle();
      expect(find.text('12'), findsOneWidget);
    });

    testWidgets('com reduzir movimento mostra o valor final já', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(const AnimatedCount(value: 12), reduceMotion: true),
      );
      expect(find.text('12'), findsOneWidget);
    });
  });

  group('PressableScale', () {
    Future<double> scaleAfterPress(
      WidgetTester tester, {
      required bool reduceMotion,
    }) async {
      await tester.pumpWidget(
        _host(
          const PressableScale(child: SizedBox(width: 80, height: 80)),
          reduceMotion: reduceMotion,
        ),
      );
      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(PressableScale)),
      );
      await tester.pump(kPremiumPressDuration * 2);
      final scale = tester
          .widget<AnimatedScale>(find.byType(AnimatedScale))
          .scale;
      await gesture.up();
      await tester.pumpAndSettle();
      return scale;
    }

    testWidgets('afunda ao toque e volta ao soltar', (tester) async {
      expect(await scaleAfterPress(tester, reduceMotion: false), 0.97);
      expect(tester.widget<AnimatedScale>(find.byType(AnimatedScale)).scale, 1);
    });

    testWidgets('não escala com reduzir movimento', (tester) async {
      expect(await scaleAfterPress(tester, reduceMotion: true), 1);
    });

    testWidgets('não bloqueia o toque do filho', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        _host(
          PressableScale(
            child: GestureDetector(
              onTap: () => taps++,
              child: const ColoredBox(
                color: Colors.red,
                child: SizedBox(width: 80, height: 80),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.byType(PressableScale));
      expect(taps, 1);
    });
  });
}
