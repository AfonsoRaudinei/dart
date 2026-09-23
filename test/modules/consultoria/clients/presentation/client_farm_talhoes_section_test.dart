import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
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
    expect(find.byTooltip('Ações do talhão'), findsOneWidget);
    expect(find.text('Talhão Norte'), findsOneWidget);
    expect(find.text('Área Total'), findsOneWidget);
    expect(find.byIcon(Icons.chevron_right), findsNothing);
  });

  testWidgets('lápis abre menu curto e não navega imediatamente', (
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

    expect(find.byTooltip('Abrir no mapa'), findsOneWidget);
    expect(find.text('Editar geometria'), findsNothing);

    await tester.tap(find.byIcon(Icons.edit_outlined));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Editar geometria'), findsOneWidget);
    expect(find.text('Vincular / editar dados'), findsOneWidget);
    expect(find.text('União'), findsNothing);
    expect(find.byTooltip('Abrir no mapa'), findsOneWidget);
  });

  testWidgets('lápis mostra União quando há outro talhão drawing na fazenda', (
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
            (ref, farmId) async => twoDrawingFields,
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

    expect(find.byTooltip('Ações do talhão'), findsNWidgets(2));

    await tester.tap(find.byTooltip('Ações do talhão').first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Editar geometria'), findsOneWidget);
    expect(find.text('Vincular / editar dados'), findsOneWidget);
    expect(find.text('União'), findsOneWidget);
    expect(find.byTooltip('Abrir no mapa'), findsNWidgets(2));
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
    expect(find.text('Mapa'), findsOneWidget);

    await tester.tap(find.text('NDVI'));
    await tester.pump();
    await tester.pump();

    expect(counter.value, greaterThanOrEqualTo(1));
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
      localPath: '/tmp/soloforte-ndvi-card.png',
    );
  }
}
