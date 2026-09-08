import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../../../modules/consultoria/occurrences/domain/occurrence.dart';
import '../../../../modules/consultoria/occurrences/presentation/controllers/occurrence_controller.dart';
import '../../../../modules/marketing/domain/entities/marketing_case.dart';
import '../../../../modules/marketing/presentation/providers/marketing_providers.dart';

enum PinCorrectionKind { occurrence, marketing }

class PinPositionCorrectionSession {
  final PinCorrectionKind kind;
  final String entityId;
  final LatLng original;
  LatLng current;
  final Object? entitySnapshot;

  PinPositionCorrectionSession({
    required this.kind,
    required this.entityId,
    required this.original,
    required this.current,
    this.entitySnapshot,
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
    Object? entitySnapshot,
  }) {
    pinCorrectionStartSession(
      this,
      kind: kind,
      entityId: entityId,
      position: position,
      entitySnapshot: entitySnapshot,
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
  Object? entitySnapshot,
}) {
  ref.read(pinPositionCorrectionProvider.notifier).state =
      PinPositionCorrectionSession(
        kind: kind,
        entityId: entityId,
        original: position,
        current: position,
        entitySnapshot: entitySnapshot,
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
        entitySnapshot: session.entitySnapshot,
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

  switch (session.kind) {
    case PinCorrectionKind.occurrence:
      final occurrence = session.entitySnapshot as Occurrence?;
      if (occurrence == null) return false;
      await ref.read(occurrenceRepositoryProvider).updateOccurrence(
        occurrence.copyWith(
          lat: newLat,
          long: newLng,
          geometry: jsonEncode({
            'type': 'Point',
            'coordinates': [newLng, newLat],
          }),
        ),
      );
      ref.invalidate(occurrencesListProvider);
    case PinCorrectionKind.marketing:
      final marketingCase = session.entitySnapshot as MarketingCase?;
      if (marketingCase == null) return false;
      final updated = MarketingCase.fromJson({
        ...marketingCase.toJson(),
        'lat': newLat,
        'lng': newLng,
      });
      await ref.read(marketingCasesProvider.notifier).updateCase(updated);
  }

  ref.read(pinPositionCorrectionProvider.notifier).state = null;
  return true;
}
