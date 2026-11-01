import 'ndvi_latest_summary.dart';

/// Lookup neutro da imagem NDVI por talhão. ADR-045.
///
/// Sem [imageDate], devolve a última imagem renderizável.
/// Com [imageDate] (`yyyy-MM-dd`), materializa essa data pelo mesmo
/// `ensureImageForDate` do histórico. O DTO [NdviLatestSummary] não muda.
abstract interface class INdviLatestLookup {
  Future<NdviLatestSummary?> getLatest(String fieldId, {String? imageDate});
}
