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
    this.pinLegend,
  });

  final String id;
  final Occurrence occurrence;
  final LatLng position;
  final String? category;
  final String urgency;
  final String status;

  /// Legenda no mapa (ex.: nome do produtor em área visitada).
  final String? pinLegend;
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
    List<Occurrence> occurrences, {
    Map<String, String> clientNameById = const {},
  }) {
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
          pinLegend: _pinLegendFor(occurrence, clientNameById),
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
          (data) {
            final legend = data.pinLegend?.trim();
            final hasLegend = legend != null && legend.isNotEmpty;
            final width = hasLegend ? _legendMarkerWidth(legend) : pinSize;
            final height = hasLegend ? 56.0 : pinSize;
            return Marker(
              key: ValueKey('occ_${data.id}'),
              point: data.position,
              width: width,
              height: height,
              alignment: hasLegend ? Alignment.bottomCenter : Alignment.center,
              child: GestureDetector(
                onTap: () => onPinTap(data.occurrence),
                child: OccurrenceMapPin(data: data),
              ),
            );
          },
        )
        .toList(growable: false);
  }

  static String? _pinLegendFor(
    Occurrence occurrence,
    Map<String, String> clientNameById,
  ) {
    if (!isAreaVisitadaCategory(occurrence.category)) return null;
    final clientId = occurrence.clientId?.trim();
    if (clientId == null || clientId.isEmpty) return null;
    final name = clientNameById[clientId]?.trim();
    if (name == null || name.isEmpty) return null;
    return _truncateLegend(name);
  }

  @visibleForTesting
  static String truncateLegendForTest(String name) => _truncateLegend(name);

  static String _truncateLegend(String name) {
    const max = 24;
    if (name.length <= max) return name;
    return '${name.substring(0, max - 1)}…';
  }

  @visibleForTesting
  static double legendMarkerWidthForTest(String legend) =>
      _legendMarkerWidth(legend);

  static double _legendMarkerWidth(String legend) {
    final len = legend.length.clamp(4, 26);
    return (len * 6.5 + 36).clamp(72, 168);
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
      case 'area_visitada':
      case 'area visitada':
        return Icons.place_outlined;
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
    final pendingLink = data.occurrence.pendingClientLink;
    final legend = data.pinLegend?.trim();
    final hasLegend = legend != null && legend.isNotEmpty;
    final opacity = isDraft ? 0.65 : 1.0;

    final pin = SizedBox(
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
          if (pendingLink)
            Positioned(
              bottom: -2,
              left: -2,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF9500),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.white, width: 1),
                ),
                child: const Text(
                  '!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                    height: 1,
                  ),
                ),
              ),
            )
          else
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

    if (!hasLegend) return pin;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        pin,
        const SizedBox(height: 2),
        Material(
          elevation: 2,
          shadowColor: Colors.black26,
          borderRadius: BorderRadius.circular(6),
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            child: Text(
              legend,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF1C1C1E),
                fontSize: 11,
                fontWeight: FontWeight.w600,
                height: 1.2,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
