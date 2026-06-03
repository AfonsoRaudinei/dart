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

    test('satellite com MapTiler key usa MapTiler oficial', () {
      final config = MapConfig.tileConfigForLayer(
        LayerType.satellite,
        mapTilerApiKey: 'test-key',
      );

      expect(config.isFallback, isFalse);
      expect(config.requiresApiKey, isTrue);
      expect(config.urlTemplate, contains('/maps/satellite-v4/256/'));
      expect(config.urlTemplate, contains('key=test-key'));
      expect(config.attribution, MapConfig.mapTilerAttribution);
      expect(config.maxZoom, MapConfig.satelliteMaxZoom);
      expect(config.maxNativeZoom, MapConfig.mapTilerSatelliteMaxNativeZoom);
      expect(config.fallbackUrl, MapConfig.esriWorldImagery);
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

    test(
      'relevo com MapTiler key usa Landscape iOS-like com fallback topo',
      () {
        final config = MapConfig.tileConfigForLayer(
          LayerType.relevo,
          mapTilerApiKey: 'test-key',
        );

        expect(config.requiresApiKey, isTrue);
        expect(config.urlTemplate, contains('/landscape/256/'));
        expect(config.urlTemplate, contains('{y}{r}.png'));
        expect(config.fallbackUrl, MapConfig.esriWorldTopo);
        expect(config.maxZoom, MapConfig.mapTilerStyledMaxZoom);
        expect(config.maxNativeZoom, MapConfig.mapTilerStyledMaxNativeZoom);
        expect(config.retinaMode, isTrue);
      },
    );
  });
}
