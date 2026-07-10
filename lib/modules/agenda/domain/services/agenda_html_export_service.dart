import 'package:soloforte_app/core/contracts/i_client_lookup.dart';
import 'package:soloforte_app/core/contracts/opportunity_summary.dart';
import 'package:soloforte_app/core/html_templates/relatorio_html_renderer.dart';
import 'package:soloforte_app/modules/agenda/domain/entities/event.dart';
import 'package:soloforte_app/modules/agenda/domain/entities/visit.dart';
import 'package:soloforte_app/modules/agenda/domain/enums/event_status.dart';

class AgendaHtmlExportService {
  /// Retorna String HTML auto-contida pronta para exportação.
  /// Nunca lança exceção — campos null são omitidos silenciosamente.
  Future<String> export({
    required List<Event> events,
    required Map<String, ClientSummary> clientes,
    required Map<String, List<OpportunitySummary>> oportunidades,
    Map<String, String> fazendas = const {},
    String? periodoLabel,
    String? consultantName,
  }) async {
    try {
      final branding = await RelatorioHtmlRenderer.brandingPlaceholders(
        consultantName: consultantName,
      );
      final ordered = [
        ...events,
      ]..sort((a, b) => a.dataInicioPlanejada.compareTo(b.dataInicioPlanejada));

      final total = events.length;
      final produtores = events.map((e) => e.clienteId).toSet().length;
      final comOport = events
          .where((e) => (oportunidades[e.clienteId]?.isNotEmpty ?? false))
          .length;
      final urgentes = events
          .where((e) => e.priority != VisitPriority.normal)
          .length;

      final periodo = _esc(periodoLabel?.trim());
      final periodoHtml = periodo.isEmpty ? '' : ' &nbsp;·&nbsp; $periodo';
      final cards = ordered
          .map(
            (event) => _buildEventCard(
              event: event,
              cliente: clientes[event.clienteId],
              fazendaNome: event.fazendaId == null
                  ? null
                  : fazendas[event.fazendaId!],
              oportunidades: oportunidades[event.clienteId] ?? const [],
            ),
          )
          .join();

      final headerSig = branding['report_header_signature'] ?? '';
      final footerSig = branding['report_footer_signature'] ?? '';

      return '''
<!DOCTYPE html>
<html lang="pt-BR">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<meta name="color-scheme" content="light only">
<title>Agenda — SoloForte</title>
<style>
  :root { color-scheme: light only; }
  @import url('https://fonts.googleapis.com/css2?family=DM+Sans:wght@300;400;500;600;700&display=swap');
  :root {
    --sf-samsung:#1428A0; --sf-navy:#2C5564; --sf-gray:#F5F5F7; --sf-text:#1D1D1F;
    --bg:#F5F5F7; --surface:#FFFFFF;
    --amber:#9A6400; --amber-tint:#FFF4DC;
    --blue:#1A5FA8; --blue-tint:#EBF3FF; --red:#C0392B;
    --grey:#636366; --sep:#E5E5EA;
    --sans:'DM Sans',-apple-system,'Helvetica Neue',sans-serif;
  }
  *,*::before,*::after{box-sizing:border-box;margin:0;padding:0;-webkit-font-smoothing:antialiased;}
  html{background:var(--bg)!important;color:var(--sf-text)!important;}
  body{background:var(--bg)!important;color:var(--sf-text)!important;font-family:var(--sans);font-size:16px;padding:0 0 56px;max-width:600px;margin:0 auto;}
  .hdr{background:linear-gradient(135deg,var(--sf-samsung) 0%,var(--sf-navy) 100%)!important;padding:20px 20px 16px;margin-bottom:24px;color:#fff;}
  .brand{display:flex;align-items:center;gap:10px;margin-bottom:14px;}
  .logo-img{width:32px;height:32px;object-fit:contain;filter:brightness(0) invert(1);opacity:.92;}
  .logo-name{font-size:14px;font-weight:700;letter-spacing:.04em;color:#fff!important;}
  .hdr-title{font-size:24px;font-weight:700;color:#fff!important;letter-spacing:-.4px;line-height:1.15;margin-bottom:5px;}
  .hdr-meta{font-size:12px;color:rgba(255,255,255,.85)!important;}
  .hdr-meta b{color:#fff!important;font-weight:500;}
  .sum{display:grid;grid-template-columns:repeat(4,1fr);gap:8px;padding:0 16px;margin-bottom:24px;}
  .sc{background:#fff!important;border-radius:10px;padding:11px 8px;text-align:center;}
  .sc-n{display:block;font-size:20px;font-weight:700;color:var(--sf-text)!important;letter-spacing:-.5px;line-height:1;margin-bottom:3px;}
  .sc-l{display:block;font-size:9px;font-weight:600;letter-spacing:.04em;text-transform:uppercase;color:#636366!important;line-height:1.2;}
  .slbl{font-size:11px;font-weight:600;letter-spacing:.06em;text-transform:uppercase;color:#636366!important;padding:0 20px;margin-bottom:6px;}
  .cg{padding:0 16px;margin-bottom:28px;}
  .card{background:#fff!important;overflow:hidden;margin-bottom:2px;}
  .cg .card:first-child{border-radius:12px 12px 2px 2px;}
  .cg .card:last-child{border-radius:2px 12px 12px 12px;}
  .cg .card:only-child{border-radius:12px;}
  .ci{display:flex;}
  .stripe{width:3px;flex-shrink:0;background:var(--sf-samsung)!important;}
  .stripe.a{background:#F0A500!important;}
  .stripe.b{background:#3A86D8!important;}
  .stripe.g{background:#AEAEB2!important;}
  .cb{flex:1;padding:14px 16px;}
  .ctop{display:flex;align-items:flex-start;justify-content:space-between;gap:8px;margin-bottom:10px;}
  .cdt{display:flex;flex-direction:column;gap:1px;}
  .dt-d{font-size:12px;font-weight:600;color:var(--sf-text)!important;letter-spacing:.01em;}
  .dt-t{font-size:11px;color:#636366!important;font-variant-numeric:tabular-nums;}
  .badge{font-size:10px;font-weight:700;letter-spacing:.05em;text-transform:uppercase;padding:3px 9px;border-radius:20px;flex-shrink:0;line-height:1.5;}
  .ba{background:#DBEAFE!important;color:#1E40AF!important;}
  .bp{background:#FFF4DC!important;color:#9A6400!important;}
  .bc{background:#DCFCE7!important;color:#166534!important;}
  .bx{background:#F2F2F7!important;color:#636366!important;}
  .fields{display:flex;flex-direction:column;}
  .field{display:grid;grid-template-columns:76px 1fr;gap:0 8px;padding:5px 0;border-bottom:1px solid #E5E5EA;}
  .field:last-child{border-bottom:none;}
  .fl{font-size:11px;font-weight:500;color:#636366!important;text-transform:uppercase;letter-spacing:.04em;padding-top:1px;line-height:1.45;}
  .fv{font-size:13px;font-weight:400;color:var(--sf-text)!important;line-height:1.45;}
  .fv.sb{font-weight:600;}
  .prow{margin-top:10px;display:flex;align-items:center;gap:5px;}
  .pdot{width:6px;height:6px;border-radius:50%;background:#C0392B!important;flex-shrink:0;}
  .ptxt{font-size:11px;font-weight:700;color:#C0392B!important;letter-spacing:.04em;text-transform:uppercase;}
  .ob{margin-top:12px;background:#EEF2FF!important;border-radius:8px;padding:10px 12px;}
  .ol{font-size:10px;font-weight:700;letter-spacing:.07em;text-transform:uppercase;color:var(--sf-navy)!important;margin-bottom:7px;}
  .oi{display:flex;align-items:flex-start;gap:8px;padding:4px 0;border-bottom:1px solid rgba(44,85,100,.12);}
  .oi:last-child{border-bottom:none;padding-bottom:0;}
  .oi:first-of-type{padding-top:0;}
  .otick{width:14px;height:14px;border-radius:50%;background:var(--sf-samsung)!important;flex-shrink:0;margin-top:2px;display:flex;align-items:center;justify-content:center;}
  .otick svg{width:8px;height:8px;stroke:#fff;fill:none;stroke-width:2.5;stroke-linecap:round;stroke-linejoin:round;}
  .ot{font-size:12px;color:var(--sf-text)!important;line-height:1.4;}
  .ftr{padding:16px 20px;margin-top:8px;background:#fff;border-top:1px solid var(--sep);}
  .sf-brand{display:flex;align-items:center;gap:10px;}
  .sf-brand-logo{width:22px;height:22px;object-fit:contain;}
  .sf-brand-copy{display:flex;flex-direction:column;gap:2px;}
  .sf-brand-copy strong{font-size:14px;font-weight:600;color:var(--sf-text);}
  .sf-brand-tagline{font-size:11px;line-height:1.4;color:#667085;}
</style>
</head>
<body>

<div class="hdr">
  <div class="brand">
    $headerSig
  </div>
  <div class="hdr-title">Agenda de Visitas</div>
  <div class="hdr-meta"><b>$total eventos</b>$periodoHtml</div>
</div>

<div class="sum">
  <div class="sc"><span class="sc-n">$total</span><span class="sc-l">Eventos</span></div>
  <div class="sc"><span class="sc-n">$produtores</span><span class="sc-l">Produtores</span></div>
  <div class="sc"><span class="sc-n">$comOport</span><span class="sc-l">Oport.</span></div>
  <div class="sc"><span class="sc-n">$urgentes</span><span class="sc-l">Urgente</span></div>
</div>

<p class="slbl">Visitas agendadas</p>

<div class="cg">
$cards</div>

<div class="ftr">
  $footerSig
</div>

</body>
</html>
''';
    } catch (_) {
      return '''
<!DOCTYPE html>
<html lang="pt-BR">
<head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1"><title>Agenda — SoloForte</title></head>
<body></body>
</html>
''';
    }
  }

