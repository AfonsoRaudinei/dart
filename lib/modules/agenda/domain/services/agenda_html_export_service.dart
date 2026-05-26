import 'package:soloforte_app/core/contracts/i_client_lookup.dart';
import 'package:soloforte_app/core/contracts/opportunity_summary.dart';

import '../entities/event.dart';

class AgendaHtmlExportService {
  String export({
    required List<Event> events,
    required Map<String, ClientSummary> clientes,
    required Map<String, List<OpportunitySummary>> oportunidades,
    DateTime? exportadoEm,
    String? periodoLabel,
  }) {
    try {
      final ordered = [...events]
        ..sort(
          (a, b) => a.dataInicioPlanejada.compareTo(b.dataInicioPlanejada),
        );

      final total = ordered.length;
      final produtores = ordered.map((event) => event.clienteId).toSet().length;
      final comOport = ordered
          .where(
            (event) => (oportunidades[event.clienteId]?.isNotEmpty ?? false),
          )
          .length;
      final urgentes = ordered
          .where((event) => event.priority.name.toLowerCase() != 'normal')
          .length;

      final exportDate = exportadoEm ?? DateTime.now();
      final exportadoLabel = _formatExportDateTime(exportDate);
      final safePeriodo = _esc(periodoLabel?.trim());
      final periodoSuffix =
          safePeriodo.isNotEmpty ? ' &nbsp;&middot;&nbsp; $safePeriodo' : '';

      final cards = ordered
          .map(
            (event) => _buildEventCard(
              event: event,
              cliente: clientes[event.clienteId],
              oportunidades: oportunidades[event.clienteId] ?? const [],
            ),
          )
          .join();

      return '''
<!DOCTYPE html>
<html lang="pt-BR">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<meta name="color-scheme" content="light only">
<title>Agenda - SoloForte</title>
<style>
  :root { color-scheme: light only; }
  @import url('https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700&display=swap');
  :root {
    --bg:#F2F2F7; --surface:#FFFFFF; --green:#1C6B45; --green-mid:#34A96C;
    --green-tint:#E8F5EE; --amber:#9A6400; --amber-tint:#FFF4DC;
    --blue:#1A5FA8; --blue-tint:#EBF3FF; --red:#C0392B; --red-tint:#FDECEA;
    --grey:#636366; --grey-tint:#F2F2F7; --sep:#E5E5EA;
    --label:#1C1C1E; --label2:#636366;
    --sans:'Inter',-apple-system,'Helvetica Neue',sans-serif;
  }
  *,*::before,*::after{box-sizing:border-box;margin:0;padding:0;-webkit-font-smoothing:antialiased;}
  html{background:#F2F2F7!important;color:#1C1C1E!important;}
  body{background:#F2F2F7!important;color:#1C1C1E!important;font-family:var(--sans);font-size:16px;padding:0 0 56px;max-width:600px;margin:0 auto;}
  .hdr{background:#fff!important;border-bottom:1px solid var(--sep);padding:20px 20px 16px;margin-bottom:24px;}
  .brand{display:flex;align-items:center;gap:10px;margin-bottom:14px;}
  .brand-icon{width:32px;height:32px;background:#1C6B45!important;border-radius:8px;display:flex;align-items:center;justify-content:center;flex-shrink:0;}
  .brand-icon svg{width:17px;height:17px;fill:#fff;}
  .brand-name{font-size:12px;font-weight:700;letter-spacing:.1em;text-transform:uppercase;color:#1C6B45!important;}
  .hdr-title{font-size:24px;font-weight:700;color:#1C1C1E!important;letter-spacing:-.4px;line-height:1.15;margin-bottom:5px;}
  .hdr-meta{font-size:12px;color:#636366!important;}
  .hdr-meta b{color:#1C1C1E!important;font-weight:500;}
  .sum{display:grid;grid-template-columns:repeat(4,1fr);gap:8px;padding:0 16px;margin-bottom:24px;}
  .sc{background:#fff!important;border-radius:10px;padding:11px 8px;text-align:center;}
  .sc-n{display:block;font-size:20px;font-weight:700;color:#1C1C1E!important;letter-spacing:-.5px;line-height:1;margin-bottom:3px;}
  .sc-l{display:block;font-size:9px;font-weight:600;letter-spacing:.04em;text-transform:uppercase;color:#636366!important;line-height:1.2;}
  .slbl{font-size:11px;font-weight:600;letter-spacing:.06em;text-transform:uppercase;color:#636366!important;padding:0 20px;margin-bottom:6px;}
  .cg{padding:0 16px;margin-bottom:28px;}
  .card{background:#fff!important;overflow:hidden;margin-bottom:2px;}
  .cg .card:first-child{border-radius:12px 12px 2px 2px;}
  .cg .card:last-child{border-radius:2px 2px 12px 12px;}
  .cg .card:only-child{border-radius:12px;}
  .ci{display:flex;}
  .stripe{width:3px;flex-shrink:0;background:#34A96C!important;}
  .stripe.a{background:#F0A500!important;}
  .stripe.b{background:#3A86D8!important;}
  .stripe.g{background:#AEAEB2!important;}
  .cb{flex:1;padding:14px 16px;}
  .ctop{display:flex;align-items:flex-start;justify-content:space-between;gap:8px;margin-bottom:10px;}
  .cdt{display:flex;flex-direction:column;gap:1px;}
  .dt-d{font-size:12px;font-weight:600;color:#1C1C1E!important;letter-spacing:.01em;}
  .dt-t{font-size:11px;color:#636366!important;font-variant-numeric:tabular-nums;}
  .badge{font-size:10px;font-weight:700;letter-spacing:.05em;text-transform:uppercase;padding:3px 9px;border-radius:20px;flex-shrink:0;line-height:1.5;}
  .ba{background:#E8F5EE!important;color:#1C6B45!important;}
  .bp{background:#FFF4DC!important;color:#9A6400!important;}
  .bc{background:#EBF3FF!important;color:#1A5FA8!important;}
  .bx{background:#F2F2F7!important;color:#636366!important;}
  .fields{display:flex;flex-direction:column;}
  .field{display:grid;grid-template-columns:76px 1fr;gap:0 8px;padding:5px 0;border-bottom:1px solid #E5E5EA;}
  .field:last-child{border-bottom:none;}
  .fl{font-size:11px;font-weight:500;color:#636366!important;text-transform:uppercase;letter-spacing:.04em;padding-top:1px;line-height:1.45;}
  .fv{font-size:13px;font-weight:400;color:#1C1C1E!important;line-height:1.45;}
  .fv.sb{font-weight:600;}
  .prow{margin-top:10px;display:flex;align-items:center;gap:5px;}
  .pdot{width:6px;height:6px;border-radius:50%;background:#C0392B!important;flex-shrink:0;}
  .ptxt{font-size:11px;font-weight:700;color:#C0392B!important;letter-spacing:.04em;text-transform:uppercase;}
  .ob{margin-top:12px;background:#E8F5EE!important;border-radius:8px;padding:10px 12px;}
  .ol{font-size:10px;font-weight:700;letter-spacing:.07em;text-transform:uppercase;color:#1C6B45!important;margin-bottom:7px;}
  .oi{display:flex;align-items:flex-start;gap:8px;padding:4px 0;border-bottom:1px solid rgba(28,107,69,.12);}
  .oi:last-child{border-bottom:none;padding-bottom:0;}
  .oi:first-of-type{padding-top:0;}
  .otick{width:14px;height:14px;border-radius:50%;background:#34A96C!important;flex-shrink:0;margin-top:2px;display:flex;align-items:center;justify-content:center;}
  .otick svg{width:8px;height:8px;stroke:#fff;fill:none;stroke-width:2.5;stroke-linecap:round;stroke-linejoin:round;}
  .ot{font-size:12px;color:#1C1C1E!important;line-height:1.4;}
  .ftr{text-align:center;padding:0 20px;margin-top:8px;}
  .ftxt{font-size:11px;color:#636366!important;line-height:1.6;}
  .fgreen{font-weight:700;color:#1C6B45!important;}
</style>
</head>
<body>

<div class="hdr">
  <div class="brand">
    <div class="brand-icon">
      <svg viewBox="0 0 24 24"><path d="M17 8C8 10 5.9 16.17 3.82 19.97A2 2 0 005.54 22C8 20 11 18.6 13 16c2-2.6 2.8-5.6 4-8z"/></svg>
    </div>
    <span class="brand-name">SoloForte</span>
  </div>
  <div class="hdr-title">Agenda de Visitas</div>
  <div class="hdr-meta">Exportado em <b>${_esc(exportadoLabel)}</b> &nbsp;&middot;&nbsp; <b>$total eventos</b>$periodoSuffix</div>
</div>

<div class="sum">
  <div class="sc"><span class="sc-n">$total</span><span class="sc-l">Eventos</span></div>
  <div class="sc"><span class="sc-n">$produtores</span><span class="sc-l">Produtores</span></div>
  <div class="sc"><span class="sc-n">$comOport</span><span class="sc-l">Oport.</span></div>
  <div class="sc"><span class="sc-n">$urgentes</span><span class="sc-l">Urgente</span></div>
</div>

<p class="slbl">Visitas agendadas</p>

<div class="cg">
$cards
</div>

<div class="ftr">
  <p class="ftxt">Gerado por <span class="fgreen">SoloForte</span> &nbsp;&middot;&nbsp; AgendaHtmlExportService &nbsp;&middot;&nbsp; soloforte.app</p>
</div>

</body>
</html>
''';
    } catch (_) {
      return '''
<!DOCTYPE html>
<html lang="pt-BR">
<head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1"><title>Agenda - SoloForte</title></head>
<body><div style="max-width:600px;margin:0 auto;font-family:sans-serif;">Exportacao indisponivel.</div></body>
</html>
''';
    }
  }

