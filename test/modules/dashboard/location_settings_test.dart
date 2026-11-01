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

  group('shouldAcceptLiveLocationFix', () {
    test('primeiro fix sempre aceita', () {
      expect(
        shouldAcceptLiveLocationFix(
          lastAcceptedAccuracyM: null,
          nextAccuracyM: 80,
        ),
        isTrue,
      );
    });

    test('aceita fix dentro do limiar de 25m', () {
      expect(
        shouldAcceptLiveLocationFix(
          lastAcceptedAccuracyM: 10,
          nextAccuracyM: 25,
        ),
        isTrue,
      );
    });

    test('rejeita fix claramente pior que o último aceito', () {
      expect(
        shouldAcceptLiveLocationFix(
          lastAcceptedAccuracyM: 12,
          nextAccuracyM: 40,
        ),
        isFalse,
      );
    });

    test('aceita fix acima do limiar se melhorou a precisão', () {
      expect(
        shouldAcceptLiveLocationFix(
          lastAcceptedAccuracyM: 35,
          nextAccuracyM: 30,
        ),
        isTrue,
      );
    });

    test('aceita fix com mesma precisão do último aceito', () {
      expect(
        shouldAcceptLiveLocationFix(
          lastAcceptedAccuracyM: 35,
          nextAccuracyM: 35,
        ),
        isTrue,
      );
    });
  });
}
