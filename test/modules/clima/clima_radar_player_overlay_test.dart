import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/core/providers/connectivity_provider.dart';
import 'package:soloforte_app/modules/clima/presentation/providers/radar_providers.dart';
import 'package:soloforte_app/modules/clima/presentation/widgets/clima_radar_player_overlay.dart';

void main() {
  group('ClimaRadarPlayerOverlay', () {
    const frame1 = ClimaRadarFrame(
      time: 1713000000,
      path: '/v2/radar/frame1',
      urlTemplate: 'https://tilecache.rainviewer.com/v2/radar/frame1/512/{z}/{x}/{y}/2/1_0.png',
      isNowcast: false,
    );
    const frame2 = ClimaRadarFrame(
      time: 1713000600,
      path: '/v2/radar/frame2',
      urlTemplate: 'https://tilecache.rainviewer.com/v2/radar/frame2/512/{z}/{x}/{y}/2/1_0.png',
      isNowcast: true,
    );

    final successResult = const ClimaRadarFetchResult(
      status: ClimaRadarFetchStatus.success,
      frames: [frame1, frame2],
    );

    Widget buildTestApp({
      required bool radarEnabled,
      required bool isOnline,
      ClimaRadarFetchResult? result,
      int initialIndex = 0,
      bool initialPlaying = true,
    }) {
      return ProviderScope(
        overrides: [
          climaRadarEnabledProvider.overrideWith(() => _PresetClimaRadarEnabled(radarEnabled)),
          isOnlineProvider.overrideWith((ref) => Stream.value(isOnline)),
          climaRadarFramesProvider.overrideWith((ref) async => result ?? successResult),
          climaRadarFrameIndexProvider.overrideWith((ref) => initialIndex),
          climaRadarPlayingProvider.overrideWith((ref) => initialPlaying),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                ClimaRadarPlayerOverlay(),
              ],
            ),
          ),
        ),
      );
    }

    testWidgets('não renderiza quando radar está desabilitado', (tester) async {
      await tester.pumpWidget(buildTestApp(radarEnabled: false, isOnline: true));
      await tester.pump();

      expect(find.byType(ClimaRadarPlayerOverlay), findsOneWidget);
      expect(find.byIcon(Icons.pause_rounded), findsNothing);
      expect(find.byIcon(Icons.play_arrow_rounded), findsNothing);
    });

    testWidgets('não renderiza quando offline', (tester) async {
      await tester.pumpWidget(buildTestApp(radarEnabled: true, isOnline: false));
      await tester.pump();

      expect(find.byIcon(Icons.pause_rounded), findsNothing);
    });

    testWidgets('renderiza player com botões de controle e timestamp', (tester) async {
      await tester.pumpWidget(buildTestApp(radarEnabled: true, isOnline: true));
      await tester.pumpAndSettle();

      // Botões principais
      expect(find.byIcon(Icons.pause_rounded), findsOneWidget);
      expect(find.byIcon(Icons.skip_previous_rounded), findsOneWidget);
      expect(find.byIcon(Icons.skip_next_rounded), findsOneWidget);
      expect(find.byIcon(Icons.tune_rounded), findsOneWidget);
    });

    testWidgets('exibe badge PREV quando frame atual é nowcast', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          radarEnabled: true,
          isOnline: true,
          initialIndex: 1, // frame2 (isNowcast = true)
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('PREV'), findsOneWidget);
    });

    testWidgets('alterna play/pause ao tocar no botão de reprodução', (tester) async {
      await tester.pumpWidget(buildTestApp(radarEnabled: true, isOnline: true, initialPlaying: true));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.pause_rounded), findsOneWidget);

      await tester.tap(find.byIcon(Icons.pause_rounded));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);
    });
  });
}

class _PresetClimaRadarEnabled extends ClimaRadarEnabled {
  final bool initial;
  _PresetClimaRadarEnabled(this.initial);

  @override
  bool build() => initial;
}
