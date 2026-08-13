import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/modules/marketing/domain/entities/marketing_case.dart';
import 'package:soloforte_app/modules/marketing/domain/entities/parametro_comparativo.dart';
import 'package:soloforte_app/modules/marketing/domain/entities/roi_bloco.dart';
import 'package:soloforte_app/modules/marketing/domain/enums/case_tipo.dart';
import 'package:soloforte_app/modules/marketing/domain/enums/plano_marketing.dart';
import 'package:soloforte_app/modules/marketing/domain/enums/produtividade_unidade.dart';
import 'package:soloforte_app/modules/marketing/presentation/widgets/edit_case_sheet.dart';

void main() {
  group('EditCaseSheet', () {
    testWidgets('não permite trocar tipo e sanitiza campos de avaliação', (
      tester,
    ) async {
      MarketingCase? savedCase;

      await tester.pumpWidget(
        _wrap(
          EditCaseSheet(
            caso: _caseAvaliacao(),
            onClose: () {},
            onSalvar: (updatedCase) async {
              savedCase = updatedCase;
            },
          ),
        ),
      );

      expect(find.text('Resultado'), findsNothing);
      expect(find.text('Antes/\nDepois'), findsNothing);
      expect(find.text('Avaliação'), findsWidgets);

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Produção ideal'),
        '72,5',
      );
      await tester.ensureVisible(find.text('Salvar'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Salvar'));
      await tester.pumpAndSettle();

      expect(savedCase, isNotNull);
      expect(savedCase!.tipo, CaseTipo.avaliacao);
      expect(savedCase!.produtividadeValor, 72.5);
      expect(savedCase!.produtividadeUnidade, ProdutividadeUnidade.scHa);
      expect(savedCase!.fotoPrincipalUrl, isNull);
      expect(savedCase!.fotoAntesUrl, isNull);
      expect(savedCase!.fotoDepoisUrl, isNull);
      expect(savedCase!.parametros, isEmpty);
    });

    testWidgets('mantém tipo resultado fixo ao salvar edição', (
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

      expect(find.text('Resultado'), findsWidgets);
      expect(find.text('Antes/\nDepois'), findsNothing);

      await tester.scrollUntilVisible(
        find.text('Salvar'),
        500,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Salvar'));
      await tester.pumpAndSettle();

      expect(savedCase, isNotNull);
      expect(savedCase!.tipo, CaseTipo.resultado);
      expect(savedCase!.produtorFazenda, 'Produtor A');
      expect(savedCase!.fotoPrincipalUrl, 'https://example.com/resultado.jpg');
      expect(savedCase!.prodSemProduto, 60);
      expect(savedCase!.prodComProduto, 68);
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
    home: MediaQuery(
      data: const MediaQueryData(size: Size(800, 1400)),
      child: Scaffold(body: child),
    ),
  );
}

MarketingCase _caseAvaliacao() {
  final now = DateTime.utc(2026, 9, 9, 12);
  return MarketingCase(
    id: 'case-avaliacao',
    tipo: CaseTipo.avaliacao,
    visibilidade: PlanoMarketing.ouro,
    lat: -12.345,
    lng: -47.89,
    localizacaoTexto: 'São domingos',
    produtorFazenda: 'Afonso',
    produtoUtilizado: 'coach',
    dataCase: now,
    nomeVendedor: 'RAUDINEI',
    telefoneVendedor: '63992418349',
    nomeTalhao: 'São domingos',
    tamanhoHa: 100,
    criadoEm: now,
    atualizadoEm: now,
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
