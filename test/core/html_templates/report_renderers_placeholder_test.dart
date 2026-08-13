import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:soloforte_app/core/html_templates/marketing_html_renderer.dart';
import 'package:soloforte_app/core/html_templates/ocorrencia_html_renderer.dart';
import 'package:soloforte_app/core/html_templates/planejamento_html_renderer.dart';
import 'package:soloforte_app/core/html_templates/propriedade_html_renderer.dart';
import 'package:soloforte_app/core/html_templates/visita_html_renderer.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final now = DateTime.utc(2026, 6, 3, 12);

  Future<void> expectNoTemplateTokens(
    String type,
    Future<String> Function() render,
  ) async {
    final html = await render();
    expect(html, isNotEmpty, reason: type);
    expect(html, isNot(contains(RegExp(r'\{\{[^}]+\}\}'))), reason: type);
  }

  test('renderers oficiais nao vazam placeholders handlebars', () async {
    await initializeDateFormatting('pt_BR');

    await expectNoTemplateTokens('planejamento semanal', () {
      final weekStart = DateTime.utc(2026, 7, 6);
      return PlanejamentoHtmlRenderer.render(
        weekStart: weekStart,
        weekEnd: weekStart.add(const Duration(days: 6)),
        days: [
          {
            'weekday_label': 'segunda-feira',
            'date_label': '6 jul 2026',
            'is_sunday': false,
            'events': [
              {
                'titulo': 'Visita tecnica',
                'horario': '08:00 – 10:00',
                'status': 'agendado',
                'status_label': 'Agendado',
                'cliente_nome': 'Cliente Teste',
                'fazenda_nome': 'Fazenda Norte',
                'tipo_label': 'Visita Técnica',
              },
            ],
          },
        ],
        totalEventos: 1,
        concluidos: 0,
        clientesUnicos: 1,
        consultantName: 'Agronomo Teste',
      );
    });

    await expectNoTemplateTokens('visita', () {
      return VisitaHtmlRenderer.render(
        relatorio: {
          'id': 'rel-1',
          'status': 'pendente_revisao',
          'title': 'Visita tecnica',
          'farmName': 'Fazenda Modelo',
          'periodStart': now.toIso8601String(),
          'periodEnd': now.add(const Duration(hours: 1)).toIso8601String(),
          'customNotes': 'Notas finais',
          'ocorrencias': [
            {
              'id': 'occ-1',
              'tipo': 'Insetos',
              'descricao': 'Lagarta em reboleira',
              'registradaEm': now.toIso8601String(),
            },
          ],
          'talhoes': [
            {
              'talhaoId': 'talhao-1',
              'nomeTalhao': 'Talhao Norte',
              'areaHectares': 12.4,
              'cultura': 'Soja',
              'safra': '2025/26',
            },
          ],
          'monitoramentos': [
            {
              'id': 'mon-1',
              'tipo': 'Fenologia',
              'dados': {'estadio': 'V4'},
              'coletadoEm': now.toIso8601String(),
            },
          ],
          'fotos': const <String>[],
          'publicacoesRefs': const ['pub-1'],
        },
        agronomistNome: 'Agronomo Teste',
        clienteNome: 'Cliente Teste',
        publicacoesTitulos: const {'pub-1': 'Manejo integrado'},
      );
    });

    await expectNoTemplateTokens('ocorrencia detalhada', () {
      return OcorrenciaHtmlRenderer.renderDetalhe({
        'id': 'occ-1',
        'type': 'Media',
        'description': 'Insetos no baixeiro',
        'category': 'insetos',
        'status': 'draft',
        'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
        'sync_status': 'local',
        'lat': -10.1,
        'long': -48.2,
      });
    });

    await expectNoTemplateTokens('lista de ocorrencias', () {
      return OcorrenciaHtmlRenderer.renderLista(
        clienteNome: 'Cliente Teste',
        fazendaNome: 'Fazenda Modelo',
        talhaoNome: 'Talhao Norte',
        agronomistNome: 'Agronomo Teste',
        dataVisita: now,
        visitSessionId: 'sess-1',
        ocorrencias: [
          {
            'id': 'occ-1',
            'type': 'Media',
            'description': 'Insetos no baixeiro',
            'category': 'insetos',
            'status': 'draft',
            'created_at': now.toIso8601String(),
            'updated_at': now.toIso8601String(),
            'sync_status': 'local',
          },
        ],
      );
    });

    await expectNoTemplateTokens('resumo propriedade', () {
      return PropriedadeHtmlRenderer.renderPropriedade(
        farmId: 'farm-1',
        farmNome: 'Fazenda Modelo',
        clienteNome: 'Cliente Teste',
        areaTotal: 200,
        municipio: 'Palmas',
        uf: 'TO',
        createdAt: now,
        updatedAt: now,
        fields: const [
          {
            'nome': 'Talhao Norte',
            'codigo': 'TN',
            'area_produtiva': 50.0,
            'centro_geo': '{}',
          },
        ],
      );
    });

    await expectNoTemplateTokens('historico visitas', () {
      return PropriedadeHtmlRenderer.renderHistorico(
        clienteNome: 'Cliente Teste',
        farmName: 'Fazenda Modelo',
        agronomistNomes: const {'agro-1': 'Agronomo Teste'},
        relatorios: [
          {
            'id': 'rel-1',
            'status': 'publicado',
            'title': 'Visita tecnica',
            'farm_name': 'Fazenda Modelo',
            'agronomist_id': 'agro-1',
            'period_start': now.toIso8601String(),
            'period_end': now.add(const Duration(hours: 1)).toIso8601String(),
            'ocorrencias': const [],
            'talhoes': const [],
            'fotos': const [],
            'publicacoes_refs': const [],
          },
        ],
      );
    });

    await expectNoTemplateTokens('marketing resultado', () {
      return MarketingHtmlRenderer.render(_marketingBase('resultado'));
    });

    await expectNoTemplateTokens('marketing antes/depois', () {
      return MarketingHtmlRenderer.render(_marketingBase('antes_depois'));
    });

    await expectNoTemplateTokens('marketing avaliacao', () {
      return MarketingHtmlRenderer.render({
        ..._marketingBase('avaliacao'),
        'nome_talhao': 'Talhao Norte',
        'tamanho_ha': 42.0,
        'conclusao_tecnica': 'Produto aprovado',
        'avaliacoes_json': jsonEncode([
          {
            'id': 'av-1',
            'titulo': 'Avaliação 1',
            'nome_lado_a': 'Testemunha',
            'nome_lado_b': 'Produto A',
            'cultura': 'Soja',
            'observacoes': 'Boa diferença visual.',
            'parametros': [
              {
                'id': 'p1',
                'titulo': 'Número de Grãos',
                'testemunha': 10,
                'teste': 12,
              },
            ],
          },
        ]),
      });
    });
  });

  test(
    'render visita inclui assinatura SoloForte unica e responsavel tecnico',
    () async {
      await initializeDateFormatting('pt_BR');

      final html = await VisitaHtmlRenderer.render(
        relatorio: {
          'id': 'rel-brand',
          'status': 'publicado',
          'title': 'Visita branding',
          'farmName': 'Fazenda Branding',
          'periodStart': now.toIso8601String(),
          'periodEnd': now.add(const Duration(hours: 2)).toIso8601String(),
          'customNotes': '',
          'ocorrencias': const [],
          'talhoes': const [],
          'monitoramentos': const [],
          'fotos': const <String>[],
          'publicacoesRefs': const <String>[],
        },
        agronomistNome: 'Agronomo Teste',
        clienteNome: 'Cliente Teste',
        publicacoesTitulos: const {},
        reportBrandName: 'Agro Forte Consultoria',
        consultantRole: 'Consultoria',
      );

      expect(html, isNot(contains('Agro Forte Consultoria')));
      expect(html, contains('SoloForte'));
      expect(html, contains('logo-img'));
      expect(html, contains('sf-brand-logo'));
      expect(html, contains('Responsável: Agronomo Teste · Consultoria'));
      expect(
        html,
        isNot(contains('Plataforma oficial de relatórios e exportação')),
      );
      expect(html, isNot(contains('footer-meta')));
      expect(html, isNot(contains('🌱')));
    },
  );

  test(
    'marketing: nenhum {{#if}} fica sem resolver (secao fantasma)',
    () async {
      await initializeDateFormatting('pt_BR');

      // Um bloco condicional nao resolvido sobrevive como `<!--  -->` depois de
      // stripUnresolvedPlaceholders, e o conteudo dele aparece sempre.
      for (final tipo in const ['resultado', 'antes_depois', 'avaliacao']) {
        final completo = await MarketingHtmlRenderer.render(
          _marketingBase(tipo),
        );
        expect(
          completo,
          isNot(contains('<!--  -->')),
          reason: '$tipo completo',
        );

        final minimo = await MarketingHtmlRenderer.render({
          'tipo': tipo,
          'produtor_fazenda': 'Cliente Teste - Fazenda Modelo',
          'produto_utilizado': 'Produto X',
          'visibilidade': 'publico',
          'status': 'publicado',
          'criado_em': '2026-06-03T12:00:00.000Z',
        });
        expect(minimo, isNot(contains('<!--  -->')), reason: '$tipo minimo');
      }
    },
  );

  test(
    'marketing: foto ausente tem fallback que independe de JavaScript',
    () async {
      await initializeDateFormatting('pt_BR');

      // O WebView do app roda com JavaScriptMode.disabled, entao o onerror do
      // <img> nunca dispara: o fallback precisa vir do proprio HTML/CSS.
      for (final tipo in const ['resultado', 'antes_depois']) {
        final html = await MarketingHtmlRenderer.render({
          ..._marketingBase(tipo),
          'foto_principal_url': null,
          'foto_antes_url': null,
          'foto_depois_url': null,
        });

        expect(html, contains('Sem foto'), reason: tipo);
        expect(html, isNot(contains('placeholder via onerror')), reason: tipo);
      }
    },
  );

  test('marketing: moeda e numeros em pt-BR com separador de milhar', () async {
    await initializeDateFormatting('pt_BR');

    final html = await MarketingHtmlRenderer.render({
      ..._marketingBase('resultado'),
      'prod_sem_produto': 1200.0,
      'prod_com_produto': 1450.0,
      'custo_produto_por_ha': 1890.5,
      'valor_grao': 110.0,
      'tamanho_ha': 1250.0,
    });

    expect(html, contains('R\$ 1.890,50'));
    expect(html, isNot(contains('R\$ 1890,50')));
    expect(html, contains('1.250,0'));
  });

  test('marketing: case minimo nao renderiza secao sem dado', () async {
    await initializeDateFormatting('pt_BR');

    final html = await MarketingHtmlRenderer.render({
      'tipo': 'resultado',
      'produtor_fazenda': 'Cliente Teste - Fazenda Modelo',
      'produto_utilizado': 'Produto X',
      'visibilidade': 'publico',
      'status': 'publicado',
      'criado_em': '2026-06-03T12:00:00.000Z',
    });

    expect(html, isNot(contains('Observações')));
    expect(html, isNot(contains('Responsável Comercial')));
  });

  test('marketing: localizacao inline exibe o texto real do case', () async {
    await initializeDateFormatting('pt_BR');

    for (final tipo in const ['resultado', 'antes_depois', 'avaliacao']) {
      final html = await MarketingHtmlRenderer.render({
        ..._marketingBase(tipo),
        'localizacao_texto': 'Fazenda Modelo · Palmas/TO',
      });

      expect(html, contains('Fazenda Modelo · Palmas/TO'), reason: tipo);
      expect(html, contains('📍'), reason: tipo);
    }
  });

  test('marketing: sem localizacao o pin nao fica orfao', () async {
    await initializeDateFormatting('pt_BR');

    for (final tipo in const ['resultado', 'antes_depois', 'avaliacao']) {
      for (final vazio in const ['', '   ']) {
        final html = await MarketingHtmlRenderer.render({
          ..._marketingBase(tipo),
          'localizacao_texto': vazio,
        });

        expect(html, isNot(contains('📍')), reason: '$tipo/"$vazio"');
        expect(
          html,
          isNot(contains('class="localizacao-inline"')),
          reason: tipo,
        );
        expect(html, isNot(contains('class="photo-caption"')), reason: tipo);
      }
    }
  });

  test(
    'ocorrencia detalhada: logo header, localizacao inline, sem meta rodape',
    () async {
      await initializeDateFormatting('pt_BR');

      final html = await OcorrenciaHtmlRenderer.renderDetalhe(
        {
          'id': 'occ-brand',
          'type': 'Média',
          'description': 'Ervas no baixeiro',
          'category': 'daninhas',
          'status': 'draft',
          'created_at': now.toIso8601String(),
          'updated_at': now.toIso8601String(),
          'sync_status': 'local',
          'lat': -10.1,
          'long': -48.2,
        },
        consultantName: 'perfil consultor',
        consultantRole: 'consultor',
      );

      expect(html, contains('logo-img'));
      expect(html, contains('SoloForte'));
      expect(html, contains('localizacao-inline'));
      expect(html, isNot(contains('localizacao-block')));
      expect(html, isNot(contains('footer-meta')));
      expect(html, isNot(contains('ID: OCC-BRAN')));
      expect(html, isNot(contains('Sync:')));
      expect(html, isNot(contains('⚠')));
      expect(html, isNot(contains('cat-emoji')));
    },
  );
}

