import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:soloforte_app/core/html_templates/marketing_html_renderer.dart';
import 'package:soloforte_app/core/html_templates/ocorrencia_html_renderer.dart';
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
        'conclusao': 'Produto aprovado',
        'avaliacoes': const [
          {
            'layout': 'duas_fotos',
            'lado_a_label': 'Antes',
            'lado_b_label': 'Depois',
            'lado_a_cultura': 'Soja',
            'lado_b_cultura': 'Soja',
            'lado_a_obs': 'Sem tratamento',
            'lado_b_obs': 'Com tratamento',
          },
        ],
      });
    });
  });

  test(
    'render visita inclui branding customizado e assinatura SoloForte',
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

      expect(html, contains('Agro Forte Consultoria'));
      expect(html, contains('SoloForte'));
      expect(html, contains('Plataforma oficial de relatórios e exportação'));
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
    'ganho_produtividade': '+12%',
    'descricao': 'Resultado validado em campo.',
    'lat': -10.1,
    'lng': -48.2,
    'nome_vendedor': 'Vendedor Teste',
    'telefone_vendedor': '(63) 99999-0000',
    'criado_em': '2026-06-03T12:00:00.000Z',
    'status': 'publicado',
  };
}
