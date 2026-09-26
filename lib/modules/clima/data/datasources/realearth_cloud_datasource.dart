import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../../core/config/map_config.dart';
import '../../../../core/utils/app_logger.dart';
import '../../domain/entities/clima_cloud_frame.dart';

typedef ClimaCloudFetch = Future<http.Response> Function(Uri uri);

final RegExp _cloudTimeKey = RegExp(r'^(\d{8})\.(\d{6})$');

/// Último carimbo válido de `{ "globalir": ["YYYYMMDD.HHMMSS", ...] }`.
/// O manifesto vem em ordem cronológica: o último item é o frame mais novo.
ClimaCloudFrame? parseClimaCloudFrame(Map<String, dynamic> json) {
  final stamps = json[MapConfig.realEarthCloudProduct];
  if (stamps is! List || stamps.isEmpty) return null;

  for (var i = stamps.length - 1; i >= 0; i--) {
    final raw = stamps[i];
    if (raw is! String) continue;
    final match = _cloudTimeKey.firstMatch(raw.trim());
    if (match == null) continue;
    return ClimaCloudFrame(
      timeKey: raw.trim(),
      urlTemplate: MapConfig.realEarthCloudTileTemplate(
        match.group(1)!,
        match.group(2)!,
      ),
    );
  }
  return null;
}

ClimaCloudFrame climaCloudLatestFallbackFrame() {
  return const ClimaCloudFrame(
    timeKey: '',
    urlTemplate: MapConfig.realEarthCloudLatestTileTemplate,
  );
}

/// Busca o frame mais recente de nuvens (RealEarth `globalir`).
///
/// Falha de rede ou manifesto vazio devolve o template "latest", para o mapa
/// ainda tentar pintar nuvens sem travar o restante das camadas.
class RealEarthCloudDatasource {
  const RealEarthCloudDatasource({required ClimaCloudFetch fetch})
    : _fetch = fetch;

  final ClimaCloudFetch _fetch;

  Future<ClimaCloudFrame> fetchLatestFrame() async {
    try {
      final response = await _fetch(
        Uri.parse(MapConfig.realEarthCloudTimesUrl),
      );
      if (response.statusCode != 200) {
        AppLogger.warning(
          'Manifesto de nuvens indisponível',
          tag: 'Radar',
          error: 'HTTP ${response.statusCode}',
        );
        return climaCloudLatestFallbackFrame();
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        AppLogger.warning(
          'Manifesto de nuvens com corpo inválido',
          tag: 'Radar',
        );
        return climaCloudLatestFallbackFrame();
      }

      final frame = parseClimaCloudFrame(decoded);
      if (frame == null) {
        AppLogger.warning('Manifesto de nuvens sem frame válido', tag: 'Radar');
        return climaCloudLatestFallbackFrame();
      }

      AppLogger.debug('cloudFrame=${frame.timeKey}', tag: 'Radar');
      return frame;
    } catch (error) {
      AppLogger.warning('Falha ao buscar nuvens', tag: 'Radar', error: error);
      return climaCloudLatestFallbackFrame();
    }
  }
}
