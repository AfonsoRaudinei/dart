import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:soloforte_app/core/html_templates/marketing_html_renderer.dart';

import '../../support/path_provider_test_bindings.dart';

const _fotoA = 'https://cdn.test/marketing/a.jpg';
const _fotoB = 'https://cdn.test/marketing/b.jpg';
final _fakeJpeg = Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xD9]);

Future<Uint8List?> _fetcher(String url) async =>
    url == _fotoA || url == _fotoB ? _fakeJpeg : null;

Map<String, dynamic> _base(String tipo) => {
  'tipo': tipo,
  'produtor_fazenda': 'João Silva - Fazenda Boa Vista',
  'produto_utilizado': 'Bioestimulante X',
  'localizacao_texto': 'Palmas, TO',
  'visibilidade': 'ouro',
  'status': 'published',
  'data_case': '2026-10-14T12:00:00.000Z',
  'criado_em': '2026-10-15T12:00:00.000Z',
  'lat': -10.184,
  'lng': -48.333,
  'descricao': 'Aplicação no V4 com boa resposta.',
  'nome_vendedor': 'Carlos Souza',
  'telefone_vendedor': '(63) 99999-0000',
};

List<int> _photoIndices(String html) => RegExp(r'data-sf-photo="(\d+)"')
    .allMatches(html)
    .map((match) => int.parse(match.group(1)!))
    .toList();

final _emoji = RegExp(r'[\u{1F300}-\u{1FAFF}\u{2600}-\u{27BF}]', unicode: true);

void _expectEditorialShell(String html, String reason) {
  expect(html, isNot(contains('googleapis')), reason: reason);
  expect(html, isNot(contains('{{sf_base_css}}')), reason: reason);
  expect(html, isNot(contains(RegExp(r'\{\{[^}]+\}\}'))), reason: reason);
  expect(html, isNot(contains(_emoji)), reason: reason);
  expect(html, contains('class="sf-letterhead"'), reason: reason);
  final letterheadStart = html.indexOf('<header class="sf-letterhead">');
  final letterhead = html.substring(
    letterheadStart,
    html.indexOf('</header>', letterheadStart),
  );
  expect(letterhead, isNot(contains('<img')), reason: reason);
  expect(html, isNot(contains('logo-img')), reason: reason);
  final footer = html.substring(html.indexOf('<footer class="sf-footer">'));
  expect(
    footer,
    contains(RegExp(r'class="sf-brand-logo" src="data:image/png;base64,')),
    reason: reason,
  );
  expect(footer, isNot(contains('Responsável')), reason: reason);
  expect(footer, isNot(contains('Carlos Souza')), reason: reason);
  expect(html, contains('class="sf-section-num"'), reason: reason);
  expect(html, contains('class="sf-sheet"'), reason: reason);
  expect(letterhead, contains('Plano Ouro'), reason: reason);
  expect(letterhead, contains('Publicado'), reason: reason);
  for (final once in ['Plano Ouro', 'Publicado', 'Carlos Souza']) {
    expect(
      RegExp(once).allMatches(html).length,
      1,
      reason: '$reason: $once repetido',
    );
  }
  expect(
    html,
    contains('<p class="sf-product">Bioestimulante X</p>'),
    reason: '$reason: produto em destaque no timbre',
  );
  expect(
    RegExp('João Silva - Fazenda Boa Vista').allMatches(html).length,
    1,
    reason: '$reason: produtor repetido',
  );
  for (final duplicateRow in [
    '>Produtor</span>',
    '>Produto</span>',
    '>Situação</span>',
    '>Divulgação</span>',
    '>Responsável comercial</span>',
  ]) {
    expect(html, isNot(contains(duplicateRow)), reason: reason);
  }
  expect(html, contains('Ponto registrado no mapa'), reason: reason);
  expect(html, contains('class="sf-signature"'), reason: reason);
  expect(html, contains('(63) 99999-0000'), reason: reason);
  for (final legacy in [
    'tipo-badge',
    'header-pills',
    'section-label-bar',
    'roi-block',
    'vendedor-block',
    'radial-gradient',
    'text-transform: uppercase',
    'filter: brightness(0) invert(1)',
  ]) {
    expect(html, isNot(contains(legacy)), reason: '$reason: $legacy');
  }
  final withoutMapAttrs = html
      .replaceAll(RegExp(r'data-sf-lat="[^"]*"'), '')
      .replaceAll(RegExp(r'data-sf-lng="[^"]*"'), '')
      .replaceAll(RegExp(r'query=[^"&]*'), '');
  expect(withoutMapAttrs, isNot(contains('-10.184')), reason: reason);
}

