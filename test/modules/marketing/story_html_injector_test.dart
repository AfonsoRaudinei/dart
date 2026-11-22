import 'dart:convert';
import 'dart:io';

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
    CaseTipo tipo = CaseTipo.resultado,
    String localizacaoTexto = 'Sorriso/MT',
    String produtorFazenda = 'Joao Silva',
    String produtoUtilizado = 'FertMax',
    String? avaliacoesJson,
    String? descricao,
    String? conclusaoTecnica,
    String? fotoAntesUrl,
    String? fotoDepoisUrl,
  }) {
    final now = DateTime.utc(2025, 6, 15);
    return MarketingCase(
      id: 'case-1',
      tipo: tipo,
      visibilidade: PlanoMarketing.ouro,
      lat: -10,
      lng: -48,
      localizacaoTexto: localizacaoTexto,
      produtorFazenda: produtorFazenda,
      produtoUtilizado: produtoUtilizado,
      criadoEm: now,
      atualizadoEm: now,
      ganhoProdutividade: ganho,
      conclusao: conclusao,
      conclusaoTecnica: conclusaoTecnica,
      descricao: descricao,
      nomeVendedor: vendedor,
      avaliacoesJson: avaliacoesJson,
      fotoAntesUrl: fotoAntesUrl,
      fotoDepoisUrl: fotoDepoisUrl,
      prodSemProduto: 60,
      prodComProduto: 70,
      unidadeProdutividade: 'sc/ha',
      custoProdutoPorHa: 90,
      valorGrao: 110,
      tamanhoHa: 50,
    );
  }

  final storyHtml = File('assets/story.html').readAsStringSync();

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

  test('escapa caracteres especiais em produtorFazenda', () {
    const html = '<!--PRODUTOR-->X<!--FAZENDA-->Y';
    final now = DateTime.utc(2025, 6, 15);
    final c = MarketingCase(
      id: 'case-esc-1',
      tipo: CaseTipo.resultado,
      visibilidade: PlanoMarketing.ouro,
      lat: -10,
      lng: -48,
      localizacaoTexto: 'Sorriso/MT',
      produtorFazenda: 'Fazenda S/A & Filhos <Premium>',
      produtoUtilizado: 'FertMax',
      criadoEm: now,
      atualizadoEm: now,
    );

    final out = injectStoryData(html, c);

    expect(out, contains('Fazenda S/A &amp; Filhos &lt;Premium&gt;'));
    expect(out, isNot(contains('<Premium>')));
  });

  test('escapa aspas em conclusao', () {
    const html = '<!--DEPOIMENTO-->texto';
    final out = injectStoryData(
      html,
      baseCase(conclusao: 'Produto "excelente" e \'recomendado\''),
    );

    expect(out, contains('&quot;excelente&quot;'));
    // Helper canônico usa &#x27; (equivalente a &#39;).
    expect(out, contains('&#x27;recomendado&#x27;'));
  });

  test('nao escapa valores numericos de produtividade', () {
    const html = '<!--GANHO-->0<!--TESTEMUNHA-->0<!--COM_PRODUTO-->0';
    final out = injectStoryData(html, baseCase(ganho: '10,5'));

    expect(out, contains('10,5'));
    expect(out, contains('60,0'));
    expect(out, contains('70,0'));
  });

  test('case resultado fica so com o card de resultado', () {
    final out = injectStoryData(storyHtml, baseCase());

    expect(out, contains('STORY:resultado'));
    expect(out, isNot(contains('STORY:antes_depois')));
    expect(out, isNot(contains('STORY:avaliacao')));
    expect(out, isNot(contains('Antes e depois')));
    expect(out, isNot(contains('Avaliação')));
    expect(out, isNot(contains('Ver case completo')));
    expect(out, isNot(contains('Excelente')));
    expect(out, isNot(contains('5,0')));
  });

  test('case antesDepois fica so com o card comparativo', () {
    final out = injectStoryData(
      storyHtml,
      baseCase(tipo: CaseTipo.antesDepois),
    );

    expect(out, contains('STORY:antes_depois'));
    expect(out, isNot(contains('STORY:resultado')));
    expect(out, isNot(contains('STORY:avaliacao')));
  });

  test('case avaliacao fica so com o card de avaliacao', () {
    final out = injectStoryData(storyHtml, baseCase(tipo: CaseTipo.avaliacao));

    expect(out, contains('STORY:avaliacao'));
    expect(out, isNot(contains('STORY:resultado')));
    expect(out, isNot(contains('STORY:antes_depois')));
    expect(out, isNot(contains('Ver case completo')));
    expect(out, isNot(contains('Excelente')));
    expect(out, isNot(contains('5,0')));
  });

  test('sem cultura o bloco IF some', () {
    const html = '<!--IF:CULTURA-->folha<!--/IF:CULTURA-->';
    final out = injectStoryData(html, baseCase());

    expect(out, isNot(contains('folha')));
    expect(out, isNot(contains('IF:CULTURA')));
    expect(out, isNot(contains('—')));
  });

  test('cultura da avaliacao permanece no card', () {
    const html = '<!--IF:CULTURA--><!--CULTURA-->folha<!--/IF:CULTURA-->';
    final out = injectStoryData(
      html,
      baseCase(avaliacoesJson: '[{"id":"1","titulo":"Av","cultura":"Soja"}]'),
    );

    expect(out, contains('Soja'));
    expect(out, isNot(contains('folha')));
  });

  test('produto do cadastro aparece dentro do IF', () {
    const html =
        '<!--IF:PRODUTO--><span class="hero-badge"><!--PRODUTO-->FertMax</span><!--/IF:PRODUTO-->';
    final out = injectStoryData(html, baseCase(produtoUtilizado: 'Bio folha'));

    expect(out, contains('Bio folha'));
    expect(out, isNot(contains('FertMax')));
  });

  test('municipio e produtor ficam em nos separados', () {
    const html =
        '<!--IF:MUNICIPIO--><span><!--MUNICIPIO-->X</span><!--/IF:MUNICIPIO--> <!--IF:PRODUTOR--><span><!--PRODUTOR-->Y</span><!--/IF:PRODUTOR-->';
    final out = injectStoryData(
      html,
      baseCase(localizacaoTexto: 'Palmas', produtorFazenda: 'Adriano Gomes'),
    );

    expect(out, contains('Palmas'));
    expect(out, contains('Adriano Gomes'));
    expect(out, isNot(contains('PalmasAdriano')));
    expect(out, isNot(contains('Adriano GomesPalmas')));
  });

  test('depoimento vazio remove o bloco sem traco', () {
    const html =
        '<!--IF:DEPOIMENTO--><p class="review-quote-text"><!--DEPOIMENTO-->superou todas as expectativas</p><!--/IF:DEPOIMENTO-->';
    final out = injectStoryData(html, baseCase());

    expect(out, isNot(contains('IF:DEPOIMENTO')));
    expect(out, isNot(contains('superou')));
    expect(out, isNot(contains('—')));
  });

  test('depoimento preenchido aparece escapado', () {
    const html = '<!--IF:DEPOIMENTO--><!--DEPOIMENTO--><!--/IF:DEPOIMENTO-->';
    final out = injectStoryData(
      html,
      baseCase(conclusao: 'Lavoura <forte> & "boa"'),
    );

    expect(out, contains('Lavoura &lt;forte&gt; &amp; &quot;boa&quot;'));
    expect(out, isNot(contains('<forte>')));
    expect(out, isNot(contains('—')));
  });

  group('story Antes/Depois a partir da Comparação 1', () {
    String comparacao1({String? a, String? b, String? c}) => jsonEncode([
      {
        'id': 'av-1',
        'titulo': 'Comparação 1',
        'nome_lado_a': 'Antes',
        'nome_lado_b': 'Depois',
        'foto_lado_a_path': a,
        'foto_lado_b_path': b,
        'foto_lado_c_path': c,
      },
      {
        'id': 'av-2',
        'titulo': 'Comparação 2',
        'foto_lado_a_path': 'https://example.com/c2-a.jpg',
        'foto_lado_b_path': 'https://example.com/c2-b.jpg',
      },
    ]);

    test('usa a primeira e a segunda foto preenchidas da Comparação 1', () {
      final fotos = storyFotosAntesDepois(
        baseCase(
          tipo: CaseTipo.antesDepois,
          avaliacoesJson: comparacao1(
            a: 'https://example.com/a.jpg',
            b: '  ',
            c: 'https://example.com/c.jpg',
          ),
          fotoAntesUrl: 'https://example.com/legado-antes.jpg',
          fotoDepoisUrl: 'https://example.com/legado-depois.jpg',
        ),
      );

      expect(fotos.antes, 'https://example.com/a.jpg');
      expect(fotos.depois, 'https://example.com/c.jpg');
    });

    test('sem blocos cai no par legado, só com as fotos preenchidas', () {
      final fotos = storyFotosAntesDepois(
        baseCase(
          tipo: CaseTipo.antesDepois,
          fotoAntesUrl: null,
          fotoDepoisUrl: 'https://example.com/legado-depois.jpg',
        ),
      );

      expect(fotos.antes, 'https://example.com/legado-depois.jpg');
      expect(fotos.depois, isNull);
    });

    test('blocos sem foto usam o par legado', () {
      final fotos = storyFotosAntesDepois(
        baseCase(
          tipo: CaseTipo.antesDepois,
          avaliacoesJson: jsonEncode([
            {'id': 'av-1', 'titulo': 'Comparação 1'},
          ]),
          fotoAntesUrl: 'https://example.com/legado-antes.jpg',
          fotoDepoisUrl: 'https://example.com/legado-depois.jpg',
        ),
      );

      expect(fotos.antes, 'https://example.com/legado-antes.jpg');
      expect(fotos.depois, 'https://example.com/legado-depois.jpg');
    });

    test('Comparação 1 sem foto mas outro bloco com foto: usa esse bloco', () {
      final fotos = storyFotosAntesDepois(
        baseCase(
          tipo: CaseTipo.antesDepois,
          avaliacoesJson: comparacao1(),
          fotoAntesUrl: 'https://example.com/legado-antes.jpg',
        ),
      );

      expect(fotos.antes, 'https://example.com/c2-a.jpg');
      expect(fotos.depois, 'https://example.com/c2-b.jpg');
    });

    test('foto única esconde rótulo Antes e o valor da testemunha', () {
      final out = injectStoryData(
        storyHtml,
        baseCase(
          tipo: CaseTipo.antesDepois,
          avaliacoesJson: comparacao1(a: 'https://example.com/a.jpg'),
        ),
        fotoAntesSrc: 'data:image/jpeg;base64,AAA',
      );

      final css = RegExp(
        r'<style id="sf-story-single-photo">([\s\S]*?)</style>',
      ).firstMatch(out)!.group(1)!;
      expect(css, contains('.compare-side.before .compare-side-label'));
      expect(css, contains('.compare-side.before .compare-side-value'));
      expect(css, contains('.compare-side.before .compare-side-overlay'));
      expect(css, contains('display: none'));
    });

    test('uma só foto: slide mostra só ela, sem lado Depois vazio', () {
      final caso = baseCase(
        tipo: CaseTipo.antesDepois,
        avaliacoesJson: comparacao1(a: 'https://example.com/a.jpg'),
      );
      final fotos = storyFotosAntesDepois(caso);

      expect(fotos.antes, 'https://example.com/a.jpg');
      expect(fotos.depois, isNull);

      final out = injectStoryData(
        storyHtml,
        caso,
        fotoAntesSrc: 'data:image/jpeg;base64,AAA',
      );

      expect(out, contains('src="data:image/jpeg;base64,AAA"'));
      expect(out, contains('sf-story-single-photo'));
      expect(
        out,
        contains('.compare-side.after, .compare-divider { display: none; }'),
      );
      expect(out, isNot(contains('{{FOTO_')));
    });

    test('duas fotos mantêm o layout lado a lado', () {
      final caso = baseCase(
        tipo: CaseTipo.antesDepois,
        avaliacoesJson: comparacao1(
          a: 'https://example.com/a.jpg',
          b: 'https://example.com/b.jpg',
        ),
      );

      final out = injectStoryData(
        storyHtml,
        caso,
        fotoAntesSrc: 'data:image/jpeg;base64,AAA',
        fotoDepoisSrc: 'data:image/jpeg;base64,BBB',
      );

      expect(out, contains('src="data:image/jpeg;base64,AAA"'));
      expect(out, contains('src="data:image/jpeg;base64,BBB"'));
      expect(out, isNot(contains('sf-story-single-photo')));
    });

    test('sem nenhuma foto o slide permanece como antes', () {
      final out = injectStoryData(
        storyHtml,
        baseCase(tipo: CaseTipo.antesDepois),
      );

      expect(out, isNot(contains('sf-story-single-photo')));
    });
  });
}
