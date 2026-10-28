import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/state/map_ndvi_overlay.dart';
import '../domain/models/drawing_models.dart';
import 'controllers/drawing_controller.dart';
import 'providers/drawing_compact_ui_provider.dart';

/// Handlers compartilhados entre a toolbar compacta no mapa e o [DrawingSheet].
class DrawingCompactSelectionActions {
  const DrawingCompactSelectionActions._();

  static void showNdviMap(
    WidgetRef ref,
    DrawingFeature feature, {
    VoidCallback? onCollapseWhileEditing,
  }) {
    if (feature.id.isEmpty) return;
    ref.read(mapNdviOverlayFieldIdProvider.notifier).state = feature.id;
    ref.read(mapNdviMonochromeEnabledProvider.notifier).state = false;
    ref.invalidate(mapNdviOverlaySummaryProvider);
    onCollapseWhileEditing?.call();
  }

  static void showMonochromeMap(
    WidgetRef ref,
    DrawingFeature feature, {
    VoidCallback? onCollapseWhileEditing,
  }) {
    if (feature.id.isEmpty) return;
    final currentField = ref.read(mapNdviOverlayFieldIdProvider);
    final currentMono = ref.read(mapNdviMonochromeEnabledProvider);
    final nextMono = !(currentField == feature.id && currentMono);
    ref.read(mapNdviOverlayFieldIdProvider.notifier).state = feature.id;
    ref.read(mapNdviMonochromeEnabledProvider.notifier).state = nextMono;
    ref.invalidate(mapNdviOverlaySummaryProvider);
    onCollapseWhileEditing?.call();
  }

  static void editGeometry(DrawingController controller) {
    controller.startEditMode();
  }

  static void requestMetadataSheet(WidgetRef ref) {
    ref.read(drawingCompactOpenMetadataProvider.notifier).state = true;
  }
}
