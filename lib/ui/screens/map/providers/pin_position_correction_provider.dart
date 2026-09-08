import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/utils/app_logger.dart';

enum PinCorrectionKind { occurrence, marketing }

class PinPositionCorrectionSession {
  final PinCorrectionKind kind;
  final String entityId;
  final LatLng original;
  LatLng current;
  final Future<bool> Function(double lat, double lng) onConfirm;

  PinPositionCorrectionSession({
    required this.kind,
    required this.entityId,
    required this.original,
    required this.current,
    required this.onConfirm,
  });
}

final pinPositionCorrectionProvider =
    StateProvider.autoDispose<PinPositionCorrectionSession?>((ref) => null);

bool isValidPinCorrectionCoordinates(double latitude, double longitude) {
  if (!latitude.isFinite || !longitude.isFinite) return false;
  if (latitude < -90 || latitude > 90) return false;
  if (longitude < -180 || longitude > 180) return false;
  return latitude != 0 || longitude != 0;
}

extension PinPositionCorrectionActions on WidgetRef {
  void startPinCorrectionSession({
    required PinCorrectionKind kind,
    required String entityId,
    required LatLng position,
    required Future<bool> Function(double lat, double lng) onConfirm,
  }) {
    pinCorrectionStartSession(
      this,
      kind: kind,
      entityId: entityId,
      position: position,
      onConfirm: onConfirm,
    );
  }

  void updatePinCorrectionCurrent(LatLng position) {
    pinCorrectionUpdateCurrent(this, position);
  }

  void cancelPinCorrection() {
    pinCorrectionCancel(this);
  }

  Future<bool> confirmPinCorrection() => pinCorrectionConfirm(this);
}

void pinCorrectionStartSession(
  dynamic ref, {
  required PinCorrectionKind kind,
  required String entityId,
  required LatLng position,
  required Future<bool> Function(double lat, double lng) onConfirm,
}) {
  final existing = ref.read(pinPositionCorrectionProvider);
  if (existing != null) {
    AppLogger.debug(
      'Substituindo sessão ativa de correção de pin (${existing.entityId} → $entityId)',
      tag: 'PinCorrection',
    );
  }

  ref.read(pinPositionCorrectionProvider.notifier).state =
      PinPositionCorrectionSession(
        kind: kind,
        entityId: entityId,
        original: position,
        current: position,
        onConfirm: onConfirm,
      );
}

void pinCorrectionUpdateCurrent(dynamic ref, LatLng position) {
  final session = ref.read(pinPositionCorrectionProvider);
  if (session == null) return;
  ref.read(pinPositionCorrectionProvider.notifier).state =
      PinPositionCorrectionSession(
        kind: session.kind,
        entityId: session.entityId,
        original: session.original,
        current: position,
        onConfirm: session.onConfirm,
      );
}

void pinCorrectionCancel(dynamic ref) {
  ref.read(pinPositionCorrectionProvider.notifier).state = null;
}

Future<bool> pinCorrectionConfirm(dynamic ref) async {
  final session = ref.read(pinPositionCorrectionProvider);
  if (session == null) return false;

  final newLat = session.current.latitude;
  final newLng = session.current.longitude;
  if (!isValidPinCorrectionCoordinates(newLat, newLng)) {
    return false;
  }

  try {
    final saved = await session.onConfirm(newLat, newLng);
    if (!saved) return false;
  } catch (error, stackTrace) {
    AppLogger.error(
      'Falha ao persistir correção de posição do pin',
      tag: 'PinCorrection',
      error: error,
      stackTrace: stackTrace,
    );
    return false;
  }

  ref.read(pinPositionCorrectionProvider.notifier).state = null;
  return true;
}
