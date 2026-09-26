import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/core/config/map_config.dart';
import 'package:soloforte_app/modules/clima/data/datasources/realearth_cloud_datasource.dart';

void main() {
  group('RealEarth globalir contract', () {
    test('último carimbo vira template XYZ datado', () {
      final frame = parseClimaCloudFrame({
        'globalir': ['20260926.140000', '20260926.150000'],
      });

      expect(frame, isNotNull);
      expect(frame!.timeKey, '20260926.150000');
      expect(
        frame.urlTemplate,
        '${MapConfig.realEarthCloudTileBase}/20260926/150000/{z}/{x}/{y}.png',
      );
    });

    test('ignora carimbo inválido no fim e usa o anterior', () {
      final frame = parseClimaCloudFrame({
        'globalir': ['20260926.150000', 'latest', 12],
      });

      expect(frame!.timeKey, '20260926.150000');
    });

    test('lista vazia não inventa frame', () {
      expect(parseClimaCloudFrame({'globalir': []}), isNull);
      expect(parseClimaCloudFrame({}), isNull);
    });

    test('fallback latest não depende de horário', () {
      final frame = climaCloudLatestFallbackFrame();
      expect(frame.isLatestFallback, isTrue);
      expect(frame.urlTemplate, MapConfig.realEarthCloudLatestTileTemplate);
      expect(frame.urlTemplate, contains('/globalir/{z}/{x}/{y}.png'));
    });

    test('fixture local segue o manifesto publicado', () {
      const raw = '''
{"globalir":["20260926.140000","20260926.150000"]}
''';
      final json = jsonDecode(raw) as Map<String, dynamic>;
      final frame = parseClimaCloudFrame(json);
      expect(frame!.urlTemplate, contains('/tiles/globalir/20260926/150000/'));
    });
  });
}
