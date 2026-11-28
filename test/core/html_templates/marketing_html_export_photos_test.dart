import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/core/constants/layout_constants.dart';
import 'package:soloforte_app/core/html_templates/html_report_viewer.dart';
import 'package:soloforte_app/core/html_templates/marketing_html_renderer.dart';
import 'package:soloforte_app/core/html_templates/relatorio_html_renderer.dart';

import '../../support/path_provider_test_bindings.dart';

void main() {
  installPathProviderTestBindings();

  const remoteUrl = 'https://cdn.test/marketing/resultado.jpg';
  final fakeBytes = Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xD9]);

  Future<Uint8List?> mockFetcher(String url) async {
    if (url == remoteUrl) return fakeBytes;
    return null;
  }

  group('RelatorioHtmlRenderer.resolvePhotoSrcForExport', () {
    test('inline base64 quando fetch remoto retorna bytes', () async {
      final src = await RelatorioHtmlRenderer.resolvePhotoSrcForExport(
        remoteUrl,
        fetchRemoteBytes: mockFetcher,
      );

      expect(src, startsWith('data:image/jpeg;base64,'));
      expect(src, isNot(contains('https://cdn.test')));
    });

    test('fallback para URL https sanitizada quando fetch falha', () async {
      final src = await RelatorioHtmlRenderer.resolvePhotoSrcForExport(
        remoteUrl,
        fetchRemoteBytes: (_) async => null,
      );

      expect(src, remoteUrl);
    });
  });

  group('MarketingHtmlRenderer export photos', () {
    test('resultado exporta foto principal inline', () async {
      final html = await MarketingHtmlRenderer.render({
        'tipo': 'resultado',
        'produtor_fazenda': 'Cliente',
        'produto_utilizado': 'Produto',
        'localizacao_texto': 'Palmas',
        'visibilidade': 'ouro',
        'foto_principal_url': remoteUrl,
        'descricao': 'Teste',
        'nome_vendedor': 'Vendedor',
        'criado_em': '2026-06-03T12:00:00.000Z',
        'status': 'published',
      }, fetchRemoteBytes: mockFetcher);

      expect(html, contains('data:image/jpeg;base64,'));
      expect(html, isNot(contains(remoteUrl)));
    });

    test('avaliacao exporta fotos dos lados inline', () async {
      final html = await MarketingHtmlRenderer.render({
        'tipo': 'avaliacao',
        'produtor_fazenda': 'Cliente',
        'produto_utilizado': 'Produto',
        'localizacao_texto': 'Palmas',
        'visibilidade': 'ouro',
        'nome_talhao': 'Talhão 1',
        'avaliacoes': [
          {
            'layout': 'duas_fotos',
            'lado_a_label': 'Lado A',
            'lado_a_foto_url': remoteUrl,
            'lado_b_label': 'Lado B',
            'lado_b_foto_url': remoteUrl,
          },
        ],
        'descricao': 'Teste',
        'nome_vendedor': 'Vendedor',
        'criado_em': '2026-06-03T12:00:00.000Z',
        'status': 'published',
      }, fetchRemoteBytes: mockFetcher);

      expect(html, contains('data:image/jpeg;base64,'));
      expect(html, isNot(contains(remoteUrl)));
    });

    test('antes/depois mantém segurança contra URL maliciosa', () async {
      final html = await MarketingHtmlRenderer.render({
        'tipo': 'antes_depois',
        'produtor_fazenda': 'Cliente',
        'produto_utilizado': 'Produto',
        'localizacao_texto': 'Palmas',
        'visibilidade': 'ouro',
        'foto_antes_url': '"><img src=x onerror=alert(1)>',
        'foto_depois_url': remoteUrl,
        'descricao': 'Teste',
        'nome_vendedor': 'Vendedor',
        'criado_em': '2026-06-03T12:00:00.000Z',
        'status': 'published',
      }, fetchRemoteBytes: mockFetcher);

      expect(html, isNot(contains('onerror=')));
      expect(html, contains('Sem foto'));
      expect(html, contains('data:image/jpeg;base64,'));
    });
  });

  group('MarketingHtmlRenderer antes/depois com avaliacoes_json', () {
    const urlA1 = 'https://cdn.test/marketing/c1-a.jpg';
    const urlB1 = 'https://cdn.test/marketing/c1-b.jpg';
    const urlC1 = 'https://cdn.test/marketing/c1-c.jpg';
    const urlA2 = 'https://cdn.test/marketing/c2-a.jpg';

    Future<Uint8List?> fetchPorUrl(String url) async {
      switch (url) {
        case urlA1:
          return Uint8List.fromList([0xFF, 0xD8, 0x01, 0xD9]);
        case urlB1:
          return Uint8List.fromList([0xFF, 0xD8, 0x02, 0xD9]);
        case urlC1:
          return Uint8List.fromList([0xFF, 0xD8, 0x03, 0xD9]);
        case urlA2:
          return Uint8List.fromList([0xFF, 0xD8, 0x04, 0xD9]);
      }
      return null;
    }

    String b64(int marker) => base64Encode([0xFF, 0xD8, marker, 0xD9]);

    Map<String, dynamic> caseComBlocos({String? conclusaoTecnica}) => {
      'tipo': 'antes_depois',
      'produtor_fazenda': 'Cliente',
      'produto_utilizado': 'Produto',
      'localizacao_texto': 'Palmas',
      'visibilidade': 'ouro',
      'foto_antes_url': urlA1,
      'foto_depois_url': null,
      'parametros_json': jsonEncode([
        {'id': 'p1', 'titulo': 'Vagens', 'testemunha': 10, 'teste': 12},
      ]),
      'conclusao_tecnica': conclusaoTecnica,
      'avaliacoes_json': jsonEncode([
        {
          'id': 'av-1',
          'titulo': 'Comparação 1',
          'nome_lado_a': 'Testemunha',
          'nome_lado_b': 'Com produto',
          'nome_lado_c': 'Concorrente',
          'foto_lado_a_path': urlA1,
          'foto_lado_b_path': urlB1,
          'foto_lado_c_path': urlC1,
          'observacoes': 'Raiz mais vigorosa <b>forte</b>',
          'parametros': [
            {'id': 'p1', 'titulo': 'Vagens', 'testemunha': 10, 'teste': 12},
          ],
        },
        {
          'id': 'av-2',
          'titulo': 'Comparação 2',
          'nome_lado_a': 'Faixa norte',
          'nome_lado_b': '',
          'foto_lado_a_path': urlA2,
          'observacoes': 'Segundo ponto da lavoura',
          'parametros': [
            {'id': 'p2', 'titulo': 'Altura', 'testemunha': 50, 'teste': 55},
          ],
        },
      ]),
      'nome_vendedor': 'Vendedor',
      'criado_em': '2026-06-03T12:00:00.000Z',
      'status': 'published',
    };

    test(
      '2 blocos e 3 fotos: fotos, rótulos, texto livre, parâmetros e conclusão',
      () async {
        final html = await MarketingHtmlRenderer.render(
          caseComBlocos(conclusaoTecnica: 'Produto elevou o vigor <ok>'),
          fetchRemoteBytes: fetchPorUrl,
        );

        expect(html, contains(b64(0x01)));
        expect(html, contains(b64(0x02)));
        expect(html, contains(b64(0x03)));
        expect(html, contains(b64(0x04)));
        expect(html, isNot(contains('https://cdn.test')));
        expect(RegExp(r'<img data-sf-photo="\d+"').allMatches(html).length, 4);

        expect(html, contains('Comparação 1'));
        expect(html, contains('Comparação 2'));
        expect(html, contains('Testemunha'));
        expect(html, contains('Com produto'));
        expect(html, contains('Concorrente'));
        expect(html, contains('Faixa norte'));

        expect(html, contains('Raiz mais vigorosa &lt;b&gt;forte&lt;/b&gt;'));
        expect(html, isNot(contains('<b>forte</b>')));
        expect(html, contains('Segundo ponto da lavoura'));
        expect(html, contains('Vagens'));
        expect(html, contains('Altura'));

        expect(html, contains('Conclusão técnica'));
        expect(html, contains('Produto elevou o vigor &lt;ok&gt;'));

        expect(html, isNot(contains('Sem foto')));
        expect(html, isNot(contains('Foto antes')));
        expect(html, isNot(contains('Parâmetros comparativos')));
        expect(html, isNot(contains('{{')));
      },
    );

    test('bloco com uma só foto não gera "Sem foto" nem lado vazio', () async {
      final html = await MarketingHtmlRenderer.render(
        caseComBlocos(),
        fetchRemoteBytes: fetchPorUrl,
      );

      expect(html, isNot(contains('Sem foto')));
      expect(html, contains('mk-compare uma-foto'));
      expect(html, isNot(contains('Conclusão técnica')));
    });

    test('sem avaliacoes_json segue o layout legado Antes/Depois', () async {
      final data = caseComBlocos()..remove('avaliacoes_json');
      data['foto_depois_url'] = urlB1;
      data['conclusao_tecnica'] = 'Conclusão do case antigo';
      final html = await MarketingHtmlRenderer.render(
        data,
        fetchRemoteBytes: fetchPorUrl,
      );

      expect(html, contains('Foto antes'));
      expect(html, contains('Foto depois'));
      expect(html, contains('>Antes<'));
      expect(html, contains('Parâmetros comparativos'));
      expect(html, contains(b64(0x01)));
      expect(html, contains(b64(0x02)));
      expect(html, isNot(contains('Comparação 1')));
      expect(html, contains('Conclusão do case antigo'));
    });

    test('avaliacoes_json vazio ou inválido mantém o legado', () async {
      for (final raw in ['[]', 'não é json', null]) {
        final data = caseComBlocos()..['avaliacoes_json'] = raw;
        final html = await MarketingHtmlRenderer.render(
          data,
          fetchRemoteBytes: fetchPorUrl,
        );
        expect(html, contains('Foto antes'), reason: 'raw=$raw');
        expect(html, contains('Sem foto'), reason: 'raw=$raw');
      }
    });

    group('blocos sem conteúdo não descartam o legado', () {
      Map<String, dynamic> legado(String avaliacoesJson) => {
        ...caseComBlocos(),
        'foto_antes_url': urlA1,
        'foto_depois_url': urlB1,
        'parametros_json': jsonEncode([
          {
            'id': 'p9',
            'titulo': 'Grãos por vagem',
            'testemunha': 2,
            'teste': 3,
          },
        ]),
        'avaliacoes_json': avaliacoesJson,
      };

      test(
        'bloco só com id/título + legado preenchido mostra o legado',
        () async {
          final html = await MarketingHtmlRenderer.render(
            legado(
              jsonEncode([
                {'id': 'av-1', 'titulo': 'Comparação 1'},
              ]),
            ),
            fetchRemoteBytes: fetchPorUrl,
          );

          expect(html, contains('Foto antes'));
          expect(html, contains('Foto depois'));
          expect(html, contains(b64(0x01)));
          expect(html, contains(b64(0x02)));
          expect(html, contains('Parâmetros comparativos'));
          expect(html, contains('Grãos por vagem'));
          expect(html, isNot(contains('Comparação 1')));
        },
      );

      test('bloco só com texto + legado: legado nas fotos/parâmetros e o bloco '
          'é mantido pelo texto, sem lados vazios', () async {
        final html = await MarketingHtmlRenderer.render(
          legado(
            jsonEncode([
              {
                'id': 'av-1',
                'titulo': 'Comparação 1',
                'observacoes': 'Só uma nota de campo',
              },
            ]),
          ),
          fetchRemoteBytes: fetchPorUrl,
        );

        // Sem foto/parâmetro no bloco, o legado segue como fonte.
        expect(html, contains('Foto antes'));
        expect(html, contains('Grãos por vagem'));
        expect(html, isNot(contains('Só uma nota de campo')));
      });

      test(
        'blocos reais ignoram o legado e descartam blocos 100% vazios',
        () async {
          final data = caseComBlocos();
          data['parametros_json'] = jsonEncode([
            {
              'id': 'p9',
              'titulo': 'Grãos por vagem',
              'testemunha': 2,
              'teste': 3,
            },
          ]);
          final blocos = jsonDecode(data['avaliacoes_json'] as String) as List;
          blocos.add({'id': 'av-3', 'titulo': 'Comparação 3'});
          blocos.add({
            'id': 'av-4',
            'titulo': 'Comparação 4',
            'observacoes': 'Texto do quarto',
          });
          data['avaliacoes_json'] = jsonEncode(blocos);
          final html = await MarketingHtmlRenderer.render(
            data,
            fetchRemoteBytes: fetchPorUrl,
          );

          expect(html, contains('Comparação 1'));
          expect(html, contains('Comparação 2'));
          expect(html, isNot(contains('Comparação 3')));
          expect(html, contains('Comparação 4'));
          expect(html, contains('Texto do quarto'));
          expect(html, isNot(contains('Grãos por vagem')));
          expect(html, isNot(contains('Foto antes')));
        },
      );
    });

    test('avaliacao exporta o lado C com rótulo e foto inline', () async {
      final html = await MarketingHtmlRenderer.render({
        'tipo': 'avaliacao',
        'produtor_fazenda': 'Cliente',
        'produto_utilizado': 'Produto',
        'localizacao_texto': 'Palmas',
        'visibilidade': 'ouro',
        'nome_talhao': 'Talhão 1',
        'avaliacoes_json': jsonEncode([
          {
            'id': 'av-1',
            'titulo': 'Avaliação 1',
            'nome_lado_a': 'Lado A',
            'nome_lado_b': 'Lado B',
            'nome_lado_c': 'Concorrente',
            'foto_lado_a_path': urlA1,
            'foto_lado_b_path': urlB1,
            'foto_lado_c_path': urlC1,
          },
        ]),
        'conclusao_tecnica': 'Conclusão da avaliação',
        'nome_vendedor': 'Vendedor',
        'criado_em': '2026-06-03T12:00:00.000Z',
        'status': 'published',
      }, fetchRemoteBytes: fetchPorUrl);

      expect(html, contains(b64(0x03)));
      expect(html, contains('Concorrente'));
      expect(RegExp(r'<img data-sf-photo="\d+"').allMatches(html).length, 3);
      expect(html, contains('Conclusão da avaliação'));
      expect(html, isNot(contains('Média')));
    });
  });

  group('MarketingHtmlRenderer resultado com múltiplas fotos (ADR-065)', () {
    const urls = [
      'https://cdn.test/marketing/r1.jpg',
      'https://cdn.test/marketing/r2.jpg',
      'https://cdn.test/marketing/r3.jpg',
    ];

    Future<Uint8List?> fetchPorUrl(String url) async {
      final i = urls.indexOf(url);
      return i < 0 ? null : Uint8List.fromList([0xFF, 0xD8, 0x10 + i, 0xD9]);
    }

    String b64(int i) => base64Encode([0xFF, 0xD8, 0x10 + i, 0xD9]);

    Map<String, dynamic> base() => {
      'tipo': 'resultado',
      'produtor_fazenda': 'Cliente',
      'produto_utilizado': 'Produto',
      'localizacao_texto': 'Palmas',
      'visibilidade': 'ouro',
      'descricao': 'Teste',
      'nome_vendedor': 'Vendedor',
      'criado_em': '2026-06-03T12:00:00.000Z',
      'status': 'published',
    };

    final imgRe = RegExp(r'<img data-sf-photo="\d+"');

    test('3 fotos: 3 imgs data-sf-photo em ordem e legendas Foto 1..3', () async {
      final html = await MarketingHtmlRenderer.render({
        ...base(),
        'foto_principal_url': urls.first,
        'fotos_resultado_json': jsonEncode(urls),
      }, fetchRemoteBytes: fetchPorUrl);

      expect(imgRe.allMatches(html).length, 3);
      final pos = [for (var i = 0; i < 3; i++) html.indexOf(b64(i))];
      expect(pos.every((p) => p >= 0), isTrue);
      expect(pos[0], lessThan(pos[1]));
      expect(pos[1], lessThan(pos[2]));
      expect(html, contains('<figcaption>Foto 1</figcaption>'));
      expect(html, contains('<figcaption>Foto 2</figcaption>'));
      expect(html, contains('<figcaption>Foto 3</figcaption>'));
      expect(html, isNot(contains('<figcaption>Foto 4')));
      expect(html, isNot(contains('https://cdn.test')));
    });

    test('lista como List também é aceita e legenda leva a data', () async {
      final html = await MarketingHtmlRenderer.render({
        ...base(),
        'data_case': '2026-06-03T12:00:00.000Z',
        'fotos_resultado_json': urls.take(2).toList(),
      }, fetchRemoteBytes: fetchPorUrl);

      expect(imgRe.allMatches(html).length, 2);
      expect(html, contains('<figcaption>Foto 1 · '));
      expect(html, contains('<figcaption>Foto 2 · '));
    });

    test('só foto_principal_url: 1 foto como antes', () async {
      final html = await MarketingHtmlRenderer.render({
        ...base(),
        'foto_principal_url': urls.first,
      }, fetchRemoteBytes: fetchPorUrl);

      expect(imgRe.allMatches(html).length, 1);
      expect(html, contains(b64(0)));
      expect(html, contains('<figcaption>Foto 1</figcaption>'));
      expect(html, isNot(contains('<figcaption>Foto 2')));
    });

    test('JSON malformado cai na foto principal', () async {
      final html = await MarketingHtmlRenderer.render({
        ...base(),
        'foto_principal_url': urls.first,
        'fotos_resultado_json': '{nao-e-lista',
      }, fetchRemoteBytes: fetchPorUrl);

      expect(imgRe.allMatches(html).length, 1);
      expect(html, contains(b64(0)));
    });

    test('URL maliciosa na lista é descartada', () async {
      final html = await MarketingHtmlRenderer.render({
        ...base(),
        'fotos_resultado_json': jsonEncode([
          urls.first,
          '"><img src=x onerror=alert(1)>',
        ]),
      }, fetchRemoteBytes: fetchPorUrl);

      expect(html, isNot(contains('onerror=')));
      expect(imgRe.allMatches(html).length, 1);
    });

    test('sem foto: sem seção Registro fotográfico', () async {
      final html = await MarketingHtmlRenderer.render(
        base(),
        fetchRemoteBytes: fetchPorUrl,
      );

      expect(imgRe.allMatches(html).length, 0);
      expect(html, isNot(contains('Registro fotográfico')));
    });
  });

  group('HtmlReportViewer', () {
    test(
      'withFabSafeAreaForInApp reserva a área do FAB só na cópia do app',
      () {
        const original = '<html><head></head><body><p>fim</p></body></html>';
        final inApp = withFabSafeAreaForInApp(original);

        expect(inApp, contains('${kFabSafeArea}px'));
        expect(inApp, contains('env(safe-area-inset-bottom'));
        expect(
          inApp.indexOf('sf-fab-safe-area'),
          lessThan(inApp.indexOf('</head>')),
        );
        expect(withFabSafeAreaForInApp(inApp), inApp);
        expect(original, isNot(contains('sf-fab-safe-area')));
      },
    );
  });
}
