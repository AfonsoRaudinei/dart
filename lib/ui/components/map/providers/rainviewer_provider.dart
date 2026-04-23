import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../../../../core/config/map_config.dart';

/// Provider que busca o path do tile de radar mais recente da RainViewer.
///
/// Retorna a URL template completa do tile (com {z}/{x}/{y}) ou null em caso
/// de erro de rede, JSON malformado ou lista vazia.
///
/// autoDispose: libera quando não há listeners (ex: radar desativado).
/// Graceful degradation: qualquer falha retorna null sem throw.
///
/// Uso no mapa:
/// ```dart
/// final tileUrl = ref.watch(rainviewerTileUrlProvider).valueOrNull;
/// if (tileUrl != null) TileLayer(urlTemplate: tileUrl, ...);
/// ```
final rainviewerTileUrlProvider = FutureProvider.autoDispose<String?>((
  ref,
) async {
  try {
    final response = await http
        .get(Uri.parse(MapConfig.rainViewerApiUrl))
        .timeout(const Duration(seconds: 8));

    if (response.statusCode != 200) return null;

    final json = jsonDecode(response.body) as Map<String, dynamic>;

    final radarMap = json['radar'] as Map<String, dynamic>?;
    if (radarMap == null) return null;

    final past = radarMap['past'] as List<dynamic>?;
    if (past == null || past.isEmpty) return null;

    // Último item = frame de radar mais recente
    final lastFrame = past.last as Map<String, dynamic>?;
    if (lastFrame == null) return null;

    final path = lastFrame['path'] as String?;
    if (path == null || path.isEmpty) return null;

    // Monta URL template compatível com flutter_map TileLayer
    return '${MapConfig.rainViewerTileBase}$path/512/{z}/{x}/{y}/2/1_1.png';
  } catch (_) {
    // Qualquer erro de rede, parse ou timeout → null (mapa continua funcional)
    return null;
  }
});
