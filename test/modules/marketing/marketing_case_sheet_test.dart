import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/modules/marketing/domain/entities/marketing_case.dart';
import 'package:soloforte_app/modules/marketing/domain/enums/case_tipo.dart';
import 'package:soloforte_app/modules/marketing/domain/enums/plano_marketing.dart';
import 'package:soloforte_app/modules/marketing/presentation/widgets/marketing_case_sheet.dart';
import 'package:soloforte_app/ui/theme/premium/design_tokens.dart';

void main() {
  group('MarketingCaseSheet', () {
    testWidgets('sheet Resultado: expand false + hero ROI líquido', (
      tester,
    ) async {
      final marketingCase = _resultadoCase();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MarketingCaseSheet(marketingCase: marketingCase),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final sheet = tester.widget<DraggableScrollableSheet>(
        find.byType(DraggableScrollableSheet),
      );
      expect(sheet.expand, isFalse);

      // Bloco de resultado: valor herói acima do rótulo descritivo
      expect(find.text('R\$ 980,00'), findsOneWidget);
      expect(find.text('ROI líquido por hectare'), findsOneWidget);

      // O ROI/ha aparece uma única vez: o detalhamento não repete o herói
      expect(find.text('R\$ 980,00/ha'), findsNothing);
      expect(find.text('ROI líquido'), findsNothing);

      // Detalhamento continua com os dados que o herói não carrega
      expect(find.text('9,3 sc/ha'), findsOneWidget);
      expect(find.text('ROI em sacas'), findsOneWidget);
      expect(find.text('Testemunha'), findsOneWidget);
      expect(find.text('Com produto'), findsOneWidget);
      expect(find.text('Ganho'), findsOneWidget);
    });

    testWidgets('resultado negativo nao sai pintado de verde', (tester) async {
      final now = DateTime.utc(2026, 8, 7);
      final prejuizo = MarketingCase(
        id: 'case-sheet-neg',
        tipo: CaseTipo.resultado,
        visibilidade: PlanoMarketing.prata,
        lat: -10,
        lng: -48,
        localizacaoTexto: 'Palmas Tocantins',
        produtorFazenda: 'Miguel',
        produtoUtilizado: 'coach',
        dataCase: now,
        prodSemProduto: 65,
        prodComProduto: 60,
        unidadeProdutividade: 'sc/ha',
        custoProdutoPorHa: 70,
        valorGrao: 105,
        criadoEm: now,
        atualizadoEm: now,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: MarketingCaseSheet(marketingCase: prejuizo)),
        ),
      );
      await tester.pumpAndSettle();

      final heroi = tester.widget<Text>(find.text('-R\$ 595,00'));
      expect(heroi.style?.color, PremiumTokens.alertError);

      final ganho = tester.widget<Text>(find.text('-5,0 sc/ha'));
      expect(ganho.style?.color, PremiumTokens.alertError);
    });
  });
}

MarketingCase _resultadoCase() {
  final now = DateTime.utc(2026, 8, 7);
  return MarketingCase(
    id: 'case-sheet-1',
    tipo: CaseTipo.resultado,
    visibilidade: PlanoMarketing.prata,
    lat: -10,
    lng: -48,
    localizacaoTexto: 'Palmas Tocantins',
    produtorFazenda: 'Miguel',
    produtoUtilizado: 'coach',
    dataCase: now,
    prodSemProduto: 55,
    prodComProduto: 65,
    unidadeProdutividade: 'sc/ha',
    custoProdutoPorHa: 70,
    valorGrao: 105,
    criadoEm: now,
    atualizadoEm: now,
  );
}
