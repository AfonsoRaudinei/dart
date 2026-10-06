import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Blindagem: Abrir no mapa (drawingId) vs GPS inicial da câmera.
void main() {
  late String viewportSource;
  late String mapScreenSource;

  setUpAll(() {
    viewportSource = File(
      'lib/ui/screens/map/controllers/map_viewport_controller.dart',
    ).readAsStringSync();
    mapScreenSource = File(
      'lib/ui/screens/private_map_screen.dart',
    ).readAsStringSync();
  });

  test(
    'apply recusa GPS quando há intent explícito, antes de _applyGpsViewport',
    () {
      final intentIdx = viewportSource.indexOf(
        'ref.read(explicitMapCameraIntentProvider)',
      );
      final gpsIdx = viewportSource.indexOf('await _applyGpsViewport');
      expect(intentIdx, greaterThanOrEqualTo(0));
      expect(gpsIdx, greaterThan(intentIdx));
    },
  );

  test('_applyGpsViewport relê estado depois do await GPS', () {
    final availableIdx = viewportSource.indexOf(
      'locationState == LocationState.available',
    );
    final waitingIdx = viewportSource.indexOf(
      'InitialViewportState.waitingForData',
      availableIdx,
    );
    final awaitIdx = viewportSource.indexOf(
      'await locationService.getCurrentPosition()',
    );
    final commitIdx = viewportSource.indexOf('shouldCommitGpsMove(', awaitIdx);
    expect(availableIdx, greaterThanOrEqualTo(0));
    expect(waitingIdx, greaterThan(availableIdx));
    expect(waitingIdx, lessThan(awaitIdx));
    expect(commitIdx, greaterThan(awaitIdx));
  });

  test('URI com drawingId arma intent no mesmo build, antes do pós-frame', () {
    final scheduleIdx = mapScreenSource.indexOf(
      'void _scheduleMapFirstQueryHandling',
    );
    final intentIdx = mapScreenSource.indexOf(
      'explicitMapCameraIntentProvider',
      scheduleIdx,
    );
    final postFrameIdx = mapScreenSource.indexOf(
      'addPostFrameCallback',
      scheduleIdx,
    );
    expect(scheduleIdx, greaterThanOrEqualTo(0));
    expect(intentIdx, greaterThan(scheduleIdx));
    expect(intentIdx, lessThan(postFrameIdx));
  });
}
