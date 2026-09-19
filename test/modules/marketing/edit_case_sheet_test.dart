import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/core/contracts/i_client_lookup.dart';
import 'package:soloforte_app/core/contracts/i_client_lookup_provider.dart';
import 'package:soloforte_app/modules/marketing/domain/entities/marketing_case.dart';
import 'package:soloforte_app/modules/marketing/domain/entities/parametro_comparativo.dart';
import 'package:soloforte_app/modules/marketing/domain/entities/roi_bloco.dart';
import 'package:soloforte_app/modules/marketing/domain/enums/case_tipo.dart';
import 'package:soloforte_app/modules/marketing/domain/enums/plano_marketing.dart';
import 'package:soloforte_app/modules/marketing/domain/enums/produtividade_unidade.dart';
import 'package:soloforte_app/modules/marketing/presentation/widgets/edit_case_sheet.dart';
import 'package:soloforte_app/modules/marketing/presentation/widgets/foto_picker_widget.dart';

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

    testWidgets('exibe seção de foto principal para case tipo resultado', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          EditCaseSheet(
            caso: _caseResultadoCompleto(),
            onClose: () {},
            onSalvar: (_) async {},
          ),
        ),
      );
      await tester.pump();

      await tester.scrollUntilVisible(
        find.text('FOTO PRINCIPAL'),
        500,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pump();

      expect(find.text('FOTO PRINCIPAL'), findsOneWidget);
      expect(find.byType(FotoPickerWidget), findsOneWidget);
      expect(find.text('Trocar'), findsOneWidget);
    });

    testWidgets('propaga nova URL de foto ao salvar case resultado', (
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

      await tester.scrollUntilVisible(
        find.byType(FotoPickerWidget),
        500,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pump();

      final picker = tester.widget<FotoPickerWidget>(
        find.byType(FotoPickerWidget),
      );
      picker.onChanged('https://example.com/nova-foto.jpg');
      await tester.pump();

      await tester.scrollUntilVisible(
        find.text('Salvar'),
        500,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pump();
      await tester.tap(find.text('Salvar'));
      await tester.pump();

      expect(savedCase, isNotNull);
      expect(savedCase!.fotoPrincipalUrl, 'https://example.com/nova-foto.jpg');
    });

    testWidgets('exibe dois pickers de foto para case antes/depois', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          EditCaseSheet(
            caso: _caseAntesDepois(),
            onClose: () {},
            onSalvar: (_) async {},
          ),
        ),
      );

      await tester.scrollUntilVisible(
        find.text('FOTOS'),
        500,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pump();

      expect(find.text('FOTOS'), findsOneWidget);
      expect(find.byType(FotoPickerWidget), findsNWidgets(2));
      expect(find.text('Antes'), findsOneWidget);
      expect(find.text('Depois'), findsOneWidget);
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
      await tester.pump();
      await tester.tap(find.text('Salvar'));
      await tester.pump();

      expect(savedCase, isNotNull);
      expect(savedCase!.tipo, CaseTipo.resultado);
      expect(savedCase!.produtorFazenda, 'Produtor A');
      expect(savedCase!.fotoPrincipalUrl, 'https://example.com/resultado.jpg');
      expect(savedCase!.prodSemProduto, 60);
      expect(savedCase!.prodComProduto, 68);
    });

    testWidgets('bloqueia salvar resultado sem foto principal', (
      tester,
    ) async {
      var saveCalled = false;

      await tester.pumpWidget(
        _wrap(
          EditCaseSheet(
            caso: _caseResultadoCompleto(),
            onClose: () {},
            onSalvar: (_) async {
              saveCalled = true;
            },
          ),
        ),
      );

      await tester.scrollUntilVisible(
        find.byType(FotoPickerWidget),
        500,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pump();

      final picker = tester.widget<FotoPickerWidget>(
        find.byType(FotoPickerWidget),
      );
      picker.onChanged(null);
      await tester.pump();

      await tester.scrollUntilVisible(
        find.text('Salvar'),
        500,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pump();
      await tester.tap(find.text('Salvar'));
      await tester.pump();

      expect(saveCalled, isFalse);
      expect(
        find.text('Foto principal obrigatória para o tipo Resultado.'),
        findsOneWidget,
      );
    });

    testWidgets('bloqueia salvar antes/depois sem ambas as fotos', (
      tester,
    ) async {
      var saveCalled = false;

      await tester.pumpWidget(
        _wrap(
          EditCaseSheet(
            caso: _caseAntesDepois(),
            onClose: () {},
            onSalvar: (_) async {
              saveCalled = true;
            },
          ),
        ),
      );

      await tester.scrollUntilVisible(
        find.byType(FotoPickerWidget).first,
        500,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pump();

      final pickers = tester.widgetList<FotoPickerWidget>(
        find.byType(FotoPickerWidget),
      );
      pickers.first.onChanged(null);
      await tester.pump();

      await tester.scrollUntilVisible(
        find.text('Salvar'),
        500,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pump();
      await tester.tap(find.text('Salvar'));
      await tester.pump();

      expect(saveCalled, isFalse);
      expect(find.text('Adicione as fotos Antes e Depois.'), findsOneWidget);
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

      await tester.scrollUntilVisible(
        find.text('Salvar'),
        500,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pump();
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
  return ProviderScope(
    overrides: [
      clientLookupProvider.overrideWithValue(_FakeClientLookup()),
    ],
    child: MaterialApp(
      home: MediaQuery(
        data: const MediaQueryData(size: Size(800, 1400)),
        child: Scaffold(body: child),
      ),
    ),
  );
}

class _FakeClientLookup implements IClientLookup {
  @override
  Future<ClientSummary?> findById(String id) async {
    return (await listAtivos()).where((c) => c.id == id).firstOrNull;
  }

  @override
  Future<List<ClientSummary>> listAtivos() async => const [
    ClientSummary(id: 'client-1', name: 'Cliente Teste', active: true),
  ];
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

MarketingCase _caseAntesDepois() {
  final now = DateTime.utc(2026, 8, 15, 12);
  return MarketingCase(
    id: 'case-antes-depois',
    tipo: CaseTipo.antesDepois,
    visibilidade: PlanoMarketing.ouro,
    lat: -12.345,
    lng: -47.89,
    localizacaoTexto: 'Fazenda Sul',
    produtorFazenda: 'Produtor B',
    produtoUtilizado: 'Produto Y',
    dataCase: now,
    fotoAntesUrl: 'https://example.com/antes.jpg',
    fotoDepoisUrl: 'https://example.com/depois.jpg',
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