void main() {
  installPathProviderTestBindings();

  setUpAll(() => initializeDateFormatting('pt_BR'));

  test('resultado usa timbre editorial e preserva ROI completo', () async {
    final html = await MarketingHtmlRenderer.render({
      ..._base('resultado'),
      'foto_principal_url': _fotoA,
      'prod_sem_produto': 60,
      'prod_com_produto': 64,
      'unidade_produtividade': 'sc/ha',
      'custo_produto_por_ha': 90,
      'valor_grao': 110,
      'tamanho_ha': 12.5,
      'area_total': 900,
      'quantidade_produzida': 1800,
      'produtividade_unidade': 'sc',
    }, fetchRemoteBytes: _fetcher);

    _expectEditorialShell(html, 'resultado');
    expect(html, contains('Case de resultado'));
    expect(html, contains('Palmas, TO · 14/10/2026'));
    expect(html, contains('<p class="mk-figure-value">60,0</p>'));
    expect(html, contains('<p class="mk-figure-value">64,0</p>'));
    expect(html, contains('<p class="mk-figure-value">+4,0</p>'));
    expect(html, contains('<p class="mk-figure-value">1800</p>'));
    expect(html, contains('R\$ 350,00'));
    expect(html, contains('R\$ 440,00/ha'));
    expect(html, contains('3,2 sc/ha'));
    expect(html, contains('39,8 sc · R\$ 4375,00'));
    expect(html, contains('2863,6 sc · R\$ 315000,00'));
    expect(html, contains('Estimativa baseada na área total do produtor.'));
    expect(html, contains('id="sf-mk-foto-1" class="sf-lb-toggle"'));
    expect(html, contains('src="data:image/jpeg;base64,'));
    expect(_photoIndices(html), [0]);
    expect(html, contains('<figcaption>Foto 1 · 14/10/2026</figcaption>'));
  });

  test('resultado sem ROI omite blocos condicionais de retorno', () async {
    final html = await MarketingHtmlRenderer.render(_base('resultado'));

    expect(html, isNot(contains('Retorno sobre investimento')));
    expect(html, isNot(contains('roi-talhao')));
    expect(html, isNot(contains('Registro fotográfico')));
    expect(html, isNot(contains('class="mk-figures"')));
    expect(html, isNot(contains(RegExp(r'\{\{[^}]+\}\}'))));
  });

  test(
    'antes/depois mostra figuras lado a lado com legenda e lightbox',
    () async {
      final html = await MarketingHtmlRenderer.render({
        ..._base('antes_depois'),
        'foto_antes_url': _fotoA,
        'foto_depois_url': _fotoB,
        'parametros_json': jsonEncode([
          {'titulo': 'Número de grãos', 'testemunha': 10, 'teste': 12},
          {'titulo': 'Altura', 'testemunha': 50, 'teste': 45, 'unidade': 'cm'},
        ]),
      }, fetchRemoteBytes: _fetcher);

      _expectEditorialShell(html, 'antes_depois');
      expect(html, contains('Case antes e depois'));
      expect(html, contains('Palmas, TO · 14/10/2026'));
      expect(html, contains('class="sf-figure-grid mk-compare"'));
      expect(html, contains('id="sf-mk-antes" class="sf-lb-toggle"'));
      expect(html, contains('id="sf-mk-depois" class="sf-lb-toggle"'));
      expect(RegExp('src="data:image/jpeg;base64,').allMatches(html).length, 2);
      expect(html, contains('>Antes</figcaption>'));
      expect(html, contains('>Depois · 14/10/2026</figcaption>'));
      expect(html, contains('<p class="mk-lead-value">+5,0%</p>'));
      expect(html, contains('<span class="mk-delta positive">+20,0%</span>'));
      expect(html, contains('<span class="mk-delta negative">-10,0%</span>'));
      expect(html, contains('50,0 → 45,0 cm'));
      expect(html, isNot(contains('Sem foto')));
      expect(_photoIndices(html), [0, 1]);
    },
  );

  test(
    'antes/depois legado não repete ganho na ficha do case',
    () async {
      final html = await MarketingHtmlRenderer.render({
        ..._base('antes_depois'),
        'ganho_produtividade': '+12%',
      });

      expect(html, contains('class="mk-figures"'));
      expect(RegExp(r'\+12%').allMatches(html).length, 1);
      expect(html, isNot(contains('Ganho de produtividade')));

      final comParametros = await MarketingHtmlRenderer.render({
        ..._base('antes_depois'),
        'ganho_produtividade': '+12%',
        'parametros_json': jsonEncode([
          {'titulo': 'Altura', 'testemunha': 50, 'teste': 55},
        ]),
      });
      expect(comParametros, isNot(contains('class="mk-figures"')));
      expect(comParametros, contains('Ganho de produtividade'));
      expect(RegExp(r'\+12%').allMatches(comParametros).length, 1);
    },
  );

  test('avaliacao renderiza blocos comparativos e conclusão', () async {
    final html = await MarketingHtmlRenderer.render({
      ..._base('avaliacao'),
      'nome_talhao': 'Talhão Norte',
      'tamanho_ha': 42.0,
      'conclusao_tecnica': 'Produto aprovado para a próxima safra.',
      'avaliacoes_json': jsonEncode([
        {
          'titulo': 'Vigor na V6',
          'nome_lado_a': 'Testemunha',
          'nome_lado_b': 'Bioestimulante X',
          'foto_lado_a_path': _fotoA,
          'foto_lado_b_path': _fotoB,
          'cultura': 'Soja',
          'observacoes': 'Diferença visual clara.',
          'parametros': [
            {'titulo': 'Número de grãos', 'testemunha': 10, 'teste': 12},
          ],
        },
      ]),
    }, fetchRemoteBytes: _fetcher);

    _expectEditorialShell(html, 'avaliacao');
    expect(html, contains('Case de avaliação'));
    expect(
      html,
      contains('Talhão Norte · Palmas, TO · 14/10/2026'),
    );
    expect(html, contains('Vigor na V6'));
    expect(html, contains('Média <strong>+20,0%</strong>'));
    expect(html, contains('id="sf-mk-av-1-a" class="sf-lb-toggle"'));
    expect(html, contains('id="sf-mk-av-1-b" class="sf-lb-toggle"'));
    expect(_photoIndices(html), [0, 1]);
    expect(html, contains('<figcaption>Testemunha · Soja</figcaption>'));
    expect(html, contains('Testemunha 10,0 → Bioestimulante X 12,0'));
    expect(html, contains('Diferença visual clara.'));
    expect(html, contains('Conclusão técnica'));
    expect(html, contains('Produto aprovado para a próxima safra.'));
    expect(html, contains('42,0 ha'));
    expect(html, isNot(contains('Investimento')));
  });

  test('avaliacao legada sem foto usa marcador textual', () async {
    final html = await MarketingHtmlRenderer.render({
      ..._base('avaliacao'),
      'avaliacoes': [
        {
          'layout': 'uma_foto',
          'lado_a_label': 'Área tratada',
          'lado_a_obs': 'Folhas mais verdes.',
        },
      ],
    });

    expect(html, contains('mk-compare uma-foto'));
    expect(html, contains('Sem foto'));
    expect(html, contains('Foto única'));
    expect(html, contains('Folhas mais verdes.'));
    expect(html, isNot(contains(_emoji)));
  });

  test('escapa texto livre do case', () async {
    final html = await MarketingHtmlRenderer.render({
      ..._base('resultado'),
      'produtor_fazenda': '<script>alert(1)</script>',
      'visibilidade': '<b>x</b>',
    });

    expect(html, isNot(contains('<script>alert(1)</script>')));
    expect(html, contains('&lt;script&gt;'));
    expect(html, isNot(contains('<b>x</b>')));
  });
}
