import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/utils/map_logger.dart';
import '../../../modules/consultoria/occurrences/domain/occurrence.dart';

@immutable
class OccurrenceMarkerData {
  const OccurrenceMarkerData({
    required this.id,
    required this.occurrence,
    required this.position,
    required this.category,
    required this.urgency,
    required this.status,
  });

  final String id;
  final Occurrence occurrence;
  final LatLng position;
  final String? category;
  final String urgency;
  final String status;
}

class OccurrenceProjectionResult {
  const OccurrenceProjectionResult({
    required this.markers,
    required this.invalidCount,
    required this.duplicateCount,
  });

  final List<OccurrenceMarkerData> markers;
  final int invalidCount;
  final int duplicateCount;
}

/// Fonte única de projeção e renderização de pins de ocorrências no mapa.
class OccurrencePinGenerator {
  static const double pinSize = 40;

  static OccurrenceProjectionResult projectOccurrences(
    List<Occurrence> occurrences,
  ) {
    if (occurrences.isEmpty) {
      return const OccurrenceProjectionResult(
        markers: <OccurrenceMarkerData>[],
        invalidCount: 0,
        duplicateCount: 0,
      );
    }

    final projected = <OccurrenceMarkerData>[];
    final seenIds = HashSet<String>();
    var invalidCount = 0;
    var duplicateCount = 0;

    for (final occurrence in occurrences) {
      final position = _resolvePosition(occurrence);
      if (position == null) {
        invalidCount++;
        continue;
      }

      if (!seenIds.add(occurrence.id)) {
        duplicateCount++;
        continue;
      }

      projected.add(
        OccurrenceMarkerData(
          id: occurrence.id,
          occurrence: occurrence,
          position: position,
          category: occurrence.category,
          urgency: occurrence.type,
          status: occurrence.status ?? '',
        ),
      );
    }

    return OccurrenceProjectionResult(
      markers: List<OccurrenceMarkerData>.unmodifiable(projected),
      invalidCount: invalidCount,
      duplicateCount: duplicateCount,
    );
  }

  static List<Marker> buildMarkers({
    required List<OccurrenceMarkerData> markerData,
    required void Function(Occurrence) onPinTap,
  }) {
    return markerData
        .map(
          (data) => Marker(
            key: ValueKey('occ_${data.id}'),
            point: data.position,
            width: pinSize,
            height: pinSize,
            alignment: Alignment.center,
            child: GestureDetector(
              onTap: () => onPinTap(data.occurrence),
              child: OccurrenceMapPin(data: data),
            ),
          ),
        )
        .toList(growable: false);
  }

  static void logProjectionDropCounts({
    required int invalidCount,
    required int duplicateCount,
  }) {
    if (invalidCount > 0) {
      MapLogger.logEvent(
        'Occurrence pins descartados por coordenada inválida: $invalidCount',
      );
    }
    if (duplicateCount > 0) {
      MapLogger.logEvent(
        'Occurrence pins descartados por id duplicado: $duplicateCount',
      );
    }
  }

  static LatLng? _resolvePosition(Occurrence occurrence) {
    final coords = occurrence.getCoordinates();
    if (coords == null) return null;

    final latitude = coords['lat'];
    final longitude = coords['long'];
    if (!_isRenderableCoordinate(latitude, longitude)) {
      return null;
    }

    return LatLng(latitude!, longitude!);
  }

  static bool _isRenderableCoordinate(double? latitude, double? longitude) {
    if (latitude == null || longitude == null) return false;
    if (!latitude.isFinite || !longitude.isFinite) return false;
    if (latitude.isNaN || longitude.isNaN) return false;
    if (latitude < -90 || latitude > 90) return false;
    if (longitude < -180 || longitude > 180) return false;
    return latitude != 0 || longitude != 0;
  }
}

class OccurrenceMapPin extends StatelessWidget {
  const OccurrenceMapPin({super.key, required this.data});

  final OccurrenceMarkerData data;

  static Color _colorForCategory(String? category) {
    return OccurrenceCategory.fromString(category).markerColor;
  }

  static Color _colorForUrgency(String? type) {
    switch ((type ?? '').toLowerCase()) {
      case 'alta':
        return const Color(0xFFFF3B30);
      case 'baixa':
        return const Color(0xFF8E8E93);
      default:
        return const Color(0xFFF59E0B);
    }
  }

  static IconData _iconForCategory(String? category) {
    switch ((category ?? '').toLowerCase()) {
      case 'doenca':
      case 'doença':
        return Icons.coronavirus_outlined;
      case 'insetos':
      case 'pragas':
        return Icons.bug_report_outlined;
      case 'daninhas':
      case 'ervas_daninhas':
      case 'ervas daninhas':
        return Icons.grass_outlined;
      case 'nutricional':
      case 'nutrientes':
        return Icons.science_outlined;
      case 'agua':
      case 'água':
        return Icons.water_drop_outlined;
      case 'amostra_solo':
      case 'amostra solo':
        return Icons.biotech_outlined;
      default:
        return Icons.place_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoryColor = _colorForCategory(data.category);
    final urgencyColor = _colorForUrgency(data.urgency);
    final icon = _iconForCategory(data.category);
    final isDraft = data.status == 'draft';
    final opacity = isDraft ? 0.65 : 1.0;

    return SizedBox(
      width: OccurrencePinGenerator.pinSize,
      height: OccurrencePinGenerator.pinSize,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: OccurrencePinGenerator.pinSize,
            height: OccurrencePinGenerator.pinSize,
            decoration: BoxDecoration(
              color: categoryColor.withValues(alpha: opacity),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: opacity),
                width: 2.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.28),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              icon,
              color: Colors.white.withValues(alpha: opacity),
              size: 18,
            ),
          ),
          Positioned(
            top: -1,
            right: -1,
            child: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: urgencyColor,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.5),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
