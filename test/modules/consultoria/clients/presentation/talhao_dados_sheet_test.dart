import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/core/contracts/i_drawing_field_writer.dart';
import 'package:soloforte_app/core/contracts/i_drawing_field_writer_provider.dart';
import 'package:soloforte_app/modules/consultoria/clients/presentation/widgets/talhao_actions_sheet.dart';

class _FakeDrawingFieldWriter implements IDrawingFieldWriter {
  String? updatedName;
  String? updatedCultura;
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
    String? safra,
  }) async {
    updatedCultura = cultura;
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
  testWidgets('TalhaoDadosSheet mostra Cultura e Safra e salva via writer', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final writer = _FakeDrawingFieldWriter();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          iDrawingFieldWriterProvider.overrideWithValue(writer),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: TalhaoDadosSheet(
              clientId: 'client-1',
              farmId: 'farm-1',
              fieldId: 'field-1',
              initialName: 'Talhão Norte',
              initialCultura: 'Soja',
              initialSafra: '2025/2026',
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Dados do talhão'), findsOneWidget);
    expect(find.text('Edite sem abrir o mapa'), findsOneWidget);
    expect(find.text('Nome do talhão'), findsOneWidget);
    expect(find.text('Cultura'), findsOneWidget);
    expect(find.text('Safra'), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Talhão Norte'),
      'Talhão Atualizado',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Soja'),
      'Milho',
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
    expect(writer.updatedSafra, '2026/2027');
    expect(find.text('Dados do talhão atualizados.'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 1700));
  });
}
