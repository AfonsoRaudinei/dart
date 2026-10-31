import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:soloforte_app/core/html_templates/ocorrencia_html_renderer.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final now = DateTime.utc(2026, 9, 21, 16, 19);

  Map<String, dynamic> areaVisitada(String category) => {
        'id': 'occ-area',
        'type': 'Média',
        'description': 'sede',
        'category': category,
        'status': 'draft',
        'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
        'sync_status': 'local',
        'lat': -10.18,
        'long': -48.88,
        'cliente_nome': 'Adriano Gomes',
        'fazenda_nome': 'Morro Verde',
        'foto_base64': 'https://example.com/capa.jpg',
      };

  for (final category in ['area_visitada', 'areaVisitada']) {
    test('área visitada ($category): só produtor + localização + assinatura',
        () async {
      await initializeDateFormatting('pt_BR');

      final html = await OcorrenciaHtmlRenderer.renderDetalhe(
        areaVisitada(category),
        consultantName: 'RAUDINEI Afonso',
        consultantRole: 'consultor',
      );

      expect(html, contains('Relatório de área visitada'));
      expect(html, contains('Adriano Gomes'));
      expect(html, contains('Produtor'));
      expect(html, contains('class="sf-map-link"'));
      expect(html, contains('Localização'));
      expect(html, contains('RAUDINEI Afonso'));
      expect(html, contains('Emitido em'));
      expect(html, contains('Criado em'));
      expect(html, contains('sf-footer'));
      expect(html, contains('SoloForte'));

      expect(html, isNot(contains('Urgência')));
      expect(html, isNot(contains('Ficha técnica')));
      expect(html, isNot(contains('Descrição')));
      expect(html, isNot(contains('>sede<')));
      expect(html, isNot(contains('Morro Verde')));
      expect(html, isNot(contains('<img data-sf-photo')));
      expect(html, isNot(contains('<span class="sf-section-num">')));
      expect(html, isNot(contains(RegExp(r'\{\{[^}]+\}\}'))));
    });
  }

  test('área visitada sem produtor e sem ponto omite as linhas', () async {
    await initializeDateFormatting('pt_BR');

    final data = areaVisitada('area_visitada')
      ..remove('cliente_nome')
      ..remove('lat')
      ..remove('long');
    final html = await OcorrenciaHtmlRenderer.renderDetalhe(data);

    expect(html, isNot(contains('Produtor')));
    expect(html, isNot(contains('class="sf-map-link"')));
    expect(html, isNot(contains(RegExp(r'\{\{[^}]+\}\}'))));
  });

  test('outras categorias continuam no template detalhado', () async {
    await initializeDateFormatting('pt_BR');

    final html = await OcorrenciaHtmlRenderer.renderDetalhe(
      areaVisitada('insetos'),
    );

    expect(html, contains('Relatório de ocorrência'));
    expect(html, contains('Urgência'));
    expect(html, isNot(contains('Relatório de área visitada')));
  });
}
