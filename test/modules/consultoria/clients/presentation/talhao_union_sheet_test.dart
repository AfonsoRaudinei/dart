import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/core/contracts/i_drawing_field_writer.dart';
import 'package:soloforte_app/core/contracts/i_drawing_field_writer_provider.dart';
import 'package:soloforte_app/modules/consultoria/clients/presentation/widgets/talhao_union_sheet.dart';

class _FakeDrawingFieldWriter implements IDrawingFieldWriter {
  String? primaryFieldId;
  String? secondaryFieldId;
  String? clientId;

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
  }) async {}

  @override
  Future<void> updateFieldMetadata({
    required String fieldId,
    String? cultura,
    String? safra,
  }) async {}

  @override
  Future<void> unionDrawingFields({
    required String primaryFieldId,
    required String secondaryFieldId,
    required String clientId,
  }) async {
    this.primaryFieldId = primaryFieldId;
    this.secondaryFieldId = secondaryFieldId;
    this.clientId = clientId;
  }
}

void main() {
  const candidates = [
    TalhaoUnionCandidate(id: 'field-b', name: 'Talhão Sul', areaHa: 4.5),
    TalhaoUnionCandidate(id: 'field-c', name: 'Talhão Leste', areaHa: 2.1),
  ];

  testWidgets('TalhaoUnionSheet confirma união via writer', (tester) async {
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
            body: TalhaoUnionSheet(
              clientId: 'client-1',
              farmId: 'farm-1',
              primaryFieldId: 'field-a',
              primaryFieldName: 'Talhão Norte',
              candidates: candidates,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('União'), findsOneWidget);
    expect(find.text('Combinar com outra área'), findsOneWidget);
    expect(find.text('Talhão Sul'), findsOneWidget);

    await tester.tap(find.text('Talhão Sul'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Confirmar'));
    await tester.pumpAndSettle();

    expect(writer.primaryFieldId, 'field-a');
    expect(writer.secondaryFieldId, 'field-b');
    expect(writer.clientId, 'client-1');
  });
}
