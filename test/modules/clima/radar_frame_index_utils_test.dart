import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/modules/clima/domain/entities/radar_rain_frame.dart';
import 'package:soloforte_app/modules/clima/domain/radar_frame_index_utils.dart';

void main() {
  group('climaRadarLatestPastFrameIndex', () {
    const past0 = ClimaRadarFrame(
      time: 1,
      path: '/a',
      urlTemplate: 'u',
      isNowcast: false,
    );
    const past1 = ClimaRadarFrame(
      time: 2,
      path: '/b',
      urlTemplate: 'u',
      isNowcast: false,
    );
    const future0 = ClimaRadarFrame(
      time: 3,
      path: '/c',
      urlTemplate: 'u',
      isNowcast: true,
    );

    test('retorna último past antes do nowcast', () {
      expect(
        climaRadarLatestPastFrameIndex([past0, past1, future0]),
        1,
      );
    });

    test('lista só nowcast retorna último índice', () {
      expect(climaRadarLatestPastFrameIndex([future0]), 0);
    });
  });

  group('climaRadarFramesManifestKey', () {
    test('muda quando quantidade de frames muda', () {
      const a = ClimaRadarFrame(
        time: 10,
        path: '/a',
        urlTemplate: 'u',
      );
      const b = ClimaRadarFrame(
        time: 20,
        path: '/b',
        urlTemplate: 'u',
        isNowcast: true,
      );
      final keyOne = climaRadarFramesManifestKey([a]);
      final keyTwo = climaRadarFramesManifestKey([a, b]);
      expect(keyOne, isNot(keyTwo));
    });
  });
}
