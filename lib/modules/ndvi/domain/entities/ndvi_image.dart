class NdviImage {
  final String id;
  final String fieldId;       // era areaId — renomeado
  final DateTime imageDate;   // era date — renomeado
  final double ndviMin;       // novo
  final double ndviMax;       // novo
  final double ndviMean;      // novo
  final String? imageUrl;     // URL remota opcional
  final String? localPath;    // path local após download
  final String source;        // 'sentinel' | 'planet' | 'auto'
  final DateTime fetchedAt;   // era cachedAt — renomeado
  final int syncStatus;       // 0=synced | 1=pending — novo

  const NdviImage({
    required this.id,
    required this.fieldId,
    required this.imageDate,
    required this.ndviMin,
    required this.ndviMax,
    required this.ndviMean,
    required this.source,
    required this.fetchedAt,
    required this.syncStatus,
    this.imageUrl,
    this.localPath,
  });
}
