import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:soloforte_app/modules/consultoria/occurrences/domain/occurrence.dart';
import 'package:soloforte_app/modules/consultoria/occurrences/presentation/controllers/occurrence_controller.dart';
import 'package:soloforte_app/modules/consultoria/occurrences/presentation/widgets/occurrence_detail_sheet.dart';
import 'package:soloforte_app/ui/components/map/providers/marker_providers.dart';

void main() {
  setUpAll(() => initializeDateFormatting('pt_BR'));

  testWidgets('marker abre detail e preserva payload externo exibido', (
    tester,
  ) async {
    final occurrence = Occurrence(
      id: 'external-1',
      type: 'Info',
      description: 'Laudo de solo',
      lat: -10.25,
      long: -48.32,
      category: 'amostra_solo',
      amostraSolo: true,
      externalSource: 'caderno_solo',
      externalAnalysisId: 'analysis-1',
      analysisPayloadJson: '{"ph":5.4,"fosforo":12}',
      createdAt: DateTime.utc(2026, 6, 21),
    );
    final container = ProviderContainer(
      overrides: [
        occurrencesListProvider.overrideWith((ref) async => [occurrence]),
      ],
    );
    addTearDown(container.dispose);
    await container.read(occurrencesListProvider.future);

    late BuildContext sheetContext;
    final markers = container.read(
      occurrenceMarkersProvider((selected) {
        OccurrenceDetailSheet.show(sheetContext, selected);
      }),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            sheetContext = context;
            return Scaffold(body: Center(child: markers.single.child));
          },
        ),
      ),
    );

    await tester.tap(find.byType(GestureDetector).first);
    await tester.pumpAndSettle();

    expect(find.text('Amostra de Solo'), findsOneWidget);
    expect(find.text('caderno_solo'), findsOneWidget);
    expect(find.text('analysis-1'), findsOneWidget);
    expect(find.textContaining('"ph": 5.4'), findsOneWidget);
    expect(find.textContaining('"fosforo": 12'), findsOneWidget);
  });
}
