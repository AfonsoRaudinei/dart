import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:soloforte_app/core/html_templates/ocorrencia_html_renderer.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final now = DateTime.utc(2026, 10, 15, 14, 1);

  Map<String, dynamic> ocorrencia() => {
    'id': 'occ-historico',
    'type': 'Média',
    'description': 'Ferrugem',
    'category': 'doenca',
    'status': 'draft',
    'created_at': now.toIso8601String(),
    'updated_at': now.toIso8601String(),
    'sync_status': 'local_only',
    'cliente_nome': 'Produtor',
    'fazenda_nome': 'Fazenda Sul',
    'talhao_nome': 'Talhão 7',
  };

  setUpAll(() async {
    await initializeDateFormatting('pt_BR');
  });

  test('inclui a linha factual quando o histórico vem preenchido', () async {
    final data = ocorrencia()
      ..['historico_talhao_linha'] =
          'Ferrugem apareceu 3 vezes; a última em R5.';

    final html = await OcorrenciaHtmlRenderer.renderDetalhe(data);

    expect(html, contains('class="sf-caption"'));
    expect(html, contains('Ferrugem apareceu 3 vezes; a última em R5.'));
    expect(html, isNot(contains('historico_talhao_linha')));
    expect(html, isNot(contains(RegExp(r'\{\{[^}]+\}\}'))));
  });

  test('omite a legenda quando o histórico está vazio', () async {
    final html = await OcorrenciaHtmlRenderer.renderDetalhe(ocorrencia());

    expect(html, isNot(contains('class="sf-caption"')));
    expect(html, isNot(contains('apareceu')));
    expect(html, isNot(contains(RegExp(r'\{\{[^}]+\}\}'))));
  });

  test('escapa o texto da linha', () async {
    final data = ocorrencia()
      ..['historico_talhao_linha'] = 'Ferrugem <b> & cia apareceu';

    final html = await OcorrenciaHtmlRenderer.renderDetalhe(data);

    expect(html, isNot(contains('<b>')));
    expect(html, contains('Ferrugem &lt;b&gt; &amp; cia apareceu'));
  });
}
