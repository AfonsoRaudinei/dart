import 'package:intl/intl.dart';

import 'relatorio_html_renderer.dart';

/// Renderer do planejamento semanal da agenda (HTML asset).
///
/// Fica em core/ e não importa tipos de modules/.
class PlanejamentoHtmlRenderer {
  static Future<String> render({
    required DateTime weekStart,
    required DateTime weekEnd,
    required List<Map<String, dynamic>> days,
    required int totalEventos,
    required int concluidos,
    required int clientesUnicos,
    String? consultantName,
    String? consultantRole,
  }) async {
    var tpl = await RelatorioHtmlRenderer.loadTemplate(
      'planejamento_semanal.html',
    );
    final branding = await RelatorioHtmlRenderer.brandingPlaceholders(
      consultantName: consultantName,
      consultantRole: consultantRole,
    );

    final efficiencyPct = totalEventos == 0
        ? 0
        : ((concluidos / totalEventos) * 100).round();

    final periodoFmt = DateFormat('d MMM', 'pt_BR');
    final periodoYearFmt = DateFormat('d MMM yyyy', 'pt_BR');
    final periodoLabel =
        '${periodoFmt.format(weekStart)} – ${periodoYearFmt.format(weekEnd)}';

    tpl = RelatorioHtmlRenderer.replacePlaceholders(tpl, {
      ...branding,
      'periodo_label': RelatorioHtmlRenderer.escapeHtml(periodoLabel),
      'efficiency_pct': efficiencyPct.toString(),
      'total_eventos': totalEventos.toString(),
      'concluidos': concluidos.toString(),
      'clientes_unicos': clientesUnicos.toString(),
    });

    tpl = RelatorioHtmlRenderer.resolveEachBlock(
      tpl,
      'days',
      html: _renderDays(days),
    );

    return RelatorioHtmlRenderer.stripUnresolvedPlaceholders(tpl);
  }

  static String _renderDays(List<Map<String, dynamic>> days) {
    if (days.isEmpty) {
      return '<div class="empty-day">Nenhum dia nesta semana.</div>';
    }
    return days.map(_renderDay).join();
  }

  static String _renderDay(Map<String, dynamic> day) {
    final weekdayLabel = RelatorioHtmlRenderer.escapeHtml(
      _string(day['weekday_label']),
    );
    final dateLabel = RelatorioHtmlRenderer.escapeHtml(
      _string(day['date_label']),
    );
    final isSunday = day['is_sunday'] == true;
    final events = _listOfMaps(day['events']);
    final completed = events
        .where((e) => _string(e['status']) == 'concluido')
        .length;
    final countLabel = events.isEmpty
        ? '0'
        : '$completed/${events.length}';

    final body = events.isEmpty
        ? '<div class="empty-day">Nenhum evento agendado</div>'
        : events.map(_renderEvent).join();

    return '''
    <section class="day-card${isSunday ? ' sunday' : ''}">
      <div class="day-header">
        <div>
          <div class="day-name">$weekdayLabel</div>
          <div class="day-date">$dateLabel</div>
        </div>
        <span class="day-count">$countLabel</span>
      </div>
      <div class="day-body">
        $body
      </div>
    </section>
    ''';
  }

  static String _renderEvent(Map<String, dynamic> event) {
    final title = RelatorioHtmlRenderer.escapeHtml(_string(event['titulo']));
    final time = RelatorioHtmlRenderer.escapeHtml(_string(event['horario']));
    final status = _string(event['status'], fallback: 'agendado');
    final statusLabel = RelatorioHtmlRenderer.escapeHtml(
      _string(event['status_label'], fallback: status),
    );
    final cliente = RelatorioHtmlRenderer.escapeHtml(
      _string(event['cliente_nome'], fallback: '—'),
    );
    final fazenda = RelatorioHtmlRenderer.escapeHtml(
      _string(event['fazenda_nome'], fallback: '—'),
    );
    final tipo = RelatorioHtmlRenderer.escapeHtml(
      _string(event['tipo_label'], fallback: '—'),
    );

    final timeHtml = time.isEmpty
        ? ''
        : '<div class="event-time">$time</div>';

    return '''
    <article class="event-row">
      <div class="event-top">
        <div>
          <div class="event-title">$title</div>
          $timeHtml
        </div>
        <span class="status-badge status-$status">$statusLabel</span>
      </div>
      <div class="event-fields">
        <span class="fl">Cliente</span><span class="fv">$cliente</span>
        <span class="fl">Fazenda</span><span class="fv">$fazenda</span>
        <span class="fl">Tipo</span><span class="fv">$tipo</span>
      </div>
    </article>
    ''';
  }

  static String _string(dynamic value, {String fallback = ''}) {
    if (value == null) return fallback;
    final text = value.toString().trim();
    return text.isEmpty ? fallback : text;
  }

  static List<Map<String, dynamic>> _listOfMaps(dynamic value) {
    if (value is! List) return const [];
    return value
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }
}
