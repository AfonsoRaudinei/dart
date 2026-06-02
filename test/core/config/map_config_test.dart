import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/core/config/map_config.dart';
import 'package:soloforte_app/core/domain/map_models.dart';

void main() {
  group('MapConfig.tileConfigForLayer', () {
    test('satellite sem MapTiler key usa Google real', () {
      final config = MapConfig.tileConfigForLayer(
        LayerType.satellite,
        mapTilerApiKey: '',
      );

      expect(config.isFallback, isFalse);
      expect(config.urlTemplate, MapConfig.googleSatelliteUrl);
      expect(config.attribution, MapConfig.googleAttribution);
      expect(config.subdomains, MapConfig.googleSatelliteSubdomains);
      expect(config.maxZoom, MapConfig.satelliteMaxZoom);
      expect(config.maxNativeZoom, MapConfig.satelliteMaxNativeZoom);
      expect(config.fallbackUrl, MapConfig.esriWorldImagery);
    });

    test('satellite com MapTiler key mantém Google real', () {
      final config = MapConfig.tileConfigForLayer(
        LayerType.satellite,
        mapTilerApiKey: 'test-key',
      );

      expect(config.isFallback, isFalse);
      expect(config.requiresApiKey, isFalse);
      expect(config.urlTemplate, MapConfig.googleSatelliteUrl);
      expect(config.attribution, MapConfig.googleAttribution);
      expect(config.maxZoom, MapConfig.satelliteMaxZoom);
      expect(config.maxNativeZoom, MapConfig.satelliteMaxNativeZoom);
    });

    test('relevo sem MapTiler key usa fallback natural', () {
      final config = MapConfig.tileConfigForLayer(
        LayerType.relevo,
        mapTilerApiKey: '',
      );

      expect(config.isFallback, isTrue);
      expect(config.urlTemplate, MapConfig.esriWorldTopo);
      expect(config.attribution, MapConfig.esriAttribution);
      expect(config.maxZoom, MapConfig.defaultLayerMaxZoom);
      expect(config.maxNativeZoom, MapConfig.defaultLayerMaxNativeZoom);
    });

    test('relevo com MapTiler key usa Outdoor 256 com fallback topo', () {
      final config = MapConfig.tileConfigForLayer(
        LayerType.relevo,
        mapTilerApiKey: 'test-key',
      );

      expect(config.requiresApiKey, isTrue);
      expect(config.urlTemplate, contains('/outdoor-v2/256/'));
      expect(config.urlTemplate, contains('{y}{r}.png'));
      expect(config.fallbackUrl, MapConfig.esriWorldTopo);
      expect(config.maxZoom, MapConfig.defaultLayerMaxZoom);
    });
  });
}
