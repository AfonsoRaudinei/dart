import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:soloforte_app/core/config/map_config.dart';
import 'package:soloforte_app/ui/components/map/providers/rainviewer_provider.dart';

/// Testes unitários do provider RainViewer (ADR-028).
///
/// Cobertos:
///   - Parsing de múltiplos frames com ordem preservada
///   - URL de tile correta para cada frame
///   - Lista vazia quando radar.past está vazio
///   - API offline / JSON inválido → lista vazia (graceful degradation)
void main() {
  group('rainviewerRadarFramesProvider', () {
    final validJson = jsonEncode({
      'host': MapConfig.rainViewerTileBase,
      'radar': {
        'past': [
          {'time': 1712990000, 'path': '/v2/radar/1712990000'},
          {'time': 1713000000, 'path': '/v2/radar/1713000000'},
          {'time': 1713010000, 'path': '/v2/radar/1713010000'},
        ],
        'nowcast': [],
      },
    });

    test('parseRainviewerRadarFrames preserva ordem e monta URLs', () {
      final json = jsonDecode(validJson) as Map<String, dynamic>;
      final frames = parseRainviewerRadarFrames(json);

      expect(frames, hasLength(3));
      expect(frames.map((frame) => frame.time), [
        1712990000,
        1713000000,
        1713010000,
      ]);
      expect(frames.map((frame) => frame.path), [
        '/v2/radar/1712990000',
        '/v2/radar/1713000000',
        '/v2/radar/1713010000',
      ]);
      expect(
        frames[1].urlTemplate,
        '${MapConfig.rainViewerTileBase}/v2/radar/1713000000/512/{z}/{x}/{y}/2/1_1.png',
      );
    });

    test('lista past vazia → lista vazia', () {
      final json =
          jsonDecode(
                jsonEncode({
                  'radar': {'past': [], 'nowcast': []},
                }),
              )
              as Map<String, dynamic>;

      expect(parseRainviewerRadarFrames(json), isEmpty);
    });

    test('campo radar ausente → lista vazia', () {
      final json = jsonDecode('{}') as Map<String, dynamic>;
      expect(parseRainviewerRadarFrames(json), isEmpty);
    });

    test('campo path ausente no frame → ignora frame inválido', () {
      final json =
          jsonDecode(
                jsonEncode({
                  'radar': {
                    'past': [
                      {'time': 1712990000},
                      {'time': 1713000000, 'path': '/v2/radar/1713000000'},
                    ],
                  },
                }),
              )
              as Map<String, dynamic>;

      final frames = parseRainviewerRadarFrames(json);

      expect(frames, hasLength(1));
      expect(frames.single.path, '/v2/radar/1713000000');
    });

    test(
      'provider retorna frames quando API responde manifesto válido',
      () async {
        final container = ProviderContainer(
          overrides: [
            rainviewerFetchProvider.overrideWithValue((uri) async {
              expect(uri.toString(), MapConfig.rainViewerApiUrl);
              return http.Response(validJson, 200);
            }),
          ],
        );
        addTearDown(container.dispose);

        final frames = await container.read(
          rainviewerRadarFramesProvider.future,
        );

        expect(frames, hasLength(3));
        expect(frames.last.path, '/v2/radar/1713010000');
      },
    );

    test('provider degrada para lista vazia em erro HTTP', () async {
      final container = ProviderContainer(
        overrides: [
          rainviewerFetchProvider.overrideWithValue(
            (_) async => http.Response('erro', 503),
          ),
        ],
      );
      addTearDown(container.dispose);

      final frames = await container.read(rainviewerRadarFramesProvider.future);

      expect(frames, isEmpty);
    });

    test('provider degrada para lista vazia em JSON inválido', () async {
      final container = ProviderContainer(
        overrides: [
          rainviewerFetchProvider.overrideWithValue(
            (_) async => http.Response('{', 200),
          ),
        ],
      );
      addTearDown(container.dispose);

      final frames = await container.read(rainviewerRadarFramesProvider.future);

      expect(frames, isEmpty);
    });

    test('constantes MapConfig têm valores não vazios', () {
      expect(MapConfig.rainViewerApiUrl, isNotEmpty);
      expect(MapConfig.rainViewerTileBase, isNotEmpty);
      expect(MapConfig.radarOverlayOpacity, greaterThan(0.0));
      expect(MapConfig.radarOverlayOpacity, lessThanOrEqualTo(1.0));
      expect(
        MapConfig.rainViewerAnimationFrameInterval,
        const Duration(milliseconds: 700),
      );
    });
  });
}
