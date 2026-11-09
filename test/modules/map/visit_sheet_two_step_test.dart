import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/core/contracts/i_visit_client_lookup.dart';
import 'package:soloforte_app/core/contracts/i_visit_client_lookup_provider.dart';
import 'package:soloforte_app/core/contracts/visit_client_hierarchy.dart';
import 'package:soloforte_app/core/domain/talhao_condicao.dart';
import 'package:soloforte_app/modules/map/presentation/widgets/visit_sheet.dart';

class _FakeVisitClientLookup implements IVisitClientLookup {
  @override
  Future<List<VisitClientSummary>> listActiveClients() async => const [
    VisitClientSummary(id: 'client-1', name: 'Produtor Alfa'),
  ];

  @override
  Future<List<VisitFarmSummary>> listFarmsByClient(String clientId) async =>
      const [VisitFarmSummary(id: 'farm-1', name: 'Fazenda Sul')];

  @override
  Future<List<VisitFieldSummary>> listFieldsByFarm(String farmId) async => [];

  @override
  Future<VisitClientHierarchy?> getClientHierarchy(String clientId) async =>
      null;
}

Future<List<VisitTalhaoOption>> _mockLoadTalhoes(String farmId) async {
  return [
    const VisitTalhaoOption(
      id: 'talhao-a',
      name: 'Talhão Alpha',
      areaHa: 12.5,
      canRate: true,
      condicao: TalhaoCondicao.bom,
    ),
    const VisitTalhaoOption(
      id: 'talhao-b',
      name: 'Talhão Beta',
      areaHa: 8.0,
      canRate: false,
      condicao: TalhaoCondicao.atencao,
    ),
  ];
}

Widget _wrap(Widget child) {
  return ProviderScope(
    overrides: [
      visitClientLookupProvider.overrideWithValue(_FakeVisitClientLookup()),
    ],
    child: MaterialApp(
      home: Scaffold(body: SizedBox(height: 700, child: child)),
    ),
  );
}

void main() {
  testWidgets(
    'dois passos: talhão → condição/atividade; Trocar talhão volta à lista',
    (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        _wrap(
          VisitSheet(
            preSelectedClienteId: 'client-1',
            loadTalhoes: _mockLoadTalhoes,
            onRateTalhao: (_, __) async {},
            onConfirm: (_, __, ___, ____) {},
            onNavigateToArea: (_, __, ___, ____, _____, ______) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Produtor Alfa'), findsOneWidget);
      expect(find.text('Atividade'), findsNothing);

      await tester.tap(find.byType(DropdownButtonFormField<VisitFarmSummary>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Fazenda Sul').last);
      await tester.pumpAndSettle();

      expect(find.text('Buscar talhão'), findsOneWidget);
      expect(find.text('Talhão Alpha'), findsOneWidget);
      expect(find.text('Talhão Beta'), findsOneWidget);
      expect(find.text('Condição'), findsNothing);

      await tester.tap(find.text('Talhão Alpha'));
      await tester.pumpAndSettle();

      expect(find.text('Condição'), findsOneWidget);
      expect(find.text('Atividade'), findsOneWidget);
      expect(find.text('Buscar talhão'), findsNothing);
      expect(find.text('Trocar talhão'), findsOneWidget);
      expect(find.text('Talhão Beta'), findsNothing);

      await tester.tap(find.text('Trocar talhão'));
      await tester.pumpAndSettle();

      expect(find.text('Buscar talhão'), findsOneWidget);
      expect(find.text('Talhão Alpha'), findsOneWidget);
      expect(find.text('Talhão Beta'), findsOneWidget);
      expect(find.text('Condição'), findsNothing);
      expect(find.text('Produtor Alfa'), findsOneWidget);
      expect(find.text('Fazenda Sul'), findsOneWidget);
    },
  );
}
