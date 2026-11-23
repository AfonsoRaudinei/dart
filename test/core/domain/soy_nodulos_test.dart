import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:soloforte_app/core/domain/soy_nodulos.dart';
import 'package:soloforte_app/core/html_templates/ocorrencia_html_renderer.dart';
import 'package:soloforte_app/modules/consultoria/occurrences/domain/occurrence.dart';

void main() {
  test('valor salvo é posição + 1; 0 e inválidos não têm rótulo', () {
    expect(nodulosValueLabel(kNodulosQuantidade, 1), 'Poucos (<10)');
    expect(nodulosValueLabel(kNodulosCor, 1), 'Rosa/vermelho');
    expect(nodulosValueLabel(kNodulosDistribuicao, 3), 'Mista');
    expect(nodulosValueLabel(kNodulosCor, 0), isNull);
    expect(nodulosValueLabel(kNodulosCor, 4), isNull);
    expect(nodulosValueLabel('incidencia', 2), isNull);
  });

  test('todas as chaves têm título e opções', () {
    for (final key in kNodulosKeys) {
      expect(kNodulosTitles[key], isNotEmpty);
      expect(kNodulosOptions[key], hasLength(3));
    }
  });

  test('categoria nodulos é reconhecida e não cai em doença', () {
    for (final raw in ['nodulos', 'Nódulos', 'nodulacao']) {
      expect(OccurrenceCategory.fromString(raw), OccurrenceCategory.nodulos);
    }
    expect(OccurrenceCategory.nodulos.label, 'Nódulos');
  });

  group('relatório HTML', () {
    TestWidgetsFlutterBinding.ensureInitialized();
    setUpAll(() async => initializeDateFormatting('pt_BR'));

    test('mostra o texto da escolha, não barras', () async {
      final html = await OcorrenciaHtmlRenderer.renderDetalhe({
        'id': 'occ-nodulos',
        'type': 'Baixa',
        'description': 'teste',
        'category': 'nodulos',
        'status': 'draft',
        'created_at': DateTime.utc(2026, 10, 15).toIso8601String(),
        'updated_at': DateTime.utc(2026, 10, 15).toIso8601String(),
        'sync_status': 'local',
        'metricas_json': jsonEncode({
          'nodulos': {
            'quantidade': 2,
            'cor': 1,
            'distribuicao': 0,
            'avaliacao': 1,
          },
        }),
        'notas_categorias_json': jsonEncode({
          'nodulos': 'Inoculante líquido no sulco',
        }),
      });
      expect(html, contains('Nódulos por planta'));
      expect(html, contains('Bom (10–30)'));
      expect(html, contains('Cor por dentro'));
      expect(html, contains('Rosa/vermelho'));
      expect(html, isNot(contains('Onde estão')));
      expect(html, contains('Avaliação geral'));
      expect(html, contains('Inoculante líquido no sulco'));
    });
  });
}
