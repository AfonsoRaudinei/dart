import 'package:intl/intl.dart';

import '../../../../core/contracts/i_client_lookup.dart';
import '../../../../core/contracts/i_farm_lookup.dart';
import '../../../../core/html_templates/planejamento_html_renderer.dart';
import '../../domain/entities/event.dart';
import '../../domain/enums/event_status.dart';

/// Monta o HTML do planejamento semanal a partir de [Event] reais.
///
/// ADR-015: usa IClientLookup / IFarmLookup (zero import de consultoria/).
class AgendaPlanejamentoHtmlService {
  final IClientLookup _clientLookup;
  final IFarmLookup? _farmLookup;

  const AgendaPlanejamentoHtmlService(
    this._clientLookup, [
    this._farmLookup,
  ]);

  Future<String> renderWeekHtml({
    required List<Event> events,
    required DateTime weekStart,
    String? consultantName,
    String? consultantRole,
  }) async {
    final weekEnd = weekStart.add(const Duration(days: 6));

    final filtered = events.where((e) {
      if (e.syncStatus == 'deleted' || e.syncStatus == 'deleted_local') {
        return false;
      }
      final d = e.dataInicioPlanejada;
      return !d.isBefore(weekStart) && !d.isAfter(weekEnd);
    }).toList()
      ..sort((a, b) => a.dataInicioPlanejada.compareTo(b.dataInicioPlanejada));

    final clientIds = filtered.map((e) => e.clienteId).toSet();
    final clientNames = <String, String>{};
    await Future.wait(
      clientIds.map((id) async {
        try {
          final c = await _clientLookup.findById(id);
          clientNames[id] = c?.name ?? '—';
        } catch (_) {
          clientNames[id] = '—';
        }
      }),
    );

    final farmIds = filtered
        .map((e) => e.fazendaId)
        .whereType<String>()
        .toSet();
    final farmNames = <String, String>{};
    if (_farmLookup != null && farmIds.isNotEmpty) {
      await Future.wait(
        farmIds.map((id) async {
          try {
            final f = await _farmLookup.findById(id);
            farmNames[id] = f?.name ?? '—';
          } catch (_) {
            farmNames[id] = '—';
          }
        }),
      );
    }

    final days = <Map<String, dynamic>>[];
    final weekdayFmt = DateFormat('EEEE', 'pt_BR');
    final dateFmt = DateFormat('d MMM yyyy', 'pt_BR');
    final timeFmt = DateFormat('HH:mm');

    for (var i = 0; i < 7; i++) {
      final day = DateTime(
        weekStart.year,
        weekStart.month,
        weekStart.day + i,
      );
      final dayEvents = filtered.where((e) {
        final d = e.dataInicioPlanejada;
        return d.year == day.year && d.month == day.month && d.day == day.day;
      }).toList();

      days.add({
        'weekday_label': weekdayFmt.format(day),
        'date_label': dateFmt.format(day),
        'is_sunday': day.weekday == DateTime.sunday,
        'events': dayEvents
            .map(
              (e) => {
                'titulo': e.titulo,
                'horario': _formatTimeRange(e, timeFmt),
                'status': e.status.name,
                'status_label': e.status.label,
                'cliente_nome': clientNames[e.clienteId] ?? '—',
                'fazenda_nome': e.fazendaId == null
                    ? '—'
                    : (farmNames[e.fazendaId!] ?? '—'),
                'tipo_label': e.tipo.label,
              },
            )
            .toList(),
      });
    }

    final concluidos =
        filtered.where((e) => e.status == EventStatus.concluido).length;

    return PlanejamentoHtmlRenderer.render(
      weekStart: weekStart,
      weekEnd: weekEnd,
      days: days,
      totalEventos: filtered.length,
      concluidos: concluidos,
      clientesUnicos: clientIds.length,
      consultantName: consultantName,
      consultantRole: consultantRole,
    );
  }

  String _formatTimeRange(Event event, DateFormat timeFmt) {
    if (event.startTime != null) {
      final start =
          '${event.startTime!.hour.toString().padLeft(2, '0')}:${event.startTime!.minute.toString().padLeft(2, '0')}';
      if (event.endTime == null) return start;
      final end =
          '${event.endTime!.hour.toString().padLeft(2, '0')}:${event.endTime!.minute.toString().padLeft(2, '0')}';
      return '$start – $end';
    }
    final start = timeFmt.format(event.dataInicioPlanejada);
    final end = timeFmt.format(event.dataFimPlanejada);
    return '$start – $end';
  }
}
