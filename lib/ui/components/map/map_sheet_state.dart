// 🛡 REFATORAÇÃO: Modelo explícito de estado do MapBottomSheet
// Compartilhado entre PrivateMapScreen e MapBottomSheet

enum MapSheetType {
  draw, // Desenho
  layers, // Camadas
  publications, // Publicações
  occurrences, // Ocorrências
  checkIn, // Check-in
}

class MapSheetState {
  final MapSheetType type;
  final bool isCreatingOccurrence;

  const MapSheetState({required this.type, this.isCreatingOccurrence = false});

  MapSheetState copyWith({MapSheetType? type, bool? isCreatingOccurrence}) {
    return MapSheetState(
      type: type ?? this.type,
      isCreatingOccurrence: isCreatingOccurrence ?? this.isCreatingOccurrence,
    );
  }
}
