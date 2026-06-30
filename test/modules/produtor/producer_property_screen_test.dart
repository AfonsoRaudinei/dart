import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:soloforte_app/core/router/app_routes.dart';
import 'package:soloforte_app/modules/produtor/data/producer_link_models.dart';
import 'package:soloforte_app/modules/produtor/data/producer_property_repository.dart';
import 'package:soloforte_app/modules/produtor/presentation/screens/producer_property_screen.dart';

void main() {
  testWidgets('exibe uma unica acao de cadastrar fazenda', (tester) async {
    await _pumpScreen(tester);

    expect(find.text('Cadastrar fazenda'), findsOneWidget);
    expect(find.byTooltip('Adicionar fazenda'), findsNothing);
  });

  testWidgets('exibe acoes de CRUD e mapa para fazenda e talhao', (
    tester,
  ) async {
    await _pumpScreen(tester);

    expect(find.byTooltip('Editar fazenda'), findsOneWidget);
    expect(find.byTooltip('Excluir fazenda'), findsOneWidget);
    expect(find.byTooltip('Editar talhão'), findsOneWidget);
    expect(find.byTooltip('Excluir talhão'), findsOneWidget);
    expect(find.text('Desenhar ou importar KML/KMZ'), findsOneWidget);
    expect(find.text('12.3 ha • com mapa'), findsOneWidget);
  });
}

Future<void> _pumpScreen(WidgetTester tester) async {
  final router = GoRouter(
    initialLocation: AppRoutes.producerProperty,
    routes: [
      GoRoute(
        path: AppRoutes.producerProperty,
        builder: (_, __) => const ProducerPropertyScreen(),
      ),
      GoRoute(
        path: AppRoutes.map,
        builder: (_, __) => const Scaffold(body: Text('Mapa')),
      ),
    ],
  );
  addTearDown(router.dispose);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        producerPropertyDashboardProvider.overrideWith(
          (ref) async => _dashboard(),
        ),
      ],
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
}

ProducerPropertyDashboard _dashboard() {
  return const ProducerPropertyDashboard(
    ownProperty: ProducerOwnProperty(
      clientId: 'producer-client-1',
      name: 'Produtor Teste',
      email: 'produtor@soloforte.app',
      farms: [
        ProducerOwnFarm(
          id: 'farm-1',
          name: 'Retiro',
          city: 'Nova Rosalândia',
          state: 'TO',
          areaHa: 2800,
          fields: [
            ProducerOwnField(
              id: 'field-1',
              name: 'Talhão 01',
              areaHa: 12.3,
              hasGeometry: true,
            ),
          ],
        ),
      ],
    ),
    linkedClients: [],
  );
}
