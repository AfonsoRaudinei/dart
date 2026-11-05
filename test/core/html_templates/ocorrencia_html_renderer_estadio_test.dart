import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:soloforte_app/core/html_templates/ocorrencia_html_renderer.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final now = DateTime.utc(2026, 10, 15, 14, 1);

  Map<String, dynamic> ocorrencia() => {
    'id': 'occ-estadio',
    'type': 'Baixa',
    'description': 'daninhas na linha',
    'category': 'ervas_daninhas',
    'status': 'draft',
    'created_at': now.toIso8601String(),
    'updated_at': now.toIso8601String(),
    'sync_status': 'local',
    'estadio_fenologico': 'V3',
  };

  setUpAll(() async {
    await initializeDateFormatting('pt_BR');
  });

  test(
    'com label e atenção exibe nome do estádio e seção de atenção',
    () async {
      final data = ocorrencia()
        ..['estadio_fenologico_label'] = 'V3 - 3ª Trifoliolada'
        ..['estadio_atencao'] = [
          'Período crítico para competição com daninhas',
          'Crescimento radicular ativo',
        ];

      final html = await OcorrenciaHtmlRenderer.renderDetalhe(data);

      expect(html, contains('V3 - 3ª Trifoliolada'));
      expect(html, contains('Atenção neste estádio'));
      expect(
        html,
        contains('<li>Período crítico para competição com daninhas</li>'),
      );
      expect(html, contains('<li>Crescimento radicular ativo</li>'));
      expect(html, isNot(contains('⚠')));
      expect(html, isNot(contains(RegExp(r'\{\{[^}]+\}\}'))));
    },
  );

  test('aceita lista de atenção como String JSON', () async {
    final data = ocorrencia()
      ..['estadio_atencao'] = '["Demanda hídrica aumentando"]';

    final html = await OcorrenciaHtmlRenderer.renderDetalhe(data);

    expect(html, contains('Atenção neste estádio'));
    expect(html, contains('<li>Demanda hídrica aumentando</li>'));
  });

  test('sem atenção a seção fica ausente e o código é mantido', () async {
    final html = await OcorrenciaHtmlRenderer.renderDetalhe(ocorrencia());

    expect(html, isNot(contains('Atenção neste estádio')));
    expect(html, contains('<span class="sf-row-value">V3</span>'));
    expect(html, isNot(contains(RegExp(r'\{\{[^}]+\}\}'))));
  });

  test('lista vazia não renderiza a seção', () async {
    final data = ocorrencia()..['estadio_atencao'] = <String>[];

    final html = await OcorrenciaHtmlRenderer.renderDetalhe(data);

    expect(html, isNot(contains('Atenção neste estádio')));
  });

  test('itens de atenção são escapados', () async {
    final data = ocorrencia()
      ..['estadio_atencao'] = ['<script>alert(1)</script> & cia'];

    final html = await OcorrenciaHtmlRenderer.renderDetalhe(data);

    expect(html, isNot(contains('<script>alert(1)</script>')));
    expect(html, contains('&lt;script&gt;'));
    expect(html, contains('&amp; cia'));
  });
}
