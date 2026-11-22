import 'entities/event.dart';
import 'enums/event_status.dart';

/// Visita já executada: tem sessão e está em andamento ou concluída.
bool isVisitaRealizada(Event event) {
  final sessionId = event.visitSessionId?.trim() ?? '';
  if (sessionId.isEmpty) return false;
  return event.status == EventStatus.concluido ||
      event.status == EventStatus.emAndamento;
}

/// Visitas realizadas cujo início cai no mês de [month], da mais recente
/// para a mais antiga.
List<Event> visitasRealizadasNoMes(List<Event> events, DateTime month) {
  final start = DateTime(month.year, month.month);
  final end = DateTime(month.year, month.month + 1);
  final selected = events.where((event) {
    if (!isVisitaRealizada(event)) return false;
    final when = event.dataInicioPlanejada;
    return !when.isBefore(start) && when.isBefore(end);
  }).toList();
  selected.sort(
    (a, b) => b.dataInicioPlanejada.compareTo(a.dataInicioPlanejada),
  );
  return selected;
}
