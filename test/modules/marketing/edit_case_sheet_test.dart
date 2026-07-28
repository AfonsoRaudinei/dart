import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/modules/marketing/domain/entities/marketing_case.dart';
import 'package:soloforte_app/modules/marketing/domain/entities/parametro_comparativo.dart';
import 'package:soloforte_app/modules/marketing/domain/entities/roi_bloco.dart';
import 'package:soloforte_app/modules/marketing/domain/enums/case_tipo.dart';
import 'package:soloforte_app/modules/marketing/domain/enums/plano_marketing.dart';
import 'package:soloforte_app/modules/marketing/presentation/widgets/edit_case_sheet.dart';

void main() {
  group('EditCaseSheet', () {
    testWidgets('sanitiza campos incompatíveis ao trocar tipo para avaliação', (
      tester,
    ) async {
      MarketingCase? savedCase;

      await tester.pumpWidget(
        _wrap(
          EditCaseSheet(
            caso: _caseResultadoCompleto(),
            onClose: () {},
            onSalvar: (updatedCase) async {
              savedCase = updatedCase;
            },
          ),
        ),
      );

      await tester.tap(find.text('Avaliação'));
      await tester.pumpAndSettle();

      await tester.enterText(find.widgetWithText(TextFormField, 'Nome do talhão'), 'Talhão 7');
      await tester.ensureVisible(find.text('Salvar'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Salvar'));
      await tester.pumpAndSettle();

      expect(savedCase, isNotNull);
      expect(savedCase!.tipo, CaseTipo.avaliacao);
      expect(savedCase!.nomeTalhao, 'Talhão 7');
      expect(savedCase!.fotoPrincipalUrl, isNull);
      expect(savedCase!.prodSemProduto, isNull);
      expect(savedCase!.prodComProduto, isNull);
      expect(savedCase!.custoProdutoPorHa, isNull);
      expect(savedCase!.valorGrao, isNull);
      expect(savedCase!.roi, isNull);
      expect(savedCase!.fotoAntesUrl, isNull);
      expect(savedCase!.fotoDepoisUrl, isNull);
      expect(savedCase!.parametros, isEmpty);
    });

    testWidgets('mantém loading até o save terminar e mostra erro em falha', (
      tester,
    ) async {
      final completer = Completer<void>();

      await tester.pumpWidget(
        _wrap(
          EditCaseSheet(
            caso: _caseResultadoCompleto(),
            onClose: () {},
            onSalvar: (_) => completer.future,
          ),
        ),
      );

      await tester.ensureVisible(find.text('Salvar'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Salvar'));
      await tester.pump();

      expect(find.text('Salvando...'), findsOneWidget);

      completer.completeError(Exception('falha'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(
        find.text('Não foi possível salvar as alterações. Tente novamente.'),
        findsOneWidget,
      );
      expect(find.text('Salvar'), findsOneWidget);
    });
  });
}

Widget _wrap(Widget child) {
  return MaterialApp(
    home: Scaffold(body: child),
  );
}

MarketingCase _caseResultadoCompleto() {
  final now = DateTime.utc(2026, 7, 28, 12);
  return MarketingCase(
    id: 'case-resultado',
    tipo: CaseTipo.resultado,
    visibilidade: PlanoMarketing.ouro,
    lat: -12.345,
    lng: -47.89,
    localizacaoTexto: 'Fazenda Central',
    produtorFazenda: 'Produtor A',
    produtoUtilizado: 'Produto X',
    dataCase: now,
    produtividadeValor: 65,
    fotoPrincipalUrl: 'https://example.com/resultado.jpg',
    prodSemProduto: 60,
    prodComProduto: 68,
    unidadeProdutividade: 'sc/ha',
    custoProdutoPorHa: 95,
    valorGrao: 120,
    parametrosJson: jsonEncode([
      const ParametroComparativo(
        id: 'param-1',
        titulo: 'Número de grãos',
        testemunha: 10,
        teste: 12,
      ).toJson(),
    ]),
    roi: const RoiBloco(investimento: 100, retorno: 200, roiCalculado: 100),
    criadoEm: now,
    atualizadoEm: now,
  );
}
