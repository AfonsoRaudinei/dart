import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/contracts/i_ndvi_latest_lookup.dart';
import '../../../../core/contracts/i_ndvi_latest_lookup_provider.dart';
import '../../../../core/contracts/ndvi_latest_summary.dart';
import '../../../../core/html_templates/relatorio_html_renderer.dart';
import '../domain/relatorio_ndvi_caption.dart';
import '../models/visit_session_snapshot.dart';

Future<List<Map<String, dynamic>>> enrichRelatorioTalhoesWithNdvi(
  WidgetRef ref,
  List<TalhaoVisitado> talhoes,
) async {
  if (talhoes.isEmpty) return const [];

  INdviLatestLookup lookup;
  try {
    lookup = ref.read(ndviLatestLookupProvider);
  } catch (_) {
    return talhoes.map((t) => t.toJson()).toList();
  }

  final enriched = <Map<String, dynamic>>[];
  for (final talhao in talhoes) {
    final map = Map<String, dynamic>.from(talhao.toJson());
    try {
      final summary = await lookup.getLatest(talhao.talhaoId);
      if (summary != null && relatorioNdviSummaryHasImage(summary)) {
        final path = await _resolveExistingNdviPath(summary);
        if (path != null && path.isNotEmpty) {
          final src = await RelatorioHtmlRenderer.resolvePhotoSrcForExport(path);
          if (src.isNotEmpty) {
            map['ndviImageSrc'] = src;
            final caption = relatorioNdviCaption(summary);
            if (caption != null && caption.isNotEmpty) {
              map['ndviCaption'] = caption;
            }
          }
        }
      }
    } catch (_) {
      // Lookup opcional — talhão segue sem NDVI no HTML.
    }
    enriched.add(map);
  }
  return enriched;
}

Future<String?> _resolveExistingNdviPath(NdviLatestSummary summary) async {
  final green = summary.greenMaskLocalPath?.trim();
  if (green != null && green.isNotEmpty && await File(green).exists()) {
    return green;
  }
  final local = summary.localPath?.trim();
  if (local != null && local.isNotEmpty && await File(local).exists()) {
    return local;
  }
  final url = summary.imageUrl?.trim();
  if (url != null && url.isNotEmpty) return url;
  return null;
}
