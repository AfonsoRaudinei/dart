import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/modules/marketing/domain/entities/marketing_case.dart';
import 'package:soloforte_app/modules/marketing/domain/enums/case_tipo.dart';
import 'package:soloforte_app/modules/marketing/domain/enums/plano_marketing.dart';
import 'package:soloforte_app/modules/marketing/presentation/widgets/marketing_case_sheet.dart';

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

      expect(find.text('ROI líquido'), findsOneWidget);
      expect(find.text('R\$ 980,00/ha'), findsOneWidget);
      expect(find.text('9,3 sc/ha'), findsOneWidget);
      expect(find.text('Testemunha'), findsOneWidget);
      expect(find.text('Com produto'), findsOneWidget);
      expect(find.text('Ganho'), findsOneWidget);
      // Bloco de resultado: valor herói acima do rótulo descritivo
      expect(find.text('R\$ 980,00'), findsOneWidget);
      expect(find.text('ROI líquido por hectare'), findsOneWidget);
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
