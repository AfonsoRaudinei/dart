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
  /// Categoria pré-selecionada ao abrir criação (ex.: `area_visitada`).
  final String? initialOccurrenceCategory;

  const MapSheetState({
    required this.type,
    this.isCreatingOccurrence = false,
    this.preSelectedClienteId,
    this.initialOccurrenceCategory,
  });

  MapSheetState copyWith({
    MapSheetType? type,
    bool? isCreatingOccurrence,
    String? preSelectedClienteId,
    String? initialOccurrenceCategory,
  }) {
    return MapSheetState(
      type: type ?? this.type,
      isCreatingOccurrence: isCreatingOccurrence ?? this.isCreatingOccurrence,
      preSelectedClienteId: preSelectedClienteId ?? this.preSelectedClienteId,
      initialOccurrenceCategory:
          initialOccurrenceCategory ?? this.initialOccurrenceCategory,
    );
  }
}
