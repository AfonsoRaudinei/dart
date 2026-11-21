import 'dart:async';
import 'dart:io' show File;
import 'dart:typed_data';

import '../../../core/contracts/i_visit_session_lookup.dart';
import '../../../core/utils/app_logger.dart';
import '../../../modules/consultoria/quick_photo/data/quick_photo_repository.dart';
import '../../../modules/consultoria/quick_photo/domain/save_quick_photo.dart';
import '../../../modules/consultoria/relatorio_visita/data/image_storage_service.dart';
import '../../../modules/drawing/domain/models/campo_test_photo_draft.dart';
import '../../../modules/drawing/domain/models/drawing_models.dart';
import '../../../modules/visitas/domain/models/visit_session.dart';

/// Mesmos campos que [VisitSessionLookupAdapter] `_toSummary` — para leitura síncrona do controller.
VisitSessionSummary? visitSessionToSummary(VisitSession? session) {
  if (session == null) return null;
  return VisitSessionSummary(
    id: session.id,
    producerId: session.producerId,
    status: session.status,
    startTime: session.startTime,
    farmId: session.farmId,
    areaId: session.areaId,
    activityType: session.activityType,
    endTime: session.endTime,
    initialLat: session.initialLat,
    initialLong: session.initialLong,
  );
}

typedef MapDrawingVisitAreaUpdate = Future<void> Function(
  String featureId, {
  String? farmId,
});

typedef PersistCampoTestPhotoFn = Future<void> Function({
  required CampoTestPhotoDraft draft,
  required IVisitSessionLookup sessionLookup,
});

typedef CampoTestPersistLocalCopy = Future<String?> Function(String localPath);

typedef CampoTestResolveLocalPath = Future<String?> Function(String storedPath);

typedef CampoTestReadFileBytes = Future<Uint8List> Function(String absolutePath);

typedef CampoTestSaveQuickPhoto = Future<void> Function({
  required Uint8List bytes,
  required String localPath,
  double? lat,
  double? lng,
});

Future<String?> _defaultCampoTestPersistLocalCopy(String localPath) =>
    ImageStorageService().persistLocalCopy(localPath);

Future<String?> _defaultCampoTestResolveLocalPath(String storedPath) =>
    ImageStorageService().resolveLocalPath(storedPath);

Future<Uint8List> _defaultCampoTestReadFileBytes(String absolutePath) =>
    File(absolutePath).readAsBytes();

Future<void> _defaultCampoTestSaveQuickPhoto({
  required Uint8List bytes,
  required String localPath,
  double? lat,
  double? lng,
  required IVisitSessionLookup sessionLookup,
}) =>
    SaveQuickPhoto(
      QuickPhotoRepository(),
      sessionLookup,
    ).execute(
      bytes: bytes,
      localPath: localPath,
      lat: lat,
      lng: lng,
    );

/// Pós-save do [DrawingSheet]: área da visita (talhão) e foto opcional do teste.
void handleMapDrawingSaved({
  required DrawingFeature? feature,
  CampoTestPhotoDraft? campoTestPhoto,
  required VisitSessionSummary? session,
  required MapDrawingVisitAreaUpdate onUpdateVisitArea,
  required IVisitSessionLookup sessionLookup,
  PersistCampoTestPhotoFn? persistCampoTestPhoto,
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
}

Future<void> persistCampoTestPhotoFromDraft({
  required CampoTestPhotoDraft draft,
  required IVisitSessionLookup sessionLookup,
  CampoTestPersistLocalCopy? persistLocalCopy,
  CampoTestResolveLocalPath? resolveLocalPath,
  CampoTestReadFileBytes? readFileBytes,
  CampoTestSaveQuickPhoto? saveQuickPhoto,
}) async {
  final copyLocal = persistLocalCopy ?? _defaultCampoTestPersistLocalCopy;
  final resolvePath = resolveLocalPath ?? _defaultCampoTestResolveLocalPath;
  final readBytes = readFileBytes ?? _defaultCampoTestReadFileBytes;
  final savePhoto = saveQuickPhoto ??
      ({
        required Uint8List bytes,
        required String localPath,
        double? lat,
        double? lng,
      }) =>
          _defaultCampoTestSaveQuickPhoto(
            bytes: bytes,
            localPath: localPath,
            lat: lat,
            lng: lng,
            sessionLookup: sessionLookup,
          );

  try {
    final storedPath = await copyLocal(draft.localPath);
    if (storedPath == null) {
      AppLogger.warning(
        'Campo teste: falha ao copiar foto para pasta estável',
        tag: 'CampoTestePhoto',
      );
      return;
    }
    final absolute = await resolvePath(storedPath);
    if (absolute == null) return;
    final bytes = await readBytes(absolute);
    await savePhoto(
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