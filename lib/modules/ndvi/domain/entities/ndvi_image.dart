/// Entidade de domínio — representa uma imagem NDVI de um talhão.
///
/// Fonte pode ser 'sentinel' (Sentinel Hub) ou 'planet' (Planet Labs).
/// [imageBase64] é o PNG codificado em base64 retornado pela Edge Function.
/// [imageCachePath] é o path local após gravação em SQLite (uso offline).
class NdviImage {
  final String areaId;
  final DateTime date;

  /// Base64 PNG retornado pela Edge Function (ausente quando carregado do cache).
  final String? imageBase64;

  /// Path local do arquivo em cache (SQLite → ndvi_cache.image_path).
  final String? imageCachePath;

  /// 'sentinel' | 'planet'
  final String source;

  final double? cloudCoverage;
  final List<DateTime> availableDates;
  final DateTime cachedAt;

  const NdviImage({
    required this.areaId,
    required this.date,
    this.imageBase64,
    this.imageCachePath,
    required this.source,
    this.cloudCoverage,
    required this.availableDates,
    required this.cachedAt,
  });

  bool get isCached => imageCachePath != null;
  bool get hasHighCloudCoverage =>
      cloudCoverage != null && cloudCoverage! > 80.0;
}
