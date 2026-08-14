// 🛡 REFATORAÇÃO: Modelo explícito de estado do MapBottomSheet
// Compartilhado entre PrivateMapScreen e MapBottomSheet

import 'package:latlong2/latlong.dart';

enum MapSheetType {
  draw, // Desenho
  layers, // Camadas
  occurrences, // Ocorrências
  checkIn, // Check-in
}

class MapSheetState {
  final MapSheetType type;
  final bool isCreatingOccurrence;
  final String? preSelectedClienteId; // P5: pré-seleção de cliente em modo=visita
  /// Pin de criação — viaja junto com o sheet para evitar race com provider.
  final double? occurrenceLatitude;
  final double? occurrenceLongitude;

  const MapSheetState({
    required this.type,
    this.isCreatingOccurrence = false,
    this.preSelectedClienteId,
    this.occurrenceLatitude,
    this.occurrenceLongitude,
  });

  /// Pin válido para criação (não nulo, finito, fora de 0,0).
  LatLng? get occurrencePin {
    final lat = occurrenceLatitude;
    final lng = occurrenceLongitude;
    if (lat == null || lng == null) return null;
    if (!lat.isFinite || !lng.isFinite) return null;
    if (lat < -90 || lat > 90 || lng < -180 || lng > 180) return null;
    if (lat == 0 && lng == 0) return null;
    return LatLng(lat, lng);
  }

  MapSheetState copyWith({
    MapSheetType? type,
    bool? isCreatingOccurrence,
    String? preSelectedClienteId,
    double? occurrenceLatitude,
    double? occurrenceLongitude,
  }) {
    return MapSheetState(
      type: type ?? this.type,
      isCreatingOccurrence: isCreatingOccurrence ?? this.isCreatingOccurrence,
      preSelectedClienteId: preSelectedClienteId ?? this.preSelectedClienteId,
      occurrenceLatitude: occurrenceLatitude ?? this.occurrenceLatitude,
      occurrenceLongitude: occurrenceLongitude ?? this.occurrenceLongitude,
    );
  }
}
