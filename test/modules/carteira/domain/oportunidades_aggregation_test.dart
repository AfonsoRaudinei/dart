import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/core/contracts/opportunity_summary.dart';
import 'package:soloforte_app/modules/carteira/domain/oportunidades_aggregation.dart';

OpportunitySummary _op({
  required String categoryId,
  required String categoryName,
  required int color,
  required double reference,
  required double closedPercent,
  required double areaHa,
  String clientId = 'c1',
}) {
  return OpportunitySummary(
    clientId: clientId,
    categoryId: categoryId,
    categoryName: categoryName,
    categoryColor: color,
    referenceValuePerHa: reference,
    closedPercent: closedPercent,
    areaHa: areaHa,
    unit: r'R$/ha',
  );
}

void main() {
  group('oportunidades_aggregation', () {
    test(
      'aggregateByCategory soma totalOpportunityValue sem alterar fórmula',
      () {
        // residual 100% * 1000 * 10 = 10000
        final a = _op(
          categoryId: 'fert',
          categoryName: 'Fertilizante',
          color: 0xFFE53935,
          reference: 1000,
          closedPercent: 0,
          areaHa: 10,
        );
        // residual 50% * 1000 * 10 = 5000
        final b = _op(
          categoryId: 'fert',
          categoryName: 'Fertilizante',
          color: 0xFFE53935,
          reference: 1000,
          closedPercent: 50,
          areaHa: 10,
          clientId: 'c2',
        );
        final c = _op(
          categoryId: 'quim',
          categoryName: 'Químico',
          color: 0xFF43A047,
          reference: 500,
          closedPercent: 0,
          areaHa: 20,
        );

        expect(a.totalOpportunityValue, 10000);
        expect(b.totalOpportunityValue, 5000);
        expect(c.totalOpportunityValue, 10000);

        final slices = aggregateOpportunitiesByCategory([a, b, c]);
        expect(slices, hasLength(2));
        expect(slices.first.id, 'fert');
        expect(slices.first.value, 15000);
        expect(slices.last.id, 'quim');
        expect(slices.last.value, 10000);
        expect(sumOpportunityValues([a, b, c]), 25000);
      },
    );

    test('aggregateByProducer ordena por valor', () {
      final slices = aggregateOpportunitiesByProducer([
        (clientId: 'c1', clientName: 'A', colorArgb: 0xFF000000, total: 100),
        (clientId: 'c2', clientName: 'B', colorArgb: 0xFFFFFFFF, total: 300),
      ]);
      expect(slices.first.label, 'B');
      expect(slices.first.value, 300);
    });
  });
}
