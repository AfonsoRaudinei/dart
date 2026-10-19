import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:soloforte_app/core/html_templates/combinado_html_renderer.dart';
import 'package:soloforte_app/core/html_templates/marketing_html_renderer.dart';
import 'package:soloforte_app/core/html_templates/ocorrencia_html_renderer.dart';
import 'package:soloforte_app/core/html_templates/relatorio_html_renderer.dart';
import 'package:soloforte_app/core/html_templates/visita_html_renderer.dart';

import '../../support/path_provider_test_bindings.dart';

void main() {
  installPathProviderTestBindings();

  final older = DateTime.utc(2026, 1, 10, 12);
  final newer = DateTime.utc(2026, 6, 3, 12);

  setUpAll(() async {
    await initializeDateFormatting('pt_BR');
  });

  Future<String> visitaFragment({required DateTime at, required String title}) {
    return VisitaHtmlRenderer.render(
      relatorio: {
        'id': 'rel-$title',
        'status': 'publicado',
        'title': title,
        'farmName': 'Fazenda Modelo',
        'periodStart': at.toIso8601String(),
        'periodEnd': at.add(const Duration(hours: 1)).toIso8601String(),
        'customNotes': 'Notas da visita',
        'ocorrencias': const [],
        'talhoes': const [],
        'monitoramentos': const [],
        'fotos': const <String>[],
        'publicacoesRefs': const <String>[],
      },
      agronomistNome: 'Agronomo Teste',
      clienteNome: 'Cliente Teste',
      publicacoesTitulos: const {},
      asFragment: true,
    );
  }

  Future<String> ocorrenciaFragment({required DateTime at}) {
    return OcorrenciaHtmlRenderer.renderDetalhe({
      'id': 'occ-1',
      'type': 'Media',
      'description': 'Insetos no baixeiro',
      'category': 'insetos',
      'status': 'confirmed',
      'created_at': at.toIso8601String(),
      'updated_at': at.toIso8601String(),
      'sync_status': 'local',
    }, asFragment: true);
  }

  test('asFragment de visita e ocorrência não traz letterhead nem rodapé', () async {
    final visita = await visitaFragment(at: newer, title: 'Visita fragmento');
    final occ = await ocorrenciaFragment(at: older);

    for (final html in [visita, occ]) {
      expect(html, isNotEmpty);
      expect(html, isNot(contains('sf-letterhead')));
      expect(html, isNot(contains('sf-footer')));
      expect(html, isNot(contains('<!DOCTYPE')));
      expect(html, isNot(contains(RegExp(r'\{\{[^}]+\}\}'))));
    }
  });

  test('combinado tem um letterhead, um rodapé e capítulos em ordem crescente', () async {
    final occFragment = await ocorrenciaFragment(at: older);
    final visitaFragmentHtml = await visitaFragment(
      at: newer,
      title: 'Visita recente',
    );

    final html = await CombinadoHtmlRenderer.render(
      clienteNome: 'Cliente Teste',
      consultantName: 'Agronomo Teste',
      consultantRole: 'Consultoria',
      chapters: [
        CombinadoHtmlChapter(
          kind: 'visita',
          occurredAt: newer,
          title: 'Visita recente',
          fragmentHtml: visitaFragmentHtml,
        ),
        CombinadoHtmlChapter(
          kind: 'ocorrencia',
          occurredAt: older,
          title: 'Insetos',
          fragmentHtml: occFragment,
        ),
      ],
    );

    expect(html, isNot(contains(RegExp(r'\{\{[^}]+\}\}'))));
    expect('class="sf-letterhead"'.allMatches(html).length, 1);
    expect('class="sf-footer"'.allMatches(html).length, 1);
    expect(html, contains('Relatório combinado'));
    expect(html, contains('Cliente Teste'));

    final letterhead = html.substring(
      html.indexOf('<header class="sf-letterhead">'),
      html.indexOf('</header>'),
    );
    expect(letterhead, isNot(contains('<img')));
    expect(letterhead, isNot(contains('SoloForte')));

    final footer = html.substring(
      html.indexOf('<footer class="sf-footer">'),
      html.indexOf('</footer>'),
    );
    expect(footer, contains('<strong>SoloForte</strong>'));

    final firstKind = RegExp(r'data-kind="([^"]+)"').firstMatch(html)!.group(1);
    expect(firstKind, 'ocorrencia');
    final kinds = RegExp(r'data-kind="([^"]+)"')
        .allMatches(html)
        .map((m) => m.group(1))
        .toList();
    expect(kinds, ['ocorrencia', 'visita']);

    final chaptersHtml = html.substring(
      html.indexOf('<article class="sf-chapter"'),
      html.lastIndexOf('</article>') + '</article>'.length,
    );
    expect(chaptersHtml, isNot(contains('<header class="sf-letterhead"')));
    expect(chaptersHtml, isNot(contains('<footer class="sf-footer"')));
    expect(html, contains('class="sf-toc"'));
    expect(html, contains('href="#capitulo-1"'));
    expect(html, contains('id="capitulo-1"'));
    expect(html, contains('id="capitulo-2"'));
  });

  test('combinado com um capítulo não exibe sumário', () async {
    final html = await CombinadoHtmlRenderer.render(
      clienteNome: 'Cliente Teste',
      chapters: [
        CombinadoHtmlChapter(
          kind: 'visita',
          occurredAt: newer,
          title: 'Única visita',
          fragmentHtml: '<p>Miolo</p>',
        ),
      ],
    );
    expect(html, isNot(contains('class="sf-toc"')));
    expect(html, contains('id="capitulo-1"'));
  });

  test('sortChronologically usa data crescente e desempate por tipo', () {
    final same = DateTime.utc(2026, 4, 1);
    final sorted = CombinadoHtmlRenderer.sortChronologically([
      CombinadoHtmlChapter(
        kind: 'resultado',
        occurredAt: same,
        title: 'R',
        fragmentHtml: '',
      ),
      CombinadoHtmlChapter(
        kind: 'visita',
        occurredAt: same,
        title: 'V',
        fragmentHtml: '',
      ),
      CombinadoHtmlChapter(
        kind: 'ocorrencia',
        occurredAt: same,
        title: 'O',
        fragmentHtml: '',
      ),
    ]);
    expect(sorted.map((c) => c.kind).toList(), [
      'visita',
      'ocorrencia',
      'resultado',
    ]);
  });

  test('capítulo marketing no combinado mantém CSS de vitrine .mk-*', () async {
    final fragment = await MarketingHtmlRenderer.render({
      'tipo': 'resultado',
      'produtor_fazenda': 'Fazenda Marketing',
      'quantidade_produzida': 120,
      'produtividade_unidade': 'sc',
    }, asFragment: true);

    expect(fragment, contains('class="mk-figures"'));
    expect(fragment, isNot(contains('sf-letterhead')));
    expect(fragment, isNot(contains('sf-footer')));

    final html = await CombinadoHtmlRenderer.render(
      clienteNome: 'Cliente Teste',
      chapters: [
        CombinadoHtmlChapter(
          kind: 'resultado',
          occurredAt: older,
          title: 'Fazenda Marketing',
          fragmentHtml: fragment,
        ),
      ],
    );

    expect('class="sf-letterhead"'.allMatches(html).length, 1);
    expect('class="sf-footer"'.allMatches(html).length, 1);
    expect(html, contains('.mk-figures'));
    expect(html, contains('.mk-lead-value'));
    expect(html, contains('class="mk-figures"'));
  });

  test('completeRender fragment vs documento', () {
    const raw = '''
<!DOCTYPE html><html><body>
<header class="sf-letterhead">Cabeçalho</header>
<main><p>Miolo</p></main>
<footer class="sf-footer">Rodapé</footer>
</body></html>
''';
    expect(RelatorioHtmlRenderer.extractMainFragment(raw), '<p>Miolo</p>');
    expect(
      RelatorioHtmlRenderer.completeRender(raw, asFragment: true),
      '<p>Miolo</p>',
    );
  });
}
