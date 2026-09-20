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

    expect(find.text('Cultura'), findsOneWidget);
    expect(find.text('Safra'), findsOneWidget);

    Finder fieldByLabel(String label) {
      return find.ancestor(
        of: find.text(label),
        matching: find.byType(TextFormField),
      );
    }

    await tester.enterText(fieldByLabel('Nome do talhão'), 'Talhão Atualizado');
    await tester.enterText(fieldByLabel('Cultura'), 'Milho');
    await tester.enterText(fieldByLabel('Safra'), '2026/2027');

    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();

    expect(writer.updatedName, 'Talhão Atualizado');
    expect(writer.updatedCultura, 'Milho');
    expect(writer.updatedSafra, '2026/2027');
  });
}