Map<String, dynamic> _marketingBase(String tipo) {
  return {
    'tipo': tipo,
    'produtor_fazenda': 'Cliente Teste - Fazenda Modelo',
    'produto_utilizado': 'Produto X',
    'localizacao_texto': 'Palmas, TO',
    'visibilidade': 'publico',
    'produtividade_valor': 72,
    'produtividade_unidade': 'sc/ha',
    'quantidade_produzida': 1800,
    'economia_gerada': 'R\$ 12.000',
    'roi_calculado': 2.5,
    'roi_investimento': 10000,
    'roi_retorno': 25000,
    'prod_sem_produto': 60,
    'prod_com_produto': 64,
    'unidade_produtividade': 'sc/ha',
    'custo_produto_por_ha': 90,
    'valor_grao': 110,
    'tamanho_ha': 12.5,
    'area_total': 900,
    'parametros_json': jsonEncode([
      {
        'id': 'param-1',
        'titulo': 'Número de Grãos',
        'testemunha': 10,
        'teste': 12,
        'unidade': 'grãos/vagem',
      },
      {
        'id': 'param-2',
        'titulo': 'Vagens por Planta',
        'testemunha': 38,
        'teste': 47,
        'unidade': 'vagens/planta',
      },
    ]),
    'ganho_produtividade': '+12%',
    'descricao': 'Resultado validado em campo.',
    'lat': -10.1,
    'lng': -48.2,
    'nome_vendedor': 'Vendedor Teste',
    'telefone_vendedor': '(63) 99999-0000',
    'data_case': '2026-07-11T00:00:00.000Z',
    'criado_em': '2026-06-03T12:00:00.000Z',
    'status': 'publicado',
  };
}
