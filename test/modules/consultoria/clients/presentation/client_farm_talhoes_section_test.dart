import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/modules/consultoria/clients/domain/agronomic_models.dart';
import 'package:soloforte_app/modules/consultoria/clients/domain/client.dart';
import 'package:soloforte_app/modules/consultoria/clients/presentation/providers/field_providers.dart';
import 'package:soloforte_app/modules/consultoria/clients/presentation/widgets/client_detail_farm_sections.dart';
import 'package:soloforte_app/modules/consultoria/clients/presentation/widgets/talhao_map_preview.dart';

void main() {
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
    FarmLinkedFieldSummary(
      id: 'drawing-1',
      name: 'Talhão Norte',
      areaHa: 12.5,
      source: FarmLinkedFieldSource.drawing,
      vertices: const [],
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
              ),
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
              ),
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
    expect(find.text('União'), findsOneWidget);
    expect(find.byTooltip('Abrir no mapa'), findsOneWidget);
  });
}
