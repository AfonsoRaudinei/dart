import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Blindagem edição de geometria (fluxo 1A + zoom + gota).
void main() {
  late String orchestrator;
  late String editLayer;
  late String drawingLayers;
  late String bottomSheet;
  late String closeCoordinator;

  setUpAll(() {
    orchestrator = File(
      'lib/ui/screens/map/widgets/map_build_orchestrator.dart',
    ).readAsStringSync();
    editLayer = File(
      'lib/modules/drawing/presentation/widgets/drawing_edit_layer.dart',
    ).readAsStringSync();
    drawingLayers = File(
      'lib/modules/drawing/presentation/widgets/drawing_layers.dart',
    ).readAsStringSync();
    bottomSheet = File(
      'lib/ui/components/map/map_bottom_sheet.dart',
    ).readAsStringSync();
    closeCoordinator = File(
      'lib/modules/drawing/presentation/coordinators/drawing_close_coordinator.dart',
    ).readAsStringSync();
  });

  test('edição não congela o mapa ao selecionar a gota', () {
    expect(
      orchestrator.contains(
        'drawingMetrics.state == DrawingState.editing ||',
      ),
      isFalse,
    );
    expect(orchestrator.contains('freezeMapGestures'), isFalse);
    expect(orchestrator.contains('InteractiveFlag.none'), isFalse);
    expect(orchestrator, contains('DrawingVertexHandleOverlay'));
  });

  test('drawing_layers não emite _vertexMarker decorativo em editing', () {
    expect(drawingLayers, contains('hideDecorativeVertexMarkers'));
    expect(drawingLayers, contains('currentState == DrawingState.editing'));
    expect(
      drawingLayers.contains(
        '!hideDecorativeVertexMarkers',
      ),
      isTrue,
    );
  });

  test('edição usa gota com cruz e midpoints sem gota automática', () {
    expect(editLayer, contains('_EditVertexGotaHandle'));
    expect(editLayer, contains('_GotaCruzPainter'));
    expect(editLayer, contains('_VertexGotaVisual'));
    expect(editLayer, contains('drawing_vertex_drag_'));
    expect(editLayer, contains('_MidpointHandle'));
    expect(_vertexMarkerBottomCenterCount(editLayer), 3);
  });

  test('gota mid-draw e edição: ponta no LatLng, não halo centrado', () {
    // Contrato img2: tip-up, corpo abaixo do dedo.
    expect(editLayer, contains('_VertexGotaMetrics'));
    expect(_vertexMarkerBottomCenterCount(editLayer), 3);
    expect(
      editLayer.contains(
        'alignment: Alignment.topCenter,\n              child: _EditVertexGotaHandle',
      ),
      isFalse,
    );
    expect(
      editLayer.contains(
        'alignment: Alignment.topCenter,\n          child: _SketchVertexHandle',
      ),
      isFalse,
    );
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

  test('1A: host fecha sheet na edição sem cancelar vértices', () {
    expect(bottomSheet, contains('_onDrawingControllerChanged'));
    expect(bottomSheet, contains('_closeDrawingSheetChrome'));
    expect(bottomSheet, contains('onCollapseWhileEditing'));
    expect(
      closeCoordinator,
      contains('fecha o chrome sem cancelar; edição permanece ativa'),
    );
    expect(
      closeCoordinator,
      contains('return const DrawingCloseDecision(shouldCloseSheet: true);'),
    );
  });
}

/// Conta `alignment: Alignment.bottomCenter` em código (ignora comentários `///`).
int _vertexMarkerBottomCenterCount(String source) {
  return source
      .split('\n')
      .where((line) => !line.trimLeft().startsWith('///'))
      .where((line) => line.contains('alignment: Alignment.bottomCenter,'))
      .length;
}
