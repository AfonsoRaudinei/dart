/// Frame de nuvens (infravermelho global) para o overlay do mapa.
class ClimaCloudFrame {
  /// Carimbo `YYYYMMDD.HHMMSS`. Vazio quando o tile é o "latest" sem horário.
  final String timeKey;
  final String urlTemplate;

  const ClimaCloudFrame({required this.timeKey, required this.urlTemplate});

  bool get isLatestFallback => timeKey.isEmpty;
}
