import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:soloforte_app/core/infra/preferences_service.dart';
import 'package:soloforte_app/core/state/map_state.dart';
import 'package:soloforte_app/core/router/app_routes.dart';
import 'package:soloforte_app/modules/consultoria/occurrences/domain/occurrence.dart';
import 'package:soloforte_app/modules/consultoria/occurrences/presentation/widgets/occurrence_detail_sheet.dart';

void main() {
  setUpAll(() => initializeDateFormatting('pt_BR'));

  Future<void> pumpWithProviders(WidgetTester tester, Widget child) async {
    SharedPreferences.setMockInitialValues({});
    final preferencesService = PreferencesService(
      await SharedPreferences.getInstance(),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          preferencesServiceProvider.overrideWithValue(preferencesService),
        ],
        child: child,
      ),
    );
  }

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

      await pumpWithProviders(
        tester,
        MaterialApp.router(routerConfig: router),
      );
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

    testWidgets('exibe ações de editar e excluir no fluxo do mapa', (
      tester,
    ) async {
      final occurrence = Occurrence(
        id: 'occ-map-actions',
        type: 'Média',
        description: 'Ferrugem no talhão 3',
        category: 'doenca',
        lat: -10.69,
        long: -48.38,
        createdAt: DateTime.utc(2026, 6, 17),
      );

      await pumpWithProviders(
        tester,
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

      expect(find.text('Editar'), findsOneWidget);
      expect(find.text('Excluir'), findsOneWidget);
      expect(find.text('Ferrugem no talhão 3'), findsOneWidget);
      expect(find.text('Status'), findsOneWidget);
    });

    testWidgets('sem backRoute não exibe seta contextual', (tester) async {
      final occurrence = Occurrence(
        id: 'occ-map-flow',
        type: 'Média',
        description: 'Fluxo mapa',
        createdAt: DateTime.utc(2026, 7, 6),
      );

      await pumpWithProviders(
        tester,
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
