import 'dart:convert';

/// Máximo de fotos de um case Resultado (ADR-065).
const int kMarketingResultadoFotosMax = 5;

/// Mínimo de fotos para publicar um case Resultado (ADR-065).
const int kMarketingResultadoFotosMin = 1;

/// Remove URLs vazias/brancas, apara espaços e respeita o limite máximo.
List<String> normalizeFotosResultado(Iterable<Object?> urls) {
  final result = <String>[];
  for (final item in urls) {
    if (item is! String) continue;
    final trimmed = item.trim();
    if (trimmed.isEmpty) continue;
    result.add(trimmed);
    if (result.length == kMarketingResultadoFotosMax) break;
  }
  return result;
}

/// Lê `fotos_resultado_json` (String JSON, List ou null) sem lançar.
/// Valor malformado vira lista vazia.
List<String> parseFotosResultado(Object? raw) {
  try {
    if (raw is List) return normalizeFotosResultado(raw);
    if (raw is String) {
      if (raw.trim().isEmpty) return const [];
      final decoded = jsonDecode(raw);
      if (decoded is List) return normalizeFotosResultado(decoded);
    }
  } catch (_) {
    // Valor malformado: tratado como sem fotos.
  }
  return const [];
}

/// Serializa a lista para a coluna `fotos_resultado_json`.
String encodeFotosResultado(List<String> urls) =>
    jsonEncode(normalizeFotosResultado(urls));

/// Lista efetiva: a lista própria quando preenchida; senão só a capa legada.
List<String> resolveFotosResultadoEfetivas(
  List<String> fotosResultado,
  String? fotoPrincipalUrl,
) {
  final lista = normalizeFotosResultado(fotosResultado);
  if (lista.isNotEmpty) return lista;
  return normalizeFotosResultado([fotoPrincipalUrl]);
}
