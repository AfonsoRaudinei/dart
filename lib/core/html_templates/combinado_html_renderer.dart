import 'relatorio_html_renderer.dart';

/// Capítulo de um relatório combinado: miolo de um tipo existente, sem envelope.
class CombinadoHtmlChapter {
  final String kind;
  final DateTime occurredAt;
  final String title;
  final String fragmentHtml;

  const CombinadoHtmlChapter({
    required this.kind,
    required this.occurredAt,
    required this.title,
    required this.fragmentHtml,
  });
}

/// R-COMBINADO-PRODUTOR — um letterhead, capítulos em ordem cronológica.
class CombinadoHtmlRenderer {
  static Future<String> render({
    required String clienteNome,
    required List<CombinadoHtmlChapter> chapters,
    String? reportBrandName,
    String? reportLogoPath,
    String? consultantName,
    String? consultantRole,
  }) async {
    var tpl = await RelatorioHtmlRenderer.loadTemplate(
      'relatorio_combinado.html',
    );
    final branding = await RelatorioHtmlRenderer.brandingPlaceholders(
      customBrandName: reportBrandName,
      customLogoPath: reportLogoPath,
      consultantName: consultantName,
      consultantRole: consultantRole,
    );

    final sorted = sortChronologically(chapters);
    final dates = sorted.map((c) => c.occurredAt).toList();
    final periodoInicio = dates.isNotEmpty
        ? RelatorioHtmlRenderer.formatDate(dates.first)
        : '';
    final periodoFim = dates.isNotEmpty
        ? RelatorioHtmlRenderer.formatDate(dates.last)
        : '';
    final periodo = periodoInicio.isEmpty
        ? ''
        : periodoInicio == periodoFim
        ? periodoInicio
        : '$periodoInicio – $periodoFim';
    final contextoLinha = [
      if (periodo.isNotEmpty) periodo,
      if (sorted.isNotEmpty)
        '${sorted.length} ${sorted.length == 1 ? 'relatório' : 'relatórios'}',
    ].join(' · ');
    final consultant = consultantName?.trim() ?? '';
    final role = consultantRole?.trim() ?? '';

    final capitulosHtml = sorted.isEmpty
        ? '<p class="sf-muted">Nenhum relatório selecionado para combinar.</p>'
        : sorted.map(_renderChapter).join('\n');

    tpl = RelatorioHtmlRenderer.replacePlaceholders(tpl, {
      ...branding,
      'cliente_nome': RelatorioHtmlRenderer.escapeHtml(clienteNome),
      'contexto_linha': contextoLinha,
      'capitulos_html': capitulosHtml,
      'consultant_nome': RelatorioHtmlRenderer.escapeHtml(consultant),
      'consultant_role': RelatorioHtmlRenderer.escapeHtml(role),
      'emitido_em': RelatorioHtmlRenderer.formatDate(DateTime.now()),
    });

    tpl = RelatorioHtmlRenderer.resolveIfBlock(
      tpl,
      'contexto_linha',
      include: contextoLinha.isNotEmpty,
    );
    tpl = RelatorioHtmlRenderer.resolveIfBlock(
      tpl,
      'consultant_nome',
      include: consultant.isNotEmpty,
    );
    tpl = RelatorioHtmlRenderer.resolveIfBlock(
      tpl,
      'consultant_role',
      include: role.isNotEmpty,
    );

    return RelatorioHtmlRenderer.finalizeDocument(tpl);
  }

  /// Ordem do papel: mais antigo → mais recente; empate visita → ocorrência → marketing.
  static List<CombinadoHtmlChapter> sortChronologically(
    List<CombinadoHtmlChapter> chapters,
  ) {
    final sorted = [...chapters];
    sorted.sort((a, b) {
      final byDate = a.occurredAt.compareTo(b.occurredAt);
      if (byDate != 0) return byDate;
      return kindRank(a.kind).compareTo(kindRank(b.kind));
    });
    return sorted;
  }

  static int kindRank(String kind) {
    switch (kind) {
      case 'visita':
        return 0;
      case 'ocorrencia':
        return 1;
      case 'resultado':
        return 2;
      case 'lado_a_lado':
        return 3;
      case 'avaliacao':
        return 4;
      default:
        return 5;
    }
  }

  static String kindLabel(String kind) {
    switch (kind) {
      case 'visita':
        return 'Visita';
      case 'ocorrencia':
        return 'Ocorrência';
      case 'resultado':
        return 'Resultado';
      case 'lado_a_lado':
        return 'Lado a lado';
      case 'avaliacao':
        return 'Avaliação';
      default:
        return kind;
    }
  }

  static String marketingKindFromTipo(String tipo) {
    switch (tipo) {
      case 'antes_depois':
        return 'lado_a_lado';
      case 'avaliacao':
        return 'avaliacao';
      case 'resultado':
      default:
        return 'resultado';
    }
  }

  static String _renderChapter(CombinadoHtmlChapter chapter) {
    final kind = RelatorioHtmlRenderer.escapeHtml(kindLabel(chapter.kind));
    final date = RelatorioHtmlRenderer.formatDate(chapter.occurredAt);
    final title = RelatorioHtmlRenderer.escapeHtml(chapter.title);
    final iso = RelatorioHtmlRenderer.escapeHtml(
      chapter.occurredAt.toUtc().toIso8601String(),
    );
    final kindAttr = RelatorioHtmlRenderer.escapeHtml(chapter.kind);
    return '''
<article class="sf-chapter" data-kind="$kindAttr" data-occurred-at="$iso">
  <header class="sf-chapter-head">
    <p class="sf-chapter-kicker">$kind · $date</p>
    <h2 class="sf-chapter-title">$title</h2>
  </header>
  <div class="sf-chapter-body">
    ${chapter.fragmentHtml}
  </div>
</article>''';
  }
}
