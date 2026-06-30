import '../../../core/utils/app_logger.dart';
import 'entities/radar_fetch_result.dart';

/// Telemetria sanitizada do overlay RainViewer (sem URLs completas).
void logClimaRadarFetch(ClimaRadarFetchResult result) {
  AppLogger.debug(
    'state=${result.status.name} '
    'frameCount=${result.frames.length} '
    'latencyMs=${result.latencyMs}'
    '${result.httpStatusCode == null ? '' : ' http=${result.httpStatusCode}'}',
    tag: 'Radar',
  );
}

void logClimaRadarOverlayState(String overlayState) {
  AppLogger.debug('overlayState=$overlayState', tag: 'Radar');
}
