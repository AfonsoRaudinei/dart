import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('ClimaRadarLayerWidget fica acima de desenho e abaixo de markers', () {
    final source = File(
      'lib/ui/screens/map/widgets/map_build_orchestrator.dart',
    ).readAsStringSync();

    final cloudIndex = source.indexOf('const ClimaCloudTileLayerWidget()');
    final radarIndex = source.indexOf('const ClimaRadarTileLayerWidget()');
    final drawingEditIndex = source.indexOf('DrawingEditLayer(');
    final markersIndex = source.indexOf('const MapMarkersWidget()');

    expect(cloudIndex, greaterThan(-1));
    expect(radarIndex, greaterThan(-1));
    expect(drawingEditIndex, greaterThan(-1));
    expect(markersIndex, greaterThan(-1));
    expect(cloudIndex, greaterThan(drawingEditIndex));
    expect(radarIndex, greaterThan(cloudIndex));
    expect(markersIndex, greaterThan(radarIndex));
  });
}
