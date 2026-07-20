import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:soloforte_app/core/config/map_config.dart';
import 'package:soloforte_app/core/domain/map_models.dart';
import 'package:soloforte_app/core/infra/preferences_service.dart';
import 'package:soloforte_app/core/services/connectivity_service.dart';
import 'package:soloforte_app/core/services/offline_tile_cache_service.dart';
import 'package:soloforte_app/core/state/map_state.dart';
import 'package:soloforte_app/core/state/map_ui_providers.dart';
import 'package:soloforte_app/ui/components/map/widgets/map_offline_widgets.dart';

void main() {
  testWidgets(
    'mapa offline inicial sinaliza cobertura local ativa no cold start',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = PreferencesService(await SharedPreferences.getInstance());
      const cacheService = _FakeOfflineTileCacheService(hasTiles: true);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            preferencesServiceProvider.overrideWithValue(prefs),
            offlineTileCacheServiceProvider.overrideWithValue(cacheService),
            connectivityServiceProvider.overrideWithValue(
              const _FakeConnectivityService(initialValue: false),
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: Stack(
                children: [SizedBox.expand(), MapOfflineStatusOverlay()],
              ),
            ),
          ),
        ),
      );

      final container = ProviderScope.containerOf(
        tester.element(find.byType(MapOfflineStatusOverlay)),
      );
      final tileConfig = MapConfig.tileConfigForLayer(
        LayerType.satellite,
        mapTilerApiKey: MapConfig.kMapTilerApiKey,
      );
      final layerKey = cacheService.layerKeyFromTemplate(
        tileConfig.urlTemplate,
      );
      container
          .read(offlineMapAreasProvider.notifier)
          .addArea(
            OfflineMapAreaConfig(
              id: 'offline-area-1',
              layerKey: layerKey,
              south: -10.2,
              west: -48.2,
              north: -9.8,
              east: -47.8,
              minZoom: 12,
              maxZoom: 18,
              createdAt: DateTime(2026, 7, 20),
            ),
          );
      container
          .read(mapCameraSnapshotProvider.notifier)
          .state = MapCameraSnapshot(
        center: const LatLng(-10.0, -48.0),
        zoom: 14,
        visibleBounds: LatLngBounds(
          const LatLng(-10.1, -48.1),
          const LatLng(-9.9, -47.9),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Mapa offline ativo'), findsOneWidget);
      expect(
        find.text('A área visível está coberta pelo cache local.'),
        findsOneWidget,
      );
    },
  );
}

class _FakeOfflineTileCacheService extends OfflineTileCacheService {
  const _FakeOfflineTileCacheService({required this.hasTiles});

  final bool hasTiles;

  @override
  Future<bool> hasTilesForArea({
    required String layerKey,
    required double south,
    required double west,
    required double north,
    required double east,
    required int zoom,
  }) async {
    return hasTiles;
  }
}

class _FakeConnectivityService implements ConnectivityService {
  const _FakeConnectivityService({required bool initialValue})
    : _initialValue = initialValue;

  final bool _initialValue;

  @override
  Stream<bool> get connectivityStream => const Stream<bool>.empty();

  @override
  Future<bool> get isConnected async => _initialValue;

  @override
  void dispose() {}
}
