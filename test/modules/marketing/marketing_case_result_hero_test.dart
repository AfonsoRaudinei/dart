import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/modules/marketing/domain/entities/marketing_case.dart';
import 'package:soloforte_app/modules/marketing/domain/enums/case_tipo.dart';
import 'package:soloforte_app/modules/marketing/domain/enums/plano_marketing.dart';
import 'package:soloforte_app/modules/marketing/presentation/widgets/marketing_case_result_hero.dart';
import 'package:soloforte_app/modules/marketing/presentation/widgets/marketing_media_image.dart';

void main() {
  testWidgets('hero mostra produto e PageView com duas fotos Antes/Depois', (
    tester,
  ) async {
    final now = DateTime.utc(2026, 7, 27);
    final marketingCase = MarketingCase(
      id: 'c1',
      tipo: CaseTipo.antesDepois,
      visibilidade: PlanoMarketing.prata,
      lat: -10,
      lng: -48,
      localizacaoTexto: 'Brejinho de Nazaré',
      produtorFazenda: 'São João',
      produtoUtilizado: 'Coach',
      fotoAntesUrl: 'https://example.com/antes.jpg',
      fotoDepoisUrl: 'https://example.com/depois.jpg',
      ganhoProdutividade: '+13,6 sc',
      criadoEm: now,
      atualizadoEm: now,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: MarketingCaseResultHero(marketingCase: marketingCase),
          ),
        ),
      ),
    );

    expect(find.text('Coach'), findsOneWidget);
    expect(find.text('+13,6 sc'), findsOneWidget);
    expect(find.text('Brejinho de Nazaré'), findsOneWidget);
    expect(find.text('Ver no mapa'), findsOneWidget);
    expect(find.byType(PageView), findsOneWidget);
    expect(find.byType(MarketingMediaImage), findsWidgets);
    final image = tester.widget<MarketingMediaImage>(
      find.byType(MarketingMediaImage).first,
    );
    expect(image.fit, BoxFit.contain);
  });

  testWidgets('hero sem foto ainda mostra produto e ROI', (tester) async {
    final now = DateTime.utc(2026, 7, 27);
    final marketingCase = MarketingCase(
      id: 'c2',
      tipo: CaseTipo.resultado,
      visibilidade: PlanoMarketing.ouro,
      lat: -10,
      lng: -48,
      localizacaoTexto: 'Palmas',
      produtorFazenda: 'Fazenda',
      produtoUtilizado: 'Produto X',
      prodSemProduto: 60,
      prodComProduto: 70,
      unidadeProdutividade: 'sc/ha',
      custoProdutoPorHa: 100,
      valorGrao: 120,
      criadoEm: now,
      atualizadoEm: now,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: MarketingCaseResultHero(marketingCase: marketingCase),
          ),
        ),
      ),
    );

    expect(find.text('Produto X'), findsOneWidget);
    expect(find.byType(PageView), findsNothing);
    expect(find.textContaining('ROI'), findsOneWidget);
  });
}
