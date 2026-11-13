import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/contracts/i_ndvi_latest_lookup.dart';
import '../../../../core/contracts/i_ndvi_latest_lookup_provider.dart';
import '../../../../core/contracts/ndvi_latest_summary.dart';
import '../../../../core/html_templates/relatorio_html_renderer.dart';
import '../domain/relatorio_ndvi_caption.dart';
import '../models/visit_session_snapshot.dart';

const Duration kRelatorioNdviPerFieldTimeout = Duration(seconds: 4);
const Duration kRelatorioNdviTotalBudget = Duration(seconds: 8);

Future<List<Map<String, dynamic>>> enrichRelatorioTalhoesWithNdvi(
  WidgetRef ref,
  List<TalhaoVisitado> talhoes,
) async {
  if (talhoes.isEmpty) return const [];

  INdviLatestLookup? lookup;
  try {
    lookup = ref.read(ndviLatestLookupProvider);
  } catch (_) {
    lookup = null;
  }
  return enrichTalhoesWithNdviLookup(lookup, talhoes);
}

/// NDVI é opcional no HTML: o lookup pode disparar fetch remoto, então cada
/// talhão tem timeout próprio e o conjunto tem teto global — ao estourar,
/// os talhões restantes seguem sem NDVI para não prender abertura/export.
@visibleForTesting
Future<List<Map<String, dynamic>>> enrichTalhoesWithNdviLookup(
  INdviLatestLookup? lookup,
  List<TalhaoVisitado> talhoes, {
  Duration perFieldTimeout = kRelatorioNdviPerFieldTimeout,
  Duration totalBudget = kRelatorioNdviTotalBudget,
}) async {
  final enriched = [
    for (final talhao in talhoes) Map<String, dynamic>.from(talhao.toJson()),
  ];
  if (lookup == null) return enriched;

  final stopwatch = Stopwatch()..start();
  for (var i = 0; i < talhoes.length; i++) {
    final remaining = totalBudget - stopwatch.elapsed;
    // Sobra menor que o timer não abre outro lookup: no CI o timeout de 1 ms
    // ainda cabia uma 4ª chamada dentro do teto.
    if (remaining < const Duration(milliseconds: 20)) break;
    final timeout = remaining < perFieldTimeout ? remaining : perFieldTimeout;
    try {
      final ndvi = await _resolveTalhaoNdvi(
        lookup,
        talhoes[i].talhaoId,
      ).timeout(timeout);
      if (ndvi == null) continue;
      enriched[i]['ndviImageSrc'] = ndvi.src;
      if (ndvi.caption != null) enriched[i]['ndviCaption'] = ndvi.caption;
    } catch (_) {
      // Timeout ou falha do lookup — talhão segue sem NDVI no HTML.
    }
  }
  return enriched;
}

Future<({String src, String? caption})?> _resolveTalhaoNdvi(
  INdviLatestLookup lookup,
  String talhaoId,
) async {
  final summary = await lookup.getLatest(talhaoId);
  if (summary == null || !relatorioNdviSummaryHasImage(summary)) return null;
  final path = await _resolveExistingNdviPath(summary);
  if (path == null || path.isEmpty) return null;
  final src = await RelatorioHtmlRenderer.resolvePhotoSrcForExport(path);
  if (src.isEmpty) return null;
  final caption = relatorioNdviCaption(summary);
  return (
    src: src,
    caption: caption != null && caption.isNotEmpty ? caption : null,
  );
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
