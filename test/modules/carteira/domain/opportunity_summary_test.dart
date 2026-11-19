import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/core/contracts/opportunity_summary.dart';

void main() {
  group('OpportunitySummary', () {
    const summary = OpportunitySummary(
      clientId: 'c1',
      categoryId: 'cat1',
      categoryName: 'Herbicida',
      categoryColor: 0xFF00AA00,
      referenceValuePerHa: 1000,
      closedPercent: 40,
      areaHa: 500,
      unit: 'R\$/ha',
    );

    test('getters calculados derivam closedPercent e areaHa', () {
      expect(summary.closedValuePerHa, 400);
      expect(summary.residualValuePerHa, 600);
      expect(summary.residualPercent, 60);
      expect(summary.totalOpportunityValue, 300000);
    });

    test('0% fechado mantém oportunidade integral sem meta', () {
      final aberto = summary.copyWith(closedPercent: 0);

      expect(aberto.residualPercent, 100);
      expect(aberto.totalOpportunityValue, 500000);
    });

    test('100% fechado zera oportunidade residual', () {
      final fechado = summary.copyWith(closedPercent: 100);

      expect(fechado.residualPercent, 0);
      expect(fechado.totalOpportunityValue, 0);
    });

    test('categoria fora de R\$/ha não vira reais multiplicando pela área', () {
      const sacas = OpportunitySummary(
        clientId: 'c1',
        categoryId: 'cat-milho',
        categoryName: 'Semente de milho',
        categoryColor: 0xFF00FF00,
        referenceValuePerHa: 600,
        closedPercent: 0,
        areaHa: 2558,
        unit: 'Sacas 60k',
        monetaryPerHa: false,
      );

      expect(sacas.totalOpportunityValue, 0);
      expect(sacas.residualPercent, 100);
    });
  });
}
