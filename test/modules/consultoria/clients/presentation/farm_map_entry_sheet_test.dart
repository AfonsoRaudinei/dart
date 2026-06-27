import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/modules/consultoria/clients/domain/agronomic_models.dart';
import 'package:soloforte_app/modules/consultoria/clients/domain/client.dart';
import 'package:soloforte_app/modules/consultoria/clients/presentation/widgets/farm_map_entry_sheet.dart';

void main() {
  final client = Client(
    id: 'client-1',
    name: 'Adriano Gomes Silva',
    phone: '63999999999',
    city: 'Pugmil',
    state: 'TO',
    createdAt: DateTime(2026, 1, 1),
  );

  test('constrói contexto completo para desenhar no mapa', () {
    final uri = buildFarmMapUri(
      client: client,
      farm: Farm(
        id: 'farm-1',
        name: 'Fazenda Retiro',
        city: 'Pugmil',
        state: 'TO',
        totalAreaHa: 150,
      ),
      mode: FarmMapEntryMode.draw,
    );

    expect(uri.path, '/map');
    expect(uri.queryParameters['modo'], 'desenho');
    expect(uri.queryParameters['clienteId'], client.id);
    expect(uri.queryParameters['clienteNome'], client.name);
    expect(uri.queryParameters['fazendaId'], 'farm-1');
    expect(uri.queryParameters['fazendaNome'], 'Fazenda Retiro');
  });

  test('constrói contexto completo para importar no mapa', () {
    final uri = buildFarmMapUri(
      client: client,
      farm: Farm(
        id: 'farm-2',
        name: 'Fazenda Boa Vista',
        city: 'Pugmil',
        state: 'TO',
        totalAreaHa: 95,
      ),
      mode: FarmMapEntryMode.import,
    );

    expect(uri.path, '/map');
    expect(uri.queryParameters['modo'], 'importar');
    expect(uri.queryParameters['fazendaId'], 'farm-2');
  });

  testWidgets('continua com fazenda existente selecionada', (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    Farm? confirmedFarm;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FarmMapEntrySheet(
            client: client,
            mode: FarmMapEntryMode.draw,
            loadFarms: (_) async => [
              Farm(
                id: 'farm-1',
                name: 'Fazenda Retiro',
                city: 'Pugmil',
                state: 'TO',
                totalAreaHa: 150,
              ),
              Farm(
                id: 'farm-2',
                name: 'Fazenda Boa Vista',
                city: 'Pugmil',
                state: 'TO',
                totalAreaHa: 95,
              ),
            ],
            createFarm: (_, __) async => throw UnimplementedError(),
            onConfirmed: (farm) => confirmedFarm = farm,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Fazenda Boa Vista'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continuar para desenhar'));
    await tester.pumpAndSettle();

    expect(confirmedFarm?.id, 'farm-2');
  });

  testWidgets('cria nova fazenda com área antes de ir ao mapa', (tester) async {
    tester.view.physicalSize = const Size(800, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    Farm? confirmedFarm;
    FarmDraftData? createdDraft;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FarmMapEntrySheet(
            client: client,
            mode: FarmMapEntryMode.import,
            loadFarms: (_) async => const [],
            createFarm: (_, draft) async {
              createdDraft = draft;
              return Farm(
                id: 'farm-new',
                name: draft.name,
                city: draft.city,
                state: draft.state,
                totalAreaHa: draft.areaHa,
              );
            },
            onConfirmed: (farm) => confirmedFarm = farm,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byType(TextFormField).at(0),
      'Fazenda Nova Esperança',
    );
    await tester.enterText(find.byType(TextFormField).at(1), 'Pugmil');
    await tester.enterText(find.byType(TextFormField).at(2), 'to');
    await tester.enterText(find.byType(TextFormField).at(3), '320,5');

    await tester.ensureVisible(find.text('Continuar para importar'));
    await tester.tap(find.text('Continuar para importar'));
    await tester.pumpAndSettle();

    expect(createdDraft, isNotNull);
    expect(createdDraft!.name, 'Fazenda Nova Esperança');
    expect(createdDraft!.city, 'Pugmil');
    expect(createdDraft!.state, 'TO');
    expect(createdDraft!.areaHa, 320.5);
    expect(confirmedFarm?.id, 'farm-new');
  });
}