  String _buildEventCard({
    required Event event,
    required ClientSummary? cliente,
    required String? fazendaNome,
    required List<OpportunitySummary> oportunidades,
  }) {
    final nomeProdutor = _esc(
      cliente?.name.trim().isNotEmpty == true
          ? cliente!.name
          : 'Produtor não informado',
    );
    final titulo = _esc(event.titulo.trim());
    final fazenda = _esc(
      (fazendaNome?.trim().isNotEmpty == true) ? fazendaNome!.trim() : '—',
    );
    final data = _esc(_formatAgendaDate(event.dataInicioPlanejada));
    final horario = _formatTimeRange(event);
    final status = _statusMeta(event.status);
    final fields = <String>[
      '<div class="field"><span class="fl">Produtor</span><span class="fv sb">$nomeProdutor</span></div>',
      '<div class="field"><span class="fl">Fazenda</span><span class="fv">$fazenda</span></div>',
    ];

    if (titulo.isNotEmpty) {
      fields.add(
        '<div class="field"><span class="fl">Objetivo</span><span class="fv">$titulo</span></div>',
      );
    }

    final horarioHtml = horario.isEmpty
        ? ''
        : '''
          <span class="dt-t">${_esc(horario)}</span>''';
    final prioridadeHtml = event.priority == VisitPriority.normal
        ? ''
        : '''
      <div class="prow"><div class="pdot"></div><span class="ptxt">Alta prioridade</span></div>''';
    final oportunidadesHtml = oportunidades.isEmpty
        ? ''
        : '''
      <div class="ob">
        <div class="ol">Oportunidades de Mercado</div>
${oportunidades.map(_buildOpportunityItem).join()}      </div>''';

    return '''
  <div class="card">
    <div class="ci">
      <div class="stripe ${status.stripeClass}"></div>
      <div class="cb">
        <div class="ctop">
          <div class="cdt">
            <span class="dt-d">$data</span>
$horarioHtml
          </div>
          <span class="badge ${status.badgeClass}">${_esc(status.label)}</span>
        </div>
        <div class="fields">
          ${fields.join()}
        </div>$prioridadeHtml$oportunidadesHtml
      </div>
    </div>
  </div>
''';
  }

