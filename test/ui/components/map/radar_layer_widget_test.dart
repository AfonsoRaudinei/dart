import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
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
    child: const MaterialApp(
      home: Scaffold(
        body: FlutterMap(
          options: MapOptions(
            initialCenter: LatLng(-15.7801, -47.9292),
            initialZoom: 5,
          ),
          children: [RadarLayerWidget()],
        ),
      ),
    ),
  );
}
