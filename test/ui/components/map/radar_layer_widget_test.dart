import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:soloforte_app/core/config/map_config.dart';
import 'package:soloforte_app/ui/components/map/providers/rainviewer_provider.dart';
import 'package:soloforte_app/ui/components/map/widgets/radar_layer_widget.dart';
import 'package:soloforte_app/ui/screens/map/providers/map_armed_mode_provider.dart';

void main() {
  group('RadarLayerWidget', () {
    testWidgets('não renderiza overlay quando clima está inativo', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildRadarMap(
          armedMode: ArmedMode.none,
          frames: const [
            RainviewerRadarFrame(
              time: 1713000000,
              path: '/v2/radar/1713000000',
              urlTemplate:
                  'https://tilecache.rainviewer.com/v2/radar/1713000000/512/{z}/{x}/{y}/2/1_1.png',
            ),
          ],
        ),
      );

      expect(find.byType(TileLayer), findsNothing);
      expect(find.text('Radar indisponível'), findsNothing);
    });

    testWidgets('renderiza overlay quando clima está ativo e há frames', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildRadarMap(
          armedMode: ArmedMode.clima,
          frames: const [
            RainviewerRadarFrame(
              time: 1713000000,
              path: '/v2/radar/1713000000',
              urlTemplate:
                  'https://tilecache.rainviewer.com/v2/radar/1713000000/512/{z}/{x}/{y}/2/1_1.png',
            ),
          ],
        ),
      );
      await tester.pump();

      expect(find.byType(TileLayer), findsOneWidget);
      expect(find.text('Radar indisponível'), findsNothing);
      expect(
        find.text('Radar ativo · sem chuva visível onde não há eco'),
        findsOneWidget,
      );
    });

    testWidgets('configura limites de zoom para overzoom do radar', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildRadarMap(
          armedMode: ArmedMode.clima,
          frames: const [
            RainviewerRadarFrame(
              time: 1713000000,
              path: '/v2/radar/1713000000',
              urlTemplate:
                  'https://tilecache.rainviewer.com/v2/radar/1713000000/512/{z}/{x}/{y}/2/1_1.png',
            ),
          ],
        ),
      );
      await tester.pump();

      final tileLayer = tester.widget<TileLayer>(find.byType(TileLayer));
      expect(tileLayer.maxZoom, MapConfig.rainViewerMaxZoom);
      expect(tileLayer.maxNativeZoom, MapConfig.rainViewerMaxNativeZoom);
    });

    testWidgets('exibe indisponível quando clima está ativo sem frames', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildRadarMap(armedMode: ArmedMode.clima, frames: const []),
      );
      await tester.pump();

      expect(find.byType(TileLayer), findsNothing);
      expect(find.text('Radar indisponível'), findsOneWidget);
    });
  });
}

Widget _buildRadarMap({
  required ArmedMode armedMode,
  required List<RainviewerRadarFrame> frames,
}) {
  return ProviderScope(
    overrides: [
      armedModeProvider.overrideWith((ref) => armedMode),
      rainviewerRadarFramesProvider.overrideWith((ref) async => frames),
    ],
    child: MaterialApp(
      home: Scaffold(
        body: FlutterMap(
          options: MapOptions(
            initialCenter: LatLng(-15.7801, -47.9292),
            initialZoom: 5,
          ),
          children: [RadarLayerWidget(tileProvider: _MemoryTileProvider())],
        ),
      ),
    ),
  );
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
