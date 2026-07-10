import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:soloforte_app/core/config/map_config.dart';
import 'package:soloforte_app/core/domain/map_models.dart';
import 'package:soloforte_app/core/infra/preferences_service.dart';
import 'package:soloforte_app/core/state/map_state.dart';
import 'package:soloforte_app/modules/clima/presentation/providers/radar_providers.dart';
import 'package:soloforte_app/modules/clima/presentation/widgets/clima_radar_zoom_guard.dart';

void main() {
  group('ClimaRadarZoomGuard', () {
    testWidgets('limita zoom ao ativar radar com camada satélite', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final preferencesService = PreferencesService(
        await SharedPreferences.getInstance(),
      );

      final mapController = MapController();
      addTearDown(mapController.dispose);

      late ProviderContainer container;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            preferencesServiceProvider.overrideWithValue(preferencesService),
            climaRadarEnabledProvider.overrideWith(() => _PresetClimaRadarEnabled(false)),
            activeLayerProvider.overrideWith(() => _PresetActiveLayer(LayerType.satellite)),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: FlutterMap(
                mapController: mapController,
                options: const MapOptions(
                  initialCenter: LatLng(-15.7801, -47.9292),
                  initialZoom: 20,
                ),
                children: [
                  ClimaRadarZoomGuard(mapController: mapController),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      container = ProviderScope.containerOf(
        tester.element(find.byType(ClimaRadarZoomGuard)),
      );

      final tileConfig = MapConfig.tileConfigForLayer(
        LayerType.satellite,
        mapTilerApiKey: MapConfig.kMapTilerApiKey,
      );
      expect(mapController.camera.zoom, 20);

      container.read(climaRadarEnabledProvider.notifier).setEnabled(true);
      await tester.pump();

      expect(
        mapController.camera.zoom,
        lessThanOrEqualTo(tileConfig.maxNativeZoom.toDouble()),
      );
    });
  });
}

class _PresetClimaRadarEnabled extends ClimaRadarEnabled {
  _PresetClimaRadarEnabled(this.initial);

  final bool initial;

  @override
  bool build() => initial;
}

class _PresetActiveLayer extends ActiveLayer {
  _PresetActiveLayer(this.initial);

  final LayerType initial;

  @override
  LayerType build() => initial;
}
