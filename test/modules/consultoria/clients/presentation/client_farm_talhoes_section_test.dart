import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:soloforte_app/core/router/app_routes.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:soloforte_app/core/contracts/i_ndvi_latest_lookup.dart';
import 'package:soloforte_app/core/contracts/i_ndvi_latest_lookup_provider.dart';
import 'package:soloforte_app/core/contracts/ndvi_latest_summary.dart';
import 'package:soloforte_app/core/infra/preferences_service.dart';
import 'package:soloforte_app/modules/consultoria/clients/domain/agronomic_models.dart';
import 'package:soloforte_app/modules/consultoria/clients/domain/client.dart';
import 'package:soloforte_app/modules/consultoria/clients/presentation/providers/field_providers.dart';
import 'package:soloforte_app/modules/consultoria/clients/presentation/widgets/client_detail_farm_sections.dart';
import 'package:soloforte_app/modules/consultoria/clients/presentation/widgets/talhao_map_preview.dart';

void main() {
  late PreferencesService preferences;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    preferences = PreferencesService(await SharedPreferences.getInstance());
  });

  final client = Client(
    id: 'client-1',
    name: 'Adriano Gomes Silva',
    phone: '63999999999',
    city: 'Pugmil',
    state: 'TO',
    createdAt: DateTime(2026, 1, 1),
  );

  final farm = Farm(
    id: 'farm-1',
    name: 'Fazenda Retiro',
    city: 'Pugmil',
    state: 'TO',
    totalAreaHa: 150,
  );

  final linkedFields = [
    const FarmLinkedFieldSummary(
      id: 'drawing-1',
      name: 'Talhão Norte',
      areaHa: 12.5,
      source: FarmLinkedFieldSource.drawing,
      vertices: [],
    ),
  ];

  final twoDrawingFields = [
    const FarmLinkedFieldSummary(
      id: 'drawing-1',
      name: 'Talhão Norte',
      areaHa: 12.5,
      source: FarmLinkedFieldSource.drawing,
      vertices: [],
    ),
    const FarmLinkedFieldSummary(
      id: 'drawing-2',
      name: 'Talhão Sul',
      areaHa: 8.0,
      source: FarmLinkedFieldSource.drawing,
      vertices: [],
    ),
  ];

  testWidgets('mostra preview de mapa e botão renomear quando há talhões', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          preferencesServiceProvider.overrideWithValue(preferences),
          farmLinkedFieldsProvider.overrideWith(
            (ref, farmId) async => linkedFields,
          ),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ClientFarmWithTalhoesSection(client: client, farm: farm),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byType(TalhaoMapPreviewWidget), findsOneWidget);
    expect(find.byTooltip('Abrir no mapa'), findsOneWidget);
    expect(find.byTooltip('Dados do talhão'), findsOneWidget);
    expect(find.byTooltip('Geometria e união'), findsOneWidget);
    expect(find.text('Talhão Norte'), findsOneWidget);
    expect(find.text('Área Total'), findsOneWidget);
    expect(find.byIcon(Icons.chevron_right), findsNothing);
  });

  testWidgets('Geometria e união navega ao mapa com ferramentas completas', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final router = GoRouter(
      initialLocation: '/farm',
      routes: [
        GoRoute(
          path: '/farm',
          builder: (context, state) => Scaffold(
            body: SingleChildScrollView(
              child: ClientFarmWithTalhoesSection(client: client, farm: farm),
            ),
          ),
        ),
        GoRoute(
          path: AppRoutes.map,
          builder: (context, state) => Scaffold(
            body: Text(state.uri.toString()),
          ),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          preferencesServiceProvider.overrideWithValue(preferences),
          farmLinkedFieldsProvider.overrideWith(
            (ref, farmId) async => linkedFields,
          ),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    await tester.tap(find.byTooltip('Geometria e união'));
    await tester.pumpAndSettle();

    expect(find.textContaining('ferramentas=completo'), findsOneWidget);
    expect(find.textContaining('drawingId=drawing-1'), findsOneWidget);
    expect(find.textContaining('modo=desenho'), findsOneWidget);
  });

  testWidgets('Geometria e união no segundo card usa o drawingId correto', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final router = GoRouter(
      initialLocation: '/farm',
      routes: [
        GoRoute(
          path: '/farm',
          builder: (context, state) => Scaffold(
            body: SingleChildScrollView(
              child: ClientFarmWithTalhoesSection(client: client, farm: farm),
            ),
          ),
        ),
        GoRoute(
          path: AppRoutes.map,
          builder: (context, state) => Scaffold(
            body: Text(state.uri.toString()),
          ),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          preferencesServiceProvider.overrideWithValue(preferences),
          farmLinkedFieldsProvider.overrideWith(
            (ref, farmId) async => twoDrawingFields,
          ),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byTooltip('Geometria e união'), findsNWidgets(2));

    await tester.tap(find.byTooltip('Geometria e união').last);
    await tester.pumpAndSettle();

    expect(find.textContaining('drawingId=drawing-2'), findsOneWidget);
    expect(find.textContaining('ferramentas=completo'), findsOneWidget);
  });

  testWidgets('modo Mapa não consulta NDVI; toque em NDVI consulta', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final counter = _NdviLookupCounter();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          preferencesServiceProvider.overrideWithValue(preferences),
          farmLinkedFieldsProvider.overrideWith(
            (ref, farmId) async => linkedFields,
          ),
          ndviLatestLookupProvider.overrideWithValue(
            _CountingNdviLookup(counter),
          ),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ClientFarmWithTalhoesSection(client: client, farm: farm),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(counter.value, 0);
    expect(find.text('Mapa'), findsNothing);
    expect(find.text('NDVI'), findsNothing);
    expect(find.byTooltip('Ver NDVI no card'), findsWidgets);

    await tester.tap(find.byTooltip('Ver NDVI no card').first);
    await tester.pump();
    await tester.pump();

    expect(counter.value, greaterThanOrEqualTo(1));
  });

  testWidgets('com várias fazendas inicia recolhido e expande no toque', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          preferencesServiceProvider.overrideWithValue(preferences),
          farmLinkedFieldsProvider.overrideWith(
            (ref, farmId) async => linkedFields,
          ),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ClientFarmWithTalhoesSection(
                client: client,
                farm: farm,
                initiallyExpanded: false,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Fazenda Retiro'), findsOneWidget);
    expect(find.text('Área Total'), findsOneWidget);
    expect(find.byTooltip('Mostrar talhões'), findsOneWidget);
    expect(find.text('Talhão Norte'), findsNothing);
    expect(find.text('Talhões'), findsNothing);

    await tester.tap(find.text('Fazenda Retiro'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Talhão Norte'), findsOneWidget);
    expect(find.text('Talhões'), findsOneWidget);
    expect(find.byTooltip('Ocultar talhões'), findsOneWidget);

    await tester.tap(find.text('Fazenda Retiro'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Fazenda Retiro'), findsOneWidget);
    expect(find.text('Talhão Norte'), findsNothing);
    expect(find.byTooltip('Mostrar talhões'), findsOneWidget);
  });
}

class _NdviLookupCounter {
  int value = 0;
}

class _CountingNdviLookup implements INdviLatestLookup {
  _CountingNdviLookup(this.counter);

  final _NdviLookupCounter counter;

  @override
  Future<NdviLatestSummary?> getLatest(String fieldId) async {
    counter.value++;
    return NdviLatestSummary(
      imageDate: DateTime(2026, 9, 12),
      ndviMean: 0.62,
      ndviMin: 0.1,
      ndviMax: 0.9,
      sourceLabel: 'Sentinel NDVI',
      source: 'sentinel',
      isColormap: true,
      localPath: '/tmp/soloforte-ndvi-card.png',
    );
  }
}
