import 'dart:convert';

import '../../../../core/contracts/i_field_lookup.dart';
import '../../../../core/geo/geo_json_polygon_geometry.dart';
import 'occurrence.dart';

/// Categorias que não entram no histórico factual do talhão.
bool isHistoricoExcludedOccurrence(Occurrence occurrence) {
  if (occurrence.amostraSolo) return true;
  if (isAreaVisitadaCategory(occurrence.category)) return true;
  return _isAmostraSoloCategory(occurrence.category);
}

bool occurrenceIsHistoricoDeleted(Occurrence occurrence) {
  final status = occurrence.syncStatus.trim().toLowerCase();
  if (status == 'deleted' || status == 'deleted_local') return true;
  return (occurrence.deletedAt?.trim() ?? '').isNotEmpty;
}

/// Chave da praga: descrição normalizada, ou a nota da categoria ativa.
String? occurrencePragaKey(Occurrence occurrence) {
  final fromDescription = normalizeOccurrencePragaText(occurrence.description);
  if (fromDescription != null) return fromDescription;
  return normalizeOccurrencePragaText(
    _noteForActiveCategory(occurrence.notasCategoriasJson, occurrence.category),
  );
}

/// Trim, minúsculas e espaços internos colapsados. Vazio vira null.
String? normalizeOccurrencePragaText(String? raw) {
  if (raw == null) return null;
  final collapsed = raw.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  if (collapsed.isEmpty) return null;
  return collapsed;
}

/// Código de estádio persistido, sem rótulo longo. Null se ausente.
String? occurrenceEstadioDisplay(Occurrence occurrence) {
  final code = occurrence.estadioFenologico?.trim() ?? '';
  if (code.isEmpty) return null;
  return code;
}

/// `field_id` gravado vence. Linha legada cai na geometria do talhão.
bool occurrenceMatchesField({
  required Occurrence occurrence,
  required String fieldId,
  FieldSummary? field,
}) {
  final wanted = fieldId.trim();
  if (wanted.isEmpty) return false;
  final stored = occurrence.fieldId?.trim() ?? '';
  if (stored.isNotEmpty) return stored == wanted;
  if (field == null) return false;
  final lat = occurrence.lat;
  final lng = occurrence.long;
  if (!isValidGeoPoint(lat, lng)) return false;
  return _fieldContainsPoint(field, lat!, lng!);
}

/// Linha factual. Null quando a chave falta, o talhão não resolve ou count < 2.
String? buildOccurrenceHistoricoTalhaoLinha({
  required Occurrence current,
  required List<Occurrence> candidates,
  required String? fieldId,
  FieldSummary? field,
}) {
  if (isHistoricoExcludedOccurrence(current)) return null;
  if (occurrenceIsHistoricoDeleted(current)) return null;
  final key = occurrencePragaKey(current);
  if (key == null) return null;
  final scope = fieldId?.trim() ?? '';
  if (scope.isEmpty) return null;
  final currentClient = current.clientId?.trim() ?? '';
  if (currentClient.isEmpty) return null;

  final matches = <Occurrence>[];
  final seen = <String>{};

  void consider(Occurrence row) {
    if (!seen.add(row.id)) return;
    if (occurrenceIsHistoricoDeleted(row)) return;
    if (isHistoricoExcludedOccurrence(row)) return;
    final client = row.clientId?.trim() ?? '';
    if (client != currentClient) return;
    if (!occurrenceMatchesField(
      occurrence: row,
      fieldId: scope,
      field: field,
    )) {
      return;
    }
    if (occurrencePragaKey(row) != key) return;
    matches.add(row);
  }

  for (final row in candidates) {
    if (row.id == current.id) continue;
    consider(row);
  }
  consider(current);
  if (!matches.any((row) => row.id == current.id)) return null;

  return formatHistoricoTalhaoCopy(
    pragaKey: key,
    count: matches.length,
    estadio: matches.isEmpty
        ? null
        : occurrenceEstadioDisplay(_latestOccurrence(matches)),
    latestAt: matches.isEmpty ? null : _latestOccurrence(matches).createdAt,
  );
}

