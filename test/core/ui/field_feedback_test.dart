import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/core/ui/field_feedback.dart';

void main() {
  testWidgets('showFieldSuccess mostra a mensagem e vibra', (tester) async {
    final haptics = <String>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'HapticFeedback.vibrate') {
          haptics.add(call.arguments as String);
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showFieldSuccess(context, 'Visita registrada.'),
              child: const Text('ok'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('ok'));
    await tester.pump();

    expect(find.text('Visita registrada.'), findsOneWidget);
    expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
    expect(haptics, contains('HapticFeedbackType.mediumImpact'));
  });
}
