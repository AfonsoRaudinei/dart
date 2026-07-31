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
      expect(frames.first.urlTemplate, contains('/512/{z}/{x}/{y}/2/1_1.png'));
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
