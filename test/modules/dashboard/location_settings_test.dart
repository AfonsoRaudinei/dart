import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/modules/dashboard/domain/location_settings.dart';

void main() {
  group('isGnssAccuracyAcceptableForCheckIn', () {
    test('retorna false quando precisão é null', () {
      expect(isGnssAccuracyAcceptableForCheckIn(null), isFalse);
    });

    test('aceita precisão até 30m', () {
      expect(isGnssAccuracyAcceptableForCheckIn(30), isTrue);
      expect(isGnssAccuracyAcceptableForCheckIn(8), isTrue);
    });

    test('rejeita precisão acima de 30m', () {
      expect(isGnssAccuracyAcceptableForCheckIn(31), isFalse);
      expect(isGnssAccuracyAcceptableForCheckIn(120), isFalse);
    });
  });
}
