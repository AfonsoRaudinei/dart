import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/core/config/map_config.dart';
import 'package:soloforte_app/core/domain/map_models.dart';

void main() {
  group('MapConfig.tileConfigForLayer', () {
    test('satellite sem MapTiler key usa fallback licenciado (sem Google)', () {
      final config = MapConfig.tileConfigForLayer(
        LayerType.satellite,
        mapTilerApiKey: '',
      );

      expect(config.isFallback, isTrue);
      expect(config.urlTemplate, MapConfig.cartoVoyagerRetina);
      expect(config.attribution, MapConfig.cartoAttribution);
      expect(config.subdomains, MapConfig.cartoSubdomains);
      expect(config.maxZoom, MapConfig.defaultLayerMaxZoom);
      expect(config.maxNativeZoom, MapConfig.defaultLayerMaxNativeZoom);
      expect(config.fallbackUrl, isNull);
    });

    // Auditoria A-001: mt{s}.google.com é endpoint interno do Google Maps,
    // sem licença fora do SDK oficial. Nenhuma camada pode usá-lo.
    test('nenhuma camada usa tiles do Google (violação de ToS)', () {
      for (final layer in LayerType.values) {
        for (final key in ['', 'test-key']) {
          final config = MapConfig.tileConfigForLayer(
            layer,
            mapTilerApiKey: key,
          );
          expect(config.urlTemplate, isNot(contains('google.com')));
          expect(config.fallbackUrl ?? '', isNot(contains('google.com')));
        }
      }
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
      expect(config.fallbackUrl, isNull);
    });

    test('relevo sem MapTiler key usa fallback limpo sem Esri', () {
      final config = MapConfig.tileConfigForLayer(
        LayerType.relevo,
        mapTilerApiKey: '',
      );

      expect(config.isFallback, isTrue);
      expect(config.urlTemplate, MapConfig.cartoVoyagerRetina);
      expect(config.attribution, MapConfig.cartoAttribution);
      expect(config.subdomains, MapConfig.cartoSubdomains);
      expect(config.maxZoom, MapConfig.defaultLayerMaxZoom);
      expect(config.maxNativeZoom, MapConfig.defaultLayerMaxNativeZoom);
      expect(config.retinaMode, isTrue);
      expect(config.fallbackUrl, isNull);
    });

    test(
      'relevo com MapTiler key usa Landscape iOS-like sem fallback Esri',
      () {
        final config = MapConfig.tileConfigForLayer(
          LayerType.relevo,
          mapTilerApiKey: 'test-key',
        );

        expect(config.requiresApiKey, isTrue);
        expect(config.urlTemplate, contains('/landscape/256/'));
        expect(config.urlTemplate, contains('{y}{r}.png'));
        expect(config.fallbackUrl, isNull);
        expect(config.maxZoom, MapConfig.mapTilerStyledMaxZoom);
        expect(config.maxNativeZoom, MapConfig.mapTilerStyledMaxNativeZoom);
        expect(config.retinaMode, isTrue);
      },
    );

    test('camadas base não usam Esri como fallback automático', () {
      for (final layer in LayerType.values) {
        final withoutKey = MapConfig.tileConfigForLayer(
          layer,
          mapTilerApiKey: '',
        );
        final withKey = MapConfig.tileConfigForLayer(
          layer,
          mapTilerApiKey: 'test-key',
        );

        expect(withoutKey.fallbackUrl, isNot(MapConfig.esriWorldImagery));
        expect(withoutKey.fallbackUrl, isNot(MapConfig.esriWorldTopo));
        expect(withKey.fallbackUrl, isNot(MapConfig.esriWorldImagery));
        expect(withKey.fallbackUrl, isNot(MapConfig.esriWorldTopo));
      }
    });
  });
}
