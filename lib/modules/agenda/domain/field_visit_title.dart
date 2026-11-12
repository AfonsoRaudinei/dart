/// Título do evento criado a partir do check-in de campo.
///
/// A regra da agenda exige entre 3 e 200 caracteres. Atividade curta
/// cai no rótulo padrão.
String fieldVisitTitle(String? activityType) {
  final trimmed = activityType?.trim() ?? '';
  if (trimmed.length >= 3 && trimmed.length <= 200) return trimmed;
  return 'Visita técnica';
}

/// Fim planejado sempre depois do início, com pelo menos 5 minutos.
DateTime fieldVisitPlannedEnd(DateTime start, DateTime? end) {
  final candidate = end ?? start.add(const Duration(hours: 1));
  if (!candidate.isAfter(start) ||
      candidate.difference(start).inMinutes < 5) {
    return start.add(const Duration(minutes: 5));
  }
  return candidate;
}
