/// Frame de radar de precipitação (RainViewer — ADR-043).
class ClimaRadarFrame {
  final int time;
  final String path;
  final String urlTemplate;

  const ClimaRadarFrame({
    required this.time,
    required this.path,
    required this.urlTemplate,
  });
}
