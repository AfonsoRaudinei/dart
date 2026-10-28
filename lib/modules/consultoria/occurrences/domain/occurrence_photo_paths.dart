import 'dart:convert';

import 'occurrence.dart';

/// Chave reservada em `fotos_categorias_json` para legendas (ADR-014).
///
/// Parsers antigos só leem valores `List` — um mapa nesta chave não vira path.
const kFotosCategoriasCaptionsKey = '_captions';

/// Teto da legenda editável por foto (campo do preview).
const kOccurrencePhotoCaptionMaxLength = 120;

bool _isCaptionsKey(String key) => key == kFotosCategoriasCaptionsKey;

String clipOccurrencePhotoCaption(String raw) {
  final trimmed = raw.trim();
  if (trimmed.length <= kOccurrencePhotoCaptionMaxLength) return trimmed;
  return trimmed.substring(0, kOccurrencePhotoCaptionMaxLength).trim();
}

/// Decodifica `fotos_categorias_json` em lista plana de paths (ordem preservada).
List<String> parseFotosCategoriasJson(String? raw) {
  final byCategory = parseFotosCategoriasByCategory(raw);
  final paths = <String>[];
  for (final list in byCategory.values) {
    paths.addAll(list);
  }
  return paths;
}

/// Paths por categoria. Ignora a chave reservada `_captions`.
Map<String, List<String>> parseFotosCategoriasByCategory(String? raw) {
  if (raw == null || raw.isEmpty || raw == '{}') return {};
  try {
    final decoded = jsonDecode(raw);
    if (decoded is! Map) return {};
    final photos = <String, List<String>>{};
    for (final entry in decoded.entries) {
      final key = entry.key.toString();
      if (_isCaptionsKey(key)) continue;
      final value = entry.value;
      if (value is! List) continue;
      final paths = <String>[];
      for (final item in value) {
        final path = item.toString();
        if (path.isNotEmpty) paths.add(path);
      }
      if (paths.isNotEmpty) photos[key] = paths;
    }
    return photos;
  } catch (_) {
    return {};
  }
}

/// Legendas opcionais keyed pelo path armazenado.
Map<String, String> parseFotosCaptions(String? raw) {
  if (raw == null || raw.isEmpty || raw == '{}') return {};
  try {
    final decoded = jsonDecode(raw);
    if (decoded is! Map) return {};
    final rawCaptions = decoded[kFotosCategoriasCaptionsKey];
    if (rawCaptions is! Map) return {};
    final captions = <String, String>{};
    for (final entry in rawCaptions.entries) {
      final path = entry.key.toString();
      final caption = clipOccurrencePhotoCaption(entry.value.toString());
      if (path.isEmpty || caption.isEmpty) continue;
      captions[path] = caption;
    }
    return captions;
  } catch (_) {
    return {};
  }
}

/// Legenda da foto [path], se houver.
String? captionForPath(String? raw, String path) {
  if (path.isEmpty) return null;
  final caption = parseFotosCaptions(raw)[path];
  if (caption == null || caption.isEmpty) return null;
  return caption;
}

/// Todos os paths de foto de uma ocorrência (galeria + fallback `photoPath`).
List<String> allPhotoPaths(Occurrence occurrence) {
  final fromJson = parseFotosCategoriasJson(occurrence.fotosCategoriasJson);
  final cover = occurrence.photoPath;
  if (cover == null || cover.isEmpty) return fromJson;

  if (fromJson.isEmpty) return [cover];
  if (fromJson.contains(cover)) return fromJson;
  return [...fromJson, cover];
}

/// Primeiro path candidato a capa (resolução de arquivo é feita na UI).
String? coverPhotoPath(Occurrence occurrence) {
  final paths = allPhotoPaths(occurrence);
  return paths.isEmpty ? null : paths.first;
}

/// Reconstrói JSON de galeria substituindo paths por versão armazenada (relativa).
///
/// Preserva e reescreve as chaves de `_captions` quando o path muda.
String? encodeFotosCategoriasJson(
  String? raw,
  String Function(String path) toStoredPath,
) {
  if (raw == null || raw.isEmpty || raw == '{}') return raw;
  try {
    final decoded = jsonDecode(raw);
    if (decoded is! Map) return raw;
    final updated = <String, dynamic>{};
    final pathRewrite = <String, String>{};
    for (final entry in decoded.entries) {
      final key = entry.key.toString();
      if (_isCaptionsKey(key)) continue;
      final list = entry.value;
      if (list is! List) continue;
      final paths = <String>[];
      for (final item in list) {
        final original = item.toString();
        if (original.isEmpty) continue;
        final stored = toStoredPath(original);
        if (stored.isEmpty) continue;
        pathRewrite[original] = stored;
        paths.add(stored);
      }
      if (paths.isNotEmpty) updated[key] = paths;
    }
    final hasPhotos = updated.isNotEmpty;
    if (!hasPhotos) return null;

    final rawCaptions = decoded[kFotosCategoriasCaptionsKey];
    if (rawCaptions is Map) {
      final captions = <String, String>{};
      for (final entry in rawCaptions.entries) {
        final originalKey = entry.key.toString();
        final caption = clipOccurrencePhotoCaption(entry.value.toString());
        if (originalKey.isEmpty || caption.isEmpty) continue;
        final stored = pathRewrite[originalKey] ?? toStoredPath(originalKey);
        if (stored.isEmpty) continue;
        captions[stored] = caption;
      }
      if (captions.isNotEmpty) {
        updated[kFotosCategoriasCaptionsKey] = captions;
      }
    }
    return jsonEncode(updated);
  } catch (_) {
    return raw;
  }
}

/// Monta o JSON persistido a partir das listas do form + legendas.
String? encodeFotosCategoriasWithCaptions(
  Map<String, List<String>> fotos,
  Map<String, String> captions,
) {
  final payload = <String, dynamic>{};
  final knownPaths = <String>{};
  for (final entry in fotos.entries) {
    if (_isCaptionsKey(entry.key)) continue;
    final paths = entry.value.where((path) => path.isNotEmpty).toList();
    if (paths.isEmpty) continue;
    payload[entry.key] = paths;
    knownPaths.addAll(paths);
  }
  if (payload.isEmpty) return null;

  final kept = <String, String>{};
  for (final entry in captions.entries) {
    if (!knownPaths.contains(entry.key)) continue;
    final caption = clipOccurrencePhotoCaption(entry.value);
    if (caption.isEmpty) continue;
    kept[entry.key] = caption;
  }
  if (kept.isNotEmpty) {
    payload[kFotosCategoriasCaptionsKey] = kept;
  }
  return jsonEncode(payload);
}
