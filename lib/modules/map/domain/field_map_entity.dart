import 'dart:ui';
import 'package:latlong2/latlong.dart';

/// Atributos visuais e fonte da entidade do mapa.
/// Unifica Talhões (Consultoria) e Desenhos (Drawing Module).
class FieldMapEntity {
  final String id;
  final String label;
  final String? subtitle;

  /// Polígonos para renderização.
  /// Lista de Lists de LatLng.
  /// Para polígonos simples: [[p1, p2, p3]]
  /// Para polígonos com buracos: [[outer], [hole1], [hole2]]
  final List<List<LatLng>> geometryRings;

  final FieldMapSource type;
  final FieldSyncStatus syncStatus;

  // Customização Visual
  final Color fillColor;
  final Color strokeColor;
  final double strokeWidth;

  final bool isSelected;
  final bool isGhost; // Ex: preview de importação

  const FieldMapEntity({
    required this.id,
    required this.label,
    this.subtitle,
    required this.geometryRings,
    required this.type,
    required this.syncStatus,
    required this.fillColor,
    required this.strokeColor,
    this.strokeWidth = 2.0,
    this.isSelected = false,
    this.isGhost = false,
  });

  FieldMapEntity copyWith({
    String? id,
    String? label,
    String? subtitle,
    List<List<LatLng>>? geometryRings,
    FieldMapSource? type,
    FieldSyncStatus? syncStatus,
    Color? fillColor,
    Color? strokeColor,
    bool? isSelected,
  }) {
    return FieldMapEntity(
      id: id ?? this.id,
      label: label ?? this.label,
      subtitle: subtitle ?? this.subtitle,
      geometryRings: geometryRings ?? this.geometryRings,
      type: type ?? this.type,
      syncStatus: syncStatus ?? this.syncStatus,
      fillColor: fillColor ?? this.fillColor,
      strokeColor: strokeColor ?? this.strokeColor,
      isSelected: isSelected ?? this.isSelected,
    );
  }
}

enum FieldMapSource {
  consultoria, // Legado
  drawing, // GeoJSON nativo
  imported, // KML
}

enum FieldSyncStatus { synced, pending, conflict, error, localOnly }
