import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/ui/components/map/map_layers_sheet.dart';

void main() {
  group('LayersSheet ações operacionais', () {
    testWidgets('exibe e dispara somente o callback correspondente', (
      tester,
    ) async {
      var coordinateCalls = 0;
      var offlineCalls = 0;

      await _pumpLayersSheet(
        tester,
        onCoordinateSearch: () async => coordinateCalls++,
        onDownloadOfflineArea: () async => offlineCalls++,
      );

      expect(find.text('Ir para coordenada'), findsOneWidget);
      expect(find.text('Baixar área offline'), findsOneWidget);

      await tester.tap(find.text('Ir para coordenada'));
      await tester.pump();
      expect(coordinateCalls, 1);
      expect(offlineCalls, 0);

      await tester.tap(find.text('Baixar área offline'));
      await tester.pump();
      expect(coordinateCalls, 1);
      expect(offlineCalls, 1);
    });

    testWidgets('oculta ações quando callbacks não são fornecidos', (
      tester,
    ) async {
      await _pumpLayersSheet(tester);

      expect(find.text('Ir para coordenada'), findsNothing);
      expect(find.text('Baixar área offline'), findsNothing);
    });
  });
}

Future<void> _pumpLayersSheet(
  WidgetTester tester, {
  Future<void> Function()? onCoordinateSearch,
  Future<void> Function()? onDownloadOfflineArea,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        home: Scaffold(
          body: SizedBox(
            height: 800,
            child: LayersSheet(
              onClose: () {},
              onCoordinateSearch: onCoordinateSearch,
              onDownloadOfflineArea: onDownloadOfflineArea,
              renderTilePreviews: false,
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}
