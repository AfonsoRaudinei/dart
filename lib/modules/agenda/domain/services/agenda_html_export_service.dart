import 'package:soloforte_app/core/contracts/i_client_lookup.dart';
import 'package:soloforte_app/core/contracts/opportunity_summary.dart';

import '../entities/event.dart';

class AgendaHtmlExportService {
  String export({
    required List<Event> events,
    required Map<String, ClientSummary> clientes,
    required Map<String, List<OpportunitySummary>> oportunidades,
  }) {
    try {
      final cards = <String>[];
      for (final event in events) {
        cards.add(_buildEventCard(event, clientes, oportunidades));
      }

      return '''
<!DOCTYPE html>
<html lang="pt-BR">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Exportacao de Agenda</title>
  <style>
    body { margin: 0; padding: 16px; background: #f5f5f5; font-family: sans-serif; color: #222; }
    .container { max-width: 600px; margin: 0 auto; }
    .card { background: white; border-radius: 8px; padding: 16px; margin-bottom: 12px; box-shadow: 0 1px 3px rgba(0,0,0,0.1); }
    .header { display: flex; justify-content: space-between; align-items: center; gap: 8px; margin-bottom: 10px; }
    .date { font-weight: 600; }
    .badge { color: #fff; border-radius: 999px; padding: 4px 10px; font-size: 12px; font-weight: 700; white-space: nowrap; }
    .line { margin: 6px 0; }
    .opps { margin-top: 8px; }
    .opps ul { list-style: none; padding-left: 0; margin: 6px 0 0 0; }
    .opps li { margin: 4px 0; }
  </style>
</head>
<body>
  <div class="container">
    ${cards.join('\n')}
  </div>
</body>
</html>
''';
    } catch (_) {
      return '''
<!DOCTYPE html>
<html lang="pt-BR">
<head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1.0"><title>Exportacao de Agenda</title></head>
<body><div style="max-width:600px;margin:0 auto;font-family:sans-serif;">Exportacao indisponivel.</div></body>
</html>
''';
    }
  }

  String _buildEventCard(
    Event event,
    Map<String, ClientSummary> clientes,
    Map<String, List<OpportunitySummary>> oportunidades,
  ) {
    final cliente = clientes[event.clienteId];
    final nomeProdutor = _escapeHtml(cliente?.name.trim().isNotEmpty == true
        ? cliente!.name
        : 'Produtor não informado');

    final dateText = _formatDate(event.dataInicioPlanejada);
    final timeText = _formatTimeRange(event);
    final headerDate = _escapeHtml(
      timeText == null ? dateText : '$dateText  $timeText',
    );

    final statusName = event.status.name;
    final statusColor = _statusColor(statusName);
    final statusLabel = _statusLabel(statusName);

    final lines = <String>[];
    lines.add('<p class="line">👤 $nomeProdutor</p>');

    final fazenda = event.titulo.trim();
    if (fazenda.isNotEmpty) {
      lines.add('<p class="line">🏡 Fazenda: ${_escapeHtml(fazenda)}</p>');
    }

    final objetivo = event.titulo.trim();
    if (objetivo.isNotEmpty) {
      lines.add('<p class="line">🎯 Objetivo: ${_escapeHtml(objetivo)}</p>');
    }

    final tipo = event.tipo.name.trim();
    if (tipo.isNotEmpty) {
      lines.add('<p class="line">🗂 Tipo de visita: ${_escapeHtml(tipo)}</p>');
    }

    final prioridade = event.priority.name.trim();
    if (prioridade.isNotEmpty && prioridade.toLowerCase() != 'normal') {
      lines.add('<p class="line">⚡ Prioridade: ${_escapeHtml(prioridade)}</p>');
    }

    final oportunidadesCliente = oportunidades[event.clienteId] ?? const [];
    if (oportunidadesCliente.isNotEmpty) {
      final items = oportunidadesCliente
          .map(
            (op) => '<li>${_escapeHtml(_opportunityLine(op))}</li>',
          )
          .join();
      lines.add(
        '<div class="opps"><strong>📈 Oportunidades de Mercado</strong><ul>$items</ul></div>',
      );
    }

    return '''
<div class="card">
  <div class="header">
    <span class="date">📅 $headerDate</span>
    <span class="badge" style="background:$statusColor;">${_escapeHtml(statusLabel)}</span>
  </div>
  ${lines.join('\n  ')}
</div>''';
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString().padLeft(4, '0');
    return '$day/$month/$year';
  }

  String? _formatTimeRange(Event event) {
    final start = event.startTime;
    if (start == null) return null;

    final startText =
        '${start.hour.toString().padLeft(2, '0')}:${start.minute.toString().padLeft(2, '0')}';
    final end = event.endTime;
    if (end == null) return startText;

    final endText =
        '${end.hour.toString().padLeft(2, '0')}:${end.minute.toString().padLeft(2, '0')}';
    return '$startText – $endText';
  }

  String _statusColor(String statusName) {
    final normalized = statusName.trim().toLowerCase();
    if (normalized == 'active' || normalized == 'ativa') return '#4CAF50';
    if (normalized == 'pending' || normalized == 'pendente') return '#FF9800';
    if (normalized == 'completed' || normalized == 'concluida') return '#2196F3';
    if (normalized == 'cancelled' || normalized == 'cancelada') return '#9E9E9E';
    return '#616161';
  }

  String _statusLabel(String statusName) {
    final normalized = statusName.trim().toLowerCase();
    if (normalized == 'active' || normalized == 'ativa') return 'Ativa';
    if (normalized == 'pending' || normalized == 'pendente') return 'Pendente';
    if (normalized == 'completed' || normalized == 'concluida') return 'Concluída';
    if (normalized == 'cancelled' || normalized == 'cancelada') return 'Cancelada';
    if (statusName.trim().isEmpty) return 'Status';
    final source = statusName.trim();
    return '${source[0].toUpperCase()}${source.substring(1)}';
  }

  String _opportunityLine(OpportunitySummary op) {
    final ref = op.referenceValuePerHa.toStringAsFixed(2);
    final pct = op.closedPercent.toStringAsFixed(1);
    return '${op.categoryName}: R\$ $ref/${op.unit} • Fechado $pct% • Área ${op.areaHa.toStringAsFixed(2)} ha';
  }

  String _escapeHtml(String value) {
    return value
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#39;');
  }
}
