import 'package:flutter/material.dart';

import '../../relatorio_visita/data/image_storage_service.dart';
import 'screens/photo_editor_screen.dart';

class QuickPhotoFlow {
  const QuickPhotoFlow._();

  static Future<void> open(
    BuildContext context, {
    double? lat,
    double? lng,
    String? visitSessionId,
    String? clientId,
    bool initialFilterActive = false,
  }) async {
    final imagePath = await ImageStorageService().captureAndSaveImage();
    if (imagePath == null || !context.mounted) return;

    await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => PhotoEditorScreen(
          imagePath: imagePath,
          lat: lat,
          lng: lng,
          visitSessionId: visitSessionId,
          clientId: clientId,
          initialFilterActive: initialFilterActive,
        ),
      ),
    );
  }

  /// Reabre o editor de anotação sobre uma mídia já existente.
  static Future<bool> openExisting(
    BuildContext context, {
    required String photoId,
    required String imagePath,
    double? lat,
    double? lng,
    String? visitSessionId,
    bool initialFilterActive = false,
  }) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => PhotoEditorScreen(
          imagePath: imagePath,
          lat: lat,
          lng: lng,
          visitSessionId: visitSessionId,
          initialFilterActive: initialFilterActive,
          existingPhotoId: photoId,
        ),
      ),
    );
    return result == true;
  }
}
