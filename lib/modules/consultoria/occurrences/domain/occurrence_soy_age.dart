/// Idade de calendário (hora zerada). Data ausente ou no futuro → null.
int? occurrenceCalendarAgeDays(DateTime? from, DateTime today) {
  if (from == null) return null;
  final start = DateTime(from.year, from.month, from.day);
  final end = DateTime(today.year, today.month, today.day);
  final days = end.difference(start).inDays;
  if (days < 0) return null;
  return days;
}

/// DAP real a partir da data de plantio. Nunca negativo.
String? occurrenceDapLabel(DateTime? plantio, {DateTime? today}) {
  final days = occurrenceCalendarAgeDays(plantio, today ?? DateTime.now());
  if (days == null) return null;
  return '$days dias desde o plantio (DAP real)';
}

/// Idade a partir da emergência. Ausente ou futura → null.
String? occurrenceSoyAgeLabel(DateTime? emergencia, {DateTime? today}) {
  final days = occurrenceCalendarAgeDays(emergencia, today ?? DateTime.now());
  if (days == null) return null;
  return 'Soja com $days dias';
}

/// Linha do ciclo. null → sem linha.
String? occurrenceCicloLabel(int? cicloDias) {
  if (cicloDias == null || cicloDias < 0) return null;
  return '$cicloDias dias';
}

/// Dígitos → int. Vazio ou inválido → null (não lança).
int? parseOccurrenceCicloDias(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return null;
  if (!RegExp(r'^\d+$').hasMatch(trimmed)) return null;
  return int.tryParse(trimmed);
}
