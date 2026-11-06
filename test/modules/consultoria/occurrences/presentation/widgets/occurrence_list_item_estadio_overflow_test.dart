import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/core/contracts/i_visit_session_lookup.dart';
import 'package:soloforte_app/core/contracts/i_visit_session_lookup_provider.dart';
import 'package:soloforte_app/modules/consultoria/occurrences/domain/occurrence.dart';
import 'package:soloforte_app/modules/consultoria/occurrences/presentation/controllers/occurrence_controller.dart';
import 'package:soloforte_app/modules/consultoria/occurrences/presentation/widgets/occurrence_list_sheet.dart';

class _IdleVisitLookup implements IVisitSessionLookup {
  @override
  Future<VisitSessionSummary?> getActiveSession() async => null;

  @override
  Future<VisitSessionSummary?> findById(String sessionId) async => null;
}

void main() {
  testWidgets(
    'estádio com DAP e DAE cabe em 360 sem overflow e mostra a idade',
    (tester) async {
      tester.view.physicalSize = const Size(360, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final overflow = <FlutterErrorDetails>[];
      final previousOnError = FlutterError.onError;
      FlutterError.onError = (details) {
        final message = details.exceptionAsString();
        if (message.contains('overflowed')) {
          overflow.add(details);
          return;
        }
        previousOnError?.call(details);
      };
      addTearDown(() => FlutterError.onError = previousOnError);

      final today = DateTime.now();
      final plantio = DateTime(
        today.year,
        today.month,
        today.day,
      ).subtract(const Duration(days: 32));
      final emergencia = plantio.add(const Duration(days: 6));
      String iso(DateTime date) {
        final y = date.year.toString().padLeft(4, '0');
        final m = date.month.toString().padLeft(2, '0');
        final d = date.day.toString().padLeft(2, '0');
        return '$y-$m-$d';
      }

      final occurrence = Occurrence(
        id: 'occ-estadio-idade',
        type: 'Média',
        description: '',
        category: 'doenca',
        status: 'confirmed',
        cultivar: 'BMX Potência',
        estadioFenologico: 'V4',
        dataPlantio: iso(plantio),
        dataEmergencia: iso(emergencia),
        createdAt: DateTime.utc(2026, 11, 5),
        clientId: 'cliente-1',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            occurrencesListProvider.overrideWith((ref) async => [occurrence]),
            visitSessionLookupProvider.overrideWithValue(_IdleVisitLookup()),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: OccurrenceListSheet(
                showHandle: false,
                showDecoration: false,
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(overflow, isEmpty);

      final idade = find.textContaining('dias após o plantio');
      expect(idade, findsOneWidget);
      final label = tester.widget<Text>(idade);
      expect(label.data, contains('dias após a emergência'));
      expect(label.maxLines, 2);
      expect(label.softWrap, isTrue);
      expect(label.overflow, isNot(TextOverflow.ellipsis));
      expect(find.text('BMX Potência'), findsOneWidget);
    },
  );
}
