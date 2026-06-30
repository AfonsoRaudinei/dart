import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/modules/clima/domain/entities/radar_fetch_result.dart';
import 'package:soloforte_app/modules/clima/domain/radar_overlay_state.dart';

void main() {
  group('resolveClimaRadarOverlayState', () {
    test('mapeia loading, active, vazio, offline e erro', () {
      expect(
        resolveClimaRadarOverlayState(
          enabled: false,
          isOnline: true,
          isLoading: false,
        ),
        ClimaRadarOverlayState.disabled,
      );
      expect(
        resolveClimaRadarOverlayState(
          enabled: true,
          isOnline: false,
          isLoading: false,
        ),
        ClimaRadarOverlayState.offline,
      );
      expect(
        resolveClimaRadarOverlayState(
          enabled: true,
          isOnline: true,
          isLoading: true,
        ),
        ClimaRadarOverlayState.loading,
      );
      expect(
        resolveClimaRadarOverlayState(
          enabled: true,
          isOnline: true,
          isLoading: false,
          result: const ClimaRadarFetchResult(
            status: ClimaRadarFetchStatus.success,
            frames: [],
          ),
        ),
        ClimaRadarOverlayState.unavailable,
      );
      expect(
        resolveClimaRadarOverlayState(
          enabled: true,
          isOnline: true,
          isLoading: false,
          result: const ClimaRadarFetchResult(
            status: ClimaRadarFetchStatus.emptyManifest,
          ),
        ),
        ClimaRadarOverlayState.noPrecipitation,
      );
    });
  });

  group('climaRadarBannerMessage', () {
    test('retorna mensagens diferenciadas por estado', () {
      expect(
        climaRadarBannerMessage(state: ClimaRadarOverlayState.noPrecipitation),
        ClimaRadarOverlayMessages.noPrecipitation,
      );
      expect(
        climaRadarBannerMessage(state: ClimaRadarOverlayState.offline),
        ClimaRadarOverlayMessages.offline,
      );
      expect(
        climaRadarBannerMessage(state: ClimaRadarOverlayState.unavailable),
        ClimaRadarOverlayMessages.unavailable,
      );
    });
  });
}
