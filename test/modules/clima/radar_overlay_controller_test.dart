import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:soloforte_app/core/contracts/i_radar_overlay_controller_provider.dart';
import 'package:soloforte_app/core/domain/map_models.dart';
import 'package:soloforte_app/core/infra/preferences_service.dart';
import 'package:soloforte_app/core/state/map_state.dart';
import 'package:soloforte_app/modules/clima/infra/radar_overlay_controller_adapter.dart';
import 'package:soloforte_app/modules/clima/presentation/providers/radar_providers.dart';

void main() {
  group('RadarOverlayControllerAdapter', () {
    test('ativa radar e troca camada para satélite', () async {
      SharedPreferences.setMockInitialValues({});
      final preferencesService = PreferencesService(
        await SharedPreferences.getInstance(),
      );

      final container = ProviderContainer(
        overrides: [
          preferencesServiceProvider.overrideWithValue(preferencesService),
          radarOverlayControllerProvider.overrideWith((ref) {
            return RadarOverlayControllerAdapter(ref);
          }),
        ],
      );
      addTearDown(container.dispose);

      container.read(activeLayerProvider.notifier).setLayer(LayerType.relevo);

      container.read(radarOverlayControllerProvider).setEnabled(
        true,
        preferSatelliteLayer: true,
      );

      expect(container.read(climaRadarEnabledProvider), isTrue);
      expect(container.read(activeLayerProvider), LayerType.satellite);
    });

    test('desativa radar sem alterar camada base', () async {
      SharedPreferences.setMockInitialValues({});
      final preferencesService = PreferencesService(
        await SharedPreferences.getInstance(),
      );

      final container = ProviderContainer(
        overrides: [
          preferencesServiceProvider.overrideWithValue(preferencesService),
          radarOverlayControllerProvider.overrideWith((ref) {
            return RadarOverlayControllerAdapter(ref);
          }),
        ],
      );
      addTearDown(container.dispose);

      container.read(activeLayerProvider.notifier).setLayer(LayerType.relevo);
      container.read(climaRadarEnabledProvider.notifier).setEnabled(true);

      container.read(radarOverlayControllerProvider).setEnabled(false);

      expect(container.read(climaRadarEnabledProvider), isFalse);
      expect(container.read(activeLayerProvider), LayerType.relevo);
    });
  });
}
