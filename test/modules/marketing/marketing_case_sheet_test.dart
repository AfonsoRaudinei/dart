import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/core/contracts/i_marketing_case_reports_lookup.dart';
import 'package:soloforte_app/core/contracts/i_marketing_case_reports_lookup_provider.dart';
import 'package:soloforte_app/core/contracts/i_occurrence_access_reader_provider.dart';
import 'package:soloforte_app/core/contracts/marketing_case_report_snapshot.dart';
import 'package:soloforte_app/core/session/user_role.dart';
import 'package:soloforte_app/modules/marketing/data/repositories/i_marketing_case_repository.dart';
import 'package:soloforte_app/modules/marketing/data/services/marketing_sync_service.dart';
import 'package:soloforte_app/modules/marketing/presentation/providers/marketing_providers.dart';
import 'package:soloforte_app/modules/settings/presentation/providers/user_profile_provider.dart';
import 'package:soloforte_app/core/ui/sheets/sheet_tokens.dart';
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
        _wrapSheet(marketingCase: marketingCase, themeId: null),
      );
      await tester.pumpAndSettle();

      final sheet = tester.widget<DraggableScrollableSheet>(
        find.byType(DraggableScrollableSheet),
      );
      expect(sheet.expand, isFalse);

      expect(find.text('ROI líquido'), findsOneWidget);
      expect(find.text('R\$ 980,00/ha'), findsOneWidget);
      expect(find.text('9,3 sc/ha'), findsOneWidget);
      expect(find.text('Testemunha (sem produto)'), findsOneWidget);
      expect(find.text('Com coach'), findsOneWidget);
      expect(find.text('Ganho'), findsOneWidget);
      expect(find.text('ROI/ha'), findsOneWidget);
    });

    testWidgets('Antes/Depois exibe a conclusão técnica após os blocos', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrapSheet(
          marketingCase: _antesDepoisCase(
            conclusaoTecnica: 'Produto elevou o vigor da raiz.',
          ),
          themeId: null,
        ),
      );
      await tester.pumpAndSettle();

      final scrollable = find.byType(Scrollable).first;
      await tester.scrollUntilVisible(
        find.text('CONCLUSÃO TÉCNICA'),
        120,
        scrollable: scrollable,
      );

      expect(find.text('CONCLUSÃO TÉCNICA'), findsOneWidget);
      expect(find.text('Produto elevou o vigor da raiz.'), findsOneWidget);
      expect(find.text('Comparação 1'), findsOneWidget);
    });

    testWidgets('Antes/Depois sem conclusão técnica não mostra o card', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrapSheet(marketingCase: _antesDepoisCase(), themeId: null),
      );
      await tester.pumpAndSettle();

      expect(find.text('CONCLUSÃO TÉCNICA'), findsNothing);
    });

    testWidgets(
      'Avaliação mostra as fotos dos blocos e a conclusão uma única vez',
      (tester) async {
        await tester.pumpWidget(
          _wrapSheet(
            marketingCase: _antesDepoisCase(
              tipo: CaseTipo.avaliacao,
              conclusaoTecnica: 'Conclusão da avaliação.',
            ),
            themeId: null,
          ),
        );
        await tester.pumpAndSettle();

        final scrollable = find.byType(Scrollable).first;
        await tester.scrollUntilVisible(
          find.text('CONCLUSÃO TÉCNICA'),
          120,
          scrollable: scrollable,
        );

        expect(find.byType(PageView), findsOneWidget);
        expect(find.text('CONCLUSÃO TÉCNICA'), findsOneWidget);
        expect(find.text('Conclusão da avaliação.'), findsOneWidget);
      },
    );

    group('carrossel de fotos por comparação', () {
      // Largura do pontinho (18 ativo / 8 inativo) + margem horizontal 3+3.
      const larguraAtivo = 24.0;
      const larguraInativo = 14.0;

      Finder pontinhos() => find.byWidgetPredicate(
        (w) =>
            w.key is ValueKey &&
            '${(w.key as ValueKey).value}'.startsWith('foto-pontinho-'),
      );

      double larguraPontinho(WidgetTester tester, int i, {int bloco = 0}) =>
          tester
              .getSize(find.byKey(ValueKey('foto-pontinho-$i')).at(bloco))
              .width;

      Future<void> abrir(WidgetTester tester, MarketingCase c) async {
        await tester.pumpWidget(_wrapSheet(marketingCase: c, themeId: null));
        await tester.pumpAndSettle();
        await tester.scrollUntilVisible(
          find.byType(PageView).first,
          120,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();
      }

      testWidgets('3 fotos: PageView com 3 páginas, 3 pontinhos e rótulos', (
        tester,
      ) async {
        final semantics = tester.ensureSemantics();
        await abrir(tester, _antesDepoisCase());

        final pageView = tester.widget<PageView>(find.byType(PageView));
        expect(pageView.childrenDelegate.estimatedChildCount, 3);
        expect(pageView.scrollDirection, Axis.horizontal);
        expect(pontinhos(), findsNWidgets(3));
        expect(find.text('Antes'), findsOneWidget);
        expect(find.bySemanticsLabel('Foto 1 de 3'), findsOneWidget);
        expect(
          larguraPontinho(tester, 0),
          greaterThan(larguraPontinho(tester, 1)),
        );

        // A borda da próxima foto fica à vista (viewportFraction < 1).
        expect(find.text('Depois'), findsOneWidget);
        semantics.dispose();
      });

      testWidgets('deslizar troca a página e o pontinho ativo', (tester) async {
        final semantics = tester.ensureSemantics();
        await abrir(tester, _antesDepoisCase());

        await tester.drag(find.byType(PageView), const Offset(-400, 0));
        await tester.pumpAndSettle();

        expect(find.bySemanticsLabel('Foto 2 de 3'), findsOneWidget);
        expect(
          larguraPontinho(tester, 1),
          greaterThan(larguraPontinho(tester, 0)),
        );
        expect(
          larguraPontinho(tester, 1),
          greaterThan(larguraPontinho(tester, 2)),
        );

        await tester.drag(find.byType(PageView), const Offset(-400, 0));
        await tester.pumpAndSettle();
        expect(find.bySemanticsLabel('Foto 3 de 3'), findsOneWidget);
        expect(find.text('Concorrente'), findsOneWidget);
        semantics.dispose();
      });

      testWidgets('1 foto: sem carrossel e sem pontinhos', (tester) async {
        await tester.pumpWidget(
          _wrapSheet(
            marketingCase: _antesDepoisCase(
              blocos: [
                _bloco(
                  'av-1',
                  'Comparação 1',
                  fotos: ['https://example.com/a.jpg'],
                ),
              ],
            ),
            themeId: null,
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(PageView), findsNothing);
        expect(pontinhos(), findsNothing);
        expect(find.byType(CachedNetworkImage), findsOneWidget);
        expect(find.text('Antes'), findsOneWidget);
      });

      testWidgets('dois blocos têm carrosséis independentes', (tester) async {
        final semantics = tester.ensureSemantics();
        await abrir(
          tester,
          _antesDepoisCase(
            blocos: [
              _bloco(
                'av-1',
                'Comparação 1',
                fotos: [
                  'https://example.com/a.jpg',
                  'https://example.com/b.jpg',
                ],
              ),
              _bloco(
                'av-2',
                'Comparação 2',
                fotos: [
                  'https://example.com/c.jpg',
                  'https://example.com/d.jpg',
                  'https://example.com/e.jpg',
                ],
              ),
            ],
          ),
        );
        expect(find.byType(PageView), findsNWidgets(2));

        await tester.drag(find.byType(PageView).first, const Offset(-400, 0));
        await tester.pumpAndSettle();

        expect(larguraPontinho(tester, 1, bloco: 0), larguraAtivo);
        expect(larguraPontinho(tester, 0, bloco: 1), larguraAtivo);
        expect(larguraPontinho(tester, 0, bloco: 0), larguraInativo);
        expect(find.bySemanticsLabel('Foto 2 de 2'), findsOneWidget);
        expect(find.bySemanticsLabel('Foto 1 de 3'), findsOneWidget);
        semantics.dispose();
      });

      testWidgets('fonte ampliada (2.0x) não estoura o carrossel com rótulos', (
        tester,
      ) async {
        await tester.pumpWidget(
          _wrapSheet(
            marketingCase: _antesDepoisCase(),
            themeId: null,
            textScale: 2.0,
          ),
        );
        await tester.pumpAndSettle();
        await tester.scrollUntilVisible(
          find.byType(PageView).first,
          120,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text('Antes'), findsOneWidget);
        final rotulo = tester.getRect(find.text('Antes'));
        final pagina = tester.getRect(find.byType(PageView));
        expect(rotulo.bottom, lessThanOrEqualTo(pagina.bottom));
      });

      testWidgets('fonte ampliada (2.0x) com rótulos vazios não estoura', (
        tester,
      ) async {
        await tester.pumpWidget(
          _wrapSheet(
            marketingCase: _antesDepoisCase(
              blocos: [
                _bloco(
                  'av-1',
                  'Comparação 1',
                  rotulos: ['', '', ''],
                  fotos: [
                    'https://example.com/a.jpg',
                    'https://example.com/b.jpg',
                    'https://example.com/c.jpg',
                  ],
                ),
              ],
            ),
            themeId: null,
            textScale: 2.0,
          ),
        );
        await tester.pumpAndSettle();
        await tester.scrollUntilVisible(
          find.byType(PageView).first,
          120,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.byType(PageView), findsOneWidget);
      });

      testWidgets('tipo avaliação legado também usa o carrossel', (
        tester,
      ) async {
        await abrir(tester, _antesDepoisCase(tipo: CaseTipo.avaliacao));

        expect(find.byType(PageView), findsOneWidget);
        expect(pontinhos(), findsNWidgets(3));
      });

      testWidgets('conclusão técnica aparece uma única vez com carrossel', (
        tester,
      ) async {
        await tester.pumpWidget(
          _wrapSheet(
            marketingCase: _antesDepoisCase(conclusaoTecnica: 'Vigor maior.'),
            themeId: null,
          ),
        );
        await tester.pumpAndSettle();
        await tester.scrollUntilVisible(
          find.text('CONCLUSÃO TÉCNICA'),
          120,
          scrollable: find.byType(Scrollable).first,
        );

        expect(find.byType(PageView), findsOneWidget);
        expect(find.text('CONCLUSÃO TÉCNICA'), findsOneWidget);
        expect(find.text('Vigor maior.'), findsOneWidget);
      });
    });

    testWidgets('perfil azul: ações de relatório e hero sem verde escuro', (
      tester,
    ) async {
      final marketingCase = _resultadoCase();

      await tester.pumpWidget(
        _wrapSheet(marketingCase: marketingCase, themeId: 'blue'),
      );
      await tester.pumpAndSettle();

      final scrollable = find.byType(Scrollable).first;
      await tester.scrollUntilVisible(
        find.text('Abrir relatório'),
        120,
        scrollable: scrollable,
      );
      await tester.scrollUntilVisible(
        find.text('Exportar HTML'),
        120,
        scrollable: scrollable,
      );

      expect(find.text('Abrir relatório'), findsOneWidget);
      expect(find.text('Exportar HTML'), findsOneWidget);

      expect(
        find.byWidgetPredicate(
          (w) =>
              w is DecoratedBox &&
              w.decoration is BoxDecoration &&
              (w.decoration as BoxDecoration).color == const Color(0xFF123D2A),
        ),
        findsNothing,
      );

      final roiValue = tester.widget<Text>(find.text('R\$ 980,00/ha'));
      expect(roiValue.style?.color, SoloForteSheetSkinIos.iconStroke);
      expect(roiValue.style?.color, isNot(PremiumTokens.brandGreen));
    });

    group('fotos do Resultado (ADR-065)', () {
      const urls = [
        'https://cdn.test/resultado-1.jpg',
        'https://cdn.test/resultado-2.jpg',
        'https://cdn.test/resultado-3.jpg',
      ];

      Finder pontinhos() => find.byWidgetPredicate(
        (w) =>
            w.key is ValueKey &&
            '${(w.key as ValueKey).value}'.startsWith('foto-pontinho-'),
      );

      Future<void> abrir(WidgetTester tester, MarketingCase c) async {
        await tester.pumpWidget(_wrapSheet(marketingCase: c, themeId: null));
        await tester.pumpAndSettle();
      }

      testWidgets('>= 2 fotos: PageView com pontinhos', (tester) async {
        await abrir(
          tester,
          _resultadoCase().copyWith(
            fotoPrincipalUrl: urls.first,
            fotosResultado: urls,
          ),
        );

        expect(find.byType(PageView), findsOneWidget);
        expect(pontinhos(), findsNWidgets(3));
        final pageView = tester.widget<PageView>(find.byType(PageView));
        expect(pageView.childrenDelegate.estimatedChildCount, 3);
      });

      testWidgets('1 foto na lista: sem PageView e sem pontinhos', (
        tester,
      ) async {
        await abrir(
          tester,
          _resultadoCase().copyWith(
            fotoPrincipalUrl: urls.first,
            fotosResultado: [urls.first],
          ),
        );

        expect(find.byType(PageView), findsNothing);
        expect(pontinhos(), findsNothing);
        expect(find.byType(CachedNetworkImage), findsOneWidget);
      });

      testWidgets('legado só com fotoPrincipalUrl exibe 1 foto', (
        tester,
      ) async {
        await abrir(
          tester,
          _resultadoCase().copyWith(fotoPrincipalUrl: urls.first),
        );

        expect(find.byType(PageView), findsNothing);
        expect(pontinhos(), findsNothing);
        expect(find.byType(CachedNetworkImage), findsOneWidget);
      });

      testWidgets('sem foto: nada de imagem do Resultado', (tester) async {
        await abrir(tester, _resultadoCase());

        expect(find.byType(PageView), findsNothing);
        expect(find.byType(CachedNetworkImage), findsNothing);
      });
    });
  });
}

