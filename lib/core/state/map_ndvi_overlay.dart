import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../contracts/i_ndvi_latest_lookup_provider.dart';
import '../contracts/ndvi_latest_summary.dart';

/// Talhão cujo raster NDVI deve cobrir o polígono no mapa. Sessão apenas.
final mapNdviOverlayFieldIdProvider = StateProvider<String?>((ref) => null);

/// Quando true, o overlay do talhão no mapa exibe o modo Preto e Branco
/// (Máscara verde binária ou filtro monocromático de alto contraste).
final mapNdviMonochromeEnabledProvider = StateProvider<bool>((ref) => false);

/// Data NDVI pedida no mapa para um talhão. Sessão, sem autoDispose.
/// Vale só enquanto [fieldId] for o talhão do overlay; null = última imagem.
class MapNdviDateSelection {
  const MapNdviDateSelection({required this.fieldId, required this.dateKey});

  final String fieldId;

  /// `yyyy-MM-dd`, o mesmo formato de `ndviImageDateKey`.
  final String dateKey;

  @override
  bool operator ==(Object other) {
    return other is MapNdviDateSelection &&
        other.fieldId == fieldId &&
        other.dateKey == dateKey;
  }

  @override
  int get hashCode => Object.hash(fieldId, dateKey);
}

class MapNdviSelectedDateNotifier extends Notifier<MapNdviDateSelection?> {
  @override
  MapNdviDateSelection? build() {
    ref.watch(mapNdviOverlayFieldIdProvider);
    return null;
  }

  void select(MapNdviDateSelection? value) => state = value;
}

final mapNdviSelectedDateProvider =
    NotifierProvider<MapNdviSelectedDateNotifier, MapNdviDateSelection?>(
      MapNdviSelectedDateNotifier.new,
    );

/// Último raster que cobriu o polígono, para manter a imagem se a data nova falhar.
class MapNdviRetainedSummary {
  const MapNdviRetainedSummary({required this.fieldId, required this.summary});

  final String fieldId;
  final NdviLatestSummary summary;
}

class MapNdviRetainedSummaryNotifier extends Notifier<MapNdviRetainedSummary?> {
  @override
  MapNdviRetainedSummary? build() {
    ref.watch(mapNdviOverlayFieldIdProvider);
    return null;
  }

  void keep(MapNdviRetainedSummary? value) => state = value;
}

final mapNdviRetainedSummaryProvider =
    NotifierProvider<MapNdviRetainedSummaryNotifier, MapNdviRetainedSummary?>(
      MapNdviRetainedSummaryNotifier.new,
    );

/// Falha ao materializar a data pedida. A UI reusa o texto do sheet de histórico.
class MapNdviDateError {
  const MapNdviDateError({required this.fieldId, required this.dateKey});

  final String fieldId;
  final String dateKey;

  @override
  bool operator ==(Object other) {
    return other is MapNdviDateError &&
        other.fieldId == fieldId &&
        other.dateKey == dateKey;
  }

  @override
  int get hashCode => Object.hash(fieldId, dateKey);
}

class MapNdviOverlayDateErrorNotifier extends Notifier<MapNdviDateError?> {
  @override
  MapNdviDateError? build() {
    ref.watch(mapNdviOverlayFieldIdProvider);
    return null;
  }

  void report(MapNdviDateError? value) => state = value;
}

final mapNdviOverlayDateErrorProvider =
    NotifierProvider<MapNdviOverlayDateErrorNotifier, MapNdviDateError?>(
      MapNdviOverlayDateErrorNotifier.new,
    );

/// Imagem NDVI do talhão no overlay. Sem data escolhida, é a última.
/// Com data, pede essa imagem; se falhar e já houver raster, mantém o anterior.
final mapNdviOverlaySummaryProvider = FutureProvider<NdviLatestSummary?>((
  ref,
) async {
  final fieldId = ref.watch(mapNdviOverlayFieldIdProvider);
  final selection = ref.watch(mapNdviSelectedDateProvider);
  final lookup = ref.watch(ndviLatestLookupProvider);

  if (fieldId == null || fieldId.isEmpty) return null;

  final dateKey = selection != null && selection.fieldId == fieldId
      ? selection.dateKey
      : null;

  try {
    final summary = await lookup.getLatest(fieldId, imageDate: dateKey);
    if (!_mapNdviRequestStillCurrent(ref, fieldId, dateKey)) {
      return summary;
    }
    final covers = mapNdviSummaryCoversField(summary);
    if (covers && summary != null) {
      ref
          .read(mapNdviRetainedSummaryProvider.notifier)
          .keep(MapNdviRetainedSummary(fieldId: fieldId, summary: summary));
      ref.read(mapNdviOverlayDateErrorProvider.notifier).report(null);
      return summary;
    }

    if (dateKey != null) {
      final retained = ref.read(mapNdviRetainedSummaryProvider);
      final error = MapNdviDateError(fieldId: fieldId, dateKey: dateKey);
      ref.read(mapNdviOverlayDateErrorProvider.notifier).report(error);
      if (retained != null && retained.fieldId == fieldId) {
        return retained.summary;
      }
    }
    return summary;
  } catch (_) {
    if (!_mapNdviRequestStillCurrent(ref, fieldId, dateKey)) return null;
    if (dateKey != null) {
      final retained = ref.read(mapNdviRetainedSummaryProvider);
      if (retained != null && retained.fieldId == fieldId) {
        ref
            .read(mapNdviOverlayDateErrorProvider.notifier)
            .report(MapNdviDateError(fieldId: fieldId, dateKey: dateKey));
        return retained.summary;
      }
    }
    rethrow;
  }
});

bool _mapNdviRequestStillCurrent(Ref ref, String fieldId, String? dateKey) {
  if (ref.read(mapNdviOverlayFieldIdProvider) != fieldId) return false;
  final selection = ref.read(mapNdviSelectedDateProvider);
  final currentKey = selection != null && selection.fieldId == fieldId
      ? selection.dateKey
      : null;
  return currentKey == dateKey;
}

/// Colormap com arquivo local existente ou URL. Preview RGB não cobre o mapa.
bool mapNdviSummaryCoversField(NdviLatestSummary? summary) {
  if (summary == null || !summary.isColormap) return false;
  final path = summary.localPath;
  if (path != null && path.isNotEmpty && File(path).existsSync()) return true;
  final url = summary.imageUrl?.trim();
  return url != null && url.isNotEmpty;
}
