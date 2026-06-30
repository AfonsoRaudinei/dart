import 'ndvi_latest_summary.dart';

/// Lookup neutro da última imagem NDVI por talhão. ADR-045.
abstract interface class INdviLatestLookup {
  Future<NdviLatestSummary?> getLatest(String fieldId);
}
