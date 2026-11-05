import '../../../../core/contracts/ndvi_latest_summary.dart';

bool relatorioNdviSummaryHasImage(NdviLatestSummary summary) {
  final green =
      summary.greenMaskLocalPath != null &&
      summary.greenMaskLocalPath!.isNotEmpty;
  if (green) return true;
  final hasLocal = summary.localPath != null && summary.localPath!.isNotEmpty;
  final hasUrl =
      summary.imageUrl != null && summary.imageUrl!.trim().isNotEmpty;
  return hasLocal || hasUrl;
}

/// Legenda NDVI para export HTML: média · dd/mm · fonte (quando colormap).
String? relatorioNdviCaption(NdviLatestSummary summary) {
  if (!relatorioNdviSummaryHasImage(summary)) return null;
  final day = summary.imageDate.day.toString().padLeft(2, '0');
  final month = summary.imageDate.month.toString().padLeft(2, '0');
  final datePart = '$day/$month';
  if (!summary.isColormap) {
    return 'Preview · $datePart';
  }
  final mean = summary.ndviMean.toStringAsFixed(2);
  final source = summary.sourceLabel.trim();
  if (source.isNotEmpty) {
    return '$mean · $datePart · $source';
  }
  return '$mean · $datePart';
}

/// Preferência de path para imagem NDVI no relatório (máscara verde → local → URL).
String? relatorioNdviPreferredPath(NdviLatestSummary summary) {
  final green = summary.greenMaskLocalPath?.trim();
  if (green != null && green.isNotEmpty) return green;
  final local = summary.localPath?.trim();
  if (local != null && local.isNotEmpty) return local;
  final url = summary.imageUrl?.trim();
  if (url != null && url.isNotEmpty) return url;
  return null;
}