Widget _wrapSheet({
  required MarketingCase marketingCase,
  required String? themeId,
  double textScale = 1.0,
}) {
  final extensions = themeId == null
      ? const <ThemeExtension<dynamic>>[]
      : <ThemeExtension<dynamic>>[SoloForteThemeExtension(themeId: themeId)];

  return ProviderScope(
    overrides: [
      marketingCaseReportsLookupProvider.overrideWithValue(
        _FakeMarketingLookup(),
      ),
      marketingCaseRepositoryProvider.overrideWithValue(_NoopMarketingRepo()),
      marketingCasesProvider.overrideWith((ref) {
        final repo = ref.watch(marketingCaseRepositoryProvider);
        final sync = ref.watch(marketingSyncServiceProvider);
        return _EmptyCasesNotifier(repo, sync);
      }),
      authorizedClientIdsProvider.overrideWith((ref) async => const <String>{}),
      currentUserRoleProvider.overrideWith((ref) => UserRole.consultor),
    ],
    child: MaterialApp(
      theme: ThemeData(extensions: extensions),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
      home: Scaffold(body: MarketingCaseSheet(marketingCase: marketingCase)),
    ),
  );
}

Map<String, dynamic> _bloco(
  String id,
  String titulo, {
  List<String> fotos = const [],
  List<String> rotulos = const ['Antes', 'Depois', 'Concorrente'],
}) => {
  'id': id,
  'titulo': titulo,
  'nome_lado_a': rotulos[0],
  'nome_lado_b': rotulos[1],
  'nome_lado_c': rotulos[2],
  for (var i = 0; i < fotos.length; i++) 'foto_lado_${'abc'[i]}_path': fotos[i],
};

