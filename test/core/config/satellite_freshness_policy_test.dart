import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/core/config/satellite_freshness_policy.dart';

void main() {
  group('isInCerradoBounds', () {
    test('Sorriso/MT está no Cerrado', () {
      expect(isInCerradoBounds(-12.54, -55.72), isTrue);
    });

    test('Rio Verde/GO está no Cerrado', () {
      expect(isInCerradoBounds(-17.79, -50.93), isTrue);
    });

    test('Dourados/MS está no Cerrado', () {
      expect(isInCerradoBounds(-22.22, -54.81), isTrue);
    });

    test('Curitiba está fora do Cerrado (sul do bbox)', () {
      expect(isInCerradoBounds(-25.42, -49.27), isFalse);
    });

    test('respeita limites norte e sul do bbox', () {
      expect(isInCerradoBounds(kCerradoNorth, -50), isTrue);
      expect(isInCerradoBounds(kCerradoSouth, -50), isTrue);
      expect(isInCerradoBounds(kCerradoNorth + 0.1, -50), isFalse);
      expect(isInCerradoBounds(kCerradoSouth - 0.1, -50), isFalse);
    });
  });

  group('freshnessForPoint', () {
    test('dentro do Cerrado indica overlay disponível', () {
      final info = freshnessForPoint(-12.54, -55.72);

      expect(info.isInCerrado, isTrue);
      expect(info.cerradoOverlayAvailable, isTrue);
      expect(info.providerLabel, 'MapTiler Satellite');
      expect(info.acquisitionPeriod, '2020–2021');
      expect(info.disclaimer, contains('INPE'));
    });

    test('fora do Cerrado não oferece overlay', () {
      final info = freshnessForPoint(-25.42, -49.27);

      expect(info.isInCerrado, isFalse);
      expect(info.cerradoOverlayAvailable, isFalse);
      expect(info.disclaimer, isNot(contains('INPE')));
    });
  });
}
