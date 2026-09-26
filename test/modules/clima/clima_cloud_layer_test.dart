import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:soloforte_app/core/config/map_config.dart';
import 'package:soloforte_app/core/providers/connectivity_provider.dart';
import 'package:soloforte_app/modules/clima/presentation/providers/radar_providers.dart';
import 'package:soloforte_app/modules/clima/presentation/widgets/clima_cloud_layer_widget.dart';

void main() {
  group('climaCloudFrameProvider', () {
    test('usa o frame mais novo do manifesto', () async {
      final container = ProviderContainer(
        overrides: [
          climaCloudFetchProvider.overrideWithValue((uri) async {
            expect(uri.toString(), MapConfig.realEarthCloudTimesUrl);
            return http.Response(
              jsonEncode({
                'globalir': ['20260926.140000', '20260926.150000'],
              }),
              200,
            );
          }),
        ],
      );
      addTearDown(container.dispose);

      final frame = await container.read(climaCloudFrameProvider.future);
      expect(frame.timeKey, '20260926.150000');
      expect(frame.urlTemplate, contains('/20260926/150000/'));
    });

    test('HTTP fora de 200 cai no template latest', () async {
      final container = ProviderContainer(
        overrides: [
          climaCloudFetchProvider.overrideWithValue(
            (_) async => http.Response('erro', 503),
          ),
        ],
      );
      addTearDown(container.dispose);

      final frame = await container.read(climaCloudFrameProvider.future);
      expect(frame.isLatestFallback, isTrue);
      expect(frame.urlTemplate, MapConfig.realEarthCloudLatestTileTemplate);
    });
  });

  group('ClimaCloudTileLayerWidget', () {
    testWidgets('pinta tiles quando o toggle está ligado e há rede', (
      tester,
    ) async {
      await tester.pumpWidget(_buildCloudMap(enabled: true, isOnline: true));
      await tester.pump();
      await tester.pump();

      expect(find.byType(TileLayer), findsOneWidget);
      final layer = tester.widget<TileLayer>(find.byType(TileLayer));
      expect(layer.urlTemplate, contains('/globalir/20260926/150000/'));
      expect(layer.maxNativeZoom, MapConfig.realEarthCloudMaxNativeZoom);
    });

    testWidgets('não pinta tiles offline nem com o toggle desligado', (
      tester,
    ) async {
      await tester.pumpWidget(_buildCloudMap(enabled: true, isOnline: false));
      await tester.pump();
      expect(find.byType(TileLayer), findsNothing);

      await tester.pumpWidget(_buildCloudMap(enabled: false, isOnline: true));
      await tester.pump();
      expect(find.byType(TileLayer), findsNothing);
    });
  });
}

Widget _buildCloudMap({required bool enabled, required bool isOnline}) {
  return ProviderScope(
    overrides: [
      climaRadarEnabledProvider.overrideWith(
        () => _PresetClimaRadarEnabled(enabled),
      ),
      isOnlineProvider.overrideWith((ref) => Stream.value(isOnline)),
      climaCloudFrameProvider.overrideWith(
        (ref) async => const ClimaCloudFrame(
          timeKey: '20260926.150000',
          urlTemplate:
              'https://realearth.ssec.wisc.edu/tiles/globalir/20260926/150000/{z}/{x}/{y}.png',
        ),
      ),
    ],
    child: MaterialApp(
      home: Scaffold(
        body: FlutterMap(
          options: const MapOptions(
            initialCenter: LatLng(-10.7, -48.4),
            initialZoom: 5,
          ),
          children: [
            ClimaCloudTileLayerWidget(tileProvider: _MemoryTileProvider()),
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
