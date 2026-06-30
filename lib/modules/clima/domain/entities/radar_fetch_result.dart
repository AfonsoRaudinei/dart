import 'radar_rain_frame.dart';

enum ClimaRadarFetchStatus {
  success,
  emptyManifest,
  httpError,
  networkError,
  parseError,
}

class ClimaRadarFetchResult {
  final ClimaRadarFetchStatus status;
  final List<ClimaRadarFrame> frames;
  final int? httpStatusCode;
  final int latencyMs;

  const ClimaRadarFetchResult({
    required this.status,
    this.frames = const [],
    this.httpStatusCode,
    this.latencyMs = 0,
  });

  bool get hasFrames => frames.isNotEmpty;
}
