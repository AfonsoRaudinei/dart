import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Blindagem edição de geometria (fluxo 1A + zoom + gota).
void main() {
  late String orchestrator;
  late String editLayer;
  late String bottomSheet;
  late String closeCoordinator;

  setUpAll(() {
    orchestrator = File(
      'lib/ui/screens/map/widgets/map_build_orchestrator.dart',
    ).readAsStringSync();
    editLayer = File(
      'lib/modules/drawing/presentation/widgets/drawing_edit_layer.dart',
    ).readAsStringSync();
    bottomSheet = File(
      'lib/ui/components/map/map_bottom_sheet.dart',
    ).readAsStringSync();
    closeCoordinator = File(
      'lib/modules/drawing/presentation/coordinators/drawing_close_coordinator.dart',
    ).readAsStringSync();
  });

  test('edição não congela mapa com InteractiveFlag.none global', () {
    expect(
      orchestrator.contains(
        'drawingMetrics.state == DrawingState.editing ||',
      ),
      isFalse,
    );
    expect(orchestrator, contains('editVertexDragActive'));
    expect(orchestrator, contains('isDraggingVertex'));
    expect(orchestrator, contains('freezeMapGestures'));
  });

  test('edição usa gota com cruz e midpoints sem gota automática', () {
    expect(editLayer, contains('_EditVertexGotaHandle'));
    expect(editLayer, contains('_GotaCruzPainter'));
    expect(editLayer, contains('_VertexGotaVisual'));
    expect(editLayer, contains('drawing_vertex_drag_'));
    expect(editLayer, contains('_MidpointHandle'));
    expect(editLayer, contains('Alignment.topCenter'));
  });

  test('gota mid-draw e edição: ponta no LatLng, não halo centrado', () {
    // Contrato img2: tip-up, corpo abaixo do dedo.
    expect(editLayer, contains('_VertexGotaMetrics'));
    expect(editLayer, contains('Alignment.topCenter'));
    // Halo circular antigo (centrado no ponto) removido do sketch.
    expect(editLayer.contains('haloDiameter'), isFalse);
    expect(editLayer.contains('shape: BoxShape.circle,\n                color: _gotaRed'), isFalse);
    // Sketch usa o mesmo visual tip-up.
    expect(editLayer, contains('_SketchVertexHandle'));
    expect(
      editLayer.indexOf('_VertexGotaVisual'),
      lessThan(editLayer.lastIndexOf('_SketchVertexHandle') + 800),
    );
  });

  test('1A: host recolhe sheet na edição sem cancelar', () {
    expect(bottomSheet, contains('_collapseDrawingSheetWhileEditing'));
    expect(bottomSheet, contains('onCollapseWhileEditing'));
    expect(bottomSheet, contains('_onDrawingControllerChanged'));
    expect(
      closeCoordinator,
      contains('host deve recolher (compact) sem cancelar'),
    );
  });
}
