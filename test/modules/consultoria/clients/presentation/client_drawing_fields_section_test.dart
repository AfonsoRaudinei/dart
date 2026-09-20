import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/core/contracts/i_drawing_field_writer.dart';
import 'package:soloforte_app/core/contracts/i_drawing_field_writer_provider.dart';
import 'package:soloforte_app/modules/consultoria/clients/domain/client.dart';
import 'package:soloforte_app/modules/consultoria/clients/presentation/providers/field_providers.dart';
import 'package:soloforte_app/modules/consultoria/clients/presentation/widgets/client_detail_farm_sections.dart';

class _FakeDrawingFieldWriter implements IDrawingFieldWriter {
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
}

void main() {
  final client = Client(
    id: 'client-1',
    name: 'Adriano Gomes Silva',
    phone: '63999999999',
    city: 'Pugmil',
    state: 'TO',
    createdAt: DateTime(2026, 1, 1),
  );

  const orphanField = ClientDrawingFieldSummary(
    id: 'drawing-orphan',
    name: 'Talhão Avulso',
    areaHa: 8,
    vertices: [],
    crop: 'Soja',
    harvest: '2025/2026',
  );

  testWidgets('avulso repassa cultura e safra ao abrir dados do talhão', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          clientDrawingFieldsProvider.overrideWith(
            (ref, clientId) async => [orphanField],
          ),
          iDrawingFieldWriterProvider.overrideWithValue(
            _FakeDrawingFieldWriter(),
          ),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ClientDrawingFieldsSection(client: client),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Ações do talhão'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Vincular / editar dados'));
    await tester.pumpAndSettle();

    Finder fieldByLabel(String label) {
      return find.ancestor(
        of: find.text(label),
        matching: find.byType(TextFormField),
      );
    }

    expect(
      tester.widget<TextFormField>(fieldByLabel('Cultura')).controller?.text,
      'Soja',
    );
    expect(
      tester.widget<TextFormField>(fieldByLabel('Safra')).controller?.text,
      '2025/2026',
    );
  });
}
