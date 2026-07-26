import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:soloforte_app/core/providers/connectivity_provider.dart';
import 'package:soloforte_app/modules/clima/domain/entities/radar_fetch_result.dart';
import 'package:soloforte_app/modules/clima/domain/entities/radar_rain_frame.dart';
import 'package:soloforte_app/modules/clima/domain/radar_overlay_state.dart';
import 'package:soloforte_app/modules/clima/presentation/providers/radar_providers.dart';
import 'package:soloforte_app/modules/clima/presentation/widgets/radar_layer_widget.dart';

void main() {
  group('ClimaRadarLayerWidget', () {
    testWidgets('renderiza tiles quando radar ativo e há frames', (
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
      // Banner/gota removido — status unificado no indicador do mapa.
      expect(find.byIcon(Icons.water_drop_outlined), findsNothing);
      expect(find.byKey(const Key('radar_active_banner')), findsNothing);
    });

    testWidgets('não exibe banner enquanto busca frames', (tester) async {
      final completer = Completer<ClimaRadarFetchResult>();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            climaRadarEnabledProvider.overrideWith(
              () => _PresetClimaRadarEnabled(true),
            ),
            isOnlineProvider.overrideWith((ref) => Stream.value(true)),
            climaRadarFramesProvider.overrideWith((ref) => completer.future),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: FlutterMap(
                options: const MapOptions(
                  initialCenter: LatLng(-15.7801, -47.9292),
                  initialZoom: 5,
                ),
                children: const [ClimaRadarStatusOverlay()],
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(find.text(ClimaRadarOverlayMessages.loading), findsNothing);
      expect(find.byType(SizedBox), findsWidgets);
    });

    testWidgets('não exibe banner offline — só oculta tiles', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            climaRadarEnabledProvider.overrideWith(
              () => _PresetClimaRadarEnabled(true),
            ),
            isOnlineProvider.overrideWith((ref) => Stream.value(false)),
            climaRadarFramesProvider.overrideWith(
              (ref) async => _successResult(),
            ),
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
                  const ClimaRadarStatusOverlay(),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(find.text(ClimaRadarOverlayMessages.offline), findsNothing);
      expect(find.byType(TileLayer), findsNothing);
    });

    testWidgets('sem precipitação: sem tiles e sem banner', (tester) async {
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

    testWidgets('erro HTTP: sem banner de indisponível', (tester) async {
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
            const ClimaRadarStatusOverlay(),
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
