import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/core/contracts/i_drawing_field_writer.dart';
import 'package:soloforte_app/core/contracts/i_drawing_field_writer_provider.dart';
import 'package:soloforte_app/modules/consultoria/clients/presentation/widgets/talhao_actions_sheet.dart';

class _FakeDrawingFieldWriter implements IDrawingFieldWriter {
  String? updatedName;
  String? updatedCultura;
  String? updatedMaterial;
  String? updatedSafra;

  @override
  Future<void> deleteFieldAndRecalculateClientArea({
    required String fieldId,
    required String clientId,
  }) async {}

  @override
  Future<void> linkFieldToFarm({
    required String fieldId,
    required String clientId,
    required String farmId,
  }) async {}

  @override
  Future<void> updateFieldName({
    required String fieldId,
    required String name,
  }) async {
    updatedName = name;
  }

  @override
  Future<void> updateFieldMetadata({
    required String fieldId,
    String? cultura,
    String? material,
    String? safra,
  }) async {
    updatedCultura = cultura;
    updatedMaterial = material;
    updatedSafra = safra;
  }

  @override
  Future<void> unionDrawingFields({
    required String primaryFieldId,
    required String secondaryFieldId,
    required String clientId,
  }) async {}
}

void main() {
  testWidgets('TalhaoDadosSheet mostra cultura em chips e salva material', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final writer = _FakeDrawingFieldWriter();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [iDrawingFieldWriterProvider.overrideWithValue(writer)],
        child: const MaterialApp(
          home: Scaffold(
            body: TalhaoDadosSheet(
              clientId: 'client-1',
              farmId: 'farm-1',
              fieldId: 'field-1',
              initialName: 'Talhão Norte',
              initialCultura: 'Soja',
              initialMaterial: 'Olimpo RR',
              initialSafra: '2025/2026',
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Dados do talhão'), findsOneWidget);
    expect(find.text('Cultura'), findsOneWidget);
    expect(find.text('Soja'), findsWidgets);
    expect(find.text('Material'), findsOneWidget);
    expect(find.text('Safra'), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Talhão Norte'),
      'Talhão Atualizado',
    );
    await tester.tap(find.text('Milho'));
    await tester.pump();
    await tester.enterText(
      find.widgetWithText(TextField, 'Olimpo RR'),
      'AG 8700',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, '2025/2026'),
      '2026/2027',
    );

    await tester.tap(find.text('Salvar'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(writer.updatedName, 'Talhão Atualizado');
    expect(writer.updatedCultura, 'Milho');
    expect(writer.updatedMaterial, 'AG 8700');
    expect(writer.updatedSafra, '2026/2027');
    expect(find.text('Dados do talhão atualizados.'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 1700));
  });

  testWidgets('Outra abre cultura livre e mantém material', (tester) async {
    tester.view.physicalSize = const Size(1800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final writer = _FakeDrawingFieldWriter();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [iDrawingFieldWriterProvider.overrideWithValue(writer)],
        child: const MaterialApp(
          home: Scaffold(
            body: TalhaoDadosSheet(
              clientId: 'client-1',
              fieldId: 'field-1',
              initialName: 'Talhão Sul',
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Material'), findsNothing);

    await tester.ensureVisible(find.text('Outra'));
    await tester.tap(find.text('Outra'));
    await tester.pump();

    expect(find.text('Qual cultura?'), findsOneWidget);
    expect(find.text('Material'), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextField, 'Ex.: Girassol'),
      'Girassol',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Ex.: Olimpo RR'),
      'Híbrido X',
    );
    await tester.tap(find.text('Salvar'));
    await tester.pump();

    expect(writer.updatedCultura, 'Girassol');
    expect(writer.updatedMaterial, 'Híbrido X');
    await tester.pump(const Duration(milliseconds: 1700));
  });
}
