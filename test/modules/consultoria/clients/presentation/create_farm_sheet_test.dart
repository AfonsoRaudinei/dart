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
            saveFarm: (_, draft) async => Farm(
              id: 'farm-1',
              name: draft.name,
              city: draft.city,
              state: draft.state,
              totalAreaHa: draft.areaHa,
            ),
            onSaved: (_) {},
          ),
        ),
      ),
    );

    await tester.tap(find.text('Salvar fazenda'));
    await tester.pumpAndSettle();

    expect(find.text('Informe o nome da fazenda'), findsOneWidget);
  });

  testWidgets('CreateFarmSheet em modo editar mostra título e oculta área', (
    tester,
  ) async {
    final existing = Farm(
      id: 'farm-edit',
      name: 'Retiro',
      city: 'Pugmil',
      state: 'TO',
      totalAreaHa: 80,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CreateFarmSheet(
            client: client,
            existingFarm: existing,
            areaFromLinkedFields: true,
            saveFarm: (_, draft) async => Farm(
              id: existing.id,
              name: draft.name,
              city: draft.city,
              state: draft.state,
              totalAreaHa: draft.areaHa,
            ),
            onSaved: (_) {},
          ),
        ),
      ),
    );

    expect(find.text('Editar fazenda'), findsOneWidget);
    expect(find.text('Retiro'), findsOneWidget);
    expect(
      find.text('A área total vem da soma dos talhões vinculados.'),
      findsOneWidget,
    );
    expect(find.text('Área total (ha) — opcional'), findsNothing);
  });
}
