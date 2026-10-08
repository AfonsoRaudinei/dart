import 'entities/radar_rain_frame.dart';

/// Índice do último quadro observado (último `past` antes do nowcast).
int climaRadarLatestPastFrameIndex(List<ClimaRadarFrame> frames) {
  if (frames.isEmpty) return 0;
  for (var i = frames.length - 1; i >= 0; i--) {
    if (!frames[i].isNowcast) return i;
  }
  return frames.length - 1;
}

/// Chave estável do manifesto para detectar recarga de frames.
String climaRadarFramesManifestKey(List<ClimaRadarFrame> frames) {
  if (frames.isEmpty) return '';
  final first = frames.first;
  final last = frames.last;
  return '${first.time}_${frames.length}_${last.time}_${last.isNowcast}';
}
