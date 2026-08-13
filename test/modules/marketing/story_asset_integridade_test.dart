import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/modules/marketing/domain/entities/marketing_case.dart';
import 'package:soloforte_app/modules/marketing/domain/entities/roi_bloco.dart';
import 'package:soloforte_app/modules/marketing/domain/enums/case_tipo.dart';
import 'package:soloforte_app/modules/marketing/domain/enums/plano_marketing.dart';
import 'package:soloforte_app/modules/marketing/presentation/widgets/story_html_injector.dart';

/// Blindagem do asset compartilhável: nenhum sinal de confiança pode ser
/// fabricado, porque `MarketingCase` não tem nota, avaliação nem verificação.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late String story;

  setUpAll(() async {
    story = await rootBundle.loadString('assets/story.html');
  });

  test('story nao exibe nota, estrelas nem selo de verificacao', () {
    expect(story, isNot(contains('class="star"')));
    expect(story, isNot(contains('review-score')));
    expect(story, isNot(contains('review-verified')));
    expect(story, isNot(contains('Verificado')));
    expect(story, isNot(contains('/ 5,0')));
    expect(story, isNot(contains('Excelente')));
  });

  test('story nao atribui o texto tecnico como avaliacao do produtor', () {
    expect(story, isNot(contains('Avaliação do Produtor')));
    expect(story, contains('Conclusão Técnica'));
  });

  test('story nao tem controle morto nem campo sem fonte de dado', () {
    expect(story, isNot(contains('href="#"')));
    expect(story, isNot(contains('review-cta-share')));
    expect(story, isNot(contains('<!--CULTURA-->')));
  });

  test('story nao inventa cargo do responsavel', () {
    expect(story, isNot(contains('Agrônoma')));
    expect(story, isNot(contains('Agrônomo')));
  });

  group('contrato do injector sobre o asset real', () {
    MarketingCase caseBase({
      String? unidade,
      double? prodSem,
      double? prodCom,
      double? custo,
      double? valor,
      RoiBloco? roiBloco,
      String? ganhoLivre,
    }) {
      final now = DateTime.utc(2026, 3, 10);
      return MarketingCase(
        id: 'case-story',
        tipo: CaseTipo.resultado,
        visibilidade: PlanoMarketing.ouro,
        lat: -10,
        lng: -48,
        localizacaoTexto: 'Sorriso/MT',
        produtorFazenda: 'Cliente X - Fazenda Y',
        produtoUtilizado: 'Produto Z',
        criadoEm: now,
        atualizadoEm: now,
        prodSemProduto: prodSem,
        prodComProduto: prodCom,
        unidadeProdutividade: unidade,
        custoProdutoPorHa: custo,
        valorGrao: valor,
        tamanhoHa: 50,
        roi: roiBloco,
        ganhoProdutividade: ganhoLivre,
      );
    }

    test('usa a unidade do case, nunca sc/ha fixo', () {
      final out = injectStoryData(
        story,
        caseBase(
          unidade: 'ton/ha',
          prodSem: 3,
          prodCom: 3.5,
          custo: 400,
          valor: 2000,
        ),
      );

      expect(out, contains('ton/ha'));
      expect(out, isNot(contains('sc/ha')));
    });

    test('ganho negativo nao gera sinal duplo', () {
      final out = injectStoryData(
        story,
        caseBase(
          unidade: 'sc/ha',
          prodSem: 70,
          prodCom: 66,
          custo: 90,
          valor: 110,
        ),
      );

      expect(out, isNot(contains('+-')));
      expect(out, isNot(contains('+−')));
      expect(out, contains('−'));
      expect(out, contains('4,0'));
    });

    test('produtividade absoluta nao e anunciada como incremento', () {
      final now = DateTime.utc(2026, 3, 10);
      final out = injectStoryData(
        story,
        MarketingCase(
          id: 'case-prod',
          tipo: CaseTipo.resultado,
          visibilidade: PlanoMarketing.ouro,
          lat: -10,
          lng: -48,
          localizacaoTexto: 'Sorriso/MT',
          produtorFazenda: 'Cliente X - Fazenda Y',
          produtoUtilizado: 'Produto Z',
          criadoEm: now,
          atualizadoEm: now,
          produtividadeValor: 72,
          unidadeProdutividade: 'sc/ha',
        ),
      );

      expect(out, contains('72,0'));
      expect(out, isNot(contains('Incremento de Produtividade')));
      expect(out, isNot(contains('sobre a testemunha')));
      expect(out, isNot(contains('+72,0')));
    });

    test('ganho negativo nao sai pintado de verde', () {
      final out = injectStoryData(
        story,
        caseBase(
          unidade: 'sc/ha',
          prodSem: 70,
          prodCom: 66,
          custo: 90,
          valor: 110,
        ),
      );

      expect(out, contains('metric-value negative'));
      expect(out, isNot(contains('metric-value positive')));
      expect(out, contains('metric-card loss'));
      expect(out, isNot(contains('metric-card gain')));
    });

    test('sem ROI nao sobra moeda nem unidade orfas', () {
      final out = injectStoryData(story, caseBase());

      expect(out, isNot(contains('R\$ —')));
      expect(out, isNot(contains('por hectare')));
      expect(out, isNot(contains('+—')));
    });

    test('valores em pt-BR usam separador de milhar', () {
      final out = injectStoryData(
        story,
        caseBase(
          unidade: 'sc/ha',
          prodSem: 60,
          prodCom: 70,
          custo: 90,
          valor: 110,
        ),
      );

      expect(out, contains('R\$ 1.010,00'));
      expect(out, isNot(contains('R\$ 1010,00')));
    });

    test('RoiBloco percentual nunca vira moeda', () {
      final out = injectStoryData(
        story,
        caseBase(
          roiBloco: const RoiBloco(
            investimento: 1000,
            retorno: 2500,
            roiCalculado: 150,
          ),
        ),
      );

      expect(out, contains('150,0%'));
      expect(out, contains('sobre o investimento'));
      expect(out, isNot(contains('R\$ 150')));
    });

    test('nao duplica produtor nem engole o separador', () {
      final out = injectStoryData(story, caseBase());

      expect(out, isNot(contains('Fazenda YSorriso/MT')));
      expect(out, contains('Sorriso/MT'));
      expect('Cliente X - Fazenda Y'.allMatches(out).length, 2);
    });
  });
}
