import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/core/config/map_config.dart';
import 'package:soloforte_app/modules/clima/data/datasources/rainviewer_radar_datasource.dart';

void main() {
  group('RainViewer manifest contract', () {
    late Map<String, dynamic> fixture;

    setUp(() {
      final raw = File('test/fixtures/rainviewer_manifest_v2.json').readAsStringSync();
      fixture = jsonDecode(raw) as Map<String, dynamic>;
    });

    test('fixture v2 usa paths hash e monta templates válidos', () {
      final frames = parseClimaRadarFrames(fixture);

      expect(frames, isNotEmpty);
      expect(frames.first.path, startsWith('/v2/radar/'));
      expect(frames.first.urlTemplate, contains('/512/{z}/{x}/{y}/2/1_1.png'));
    });

    test(
      'API pública responde manifesto parseável',
      () async {
        final client = HttpClient();
        try {
          final request = await client.getUrl(
            Uri.parse(MapConfig.rainViewerApiUrl),
          );
          final response = await request.close();
          expect(response.statusCode, 200);

          final body = await response.transform(utf8.decoder).join();
          final json = jsonDecode(body);
          expect(json, isA<Map<String, dynamic>>());

          final frames = parseClimaRadarFrames(json as Map<String, dynamic>);
          expect(frames, isNotEmpty);
          expect(frames.last.urlTemplate, isNotEmpty);
        } finally {
          client.close(force: true);
        }
      },
      timeout: const Timeout(Duration(seconds: 20)),
    );
  });
}
