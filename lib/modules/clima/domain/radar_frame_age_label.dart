/// Rótulo de idade do frame de radar para o banner do mapa.
String formatClimaRadarFrameAgeLabel(int frameTimeUnix, DateTime now) {
  final frameTime = DateTime.fromMillisecondsSinceEpoch(
    frameTimeUnix * 1000,
    isUtc: true,
  ).toLocal();
  final diff = now.difference(frameTime);
  if (diff.inMinutes < 1) return 'agora';
  if (diff.inMinutes < 60) return 'há ${diff.inMinutes} min';
  return 'há ${diff.inHours} h';
}
