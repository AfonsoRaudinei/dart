import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/modules/marketing/domain/entities/marketing_roi_calculation.dart';

void main() {
  group('MarketingRoiCalculation', () {
    test('calcula ROI agronomico com area total estimada', () {
      const input = MarketingRoiInput(
        prodSemProduto: 60,
        prodComProduto: 64,
        unidadeProdutividade: 'sc/ha',
        custoProdutoPorHa: 90,
        valorGrao: 110,
        areaTotal: 900,
      );

      const roi = MarketingRoiCalculation(input);

      expect(roi.ganhoScHa, 4);
      expect(roi.receitaGanho, 440);
      expect(roi.roiLiquidoRsHa, 350);
      expect(roi.roiEmSacasHa, closeTo(3.182, 0.001));
      expect(roi.roiSacasTotal, closeTo(2863.636, 0.001));
      expect(roi.roiReaisTotal, 315000);
    });

    test('valor do grao zero nao divide por zero', () {
      const input = MarketingRoiInput(
        prodSemProduto: 60,
        prodComProduto: 64,
        unidadeProdutividade: 'sc/ha',
        custoProdutoPorHa: 90,
        valorGrao: 0,
      );

      const roi = MarketingRoiCalculation(input);

      expect(roi.roiEmSacasHa, 0);
    });

    test('ganho negativo e dado valido', () {
      const input = MarketingRoiInput(
        prodSemProduto: 64,
        prodComProduto: 60,
        unidadeProdutividade: 'sc/ha',
        custoProdutoPorHa: 90,
        valorGrao: 110,
      );

      const roi = MarketingRoiCalculation(input);

      expect(roi.ganhoScHa, -4);
      expect(roi.roiLiquidoRsHa, -530);
    });
  });
}
