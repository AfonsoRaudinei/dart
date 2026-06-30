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

@visibleForTesting
List<ClimaRadarFrame> parseClimaRadarFrames(Map<String, dynamic> json) {
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

        return ClimaRadarFrame(
          time: time,
          path: path,
          urlTemplate: '$host$path/512/{z}/{x}/{y}/2/1_1.png',
        );
      })
      .whereType<ClimaRadarFrame>()
      .toList(growable: false);
}

/// Busca frames passados do manifesto RainViewer.
class RainviewerRadarDatasource {
  const RainviewerRadarDatasource({required ClimaRadarFetch fetch}) : _fetch = fetch;

  final ClimaRadarFetch _fetch;

  Future<ClimaRadarFetchResult> fetchPastFrames() async {
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

      final frames = parseClimaRadarFrames(decoded);
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
