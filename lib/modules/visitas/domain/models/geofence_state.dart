class GeofenceState {
  final String? areaId;
  final bool inside;
  final DateTime? lastTransition;

  const GeofenceState({this.areaId, required this.inside, this.lastTransition});

  factory GeofenceState.initial() {
    return const GeofenceState(inside: false);
  }

  GeofenceState copyWith({
    String? areaId,
    bool? inside,
    DateTime? lastTransition,
  }) {
    return GeofenceState(
      areaId: areaId ?? this.areaId,
      inside: inside ?? this.inside,
      lastTransition: lastTransition ?? this.lastTransition,
    );
  }
}
