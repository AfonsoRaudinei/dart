import 'package:flutter/material.dart';
import '../../../../modules/map/design/sf_icons.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../modules/consultoria/occurrences/domain/occurrence.dart';

/// Gerador de pins minimalistas para ocorrências no mapa
class OccurrencePinGenerator {
  /// Renderiza pins de ocorrências no mapa baseado no zoom
  static List<Marker> generatePins({
    required List<Occurrence> occurrences,
    required double currentZoom,
    required Function(Occurrence) onPinTap,
  }) {
    return occurrences
        .map((occ) {
          final coords = occ.getCoordinates();
          if (coords == null) return null;

          return Marker(
            point: LatLng(coords['lat']!, coords['long']!),
            width: 32,
            height: 32,
            child: GestureDetector(
              onTap: () => onPinTap(occ),
              child: _OccurrencePin(
                occurrence: occ,
                showIcon: currentZoom >= 13,
              ),
            ),
          );
        })
        .whereType<Marker>()
        .toList();
  }
}

/// Widget de pin individual
class _OccurrencePin extends StatelessWidget {
  final Occurrence occurrence;
  final bool showIcon;

  const _OccurrencePin({required this.occurrence, required this.showIcon});

  Color _getCategoryColor() {
    final category = OccurrenceCategory.fromString(occurrence.category);
    switch (category) {
      case OccurrenceCategory.doenca:
        return Colors.blue.shade700;
      case OccurrenceCategory.insetos:
        return Colors.red.shade700;
      case OccurrenceCategory.daninhas:
        return Colors.orange.shade700;
      case OccurrenceCategory.nutricional:
        return Colors.grey.shade600;
      case OccurrenceCategory.agua:
        return Colors.cyan.shade700;
    }
  }

  IconData _getCategoryIcon() {
    final category = OccurrenceCategory.fromString(occurrence.category);
    switch (category) {
      case OccurrenceCategory.doenca:
        return SFIcons.coronavirus; // 🦠
      case OccurrenceCategory.insetos:
        return SFIcons.bugReport; // 🐛
      case OccurrenceCategory.daninhas:
        return SFIcons.grass; // 🌿
      case OccurrenceCategory.nutricional:
        return SFIcons.science; // ⚗️
      case OccurrenceCategory.agua:
        return SFIcons.waterDrop; // 💧
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getCategoryColor();
    final isDraft = occurrence.status == 'draft';
    final opacity = isDraft ? 0.5 : 1.0;

    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: color.withValues(alpha: opacity),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: showIcon
          ? Center(
              child: Icon(
                _getCategoryIcon(),
                size: 16,
                color: Colors.white.withValues(alpha: opacity),
              ),
            )
          : null, // Pin vazio em zoom distante
    );
  }
}
