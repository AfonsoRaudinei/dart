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
    final consultant = consultantName?.trim() ?? '';
    final role = consultantRole?.trim() ?? '';
    final contextoLinha = _plural(totalEventos, 'evento', 'eventos');

    tpl = RelatorioHtmlRenderer.replacePlaceholders(tpl, {
      ...branding,
      'periodo_label': RelatorioHtmlRenderer.escapeHtml(periodoLabel),
      'contexto_linha': contextoLinha,
      'efficiency_pct': efficiencyPct.toString(),
      'total_eventos': totalEventos.toString(),
      'total_eventos_label': totalEventos == 1 ? 'evento' : 'eventos',
      'concluidos': concluidos.toString(),
      'concluidos_label': concluidos == 1 ? 'concluído' : 'concluídos',
      'clientes_unicos': clientesUnicos.toString(),
      'clientes_unicos_label': clientesUnicos == 1 ? 'cliente' : 'clientes',
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
    tpl = RelatorioHtmlRenderer.resolveEachBlock(
      tpl,
      'days',
      html: _renderDays(days),
    );

    return RelatorioHtmlRenderer.finalizeDocument(tpl);
  }

  static String _renderDays(List<Map<String, dynamic>> days) {
    if (days.isEmpty) {
      return '<p class="sf-muted empty-day">Nenhum dia nesta semana.</p>';
    }
    return days.map(_renderDay).join();
  }

  static String _renderDay(Map<String, dynamic> day) {
    final weekdayLabel = RelatorioHtmlRenderer.escapeHtml(
      _capitalize(_string(day['weekday_label'])),
    );
    final dateLabel = RelatorioHtmlRenderer.escapeHtml(
      _string(day['date_label']),
    );
    final isSunday = day['is_sunday'] == true;
    final events = _listOfMaps(day['events']);
    final completed = events
        .where((e) => _string(e['status']) == 'concluido')
        .length;

    final label = [
      if (weekdayLabel.isNotEmpty) weekdayLabel,
      if (dateLabel.isNotEmpty) dateLabel,
      if (events.isNotEmpty) '$completed de ${events.length} concluídos',
    ].join(' · ');

    final body = events.isEmpty
        ? '<p class="sf-muted empty-day">Nenhum evento agendado</p>'
        : '<div class="sf-sheet">${events.map(_renderEvent).join()}</div>';

    return '''
    <p class="sf-group-label day-group${isSunday ? ' sunday' : ''}">$label</p>
    $body
    ''';
  }

  static String _renderEvent(Map<String, dynamic> event) {
    final title = RelatorioHtmlRenderer.escapeHtml(_string(event['titulo']));
    final time = RelatorioHtmlRenderer.escapeHtml(_string(event['horario']));
    final status = _string(event['status'], fallback: 'agendado');
    final statusLabel = RelatorioHtmlRenderer.escapeHtml(
      _string(
        event['status_label'],
        fallback: RelatorioHtmlRenderer.humanizeKey(status),
      ),
    );
    final campos = [
      _campo('Cliente', event['cliente_nome']),
      _campo('Fazenda', event['fazenda_nome']),
      _campo('Tipo', event['tipo_label']),
    ].whereType<String>().toList();

    return '''
    <div class="sf-item event-row">
      <div class="sf-item-body">
        <div class="sf-item-head">
          <span class="sf-item-title">$title</span>
          <span class="sf-status"><span class="sf-dot ${_statusDot(status)}"></span>$statusLabel</span>
        </div>
        ${time.isEmpty ? '' : '<span class="sf-caption">$time</span>'}
        ${campos.isEmpty ? '' : '<span class="sf-caption">${campos.join(' · ')}</span>'}
      </div>
    </div>
    ''';
  }

  static String? _campo(String label, Object? value) {
    final text = _string(value);
    if (text.isEmpty || text == '—') return null;
    return '$label: ${RelatorioHtmlRenderer.escapeHtml(text)}';
  }

  static String _statusDot(String status) {
    switch (status) {
      case 'concluido':
        return 'ok';
      case 'emAndamento':
      case 'finalizando':
        return 'media';
      default:
        return 'draft';
    }
  }

  static String _plural(int count, String singular, String plural) {
    return '$count ${count == 1 ? singular : plural}';
  }

  static String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
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
