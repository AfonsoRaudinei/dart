/// Rótulo de idade do frame de radar para o player e banner do mapa.
String formatClimaRadarFrameAgeLabel(
  int frameTimeUnix,
  DateTime now, {
  bool isNowcast = false,
}) {
  final frameTime = DateTime.fromMillisecondsSinceEpoch(
    frameTimeUnix * 1000,
    isUtc: true,
  ).toLocal();
  final diff = now.difference(frameTime);

  if (isNowcast || diff.isNegative) {
    final futureMinutes = (-diff.inMinutes).clamp(0, 180);
    if (futureMinutes < 1) return 'agora (prev.)';
    if (futureMinutes < 60) return '+$futureMinutes min (prev.)';
    return '+${(-diff.inHours).clamp(1, 12)} h (prev.)';
  }

  if (diff.inMinutes < 1) return 'agora';
  if (diff.inMinutes < 60) return 'há ${diff.inMinutes} min';
  return 'há ${diff.inHours} h';
}

/// Formata a hora do frame no padrão HH:mm local.
String formatClimaRadarFrameTimeString(int frameTimeUnix) {
  final frameTime = DateTime.fromMillisecondsSinceEpoch(
    frameTimeUnix * 1000,
    isUtc: true,
  ).toLocal();
  final hour = frameTime.hour.toString().padLeft(2, '0');
  final minute = frameTime.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}
