import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:soloforte_app/core/html_templates/ocorrencia_html_renderer.dart';
import 'package:soloforte_app/core/html_templates/relatorio_html_renderer.dart';

void main() {
  group('nivelBar', () {
    test('acende os segmentos pedidos na cor do nível', () {
      final html = RelatorioHtmlRenderer.nivelBar(
        filled: 2,
        total: 3,
        cor: 'laranja',
      );
      expect(html, contains('sf-bar-laranja'));
      expect(RegExp('sf-bar-seg on').allMatches(html).length, 2);
      expect(RegExp('sf-bar-seg"').allMatches(html).length, 1);
    });

    test('corIntensidade: verde, amarelo, laranja e vermelho', () {
      expect([0, 1, 2, 3].map(RelatorioHtmlRenderer.corIntensidade).toList(), [
        'verde',
        'amarelo',
        'laranja',
        'vermelho',
      ]);
    });
  });

  group('relatório de ocorrência', () {
    TestWidgetsFlutterBinding.ensureInitialized();
    setUpAll(() async => initializeDateFormatting('pt_BR'));

    Map<String, dynamic> dados(String urgencia) => {
      'id': 'occ-barras',
      'type': urgencia,
      'description': 'teste',
      'category': 'insetos',
      'status': 'draft',
      'created_at': DateTime.utc(2026, 10, 15).toIso8601String(),
      'updated_at': DateTime.utc(2026, 10, 15).toIso8601String(),
      'sync_status': 'local',
      'metricas_json': jsonEncode({
        'insetos': {'incidencia': 1, 'severidade': 3},
      }),
    };

    test('urgência alta ganha barra vermelha de 3 segmentos', () async {
      final html = await OcorrenciaHtmlRenderer.renderDetalhe(dados('Alta'));
      expect(html, contains('sf-bar sf-bar-vermelho'));
      expect(html, isNot(contains(RegExp(r'\{\{[^}]+\}\}'))));
    });

    test('urgência baixa é verde e média é laranja', () async {
      expect(
        await OcorrenciaHtmlRenderer.renderDetalhe(dados('Baixa')),
        contains('sf-bar sf-bar-verde'),
      );
      expect(
        await OcorrenciaHtmlRenderer.renderDetalhe(dados('Média')),
        contains('sf-bar sf-bar-laranja'),
      );
    });

    test('métricas 0–3 viram barra amarela/vermelha com rótulo', () async {
      final html = await OcorrenciaHtmlRenderer.renderDetalhe(dados('Baixa'));
      expect(html, contains('sf-bar sf-bar-amarelo'));
      expect(html, contains('sf-bar sf-bar-vermelho'));
      expect(html, contains('Alta</span>'));
    });
  });
}