  String _buildOpportunityItem(OpportunitySummary op) {
    return '''
        <div class="oi">
          <div class="otick"><svg viewBox="0 0 10 10"><polyline points="2,5 4,7 8,3"/></svg></div>
          <span class="ot">${_esc(_opportunityText(op))}</span>
        </div>
''';
  }

  String _opportunityText(OpportunitySummary op) {
    return '${op.categoryName}: ${_decimal(op.residualValuePerHa)} ${op.unit} pendente por ha, ${_decimal(op.residualPercent)}% em aberto, ${_decimal(op.areaHa)} ha';
  }

  String _decimal(double value) {
    return value.toStringAsFixed(2).replaceAll('.', ',');
  }

  String _formatAgendaDate(DateTime date) {
    const weekdays = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sab', 'Dom'];
    const months = [
      'Jan',
      'Fev',
      'Mar',
      'Abr',
      'Mai',
      'Jun',
      'Jul',
      'Ago',
      'Set',
      'Out',
      'Nov',
      'Dez',
    ];
    final weekday = weekdays[date.weekday - 1];
    final day = date.day.toString().padLeft(2, '0');
    final month = months[date.month - 1];
    return '$weekday, $day $month ${date.year}';
  }

  String _formatTimeRange(Event event) {
    final start = event.startTime;
    if (start == null) return '';

    final startText = _timeOfDay(start.hour, start.minute);
    final end = event.endTime;
    if (end == null) return startText;

    return '$startText – ${_timeOfDay(end.hour, end.minute)}';
  }

  String _timeOfDay(int hour, int minute) {
    final hh = hour.toString().padLeft(2, '0');
    final mm = minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }

  _StatusMeta _statusMeta(EventStatus status) {
    switch (status) {
      case EventStatus.emAndamento:
      case EventStatus.finalizando:
        return const _StatusMeta('', 'ba', 'Ativa');
      case EventStatus.agendado:
        return const _StatusMeta('a', 'bp', 'Pendente');
      case EventStatus.concluido:
        return const _StatusMeta('b', 'bc', 'Concluída');
      case EventStatus.cancelado:
        return const _StatusMeta('g', 'bx', 'Cancelada');
    }
  }

  String _esc(String? s) {
    if (s == null || s.isEmpty) return '';
    return s
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;');
  }
}

class _StatusMeta {
  const _StatusMeta(this.stripeClass, this.badgeClass, this.label);

  final String stripeClass;
  final String badgeClass;
  final String label;
}
