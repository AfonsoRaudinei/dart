import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/modules/marketing/domain/entities/marketing_case.dart';
import 'package:soloforte_app/modules/marketing/domain/enums/case_tipo.dart';
import 'package:soloforte_app/modules/marketing/domain/enums/plano_marketing.dart';
import 'package:soloforte_app/modules/marketing/presentation/widgets/story_html_injector.dart';

void main() {
  MarketingCase baseCase({
    String? ganho,
    String? conclusao,
    String? vendedor,
  }) {
    final now = DateTime.utc(2025, 6, 15);
    return MarketingCase(
      id: 'case-1',
      tipo: CaseTipo.resultado,
      visibilidade: PlanoMarketing.ouro,
      lat: -10,
      lng: -48,
      localizacaoTexto: 'Sorriso/MT',
      produtorFazenda: 'Joao Silva',
      produtoUtilizado: 'FertMax',
      criadoEm: now,
      atualizadoEm: now,
      ganhoProdutividade: ganho,
      conclusao: conclusao,
      nomeVendedor: vendedor,
      prodSemProduto: 60,
      prodComProduto: 70,
      unidadeProdutividade: 'sc/ha',
      custoProdutoPorHa: 90,
      valorGrao: 110,
      tamanhoHa: 50,
    );
  }

  test('injeta marcadores obrigatorios e derivados', () {
    const html =
        '<!--PRODUTOR-->X<!--PRODUTO-->Z<!--LOCALIZAÇÃO-->L'
        '<!--SAFRA-->2020/21<!--INICIAL-->?<!--CATEGORIA-->Cat'
        '<!--GANHO-->0<!--TESTEMUNHA-->0<!--COM_PRODUTO-->0';

    final out = injectStoryData(html, baseCase(ganho: '+12,5'));

    expect(out, contains('Joao Silva'));
    expect(out, contains('FertMax'));
    expect(out, contains('Sorriso/MT'));
    expect(out, contains('2025/26'));
    expect(out, contains('J'));
    expect(out, contains('Resultado'));
    expect(out, contains('12,5'));
    expect(out, contains('60,0'));
    expect(out, contains('70,0'));
    expect(out, isNot(contains('<!--PRODUTOR-->')));
    expect(out, isNot(contains('<!--GANHO-->')));
  });

  test('nulls opcionais viram traco', () {
    const html = '<!--DEPOIMENTO-->texto<!--CONSULTOR-->nome<!--CULTURA-->Soja';
    final out = injectStoryData(html, baseCase());

    expect(out, contains('—'));
    expect(out, isNot(contains('<!--DEPOIMENTO-->')));
    expect(out, isNot(contains('<!--CONSULTOR-->')));
  });

  test('substitui placeholder de foto quando ha src', () {
    const html =
        '<div class="hero-photo-placeholder"><span>Foto</span></div>{{LOGO_URL}}';
    final out = injectStoryData(
      html,
      baseCase(),
      fotoSrc: 'data:image/jpeg;base64,abc',
      logoSrc: 'data:image/png;base64,logo',
    );

    expect(out, contains('src="data:image/jpeg;base64,abc"'));
    expect(out, contains('data:image/png;base64,logo'));
    expect(out, isNot(contains('hero-photo-placeholder')));
  });
}
