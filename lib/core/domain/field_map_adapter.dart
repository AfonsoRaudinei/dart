import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../../modules/consultoria/clients/domain/agronomic_models.dart';
import '../../modules/drawing/domain/models/drawing_models.dart';
import 'field_map_entity.dart';

class FieldMapAdapter {
  static FieldMapEntity fromTalhao(Talhao talhao, {bool isSelected = false}) {
    List<List<LatLng>> rings = [];
    if (talhao.geometry != null) {
      try {
        if (talhao.geometry!['type'] == 'Polygon') {
          final coords = talhao.geometry!['coordinates'] as List;
          rings = coords
              .map((ring) {
                return (ring as List)
                    .map((pt) {
                      final double lng = (pt[0] as num).toDouble();
                      final double lat = (pt[1] as num).toDouble();
                      return LatLng(lat, lng);
                    })
                    .toList()
                    .cast<LatLng>();
              })
              .toList()
              .cast<List<LatLng>>();
        }
      } catch (e) {
        debugPrint('Error parsing Talhao geometry: $e');
      }
    }

    return FieldMapEntity(
      id: talhao.id,
      label: talhao.name,
      subtitle: '${talhao.crop} ${talhao.harvest}',
      geometryRings: rings,
      type: FieldMapSource.consultoria,
      syncStatus:
          FieldSyncStatus.synced, // Assumindo synced pois vem do backend
        fillColor: isSelected
          ? Colors.green.withValues(alpha: 0.4)
          : Colors.green.withValues(alpha: 0.15),
      strokeColor: isSelected ? Colors.white : Colors.green[800]!,
      strokeWidth: isSelected ? 3.0 : 1.5,
      isSelected: isSelected,
    );
  }

  static FieldMapEntity fromDrawingFeature(
    DrawingFeature feature, {
    bool isSelected = false,
  }) {
    List<List<LatLng>> rings = [];

    if (feature.geometry is DrawingPolygon) {
      final poly = feature.geometry as DrawingPolygon;
      rings = poly.coordinates.map((ring) {
        return ring.map((pt) => LatLng(pt[1], pt[0])).toList();
      }).toList();
    }
    // TODO: MultiPolygon support

    // Status mapping
    FieldSyncStatus status;
    switch (feature.properties.syncStatus) {
      case SyncStatus.synced:
        status = FieldSyncStatus.synced;
        break;
      case SyncStatus.pending_sync:
        status = FieldSyncStatus.pending;
        break;
      case SyncStatus.conflict:
        status = FieldSyncStatus.conflict;
        break;
      case SyncStatus.local_only:
        status = FieldSyncStatus.localOnly;
        break;
    }

    // Color logic
    Color baseColor = Colors.blue;
    if (feature.properties.autorTipo == AuthorType.consultor) {
      baseColor = Colors.purple;
    }

    return FieldMapEntity(
      id: feature.id,
      label: feature.properties.nome,
      subtitle: feature.properties.tipo.name,
      geometryRings: rings,
      type: FieldMapSource.drawing,
      syncStatus: status,
        fillColor: isSelected
          ? baseColor.withValues(alpha: 0.4)
          : baseColor.withValues(alpha: 0.15),
      strokeColor: isSelected ? Colors.white : baseColor,
      strokeWidth: isSelected ? 3.0 : 2.0,
      isSelected: isSelected,
    );
  }
}
