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

  testWidgets('fazenda do consultor entra em Minha área', (tester) async {
    await _pumpScreen(tester, dashboard: _linkedDashboard());

    expect(find.text('Nenhuma fazenda cadastrada ainda.'), findsNothing);
    expect(find.text('Terra Viva'), findsWidgets);
    expect(find.text('Talhão 1 • 94.8 ha • com mapa'), findsOneWidget);
    expect(find.text('Ver no mapa'), findsOneWidget);
    expect(find.text('Cadastrar fazenda'), findsOneWidget);
    expect(find.byTooltip('Editar fazenda'), findsNothing);
  });
}

Future<void> _pumpScreen(
  WidgetTester tester, {
  ProducerPropertyDashboard? dashboard,
}) async {
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
          (ref) async => dashboard ?? _dashboard(),
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

ProducerPropertyDashboard _linkedDashboard() {
  return ProducerPropertyDashboard(
    ownProperty: const ProducerOwnProperty(
      clientId: 'producer-client-1',
      name: 'Jonathan Pereira dos Santos',
      email: 'jonathan.terraviva@gmail.com',
      farms: [],
    ),
    linkedClients: [
      ProducerLinkedClient(
        link: ProducerClientLink(
          id: 'link-1',
          consultorUserId: 'consultor-1',
          clientId: 'client-jonathan',
          producerUserId: 'producer-client-1',
          status: 'active',
          expiresAt: DateTime.utc(2026, 11, 21),
          usedAt: DateTime.utc(2026, 11, 14),
          createdAt: DateTime.utc(2026, 11, 14),
          updatedAt: DateTime.utc(2026, 11, 14),
        ),
        name: 'Jonathan Pereira dos Santos',
        phone: null,
        email: null,
        city: 'Pium',
        state: 'TO',
        farms: const [
          ProducerLinkedFarm(
            id: 'farm-tv',
            name: 'Terra Viva',
            city: 'Pium',
            state: 'TO',
            areaHa: 200,
            fields: [
              ProducerLinkedField(
                id: 'field-1',
                name: 'Talhão 1',
                areaHa: 94.806,
                geometryJson: '{"type":"Polygon"}',
                fromDrawing: true,
              ),
            ],
          ),
        ],
        reports: const [],
      ),
    ],
  );
}
