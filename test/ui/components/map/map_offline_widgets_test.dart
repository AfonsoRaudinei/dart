import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/core/state/map_state.dart';
import 'package:soloforte_app/ui/components/map/widgets/map_offline_widgets.dart';

void main() {
  group('OfflineMapAreaConfig.mergeWithViewport', () {
    test('nao encolhe bbox quando viewport e subconjunto da area existente', () {
      final existing = OfflineMapAreaConfig(
        id: 'area-1',
        layerKey: 'layer-a',
        south: -15,
        west: -55,
        north: -12,
        east: -50,
        minZoom: 10,
        maxZoom: 18,
        createdAt: _fixedDate,
      );
      final merged = existing.mergeWithViewport(
        south: -14,
        west: -54,
        north: -13,
        east: -53,
        minZoom: 14,
        maxZoom: 16,
        createdAt: _refreshDate,
      );

      expect(merged.id, 'area-1');
      expect(merged.layerKey, 'layer-a');
      expect(merged.south, -15);
      expect(merged.west, -55);
      expect(merged.north, -12);
      expect(merged.east, -50);
      expect(merged.minZoom, 10);
      expect(merged.maxZoom, 18);
      expect(merged.createdAt, _refreshDate);
    });

    test('expande bbox e zoom quando viewport ultrapassa area existente', () {
      final existing = OfflineMapAreaConfig(
        id: 'area-2',
        layerKey: 'layer-a',
        south: -14,
        west: -54,
        north: -13,
        east: -53,
        minZoom: 14,
        maxZoom: 16,
        createdAt: _fixedDate,
      );
      final merged = existing.mergeWithViewport(
        south: -15,
        west: -55,
        north: -12,
        east: -50,
        minZoom: 12,
        maxZoom: 18,
        createdAt: _refreshDate,
      );

      expect(merged.south, -15);
      expect(merged.west, -55);
      expect(merged.north, -12);
      expect(merged.east, -50);
      expect(merged.minZoom, 12);
      expect(merged.maxZoom, 18);
    });
  });

  group('buildMapOfflineStatusPresentation', () {
    test('sinaliza mapa offline ativo quando viewport ja esta coberto', () {
      final result = buildMapOfflineStatusPresentation(
        isOnline: false,
        hasOfflineAreasForLayer: true,
        hasOfflineCoverageForViewport: true,
        isCheckingCoverage: false,
      );

      expect(result.state, MapOfflineVisualState.offlineActive);
      expect(result.canDownloadCurrentArea, isFalse);
      expect(result.title, 'Mapa offline ativo');
    });

    test('orienta quando usuario esta offline fora da area baixada', () {
      final result = buildMapOfflineStatusPresentation(
        isOnline: false,
        hasOfflineAreasForLayer: true,
        hasOfflineCoverageForViewport: false,
        isCheckingCoverage: false,
      );

      expect(result.state, MapOfflineVisualState.offlineOutOfCoverage);
      expect(result.message, contains('não está coberta offline'));
    });

    test('estimula download quando area visivel ainda nao foi baixada', () {
      final result = buildMapOfflineStatusPresentation(
        isOnline: true,
        hasOfflineAreasForLayer: false,
        hasOfflineCoverageForViewport: false,
        isCheckingCoverage: false,
      );

      expect(result.state, MapOfflineVisualState.onlineUncovered);
      expect(result.canDownloadCurrentArea, isTrue);
      expect(result.title, 'Baixe a área visível');
      expect(result.downloadActionLabel, 'Baixar área');
    });

    test('sinaliza area desatualizada quando online e TTL expirado', () {
      final result = buildMapOfflineStatusPresentation(
        isOnline: true,
        hasOfflineAreasForLayer: true,
        hasOfflineCoverageForViewport: true,
        isCheckingCoverage: false,
        isOfflineAreaStale: true,
      );

      expect(result.state, MapOfflineVisualState.onlineStale);
      expect(result.title, 'Área offline desatualizada');
      expect(result.canDownloadCurrentArea, isTrue);
      expect(result.downloadActionLabel, 'Atualizar área');
      expect(result.message, contains('180 dias'));
    });

    test('avisa imagem desatualizada quando offline e TTL expirado', () {
      final result = buildMapOfflineStatusPresentation(
        isOnline: false,
        hasOfflineAreasForLayer: true,
        hasOfflineCoverageForViewport: true,
        isCheckingCoverage: false,
        isOfflineAreaStale: true,
      );

      expect(result.state, MapOfflineVisualState.offlineStale);
      expect(result.canDownloadCurrentArea, isFalse);
      expect(result.message, contains('desatualizadas'));
    });

    test('online coberto usa label Atualizar area', () {
      final result = buildMapOfflineStatusPresentation(
        isOnline: true,
        hasOfflineAreasForLayer: true,
        hasOfflineCoverageForViewport: true,
        isCheckingCoverage: false,
      );

      expect(result.downloadActionLabel, 'Atualizar área');
    });
  });
}

final _fixedDate = DateTime(2020, 1, 1);
final _refreshDate = DateTime(2026, 9, 19);
