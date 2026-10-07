import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../../../../../ui/screens/map/providers/pin_position_correction_provider.dart';
import '../../domain/occurrence.dart';
import '../controllers/occurrence_controller.dart';

/// Inicia correção de posição no mapa após fechar o sheet de detalhe.
void launchOccurrencePinCorrectionSession(
  BuildContext context,
  WidgetRef ref,
  Occurrence occurrence,
) {
  final coords = occurrence.getCoordinates();
  if (coords == null) return;
  HapticFeedback.selectionClick();
  final repository = ref.read(occurrenceRepositoryProvider);
  final container = ProviderScope.containerOf(context, listen: false);
  final lat = coords['lat']!;
  final lng = coords['long']!;
  Navigator.of(context).pop();
  WidgetsBinding.instance.addPostFrameCallback((_) {
    pinCorrectionStartSession(
      container,
      kind: PinCorrectionKind.occurrence,
      entityId: occurrence.id,
      position: LatLng(lat, lng),
      onConfirm: (newLat, newLng) async {
        await repository.updateOccurrence(
          occurrence.copyWith(
            lat: newLat,
            long: newLng,
            geometry: jsonEncode({
              'type': 'Point',
              'coordinates': [newLng, newLat],
            }),
          ),
        );
        container.invalidate(occurrencesListProvider);
        return true;
      },
    );
  });
}
