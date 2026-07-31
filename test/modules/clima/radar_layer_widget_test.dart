import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:soloforte_app/core/config/map_config.dart';
import 'package:soloforte_app/core/providers/connectivity_provider.dart';
import 'package:soloforte_app/modules/clima/domain/entities/radar_fetch_result.dart';
import 'package:soloforte_app/modules/clima/domain/entities/radar_rain_frame.dart';
import 'package:soloforte_app/modules/clima/domain/radar_overlay_state.dart';
import 'package:soloforte_app/modules/clima/presentation/providers/radar_providers.dart';
import 'package:soloforte_app/modules/clima/presentation/widgets/radar_layer_widget.dart';

void main() {
  group('ClimaRadarLayerWidget', () {
    testWidgets('renderiza overlay quando radar ativo e há frames', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildRadarMap(
          radarEnabled: true,
          isOnline: true,
          result: _successResult(),
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(find.byType(TileLayer), findsOneWidget);
      expect(find.byKey(const Key('radar_active_banner')), findsNothing);
    });

    testWidgets('não exibe banner no topo quando radar desligado', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildRadarMap(
          radarEnabled: false,
          isOnline: true,
          result: _successResult(),
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(find.byType(TileLayer), findsNothing);
      expect(find.byKey(const Key('radar_loading_banner')), findsNothing);
    });

    testWidgets('não renderiza tiles quando sem conexão', (tester) async {
      await tester.pumpWidget(
        _buildRadarMap(
          radarEnabled: true,
          isOnline: false,
          result: _successResult(),
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(find.text(ClimaRadarOverlayMessages.offline), findsNothing);
      expect(find.byType(TileLayer), findsNothing);
    });

    testWidgets('não renderiza tiles quando manifesto vazio', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildRadarMap(
          radarEnabled: true,
          isOnline: true,
          result: const ClimaRadarFetchResult(
            status: ClimaRadarFetchStatus.emptyManifest,
          ),
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(
        find.text(ClimaRadarOverlayMessages.noPrecipitation),
        findsNothing,
      );
      expect(find.byType(TileLayer), findsNothing);
    });

    testWidgets('não renderiza tiles em erro HTTP', (tester) async {
      await tester.pumpWidget(
        _buildRadarMap(
          radarEnabled: true,
          isOnline: true,
          result: const ClimaRadarFetchResult(
            status: ClimaRadarFetchStatus.httpError,
            httpStatusCode: 503,
          ),
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(find.text(ClimaRadarOverlayMessages.unavailable), findsNothing);
      expect(find.byType(TileLayer), findsNothing);
    });
  });
}

ClimaRadarFetchResult _successResult() {
  return ClimaRadarFetchResult(
    status: ClimaRadarFetchStatus.success,
    frames: const [
      ClimaRadarFrame(
        time: 1713000000,
        path: '/v2/radar/1713000000',
        urlTemplate:
            'https://tilecache.rainviewer.com/v2/radar/1713000000/512/{z}/{x}/{y}/2/1_1.png',
      ),
    ],
  );
}

Widget _buildRadarMap({
  required bool radarEnabled,
  required bool isOnline,
  required ClimaRadarFetchResult result,
}) {
  return ProviderScope(
    overrides: [
      climaRadarEnabledProvider.overrideWith(
        () => _PresetClimaRadarEnabled(radarEnabled),
      ),
      isOnlineProvider.overrideWith((ref) => Stream.value(isOnline)),
      climaRadarFramesProvider.overrideWith((ref) async => result),
    ],
    child: MaterialApp(
      home: Scaffold(
        body: FlutterMap(
          options: const MapOptions(
            initialCenter: LatLng(-15.7801, -47.9292),
            initialZoom: 5,
          ),
          children: [
            ClimaRadarTileLayerWidget(tileProvider: _MemoryTileProvider()),
          ],
        ),
      ),
    ),
  );
}

class _PresetClimaRadarEnabled extends ClimaRadarEnabled {
  _PresetClimaRadarEnabled(this.initial);

  final bool initial;

  @override
  bool build() => initial;
}

class _MemoryTileProvider extends TileProvider {
  static final _tileImage = MemoryImage(
    Uri.parse(
      'data:image/png;base64,'
      'iVBORw0KGgoAAAANSUhEUgAAAQAAAAEAAQMAAABmvDolAAAAAXNSR0IB2cksfwAA'
      'AAlwSFlzAAALEwAACxMBAJqcGAAAAANQTFRF////p8QbyAAAAB9JREFUeJztwQENA'
      'AAAwqD3T20ON6AAAAAAAAAAAL4NIQAAAfFnIe4AAAAASUVORK5CYII=',
    ).data!.contentAsBytes(),
  );

  @override
  ImageProvider<Object> getImage(
    TileCoordinates coordinates,
    TileLayer options,
  ) => _tileImage;
}
