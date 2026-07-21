import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/ui/components/map/widgets/map_layers.dart';

void main() {
  group('shouldUseOfflineTileLayer', () {
    test(
      'prioriza cache local quando viewport offline esta coberta e conectividade inicial nao confirmou online',
      () {
        expect(
          shouldUseOfflineTileLayer(
            hasOfflineCoverageForViewport: true,
            offlineTemplate: '/tmp/offline_tiles/{z}/{x}/{y}.tile',
            isOnline: null,
          ),
          isTrue,
        );
      },
    );

    test('usa cache local quando o app inicia explicitamente offline', () {
      expect(
        shouldUseOfflineTileLayer(
          hasOfflineCoverageForViewport: true,
          offlineTemplate: '/tmp/offline_tiles/{z}/{x}/{y}.tile',
          isOnline: false,
        ),
        isTrue,
      );
    });

    test('nao usa cache local sem cobertura offline da viewport', () {
      expect(
        shouldUseOfflineTileLayer(
          hasOfflineCoverageForViewport: false,
          offlineTemplate: '/tmp/offline_tiles/{z}/{x}/{y}.tile',
          isOnline: false,
        ),
        isFalse,
      );
    });

    test('nao usa cache local quando o app confirmou estado online', () {
      expect(
        shouldUseOfflineTileLayer(
          hasOfflineCoverageForViewport: true,
          offlineTemplate: '/tmp/offline_tiles/{z}/{x}/{y}.tile',
          isOnline: true,
        ),
        isFalse,
      );
    });
  });
}
