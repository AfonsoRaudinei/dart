import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/ui/components/map/widgets/map_offline_widgets.dart';

void main() {
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
    });
  });
}
