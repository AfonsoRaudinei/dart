import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:soloforte_app/core/infra/preferences_service.dart';
import 'package:soloforte_app/modules/consultoria/occurrences/domain/occurrence.dart';
import 'package:soloforte_app/modules/consultoria/occurrences/presentation/widgets/occurrence_detail_sheet.dart';

void main() {
  setUpAll(() => initializeDateFormatting('pt_BR'));

  testWidgets(
    'detalhe no mapa omite status Rascunho/Confirmada e exibe ações de relatório',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final preferencesService = PreferencesService(
        await SharedPreferences.getInstance(),
      );
      final occurrence = Occurrence(
        id: 'occ-report-actions',
        type: 'Média',
        description: 'Praga leve no talhão',
        status: 'draft',
        createdAt: DateTime.utc(2026, 10, 1, 14, 0),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            preferencesServiceProvider.overrideWithValue(preferencesService),
          ],
          child: MaterialApp(
            home: Builder(
              builder: (context) => TextButton(
                onPressed: () => OccurrenceDetailSheet.show(
                  context,
                  occurrence,
                ),
                child: const Text('abrir-detalhe'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('abrir-detalhe'));
      await tester.pumpAndSettle();

      expect(find.text('Status'), findsNothing);
      expect(find.text('Rascunho'), findsNothing);
      expect(find.text('Confirmada'), findsNothing);
      expect(find.text('Abrir relatório'), findsOneWidget);
      expect(find.text('Exportar HTML'), findsOneWidget);
      expect(find.textContaining('Urgência'), findsOneWidget);
    },
  );

  Future<void> pumpDetail(
    WidgetTester tester,
    Occurrence occurrence, {
    Future<void> Function(BuildContext, Occurrence)? onExportLocation,
  }) async {
    SharedPreferences.setMockInitialValues({});
    final preferencesService = PreferencesService(
      await SharedPreferences.getInstance(),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          preferencesServiceProvider.overrideWithValue(preferencesService),
        ],
        child: MaterialApp(
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () => OccurrenceDetailSheet.show(
                context,
                occurrence,
                onExportLocation: onExportLocation,
              ),
              child: const Text('abrir-detalhe'),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('abrir-detalhe'));
    await tester.pumpAndSettle();
  }

  Occurrence buildOccurrence(String category) => Occurrence(
        id: 'occ-$category',
        type: 'Média',
        description: 'sede',
        status: 'draft',
        category: category,
        lat: -10.18,
        long: -48.88,
        createdAt: DateTime.utc(2026, 9, 21, 16, 19),
      );

  testWidgets(
    'área visitada com callback exibe Exportar localização e oculta urgência',
    (tester) async {
      Occurrence? exported;
      await pumpDetail(
        tester,
        buildOccurrence(kOccurrenceAreaVisitadaCategory),
        onExportLocation: (_, o) async => exported = o,
      );

      expect(find.text('Exportar localização'), findsOneWidget);
      expect(find.textContaining('Urgência'), findsNothing);

      await tester.ensureVisible(find.text('Exportar localização'));
      await tester.tap(find.text('Exportar localização'));
      await tester.pumpAndSettle();
      expect(exported?.id, 'occ-$kOccurrenceAreaVisitadaCategory');
    },
  );

  testWidgets('área visitada sem callback não exibe Exportar localização', (
    tester,
  ) async {
    await pumpDetail(tester, buildOccurrence(kOccurrenceAreaVisitadaCategory));

    expect(find.text('Exportar localização'), findsNothing);
  });

  testWidgets('outras categorias não exibem Exportar localização', (
    tester,
  ) async {
    await pumpDetail(
      tester,
      buildOccurrence('insetos'),
      onExportLocation: (context, occurrence) async {},
    );

    expect(find.text('Exportar localização'), findsNothing);
    expect(find.textContaining('Urgência'), findsOneWidget);
  });
}