/// Copy PT. Null quando count < 2 ou a chave está vazia.
String? formatHistoricoTalhaoCopy({
  required String pragaKey,
  required int count,
  String? estadio,
  DateTime? latestAt,
}) {
  if (count < 2) return null;
  final label = _capitalizeFirst(pragaKey.trim());
  if (label.isEmpty) return null;
  final stage = estadio?.trim() ?? '';
  final when = stage.isNotEmpty
      ? stage
      : (latestAt == null ? '' : 'data ${_formatDay(latestAt)}');
  if (when.isEmpty) return null;
  return '$label apareceu $count vezes; a última em $when.';
}

Occurrence _latestOccurrence(List<Occurrence> matches) {
  var latest = matches.first;
  for (final row in matches.skip(1)) {
    if (row.createdAt.isAfter(latest.createdAt)) latest = row;
  }
  return latest;
}

String _capitalizeFirst(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) return trimmed;
  final runes = trimmed.runes.toList(growable: false);
  final first = String.fromCharCode(runes.first).toUpperCase();
  final rest = String.fromCharCodes(runes.skip(1));
  return '$first$rest';
}

String _formatDay(DateTime value) {
  final local = value.toLocal();
  final day = local.day.toString().padLeft(2, '0');
  final month = local.month.toString().padLeft(2, '0');
  return '$day/$month/${local.year}';
}

bool _isAmostraSoloCategory(String? category) {
  final value = category?.trim().toLowerCase() ?? '';
  return value == 'amostra_solo' ||
      value == 'amostra solo' ||
      value == 'amostra de solo' ||
      value == 'amostrasolo';
}

String? _noteForActiveCategory(String? notasJson, String? category) {
  if (notasJson == null || notasJson.trim().isEmpty) return null;
  final active = category?.trim() ?? '';
  if (active.isEmpty) return null;
  Object? decoded;
  try {
    decoded = jsonDecode(notasJson);
  } catch (_) {
    return null;
  }
  if (decoded is! Map) return null;

  final wanted = <String>{
    active.toLowerCase(),
    if (_noteKeyForCategory(active) case final key?) key.toLowerCase(),
  };

  for (final entry in decoded.entries) {
    final key = entry.key.toString().trim().toLowerCase();
    if (!wanted.contains(key)) continue;
    final value = entry.value?.toString();
    if (value != null && value.trim().isNotEmpty) return value;
  }
  return null;
}

/// Chave gravada em `notasCategoriasJson` (`OccurrenceCategory.name`).
String? _noteKeyForCategory(String category) {
  switch (category.trim().toLowerCase()) {
    case 'doenca':
    case 'doença':
      return 'doenca';
    case 'insetos':
    case 'pragas':
      return 'insetos';
    case 'daninhas':
    case 'ervas daninhas':
    case 'ervas_daninhas':
      return 'daninhas';
    case 'nutricional':
    case 'nutrientes':
      return 'nutricional';
    case 'agua':
    case 'água':
    case 'estresse hídrico':
      return 'agua';
    case 'amostra_solo':
    case 'amostra solo':
    case 'amostra de solo':
    case 'amostrasolo':
      return 'amostraSolo';
    case 'plantio':
      return 'plantio';
    case 'area_visitada':
    case 'area visitada':
    case 'areavisitada':
      return 'areaVisitada';
    default:
      return null;
  }
}

bool _fieldContainsPoint(FieldSummary field, double lat, double lng) {
  final bbox = field.bbox;
  if (bbox != null && bbox.length == 4) {
    if (lng < bbox[0] || lat < bbox[1] || lng > bbox[2] || lat > bbox[3]) {
      return false;
    }
  }
  return geoJsonContainsPoint(field.geometry, lat, lng);
}
