import 'dart:convert';

import 'occurrence.dart';

/// Decodifica `fotos_categorias_json` em lista plana de paths (ordem preservada).
List<String> parseFotosCategoriasJson(String? raw) {
  if (raw == null || raw.isEmpty || raw == '{}') return [];
  try {
    final decoded = jsonDecode(raw);
    if (decoded is! Map) return [];
    final paths = <String>[];
    for (final value in decoded.values) {
      if (value is List) {
        for (final item in value) {
          final path = item.toString();
          if (path.isNotEmpty) paths.add(path);
        }
      }
    }
    return paths;
  } catch (_) {
    return [];
  }
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
String? encodeFotosCategoriasJson(
  String? raw,
  String Function(String path) toStoredPath,
) {
  if (raw == null || raw.isEmpty || raw == '{}') return raw;
  try {
    final decoded = jsonDecode(raw);
    if (decoded is! Map) return raw;
    final updated = <String, List<String>>{};
    for (final entry in decoded.entries) {
      final list = entry.value;
      if (list is! List) continue;
      updated[entry.key.toString()] = list
          .map((item) => toStoredPath(item.toString()))
          .where((path) => path.isNotEmpty)
          .toList();
    }
    if (updated.isEmpty) return null;
    return jsonEncode(updated);
  } catch (_) {
    return raw;
  }
}
