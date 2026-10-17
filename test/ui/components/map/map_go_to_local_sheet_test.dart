import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/ui/components/map/map_go_to_local_sheet.dart';

void main() {
  testWidgets('MapGoToLocalSheet dispara callback de município', (tester) async {
    var municipalityCalls = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: ElevatedButton(
              onPressed: () {
                showMapGoToLocalSheet(
                  context,
                  onMunicipalitySearch: () async => municipalityCalls++,
                  onCoordinateSearch: () async {},
                );
              },
              child: const Text('Abrir'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();

    expect(find.text('Ir para local'), findsOneWidget);
    await tester.tap(find.text('Ir para município'));
    await tester.pumpAndSettle();

    expect(municipalityCalls, 1);
  });

  testWidgets('MapGoToLocalSheet dispara callback de coordenada', (tester) async {
    var coordinateCalls = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: ElevatedButton(
              onPressed: () {
                showMapGoToLocalSheet(
                  context,
                  onMunicipalitySearch: () async {},
                  onCoordinateSearch: () async => coordinateCalls++,
                );
              },
              child: const Text('Abrir'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ir para coordenada'));
    await tester.pumpAndSettle();

    expect(coordinateCalls, 1);
  });
}
