import 'entities/event.dart';
import 'entities/visit_session.dart';

const _months = [
  'jan',
  'fev',
  'mar',
  'abr',
  'mai',
  'jun',
  'jul',
  'ago',
  'set',
  'out',
  'nov',
  'dez',
];

String formatEventDate(DateTime date) {
  return '${date.day} ${_months[date.month - 1]} ${date.year}';
}

String formatEventTime(DateTime time) {
  final hour = time.hour.toString().padLeft(2, '0');
  final minute = time.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}

String formatEventDuration(int minutes) {
  if (minutes < 1) return '<1 min';
  if (minutes < 60) return '$minutes min';
  final hours = minutes ~/ 60;
  final rest = minutes % 60;
  return rest == 0 ? '${hours}h' : '${hours}h ${rest}min';
}

/// Dia, horário e duração numa linha só. Visita já encerrada mostra o
/// horário real; antes disso, o planejado.
String eventWhenLine(Event event, [VisitSession? session]) {
  final realEnd = session?.endAtReal;
  final start = realEnd != null
      ? session!.startAtReal
      : event.dataInicioPlanejada;
  final end = realEnd ?? event.dataFimPlanejada;
  final minutes = end.difference(start).inMinutes;
  return '${formatEventDate(start)} · '
      '${formatEventTime(start)} – ${formatEventTime(end)} · '
      '${formatEventDuration(minutes)}';
}
