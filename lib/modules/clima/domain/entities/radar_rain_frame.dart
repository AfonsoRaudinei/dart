/// Frame de radar de precipitação (RainViewer — ADR-043).
class ClimaRadarFrame {
  final int time;
  final String path;
  final String urlTemplate;
  final bool isNowcast;

  const ClimaRadarFrame({
    required this.time,
    required this.path,
    required this.urlTemplate,
    this.isNowcast = false,
  });
}
