import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:soloforte_app/core/html_templates/visita_html_renderer.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await initializeDateFormatting('pt_BR');
  });

  test('HTML inclui NDVI quando talhao tem ndviImageSrc', () async {
    const dataUri =
        'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==';
    final html = await VisitaHtmlRenderer.render(
      relatorio: {
        'id': 'rel-ndvi',
        'status': 'pendente_revisao',
        'farmName': 'Fazenda',
        'periodStart': DateTime.utc(2026, 6, 3).toIso8601String(),
        'periodEnd': DateTime.utc(2026, 6, 3, 2).toIso8601String(),
        'talhoes': [
          {
            'talhaoId': 't1',
            'nomeTalhao': 'Norte',
            'ndviImageSrc': dataUri,
            'ndviCaption': '0.62 · 12/09 · Sentinel',
          },
        ],
        'ocorrencias': const [],
        'monitoramentos': const [],
        'fotos': const [],
        'publicacoesRefs': const [],
      },
      agronomistNome: 'Agrônomo',
      clienteNome: 'Cliente',
      publicacoesTitulos: const {},
    );

    expect(html, contains('sf-ndvi-figure'));
    expect(html, contains(dataUri));
    expect(html, contains('0.62 · 12/09 · Sentinel'));
  });

  test('HTML omite clima quando climaManual ausente ou vazio', () async {
    final base = {
      'id': 'rel-clima',
      'status': 'pendente_revisao',
      'farmName': 'Fazenda',
      'periodStart': DateTime.utc(2026, 6, 3).toIso8601String(),
      'periodEnd': DateTime.utc(2026, 6, 3, 2).toIso8601String(),
      'talhoes': const [],
      'ocorrencias': const [],
      'monitoramentos': const [],
      'fotos': const [],
      'publicacoesRefs': const [],
    };

    final without = await VisitaHtmlRenderer.render(
      relatorio: base,
      agronomistNome: 'Agrônomo',
      clienteNome: 'Cliente',
      publicacoesTitulos: const {},
    );
    expect(without, isNot(contains('Clima (próximos dias)')));

    final empty = await VisitaHtmlRenderer.render(
      relatorio: {
        ...base,
        'climaManual': {'dias': [], 'pulverizacaoNota': ''},
      },
      agronomistNome: 'Agrônomo',
      clienteNome: 'Cliente',
      publicacoesTitulos: const {},
    );
    expect(empty, isNot(contains('Clima (próximos dias)')));

    final withClima = await VisitaHtmlRenderer.render(
      relatorio: {
        ...base,
        'climaManual': {
          'dias': [
            {'resumo': 'Chuva à tarde'},
          ],
          'pulverizacaoNota': 'Aplicar cedo',
        },
      },
      agronomistNome: 'Agrônomo',
      clienteNome: 'Cliente',
      publicacoesTitulos: const {},
    );
    expect(withClima, contains('Clima (próximos dias)'));
    expect(withClima, contains('Chuva à tarde'));
    expect(withClima, contains('Aplicar cedo'));
  });
}