  String _buildEventCard({
    required Event event,
    required ClientSummary? cliente,
    required List<OpportunitySummary> oportunidades,
  }) {
    final nomeProdutor = _esc(
      cliente?.name.trim().isNotEmpty == true
          ? cliente!.name
          : 'Produtor não informado',
    );
    final cidade = _esc(_extractCity(cliente));
    final fazenda = _esc(event.titulo.trim());
    final objetivo = _esc(event.titulo.trim());

    final dateText = _formatAgendaDate(event.dataInicioPlanejada);
    final timeText = _formatTimeRange(event);
    final timeLine = timeText.isEmpty ? '' : '<span class="dt-t">$timeText</span>';

    final statusMeta = _statusMeta(event.status.name);

    final fields = <String>[
      '<div class="field"><span class="fl">Produtor</span><span class="fv sb">$nomeProdutor</span></div>',
    ];
    if (fazenda.isNotEmpty) {
      fields.add(
        '<div class="field"><span class="fl">Fazenda</span><span class="fv">$fazenda</span></div>',
      );
    }
    if (cidade.isNotEmpty) {
      fields.add(
        '<div class="field"><span class="fl">Cidade</span><span class="fv">$cidade</span></div>',
      );
    }
    if (objetivo.isNotEmpty) {
      fields.add(
        '<div class="field"><span class="fl">Objetivo</span><span class="fv">$objetivo</span></div>',
      );
    }

    final isUrgente = event.priority.name.toLowerCase() != 'normal';
    final prioridade = isUrgente
        ? '<div class="prow"><div class="pdot"></div><span class="ptxt">Alta prioridade</span></div>'
        : '';

    final oportunidadesBloco = oportunidades.isEmpty
        ? ''
        : '''
<div class="ob">
  <div class="ol">Oportunidades de Mercado</div>
  ${oportunidades.map(_buildOpportunityItem).join()}
</div>''';

    return '''
<div class="card">
  <div class="ci">
    <div class="stripe ${statusMeta.stripeClass}"></div>
    <div class="cb">
      <div class="ctop">
        <div class="cdt">
          <span class="dt-d">$dateText</span>
          $timeLine
        </div>
        <span class="badge ${statusMeta.badgeClass}">${_esc(statusMeta.label)}</span>
      </div>
      <div class="fields">
        ${fields.join()}
      </div>
      $prioridade
      $oportunidadesBloco
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
    return '${op.categoryName}: R\$ ${_decimal(op.referenceValuePerHa)}/${op.unit} - Fechado ${_decimal(op.closedPercent)}% - Area ${_decimal(op.areaHa)} ha';
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
    final year = date.year.toString();
    return '$weekday, $day $month $year';
  }

  String _formatExportDateTime(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString().padLeft(4, '0');
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$day/$month/$year às $hour:$minute';
  }

  String _formatTimeRange(Event event) {
    final start = event.startTime;
    if (start == null) return '';
    final startText = _timeOfDay(start.hour, start.minute);
    final end = event.endTime;
    if (end == null) return startText;
    final endText = _timeOfDay(end.hour, end.minute);
    return '$startText - $endText';
  }

  String _timeOfDay(int hour, int minute) {
    final hh = hour.toString().padLeft(2, '0');
    final mm = minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }

  _StatusMeta _statusMeta(String statusName) {
    final normalized = statusName.trim().toLowerCase();
    if (normalized == 'active' || normalized == 'ativa') {
      return const _StatusMeta('', 'ba', 'Ativa');
    }
    if (normalized == 'pending' || normalized == 'pendente') {
      return const _StatusMeta('a', 'bp', 'Pendente');
    }
    if (normalized == 'completed' || normalized == 'concluida') {
      return const _StatusMeta('b', 'bc', 'Concluída');
    }
    if (normalized == 'cancelled' || normalized == 'cancelada') {
      return const _StatusMeta('g', 'bx', 'Cancelada');
    }
    return _StatusMeta(
      'g',
      'bx',
      statusName.trim().isEmpty ? 'Status' : statusName.trim(),
    );
  }

  String _extractCity(ClientSummary? cliente) {
    if (cliente == null) return '';
    try {
      final dynamic maybeCity = (cliente as dynamic).city;
      if (maybeCity is String && maybeCity.trim().isNotEmpty) {
        return maybeCity.trim();
      }
    } catch (_) {}
    return '';
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
  final String stripeClass;
  final String badgeClass;
  final String label;

  const _StatusMeta(this.stripeClass, this.badgeClass, this.label);
}
