import 'ndvi_latest_summary.dart';

/// Lookup neutro da última imagem NDVI por talhão. ADR-045.
abstract interface class INdviLatestLookup {
  Future<NdviLatestSummary?> getLatest(String fieldId);

  /// Datas do talhão, da mais nova para a mais antiga. ADR-045.
  Future<List<NdviLatestSummary>> getHistory(String fieldId);

  /// Cena de uma data (`yyyy-MM-dd`). ADR-045.
  Future<NdviLatestSummary?> getForDate(String fieldId, String imageDate);
}
