import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:soloforte_app/core/router/app_routes.dart';
import 'package:soloforte_app/modules/consultoria/occurrences/domain/occurrence.dart';
import 'package:soloforte_app/modules/consultoria/occurrences/presentation/widgets/occurrence_detail_sheet.dart';

void main() {
  setUpAll(() => initializeDateFormatting('pt_BR'));

  group('OccurrenceDetailSheet backRoute', () {
    testWidgets('exibe seta e navega para backRoute ao tocar', (tester) async {
      final occurrence = Occurrence(
        id: 'occ-back-route',
        type: 'Alta',
        description: 'Detalhe com retorno contextual',
        createdAt: DateTime.utc(2026, 7, 6),
      );

      late GoRouter router;
      router = GoRouter(
        initialLocation: AppRoutes.reports,
        routes: [
          GoRoute(
            path: AppRoutes.map,
            builder: (_, __) => const Scaffold(body: Text('map-page')),
          ),
          GoRoute(
            path: AppRoutes.reports,
            builder: (context, __) => Scaffold(
              body: TextButton(
                onPressed: () => OccurrenceDetailSheet.show(
                  context,
                  occurrence,
                  backRoute: AppRoutes.reports,
                ),
                child: const Text('abrir-sheet'),
              ),
            ),
          ),
        ],
      );

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();

      await tester.tap(find.text('abrir-sheet'));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.arrow_back_ios_new), findsOneWidget);
      expect(find.text('Detalhe com retorno contextual'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.arrow_back_ios_new));
      await tester.pumpAndSettle();

      expect(router.state.uri.path, AppRoutes.reports);
      expect(find.text('abrir-sheet'), findsOneWidget);
      expect(find.text('map-page'), findsNothing);
    });

    testWidgets('sem backRoute não exibe seta contextual', (tester) async {
      final occurrence = Occurrence(
        id: 'occ-map-flow',
        type: 'Média',
        description: 'Fluxo mapa',
        createdAt: DateTime.utc(2026, 7, 6),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () => OccurrenceDetailSheet.show(context, occurrence),
              child: const Text('abrir-mapa'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('abrir-mapa'));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.arrow_back_ios_new), findsNothing);
      expect(find.text('Fluxo mapa'), findsOneWidget);
    });
  });
}
