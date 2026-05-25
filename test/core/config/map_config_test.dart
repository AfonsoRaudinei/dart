import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/core/config/map_config.dart';
import 'package:soloforte_app/core/domain/map_models.dart';

void main() {
  group('MapConfig.tileConfigForLayer', () {
    test('satellite sem MapTiler key usa fallback Carto retina', () {
      final config = MapConfig.tileConfigForLayer(
        LayerType.satellite,
        mapTilerApiKey: '',
      );

      expect(config.isFallback, isTrue);
      expect(config.urlTemplate, MapConfig.cartoVoyagerRetina);
      expect(config.attribution, MapConfig.cartoAttribution);
      expect(config.maxZoom, MapConfig.defaultLayerMaxZoom);
      expect(config.maxNativeZoom, MapConfig.defaultLayerMaxNativeZoom);
      expect(config.retinaMode, isTrue);
    });

    test('satellite com MapTiler key usa tiles 256 com HiDPI', () {
      final config = MapConfig.tileConfigForLayer(
        LayerType.satellite,
        mapTilerApiKey: 'test-key',
      );

      expect(config.isFallback, isFalse);
      expect(config.requiresApiKey, isTrue);
      expect(config.urlTemplate, contains('/hybrid/256/'));
      expect(config.urlTemplate, contains('{y}{r}.jpg'));
      expect(config.urlTemplate, contains('key=test-key'));
      expect(config.attribution, MapConfig.mapTilerAttribution);
      expect(config.maxZoom, MapConfig.satelliteMaxZoom);
      expect(config.maxNativeZoom, MapConfig.satelliteMaxNativeZoom);
      expect(config.retinaMode, isTrue);
      expect(config.fallbackUrl, MapConfig.cartoVoyagerRetina);
    });

    test('relevo sem MapTiler key usa fallback natural', () {
      final config = MapConfig.tileConfigForLayer(
        LayerType.relevo,
        mapTilerApiKey: '',
      );

      expect(config.isFallback, isTrue);
      expect(config.urlTemplate, MapConfig.stadiaStamenTerrainUrl);
      expect(
        config.attribution,
        MapConfig.hasStadiaApiKey
            ? MapConfig.stadiaAttribution
            : MapConfig.osmAttribution,
      );
      expect(config.maxZoom, MapConfig.defaultLayerMaxZoom);
      expect(config.maxNativeZoom, MapConfig.defaultLayerMaxNativeZoom);
    });

    test('relevo com MapTiler key usa Landscape 256 com fallback Carto', () {
      final config = MapConfig.tileConfigForLayer(
        LayerType.relevo,
        mapTilerApiKey: 'test-key',
      );

      expect(config.requiresApiKey, isTrue);
      expect(config.urlTemplate, contains('/landscape/256/'));
      expect(config.urlTemplate, contains('{y}{r}.png'));
      expect(config.fallbackUrl, MapConfig.cartoVoyagerRetina);
      expect(config.maxZoom, MapConfig.defaultLayerMaxZoom);
    });
  });
}
