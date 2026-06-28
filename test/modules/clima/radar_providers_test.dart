import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:soloforte_app/core/config/map_config.dart';
import 'package:soloforte_app/modules/clima/data/datasources/rainviewer_radar_datasource.dart';
import 'package:soloforte_app/modules/clima/domain/entities/radar_fetch_result.dart';
import 'package:soloforte_app/modules/clima/domain/radar_frame_age_label.dart';
import 'package:soloforte_app/modules/clima/presentation/providers/radar_providers.dart';

void main() {
  group('climaRadarFramesProvider', () {
    final validJson = jsonEncode({
      'host': MapConfig.rainViewerTileBase,
      'radar': {
        'past': [
          {'time': 1712990000, 'path': '/v2/radar/1712990000'},
          {'time': 1713000000, 'path': '/v2/radar/1713000000'},
        ],
        'nowcast': [],
      },
    });

    test('parseClimaRadarFrames preserva ordem e monta URLs', () {
      final json = jsonDecode(validJson) as Map<String, dynamic>;
      final frames = parseClimaRadarFrames(json);

      expect(frames, hasLength(2));
      expect(
        frames[1].urlTemplate,
        '${MapConfig.rainViewerTileBase}/v2/radar/1713000000/512/{z}/{x}/{y}/2/1_1.png',
      );
    });

    test('provider retorna success quando API responde manifesto válido', () async {
      final container = ProviderContainer(
        overrides: [
          climaRadarFetchProvider.overrideWithValue((uri) async {
            expect(uri.toString(), MapConfig.rainViewerApiUrl);
            return http.Response(validJson, 200);
          }),
        ],
      );
      addTearDown(container.dispose);

      final result = await container.read(climaRadarFramesProvider.future);
      expect(result.status, ClimaRadarFetchStatus.success);
      expect(result.frames, hasLength(2));
    });

    test('provider retorna httpError em erro HTTP', () async {
      final container = ProviderContainer(
        overrides: [
          climaRadarFetchProvider.overrideWithValue(
            (_) async => http.Response('erro', 503),
          ),
        ],
      );
      addTearDown(container.dispose);

      final result = await container.read(climaRadarFramesProvider.future);
      expect(result.status, ClimaRadarFetchStatus.httpError);
      expect(result.frames, isEmpty);
    });

    test('provider retorna emptyManifest quando past está vazio', () async {
      final container = ProviderContainer(
        overrides: [
          climaRadarFetchProvider.overrideWithValue(
            (_) async => http.Response(
              jsonEncode({'radar': {'past': [], 'nowcast': []}}),
              200,
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      final result = await container.read(climaRadarFramesProvider.future);
      expect(result.status, ClimaRadarFetchStatus.emptyManifest);
    });
  });

  group('formatClimaRadarFrameAgeLabel', () {
    test('formata idade recente e minutos', () {
      final now = DateTime(2026, 6, 27, 12, 0);
      expect(
        formatClimaRadarFrameAgeLabel(now.millisecondsSinceEpoch ~/ 1000, now),
        'agora',
      );
    });
  });
}
