import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/modules/consultoria/occurrences/presentation/coordinators/occurrence_close_coordinator.dart';
import 'package:soloforte_app/modules/consultoria/occurrences/presentation/coordinators/occurrence_form_guard.dart';

void main() {
  group('OccurrenceCloseCoordinator', () {
    testWidgets('fecha imediatamente quando formulário não está dirty', (
      tester,
    ) async {
      final guard = OccurrenceFormGuard();
      guard.readIsDirty = () => false;
      var closed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () async {
                  closed = await OccurrenceCloseCoordinator.confirmDiscardIfDirty(
                    context,
                    guard: guard,
                  );
                },
                child: const Text('Fechar'),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Fechar'));
      await tester.pumpAndSettle();

      expect(closed, isTrue);
      expect(find.text('Descartar ocorrência?'), findsNothing);
    });

    testWidgets('pede confirmação quando formulário está dirty', (
      tester,
    ) async {
      final guard = OccurrenceFormGuard();
      guard.readIsDirty = () => true;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () {
                  OccurrenceCloseCoordinator.confirmDiscardIfDirty(
                    context,
                    guard: guard,
                  );
                },
                child: const Text('Fechar'),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Fechar'));
      await tester.pumpAndSettle();

      expect(find.text('Descartar ocorrência?'), findsOneWidget);
    });
  });
}
