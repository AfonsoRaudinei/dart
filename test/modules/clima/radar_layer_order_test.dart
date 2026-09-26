import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final source = File(
    'lib/ui/screens/map/widgets/map_build_orchestrator.dart',
  ).readAsStringSync();

  test('ClimaRadarLayerWidget fica acima de desenho e abaixo de markers', () {
    final radarIndex = source.indexOf('const ClimaRadarTileLayerWidget()');
    final drawingEditIndex = source.indexOf('DrawingEditLayer(');
    final markersIndex = source.indexOf('const MapMarkersWidget()');

    expect(radarIndex, greaterThan(-1));
    expect(drawingEditIndex, greaterThan(-1));
    expect(markersIndex, greaterThan(-1));
    expect(radarIndex, greaterThan(drawingEditIndex));
    expect(markersIndex, greaterThan(radarIndex));
  });

  test('o toggle do mapa não desenha camada de nuvens', () {
    expect(source, isNot(contains('ClimaCloudTileLayerWidget')));
    expect(
      File(
        'lib/modules/clima/presentation/widgets/clima_cloud_layer_widget.dart',
      ).existsSync(),
      isFalse,
      reason: 'o toggle do mapa mostra chuva (radar), não nuvens',
    );
  });
}
