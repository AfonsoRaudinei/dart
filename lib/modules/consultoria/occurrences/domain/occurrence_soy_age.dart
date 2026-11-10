import 'occurrence.dart';

/// Idade de calendário (hora zerada). Data ausente ou no futuro → null.
int? occurrenceCalendarAgeDays(DateTime? from, DateTime today) {
  if (from == null) return null;
  final start = DateTime(from.year, from.month, from.day);
  final end = DateTime(today.year, today.month, today.day);
  final days = end.difference(start).inDays;
  if (days < 0) return null;
  return days;
}

/// DAP a partir da data de plantio. Nunca negativo.
String? occurrenceDapLabel(DateTime? plantio, {DateTime? today}) {
  final days = occurrenceCalendarAgeDays(plantio, today ?? DateTime.now());
  if (days == null) return null;
  return '$days dias após o plantio (DAP)';
}

/// DAE a partir da emergência. Ausente ou futura → null.
String? occurrenceSoyAgeLabel(DateTime? emergencia, {DateTime? today}) {
  final days = occurrenceCalendarAgeDays(emergencia, today ?? DateTime.now());
  if (days == null) return null;
  return '$days dias após a emergência (DAE)';
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

DateTime? parseOccurrenceIsoDate(String? iso) {
  final value = iso?.trim() ?? '';
  if (value.isEmpty) return null;
  return DateTime.tryParse(value);
}

/// DAP compacto para lista/relatório (Farmbox).
String? occurrenceDapCampoLabel(DateTime? plantio, {DateTime? today}) {
  final days = occurrenceCalendarAgeDays(plantio, today ?? DateTime.now());
  if (days == null) return null;
  return '$days dias após o plantio';
}

/// DAE compacto para lista/relatório (Farmbox).
String? occurrenceDaeCampoLabel(DateTime? emergencia, {DateTime? today}) {
  final days = occurrenceCalendarAgeDays(emergencia, today ?? DateTime.now());
  if (days == null) return null;
  return '$days dias após a emergência';
}

/// Resumo DAP/DAE a partir das datas ISO da ocorrência.
String? occurrenceIdadeCampoResumo({
  String? dataPlantioIso,
  String? dataEmergenciaIso,
  DateTime? today,
}) {
  final t = today ?? DateTime.now();
  final parts = <String>[];
  final dap = occurrenceDapCampoLabel(
    parseOccurrenceIsoDate(dataPlantioIso),
    today: t,
  );
  if (dap != null) parts.add(dap);
  final dae = occurrenceDaeCampoLabel(
    parseOccurrenceIsoDate(dataEmergenciaIso),
    today: t,
  );
  if (dae != null) parts.add(dae);
  if (parts.isEmpty) return null;
  return parts.join(' · ');
}

/// Estádio (código ou rótulo) com idade de campo — ex.: `V4 — 32 dias após o plantio`.
String formatEstadioComIdadeCampo({
  String? estadioCode,
  String? estadioLabel,
  String? idadeResumo,
}) {
  final label = (estadioLabel?.trim().isNotEmpty == true)
      ? estadioLabel!.trim()
      : estadioCode?.trim();
  // Sufixo só junto do estádio. Sem estádio, a lista e o detalhe ficam iguais à main.
  if (label == null || label.isEmpty) {
    return '';
  }
  if (idadeResumo == null || idadeResumo.trim().isEmpty) {
    return label;
  }
  return '$label — $idadeResumo';
}

/// Linha única estádio + DAP/DAE para lista, detalhe e relatório.
String occurrenceEstadioDisplay(
  Occurrence occurrence, {
  DateTime? today,
  String? estadioLabel,
}) {
  return formatEstadioComIdadeCampo(
    estadioCode: occurrence.estadioFenologico,
    estadioLabel: estadioLabel,
    idadeResumo: occurrenceIdadeCampoResumo(
      dataPlantioIso: occurrence.dataPlantio,
      dataEmergenciaIso: occurrence.dataEmergencia,
      today: today,
    ),
  );
}
