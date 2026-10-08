import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/modules/clima/data/datasources/rainviewer_radar_datasource.dart';

void main() {
  group('RainViewer manifest contract', () {
    late Map<String, dynamic> fixture;

    setUp(() {
      final raw = File('test/fixtures/rainviewer_manifest_v2.json')
          .readAsStringSync();
      fixture = jsonDecode(raw) as Map<String, dynamic>;
    });

    test('fixture v2 usa paths hash e monta templates válidos', () {
      final frames = parseClimaRadarFrames(fixture);

      expect(frames, isNotEmpty);
      expect(frames.first.path, startsWith('/v2/radar/'));
      expect(frames.first.urlTemplate, contains('/512/{z}/{x}/{y}/2/1_0.png'));
      expect(frames.first.isNowcast, isFalse);
    });

    test('parseClimaRadarFrames suporta nowcast e scheme customizado', () {
      final jsonWithNowcast = {
        'host': 'https://tilecache.rainviewer.com',
        'radar': {
          'past': [
            {'time': 1782607200, 'path': '/v2/radar/past1'},
          ],
          'nowcast': [
            {'time': 1782607800, 'path': '/v2/radar/nowcast1'},
          ],
        },
      };

      final frames = parseClimaRadarFrames(
        jsonWithNowcast,
        colorScheme: 6, // NEXRAD
        tileOptions: '1_0',
      );

      expect(frames, hasLength(2));
      expect(frames.first.isNowcast, isFalse);
      expect(frames.first.urlTemplate, contains('/6/1_0.png'));
      expect(frames.last.isNowcast, isTrue);
      expect(frames.last.urlTemplate, contains('/v2/radar/nowcast1/512/{z}/{x}/{y}/6/1_0.png'));
    });

    test('manifesto parseável a partir de fixture local (sem HTTP live)', () {
      final radar = fixture['radar'] as Map<String, dynamic>;
      final past = radar['past'] as List<dynamic>;
      expect(past, isNotEmpty);

      final frames = parseClimaRadarFrames(fixture);
      expect(frames, hasLength(past.length));
      expect(frames.last.urlTemplate, isNotEmpty);
      expect(frames.last.urlTemplate, contains('rainviewer.com'));
    });
  });
}
