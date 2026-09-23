import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../contracts/i_ndvi_latest_lookup_provider.dart';
import '../contracts/ndvi_latest_summary.dart';

/// Talhão cujo raster NDVI deve cobrir o polígono no mapa. Sessão apenas.
final mapNdviOverlayFieldIdProvider = StateProvider<String?>((ref) => null);

/// Última imagem do talhão pedido pela rota `/map?ndvi=1`.
final mapNdviOverlaySummaryProvider =
    FutureProvider<NdviLatestSummary?>((ref) async {
      final fieldId = ref.watch(mapNdviOverlayFieldIdProvider);
      if (fieldId == null || fieldId.isEmpty) return null;
      return ref.watch(ndviLatestLookupProvider).getLatest(fieldId);
    });

/// Colormap com arquivo local existente ou URL. Preview RGB não cobre o mapa.
bool mapNdviSummaryCoversField(NdviLatestSummary? summary) {
  if (summary == null || !summary.isColormap) return false;
  final path = summary.localPath;
  if (path != null && path.isNotEmpty && File(path).existsSync()) return true;
  final url = summary.imageUrl?.trim();
  return url != null && url.isNotEmpty;
}
