import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/core/domain/soy_phenology.dart';

void main() {
  group('soyCalendarAgeDays', () {
    final today = DateTime(2026, 3, 21);

    test('data ausente ou futura não conta', () {
      expect(soyCalendarAgeDays(null, today), isNull);
      expect(soyCalendarAgeDays(DateTime(2026, 3, 22), today), isNull);
    });

    test('mesmo dia é zero e vinte dias depois é vinte', () {
      expect(soyCalendarAgeDays(DateTime(2026, 3, 21, 18), today), 0);
      expect(soyCalendarAgeDays(DateTime(2026, 3, 1), today), 20);
    });
  });

  group('suggestedEstadioForDae', () {
    test('escolhe o maior dap menor ou igual ao DAE', () {
      expect(suggestedEstadioForDae(dae: 0)?.code, 'VE');
      expect(suggestedEstadioForDae(dae: 20, cultura: 'Soja')?.code, 'V4');
      expect(suggestedEstadioForDae(dae: 25)?.code, 'V5');
      expect(suggestedEstadioForDae(dae: 100)?.code, 'R5.1');
    });

    test('cultura que não é soja não sugere estádio', () {
      expect(suggestedEstadioForDae(dae: 20, cultura: 'Milho'), isNull);
      expect(suggestedEstadioForDae(dae: null), isNull);
      expect(suggestedEstadioForDae(dae: -1), isNull);
    });
  });

  group('approximateSoyHarvestDate', () {
    test('soma o ciclo à emergência', () {
      final harvest = approximateSoyHarvestDate(
        dataEmergenciaIso: '2026-01-10',
        dataPlantioIso: '2026-01-01',
        cicloDias: 120,
      );
      expect(harvest, DateTime(2026, 5, 10));
    });

    test('sem emergência usa a data de plantio', () {
      final harvest = approximateSoyHarvestDate(
        dataEmergenciaIso: null,
        dataPlantioIso: '2026-01-01',
        cicloDias: 10,
      );
      expect(harvest, DateTime(2026, 1, 11));
    });

    test('sem ciclo ou sem data não inventa colheita', () {
      expect(
        approximateSoyHarvestDate(
          dataEmergenciaIso: '2026-01-10',
          dataPlantioIso: '2026-01-01',
          cicloDias: null,
        ),
        isNull,
      );
      expect(
        approximateSoyHarvestDate(
          dataEmergenciaIso: '2026-01-10',
          dataPlantioIso: '2026-01-01',
          cicloDias: -1,
        ),
        isNull,
      );
      expect(
        approximateSoyHarvestDate(
          dataEmergenciaIso: null,
          dataPlantioIso: null,
          cicloDias: 110,
        ),
        isNull,
      );
    });
  });
}
