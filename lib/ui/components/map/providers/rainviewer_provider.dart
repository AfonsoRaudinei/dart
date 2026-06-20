import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../../../../core/config/map_config.dart';

typedef RainviewerFetch = Future<http.Response> Function(Uri uri);

class RainviewerRadarFrame {
  final int time;
  final String path;
  final String urlTemplate;

  const RainviewerRadarFrame({
    required this.time,
    required this.path,
    required this.urlTemplate,
  });
}

final rainviewerFetchProvider = Provider<RainviewerFetch>((ref) {
  return (uri) => http.get(uri).timeout(const Duration(seconds: 8));
});

/// Liga/desliga o overlay de radar de chuva.
///
/// Provider dedicado (não reaproveita `armedModeProvider`) porque o radar é um
/// **overlay persistente**, não um "modo de toque" mutuamente exclusivo. Assim,
/// armar Ocorrências/Marketing não desliga mais a chuva silenciosamente.
final radarEnabledProvider = StateProvider<bool>((ref) => false);

/// Índice do frame atual da animação do radar.
final rainviewerFrameIndexProvider = StateProvider.autoDispose<int>((ref) => 0);

@visibleForTesting
List<RainviewerRadarFrame> parseRainviewerRadarFrames(
  Map<String, dynamic> json,
) {
  final radarMap = json['radar'] as Map<String, dynamic>?;
  if (radarMap == null) return const [];

  final past = radarMap['past'] as List<dynamic>?;
  if (past == null || past.isEmpty) return const [];

  final rawHost = (json['host'] as String?)?.trim().replaceAll(
    RegExp(r'/$'),
    '',
  );
  final host = rawHost == null || rawHost.isEmpty
      ? MapConfig.rainViewerTileBase
      : rawHost;

  return past
      .whereType<Map<String, dynamic>>()
      .map((frame) {
        final time = frame['time'];
        final path = frame['path'] as String?;
        if (time is! int || path == null || path.isEmpty) return null;

        return RainviewerRadarFrame(
          time: time,
          path: path,
          urlTemplate: '$host$path/512/{z}/{x}/{y}/2/1_1.png',
        );
      })
      .whereType<RainviewerRadarFrame>()
      .toList(growable: false);
}

/// Provider que busca todos os frames passados de radar da RainViewer.
///
/// Retorna a lista ordenada de frames disponíveis em radar.past, preservando a
/// ordem do manifesto. Falhas remotas degradam para lista vazia sem throw.
///
/// autoDispose: libera quando não há listeners (ex: radar desativado).
/// Graceful degradation: qualquer falha retorna lista vazia sem comprometer UI.
///
/// Uso no mapa:
/// ```dart
/// final frames = ref.watch(rainviewerRadarFramesProvider).valueOrNull ?? [];
/// if (frames.isNotEmpty) TileLayer(urlTemplate: frames[index].urlTemplate);
/// ```
final rainviewerRadarFramesProvider =
    FutureProvider.autoDispose<List<RainviewerRadarFrame>>((ref) async {
      try {
        final fetch = ref.watch(rainviewerFetchProvider);
        final response = await fetch(Uri.parse(MapConfig.rainViewerApiUrl));

        if (response.statusCode != 200) {
          debugPrint('[RainViewer] HTTP ${response.statusCode}');
          return const [];
        }

        final decoded = jsonDecode(response.body);
        if (decoded is! Map<String, dynamic>) return const [];

        return parseRainviewerRadarFrames(decoded);
      } catch (e) {
        debugPrint('[RainViewer] Erro ao buscar tiles: $e');
        return const [];
      }
    });