MarketingCase _antesDepoisCase({
  CaseTipo tipo = CaseTipo.antesDepois,
  String? conclusaoTecnica,
  List<Map<String, dynamic>>? blocos,
}) {
  final now = DateTime.utc(2026, 8, 7);
  return MarketingCase(
    id: 'case-sheet-ad',
    tipo: tipo,
    visibilidade: PlanoMarketing.prata,
    lat: -10,
    lng: -48,
    localizacaoTexto: 'Palmas Tocantins',
    produtorFazenda: 'Miguel',
    produtoUtilizado: 'coach',
    dataCase: now,
    nomeTalhao: tipo == CaseTipo.avaliacao ? 'Talhão 1' : null,
    avaliacoesJson: jsonEncode(
      blocos ??
          [
            _bloco(
              'av-1',
              'Comparação 1',
              fotos: [
                'https://example.com/a.jpg',
                'https://example.com/b.jpg',
                'https://example.com/c.jpg',
              ],
            ),
          ],
    ),
    conclusaoTecnica: conclusaoTecnica,
    criadoEm: now,
    atualizadoEm: now,
  );
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

class _FakeMarketingLookup implements IMarketingCaseReportsLookup {
  @override
  Future<MarketingCaseReportExportBundle> buildExportBundle(
    String caseId, {
    required String? fallbackConsultantName,
    required String fallbackConsultantRole,
    String? reportBrandName,
    String? reportLogoPath,
    String? consultantName,
    String? consultantRole,
    bool asFragment = false,
  }) async {
    return const MarketingCaseReportExportBundle(
      title: 'Marketing test',
      fileBaseName: 'marketing_test',
      html: '<html></html>',
      json: {},
      csv: '',
    );
  }

  @override
  Future<void> deleteCase(String id) async {}

  @override
  Future<bool> publishDraftCase(BuildContext context, String caseId) async =>
      false;

  @override
  Future<void> showEditSheet(BuildContext context, String caseId) async {}
}

class _EmptyCasesNotifier extends MarketingCasesNotifier {
  _EmptyCasesNotifier(
    IMarketingCaseRepository repository,
    MarketingSyncService syncService,
  ) : super(repository, syncService, null) {
    state = const AsyncData([]);
  }

  @override
  Future<void> load({bool forceSync = false}) async {}
}

class _NoopMarketingRepo implements IMarketingCaseRepository {
  @override
  Future<List<MarketingCase>> fetchMarketingCases() async => const [];

  @override
  Future<List<MarketingCase>> getLocalCases() async => const [];

  @override
  Future<void> saveToCache(List<MarketingCase> cases) async {}

  @override
  Future<void> saveSingleToCache(MarketingCase marketingCase) async {}

  @override
  Future<MarketingCase> saveCase(MarketingCase marketingCase) async =>
      marketingCase;

  @override
  Future<MarketingCase> saveAsDraft(MarketingCase marketingCase) async =>
      marketingCase;

  @override
  Future<MarketingCase> getById(String id) async => throw UnimplementedError();

  @override
  Future<void> updateCase(MarketingCase marketingCase) async {}

  @override
  Future<MarketingCase> softDelete(String id) async =>
      throw UnimplementedError();
}
