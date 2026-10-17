import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:soloforte_app/core/html_templates/marketing_html_renderer.dart';
import 'package:soloforte_app/core/html_templates/ocorrencia_html_renderer.dart';
import 'package:soloforte_app/core/html_templates/planejamento_html_renderer.dart';
import 'package:soloforte_app/core/html_templates/propriedade_html_renderer.dart';
import 'package:soloforte_app/core/html_templates/relatorio_html_renderer.dart';
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
    expect(html, isNot(contains('fonts.googleapis.com')), reason: type);
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

  test('ocorrencia detalhada: fotos ampliáveis, sem emoji, só Criado em e '
      'cliente/fazenda/talhão', () async {
    await initializeDateFormatting('pt_BR');

    final html = await OcorrenciaHtmlRenderer.renderDetalhe({
      'id': 'occ-lb',
      'type': 'Alta',
      'description': 'Lagarta no baixeiro',
      'category': 'insetos',
      'status': 'draft',
      'created_at': now.toIso8601String(),
      'updated_at': now.add(const Duration(days: 2)).toIso8601String(),
      'sync_status': 'local',
      'foto_base64': 'https://example.com/capa.jpg',
      'fotos_categorias_json': jsonEncode({
        'insetos': ['https://example.com/a.jpg', 'https://example.com/b.jpg'],
        'doenca': ['https://example.com/c.jpg'],
      }),
      'notas_categorias_json': jsonEncode({'insetos': 'Nota técnica'}),
      'metricas_json': jsonEncode({
        'insetos': {'severidade': 3},
      }),
      'cliente_nome': 'Produtor <Teste>',
      'fazenda_nome': 'Fazenda Norte',
      'talhao_nome': 'Talhão 7',
    });

    expect(html, isNot(contains(RegExp(r'\{\{[^}]+\}\}'))));

    expect(html, contains('id="sf-foto-hero" class="sf-lb-toggle"'));
    expect(html, contains('<label for="sf-foto-hero" class="photo-hero">'));
    expect(html, contains('Foto 1 · Insetos · 03/06/2026'));
    for (final n in [1, 2, 3]) {
      expect(
        RegExp('id="sf-foto-$n"').allMatches(html).length,
        1,
        reason: 'id sf-foto-$n deve ser único',
      );
      expect(html, contains('<label for="sf-foto-$n" class="galeria-foto">'));
      expect(html, contains('<figcaption>Foto ${n + 1}</figcaption>'));
    }
    expect(html, isNot(contains('id="sf-foto-4"')));
    expect(html, contains('.sf-lb-toggle:checked + label'));
    expect(html, isNot(contains('<div class="galeria-foto">')));

    for (final emoji in ['🐛', '🦠', '🌿', '🧪', '💧', '🪨', '🌾']) {
      expect(html, isNot(contains(emoji)), reason: emoji);
    }
    expect(html, isNot(contains('galeria-grupo-emoji')));
    expect(html, isNot(contains('nota-emoji')));

    expect(html, isNot(contains('Histórico')));
    expect(html, isNot(contains('Atualizado em')));
    expect(html, contains('sf-created-at">Criado em '));
    expect(
      html.indexOf('class="sf-created-at"'),
      lessThan(html.indexOf('<footer')),
    );

    expect(html, contains('Produtor &lt;Teste&gt;'));
    expect(html, contains('>Fazenda</span>'));
    expect(html, contains('Fazenda Norte'));
    expect(html, contains('>Talhão</span>'));
    expect(html, contains('Talhão 7'));
    expect(
      html,
      contains(
        'Produtor &lt;Teste&gt; · Fazenda Norte · Talhão 7 · 03/06/2026',
      ),
    );
  });

  group('documento editorial (pilotos)', () {
    final emoji = RegExp(
      r'[\u{1F300}-\u{1FAFF}\u{2600}-\u{27BF}]',
      unicode: true,
    );

    void expectEditorialDocument(String html, {required String reason}) {
      expect(html, isNot(contains('fonts.googleapis.com')), reason: reason);
      expect(html, isNot(contains('{{sf_base_css}}')), reason: reason);
      expect(html, isNot(contains(RegExp(r'\{\{[^}]+\}\}'))), reason: reason);
      expect(html, contains('.sf-letterhead'), reason: reason);
      expect(html, contains('class="sf-letterhead"'), reason: reason);
      expect(
        html,
        contains(RegExp(r'class="logo-img" src="data:image/png;base64,')),
        reason: reason,
      );
      expect(html, isNot(contains('invert(1)')), reason: reason);
      expect(html, isNot(contains('radial-gradient')), reason: reason);
      expect(html, isNot(contains('section-label-bar')), reason: reason);
      expect(
        html,
        isNot(contains('text-transform: uppercase')),
        reason: reason,
      );
      expect(html, isNot(contains(emoji)), reason: reason);
    }

    test(
      'ocorrencia detalhada usa base editorial sem rótulos técnicos',
      () async {
        await initializeDateFormatting('pt_BR');

        final html = await OcorrenciaHtmlRenderer.renderDetalhe(
          {
            'id': 'occ-editorial-1234',
            'type': 'Média',
            'description': 'Lagarta no baixeiro',
            'category': 'insetos',
            'status': 'draft',
            'created_at': now.toIso8601String(),
            'lat': -10.1,
            'long': -48.2,
            'recomendacoes': 'Aplicar inseticida biológico.',
            'nutrientes_json': jsonEncode(['N', 'K']),
            'cliente_nome': 'Cliente Teste',
          },
          consultantName: 'Agronomo Teste',
          consultantRole: 'Consultoria',
        );

        expectEditorialDocument(html, reason: 'ocorrencia');
        expect(html, contains('Relatório de ocorrência'));
        expect(html, contains('Urgência média'));
        expect(html, contains('Rascunho'));
        expect(html, isNot(contains(RegExp(r'>\s*draft\s*<'))));
        expect(html, isNot(contains('#OCC-EDIT')));
        expect(html, isNot(contains('OCC-EDIT')));
        expect(html, contains('Ponto registrado no mapa'));
        expect(html, isNot(contains('-10.1')));
        expect(html, contains('<p class="sf-prose">N, K</p>'));
        expect(html, isNot(contains('nutriente-badge')));
        expect(html, contains('class="sf-callout"'));
        expect(html, contains('class="sf-signature"'));
        expect(html, contains('Agronomo Teste'));
        expect(
          html.indexOf('class="sf-signature"'),
          lessThan(html.indexOf('<footer')),
        );
      },
    );

    test('ocorrencia confirmada mostra situação por extenso', () async {
      await initializeDateFormatting('pt_BR');

      final html = await OcorrenciaHtmlRenderer.renderDetalhe({
        'id': 'occ-conf',
        'type': 'Alta',
        'category': 'doenca',
        'status': 'confirmed',
        'created_at': now.toIso8601String(),
      });

      expect(html, contains('Confirmada'));
      expect(html, contains('Urgência alta'));
      expect(html, isNot(contains(RegExp(r'>\s*confirmed\s*<'))));
      expect(html, isNot(contains('class="sf-signature"')));
    });

    test('relatorio visita usa base editorial e preserva dados', () async {
      await initializeDateFormatting('pt_BR');

      final html = await VisitaHtmlRenderer.render(
        relatorio: {
          'id': 'rel-editorial',
          'status': 'publicado',
          'title': 'Visita técnica',
          'farmName': 'Fazenda Modelo',
          'periodStart': now.toIso8601String(),
          'periodEnd': now.add(const Duration(hours: 1)).toIso8601String(),
          'customNotes': 'Notas finais',
          'ocorrencias': [
            {
              'id': 'occ-1',
              'tipo': 'Insetos',
              'descricao': 'Lagarta em reboleira',
              'severity': 'moderada',
              'recomendacoes': 'Monitorar em 7 dias',
              'lat': -10.1234,
              'lng': -48.5678,
              'registradaEm': now.toIso8601String(),
            },
          ],
          'talhoes': [
            {
              'talhaoId': 'talhao-1',
              'nomeTalhao': 'Talhao Norte',
              'areaHectares': 42.0,
              'cultura': 'Soja',
              'safra': '2025/26',
            },
          ],
          'monitoramentos': [
            {
              'id': 'mon-1',
              'tipo': 'Fenologia',
              'dados': {'estadio': 'V4', 'altura_cm': 38},
              'coletadoEm': now.toIso8601String(),
            },
          ],
          'fotos': const <String>[],
          'publicacoesRefs': const ['pub-1'],
        },
        agronomistNome: 'Agronomo Teste',
        clienteNome: 'Cliente Teste',
        publicacoesTitulos: const {'pub-1': 'Manejo integrado'},
        consultantRole: 'Consultoria',
      );

      expectEditorialDocument(html, reason: 'visita');
      expect(html, contains('Relatório de visita'));
      expect(html, contains('Visita técnica'));
      expect(html, contains('Fazenda Modelo · Cliente Teste · 03/06/2026'));
      expect(html, contains('Publicado'));
      expect(html, contains('Talhao Norte'));
      expect(html, contains('Cultura: Soja · Safra: 2025/26'));
      expect(html, contains('42,0 ha'));
      expect(html, contains('Lagarta em reboleira'));
      expect(html, contains('Monitorar em 7 dias'));
      expect(html, contains('Moderada'));
      expect(html, contains('Ponto registrado no mapa'));
      expect(html, isNot(contains('-10.1234')));
      expect(html, contains('Fenologia'));
      expect(html, contains('V4'));
      expect(html, isNot(contains('>estadio<')));
      expect(html, isNot(contains('>altura_cm<')));
      expect(html, contains('>Estádio<'));
      expect(html, contains('>Altura (cm)<'));
      expect(html, contains('>38<'));
      expect(html, contains('Manejo integrado'));
      expect(html, contains('Notas finais'));
      expect(html, contains('class="sf-signature"'));
      expect(html, isNot(contains('talhao-chip')));
      expect(html, isNot(contains('publicacao-badge')));
    });
  });

  test('humanizeKey converte chaves técnicas em rótulos legíveis', () {
    expect(RelatorioHtmlRenderer.humanizeKey('estadio'), 'Estádio');
    expect(RelatorioHtmlRenderer.humanizeKey('altura_cm'), 'Altura (cm)');
    expect(
      RelatorioHtmlRenderer.humanizeKey('incidencia_pct'),
      'Incidência (%)',
    );
    expect(RelatorioHtmlRenderer.humanizeKey('area_ha'), 'Área (ha)');
    expect(
      RelatorioHtmlRenderer.humanizeKey('plantas_por_metro'),
      'Plantas por metro',
    );
    expect(RelatorioHtmlRenderer.humanizeKey('severidade'), 'Severidade');
  });

  test(
    'base CSS de impressão não força a lista agrupada inteira na página',
    () {
      final css = File(
        'assets/html_templates/_sf_document_base.css',
      ).readAsStringSync();
      final printBlock = css.substring(css.indexOf('@media print'));
      final avoidRule = RegExp(
        r'([^{}]+)\{[^}]*page-break-inside:\s*avoid',
      ).firstMatch(printBlock);
      expect(avoidRule, isNotNull);
      final selectors = avoidRule!.group(1)!;
      expect(selectors, isNot(contains('.sf-sheet')));
      for (final selector in [
        '.sf-row',
        '.sf-item',
        '.sf-figure',
        '.sf-callout',
        '.sf-signature',
      ]) {
        expect(selectors, contains(selector));
      }
    },
  );

  test(
    'ocorrencia detalhada oculta cards de cliente/fazenda/talhão vazios',
    () async {
      await initializeDateFormatting('pt_BR');

      final html = await OcorrenciaHtmlRenderer.renderDetalhe({
        'id': 'occ-sem-local',
        'type': 'Baixa',
        'category': 'doenca',
        'created_at': now.toIso8601String(),
        'cliente_nome': '',
      });

      expect(html, isNot(contains('>Cliente</span>')));
      expect(html, isNot(contains('>Fazenda</span>')));
      expect(html, isNot(contains('>Talhão</span>')));
      expect(html, contains('>Categoria</span>'));
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
