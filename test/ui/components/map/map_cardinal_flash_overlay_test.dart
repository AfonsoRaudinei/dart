import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/modules/map/presentation/providers/map_location_mode_provider.dart';
import 'package:soloforte_app/ui/components/map/widgets/map_cardinal_flash_overlay.dart';

void main() {
  testWidgets('northLocked mostra N S L O e some após a duração', (
    tester,
  ) async {
    await tester.pumpWidget(_host(MapLocationMode.northLocked));

    expect(find.text('N'), findsOneWidget);
    expect(find.text('S'), findsOneWidget);
    expect(find.text('L'), findsOneWidget);
    expect(find.text('O'), findsOneWidget);

    await tester.pump(kMapCardinalFlashDuration);

    expect(find.text('N'), findsNothing);
    expect(find.text('S'), findsNothing);
    expect(find.text('L'), findsNothing);
    expect(find.text('O'), findsNothing);
  });

  testWidgets('idle não mostra as letras cardeais', (tester) async {
    await tester.pumpWidget(_host(MapLocationMode.idle));
    await tester.pump();

    expect(find.text('N'), findsNothing);
    expect(find.text('S'), findsNothing);
    expect(find.text('L'), findsNothing);
    expect(find.text('O'), findsNothing);
  });

  testWidgets(
    'following não mostra; a transição para northLocked liga o flash',
    (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(body: Stack(children: [MapCardinalFlashOverlay()])),
          ),
        ),
      );

      expect(find.text('N'), findsNothing);

      container.read(mapLocationModeProvider.notifier).state =
          MapLocationMode.following;
      await tester.pump();
      expect(find.text('L'), findsNothing);
      expect(find.text('O'), findsNothing);

      container.read(mapLocationModeProvider.notifier).state =
          MapLocationMode.northLocked;
      await tester.pump();

      expect(find.text('N'), findsOneWidget);
      expect(find.text('S'), findsOneWidget);
      expect(find.text('L'), findsOneWidget);
      expect(find.text('O'), findsOneWidget);
    },
  );
}

Widget _host(MapLocationMode mode) {
  return ProviderScope(
    overrides: [mapLocationModeProvider.overrideWith((ref) => mode)],
    child: const MaterialApp(
      home: Scaffold(body: Stack(children: [MapCardinalFlashOverlay()])),
    ),
  );
}
