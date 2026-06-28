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

    test('100% fechado zera oportunidade residual', () {
      final fechado = summary.copyWith(closedPercent: 100);

      expect(fechado.residualPercent, 0);
      expect(fechado.totalOpportunityValue, 0);
    });
  });
}
