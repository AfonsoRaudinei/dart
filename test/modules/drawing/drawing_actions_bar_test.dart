import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/modules/drawing/domain/models/drawing_models.dart';
import 'package:soloforte_app/modules/drawing/presentation/widgets/components/drawing_actions_bar.dart';

void main() {
  testWidgets('dispara todas as ações contextuais do talhão', (tester) async {
    tester.view.physicalSize = const Size(800, 3000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final calls = <String>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: DrawingActionsBar(
              selectedFeature: _feature(),
              onEditGeometry: () => calls.add('geometry'),
              onEditMetadata: () => calls.add('metadata'),
              onUnion: () => calls.add('union'),
              onDifference: () => calls.add('difference'),
              onIntersection: () => calls.add('intersection'),
              onExport: () => calls.add('export'),
              onExportAll: () => calls.add('exportAll'),
              onToggleMultiSelect: () => calls.add('multi'),
              onDuplicateSelected: () => calls.add('duplicate'),
              onMoveSelected: () => calls.add('move'),
              onSelectByGroup: () => calls.add('group'),
              onDeleteSelected: () => calls.add('deleteSelected'),
              onDelete: () => calls.add('delete'),
              selectedCount: 2,
            ),
          ),
        ),
      ),
    );

    for (final label in <String>[
      'Editar Geometria',
      'Vincular / editar dados',
      'União',
      'Diferença',
      'Interseção',
      'Exportar este talhão',
      'Exportar todos os talhões',
      'Ativar multi-seleção',
      'Duplicar selecionados',
      'Mover selecionados',
      'Selecionar por grupo',
    ]) {
      final target = find.text(label);
      await tester.ensureVisible(target);
      await tester.tap(target);
      await tester.pump();
    }

    await tester.ensureVisible(find.text('Excluir selecionados'));
    await tester.tap(find.text('Excluir selecionados'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Excluir'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Excluir').last);
    await tester.tap(find.text('Excluir').last);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Excluir'));
    await tester.pumpAndSettle();

    expect(calls, <String>[
      'geometry',
      'metadata',
      'union',
      'difference',
      'intersection',
      'export',
      'exportAll',
      'multi',
      'duplicate',
      'move',
      'group',
      'deleteSelected',
      'delete',
    ]);
  });
}

DrawingFeature _feature() {
  final now = DateTime(2026);
  return DrawingFeature(
    id: 'field-1',
    geometry: DrawingPolygon(
      coordinates: const [
        [
          [-48, -10],
          [-47.99, -10],
          [-47.99, -9.99],
          [-48, -10],
        ],
      ],
    ),
    properties: DrawingProperties(
      nome: 'Talhão Norte',
      tipo: DrawingType.talhao,
      origem: DrawingOrigin.desenho_manual,
      status: DrawingStatus.rascunho,
      autorId: 'user-1',
      autorTipo: AuthorType.consultor,
      areaHa: 1,
      versao: 1,
      ativo: true,
      createdAt: now,
      updatedAt: now,
      syncStatus: SyncStatus.synced,
    ),
  );
}
