import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/modules/consultoria/clients/domain/agronomic_models.dart';
import 'package:soloforte_app/modules/consultoria/clients/domain/client.dart';
import 'package:soloforte_app/modules/consultoria/clients/presentation/widgets/create_farm_sheet.dart';

void main() {
  final client = Client(
    id: 'client-1',
    name: 'Adriano Gomes Silva',
    phone: '63999999999',
    city: 'Pugmil',
    state: 'TO',
    createdAt: DateTime(2026, 1, 1),
  );

  testWidgets('CreateFarmSheet valida nome obrigatório', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CreateFarmSheet(
            client: client,
            createFarm: (_, draft) async => Farm(
              id: 'farm-1',
              name: draft.name,
              city: draft.city,
              state: draft.state,
              totalAreaHa: draft.areaHa,
            ),
            onCreated: (_) {},
          ),
        ),
      ),
    );

    await tester.tap(find.text('Salvar fazenda'));
    await tester.pumpAndSettle();

    expect(find.text('Informe o nome da fazenda'), findsOneWidget);
  });
}
