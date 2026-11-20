import 'dart:async';
import 'dart:io' show File;

import '../../../core/contracts/i_visit_session_lookup.dart';
import '../../../core/utils/app_logger.dart';
import '../../../modules/consultoria/quick_photo/data/quick_photo_repository.dart';
import '../../../modules/consultoria/quick_photo/domain/save_quick_photo.dart';
import '../../../modules/consultoria/relatorio_visita/data/image_storage_service.dart';
import '../../../modules/drawing/domain/models/campo_test_photo_draft.dart';
import '../../../modules/drawing/domain/models/drawing_models.dart';

typedef MapDrawingVisitAreaUpdate = Future<void> Function(
  String featureId, {
  String? farmId,
});

/// Pós-save do [DrawingSheet]: área da visita (talhão) e foto opcional do teste.
void handleMapDrawingSaved({
  required DrawingFeature? feature,
  CampoTestPhotoDraft? campoTestPhoto,
  required VisitSessionSummary? session,
  required MapDrawingVisitAreaUpdate onUpdateVisitArea,
  required IVisitSessionLookup sessionLookup,
}) {
  final areaId = session?.areaId;
  if (feature != null &&
      feature.properties.tipo == DrawingType.talhao &&
      session != null &&
      (areaId == null || areaId.isEmpty)) {
    final farmId = feature.properties.fazendaId;
    unawaited(
      onUpdateVisitArea(
        feature.id,
        farmId: (farmId == null || farmId.isEmpty)
            ? session.farmId
            : farmId,
      ),
    );
  }
  if (feature?.properties.tipo == DrawingType.teste && campoTestPhoto != null) {
    unawaited(
      persistCampoTestPhotoFromDraft(
        draft: campoTestPhoto,
        sessionLookup: sessionLookup,
      ),
    );
  }
}

Future<void> persistCampoTestPhotoFromDraft({
  required CampoTestPhotoDraft draft,
  required IVisitSessionLookup sessionLookup,
}) async {
  try {
    final storage = ImageStorageService();
    final storedPath = await storage.persistLocalCopy(draft.localPath);
    if (storedPath == null) {
      AppLogger.warning(
        'Campo teste: falha ao copiar foto para pasta estável',
        tag: 'CampoTestePhoto',
      );
      return;
    }
    final absolute = await storage.resolveLocalPath(storedPath);
    if (absolute == null) return;
    final bytes = await File(absolute).readAsBytes();
    await SaveQuickPhoto(
      QuickPhotoRepository(),
      sessionLookup,
    ).execute(
      bytes: bytes,
      localPath: storedPath,
      lat: draft.lat,
      lng: draft.lng,
    );
  } catch (e) {
    AppLogger.warning(
      'Campo teste: erro ao persistir foto',
      tag: 'CampoTestePhoto',
      error: e,
    );
  }
}