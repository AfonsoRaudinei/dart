/// Resumo neutro da última imagem NDVI de um talhão. ADR-045.
class NdviLatestSummary {
  const NdviLatestSummary({
    required this.imageDate,
    required this.ndviMean,
    required this.ndviMin,
    required this.ndviMax,
    required this.sourceLabel,
    required this.source,
    required this.isColormap,
    this.localPath,
    this.imageUrl,
  });

  final DateTime imageDate;
  final double ndviMean;
  final double ndviMin;
  final double ndviMax;
  final String sourceLabel;

  /// Fonte persistida (`sentinel`, `planet_preview`, …). ADR-045.
  final String source;

  /// True quando a imagem é raster NDVI e pode ser georreferenciada no card.
  /// Preview RGB (Planet) é false. Calculado pelo adapter com a regra do módulo.
  final bool isColormap;

  /// Arquivo local da última imagem, quando já baixado. ADR-045.
  final String? localPath;

  /// URL remota da última imagem. ADR-045.
  final String? imageUrl;
}
