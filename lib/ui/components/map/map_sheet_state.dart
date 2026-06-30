// 🛡 REFATORAÇÃO: Modelo explícito de estado do MapBottomSheet
// Compartilhado entre PrivateMapScreen e MapBottomSheet

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

  const MapSheetState({
    required this.type,
    this.isCreatingOccurrence = false,
    this.preSelectedClienteId,
  });

  MapSheetState copyWith({
    MapSheetType? type,
    bool? isCreatingOccurrence,
    String? preSelectedClienteId,
  }) {
    return MapSheetState(
      type: type ?? this.type,
      isCreatingOccurrence: isCreatingOccurrence ?? this.isCreatingOccurrence,
      preSelectedClienteId: preSelectedClienteId ?? this.preSelectedClienteId,
    );
  }
}
