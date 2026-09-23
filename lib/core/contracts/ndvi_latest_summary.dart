/// Resumo neutro da última imagem NDVI de um talhão. ADR-045.
class NdviLatestSummary {
  const NdviLatestSummary({
    required this.imageDate,
    required this.ndviMean,
    required this.ndviMin,
    required this.ndviMax,
    required this.sourceLabel,
    this.localPath,
    this.imageUrl,
  });

  final DateTime imageDate;
  final double ndviMean;
  final double ndviMin;
  final double ndviMax;
  final String sourceLabel;

  /// Arquivo local da última imagem, quando já baixado. ADR-045.
  final String? localPath;

  /// URL remota da última imagem. ADR-045.
  final String? imageUrl;
}
