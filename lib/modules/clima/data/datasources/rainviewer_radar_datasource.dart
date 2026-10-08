import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../../../core/config/map_config.dart';
import '../../../../core/utils/app_logger.dart';
import '../../domain/entities/radar_fetch_result.dart';
import '../../domain/entities/radar_rain_frame.dart';
import '../../domain/radar_overlay_logger.dart';

typedef ClimaRadarFetch = Future<http.Response> Function(Uri uri);

/// Lê `radar.past` e opcionalmente `radar.nowcast` (frames de previsão futura).
/// Por padrão utiliza opções 1_0 (suavizado sem neve) otimizado para o Brasil.
@visibleForTesting
List<ClimaRadarFrame> parseClimaRadarFrames(
  Map<String, dynamic> json, {
  int colorScheme = MapConfig.rainViewerDefaultColorScheme,
  String tileOptions = MapConfig.rainViewerDefaultTileOptions,
  bool includeNowcast = true,
}) {
  final radarMap = json['radar'] as Map<String, dynamic>?;
  if (radarMap == null) return const [];

  final past = radarMap['past'] as List<dynamic>? ?? const [];
  final nowcast = includeNowcast
      ? (radarMap['nowcast'] as List<dynamic>? ?? const [])
      : const [];

  if (past.isEmpty && nowcast.isEmpty) return const [];

  final rawHost = (json['host'] as String?)?.trim().replaceAll(
    RegExp(r'/$'),
    '',
  );
  final host = rawHost == null || rawHost.isEmpty
      ? MapConfig.rainViewerTileBase
      : rawHost;

  ClimaRadarFrame? toFrame(dynamic frame, {required bool isNowcast}) {
    if (frame is! Map<String, dynamic>) return null;
    final time = frame['time'];
    final path = frame['path'] as String?;
    if (time is! int || path == null || path.isEmpty) return null;

    return ClimaRadarFrame(
      time: time,
      path: path,
      urlTemplate: '$host$path/512/{z}/{x}/{y}/$colorScheme/$tileOptions.png',
      isNowcast: isNowcast,
    );
  }

  final pastFrames = past
      .map((f) => toFrame(f, isNowcast: false))
      .whereType<ClimaRadarFrame>();
  final nowcastFrames = nowcast
      .map((f) => toFrame(f, isNowcast: true))
      .whereType<ClimaRadarFrame>();

  return [...pastFrames, ...nowcastFrames];
}

/// Busca frames de radar do manifesto RainViewer.
class RainviewerRadarDatasource {
  const RainviewerRadarDatasource({required ClimaRadarFetch fetch})
    : _fetch = fetch;

  final ClimaRadarFetch _fetch;

  Future<ClimaRadarFetchResult> fetchPastFrames({
    int colorScheme = MapConfig.rainViewerDefaultColorScheme,
    String tileOptions = MapConfig.rainViewerDefaultTileOptions,
    bool includeNowcast = true,
  }) async {
    final stopwatch = Stopwatch()..start();
    try {
      final response = await _fetch(Uri.parse(MapConfig.rainViewerApiUrl));
      stopwatch.stop();

      if (response.statusCode != 200) {
        final result = ClimaRadarFetchResult(
          status: ClimaRadarFetchStatus.httpError,
          httpStatusCode: response.statusCode,
          latencyMs: stopwatch.elapsedMilliseconds,
        );
        logClimaRadarFetch(result);
        AppLogger.warning(
          'Manifesto RainViewer indisponível',
          tag: 'Radar',
          error: 'HTTP ${response.statusCode}',
        );
        return result;
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        final result = ClimaRadarFetchResult(
          status: ClimaRadarFetchStatus.parseError,
          latencyMs: stopwatch.elapsedMilliseconds,
        );
        logClimaRadarFetch(result);
        return result;
      }

      final frames = parseClimaRadarFrames(
        decoded,
        colorScheme: colorScheme,
        tileOptions: tileOptions,
        includeNowcast: includeNowcast,
      );
      final result = ClimaRadarFetchResult(
        status: frames.isEmpty
            ? ClimaRadarFetchStatus.emptyManifest
            : ClimaRadarFetchStatus.success,
        frames: frames,
        latencyMs: stopwatch.elapsedMilliseconds,
      );
      logClimaRadarFetch(result);
      return result;
    } on TimeoutException catch (error, stackTrace) {
      stopwatch.stop();
      final result = ClimaRadarFetchResult(
        status: ClimaRadarFetchStatus.networkError,
        latencyMs: stopwatch.elapsedMilliseconds,
      );
      logClimaRadarFetch(result);
      AppLogger.warning(
        'Timeout ao buscar manifesto RainViewer',
        tag: 'Radar',
        error: error,
      );
      AppLogger.debug(stackTrace.toString(), tag: 'Radar');
      return result;
    } catch (error, stackTrace) {
      stopwatch.stop();
      final result = ClimaRadarFetchResult(
        status: ClimaRadarFetchStatus.parseError,
        latencyMs: stopwatch.elapsedMilliseconds,
      );
      logClimaRadarFetch(result);
      AppLogger.warning(
        'Falha ao buscar manifesto RainViewer',
        tag: 'Radar',
        error: error,
      );
      AppLogger.debug(stackTrace.toString(), tag: 'Radar');
      return result;
    }
  }
}
