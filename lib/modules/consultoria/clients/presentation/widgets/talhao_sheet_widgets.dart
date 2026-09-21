import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:latlong2/latlong.dart';
import 'package:soloforte_app/modules/consultoria/clients/presentation/widgets/client_sheet_widgets.dart';
import 'package:soloforte_app/modules/consultoria/clients/presentation/widgets/farm_linked_field_list.dart';

export 'client_sheet_widgets.dart';

typedef TalhaoSheetVisuals = ClientSheetVisuals;
typedef TalhaoSheetScaffold = ClientSheetScaffold;
typedef TalhaoSheetActionCard = ClientSheetActionCard;
typedef TalhaoSheetActionRow = ClientSheetActionRow;
typedef TalhaoSheetSectionLabel = ClientSheetSectionLabel;
typedef TalhaoSheetFormField = ClientSheetFormField;
typedef TalhaoSheetButtonRow = ClientSheetButtonRow;
typedef TalhaoSheetFarmSkeleton = ClientSheetFarmSkeleton;
typedef TalhaoSheetInlineBanner = ClientSheetInlineBanner;
typedef TalhaoSheetIosRadio = ClientSheetIosRadio;

/// Mini preview de polígono para listas de união.
class TalhaoPolygonThumb extends StatelessWidget {
  const TalhaoPolygonThumb({
    super.key,
    required this.vertices,
    this.size = 48,
  });

  final List<LatLng> vertices;
  final double size;

  @override
  Widget build(BuildContext context) {
    final visuals = ClientSheetVisuals.of(context);
    final radius = visuals.isIos ? 10.0 : 8.0;

    if (vertices.length < 3) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: const Color(0xFFF2F2F7),
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(color: visuals.cardBorder),
        ),
        child: Icon(Icons.map_outlined, size: 20, color: visuals.muted),
      );
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFFF2F2F7),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: visuals.cardBorder),
      ),
      clipBehavior: Clip.antiAlias,
      child: CustomPaint(
        painter: _TalhaoPolygonSilhouettePainter(
          vertices: vertices,
          fillColor: visuals.accent.withValues(alpha: 0.35),
          strokeColor: visuals.accent,
        ),
      ),
    );
  }
}

class _TalhaoPolygonSilhouettePainter extends CustomPainter {
  _TalhaoPolygonSilhouettePainter({
    required this.vertices,
    required this.fillColor,
    required this.strokeColor,
  });

  final List<LatLng> vertices;
  final Color fillColor;
  final Color strokeColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (vertices.length < 3) return;

    var minLat = vertices.first.latitude;
    var maxLat = vertices.first.latitude;
    var minLng = vertices.first.longitude;
    var maxLng = vertices.first.longitude;

    for (final point in vertices) {
      minLat = minLat < point.latitude ? minLat : point.latitude;
      maxLat = maxLat > point.latitude ? maxLat : point.latitude;
      minLng = minLng < point.longitude ? minLng : point.longitude;
      maxLng = maxLng > point.longitude ? maxLng : point.longitude;
    }

    final latSpan = (maxLat - minLat).abs();
    final lngSpan = (maxLng - minLng).abs();
    if (latSpan == 0 && lngSpan == 0) return;

    const padding = 6.0;
    final drawableWidth = size.width - (padding * 2);
    final drawableHeight = size.height - (padding * 2);

    final path = ui.Path();
    for (var i = 0; i < vertices.length; i++) {
      final point = vertices[i];
      final normalizedX =
          lngSpan == 0 ? 0.5 : (point.longitude - minLng) / lngSpan;
      final normalizedY =
          latSpan == 0 ? 0.5 : (point.latitude - minLat) / latSpan;
      final dx = padding + (normalizedX * drawableWidth);
      final dy = padding + ((1 - normalizedY) * drawableHeight);
      if (i == 0) {
        path.moveTo(dx, dy);
      } else {
        path.lineTo(dx, dy);
      }
    }
    path.close();

    canvas.drawPath(path, Paint()..color = fillColor);
    canvas.drawPath(
      path,
      Paint()
        ..color = strokeColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  @override
  bool shouldRepaint(covariant _TalhaoPolygonSilhouettePainter oldDelegate) {
    return oldDelegate.vertices != vertices ||
        oldDelegate.fillColor != fillColor ||
        oldDelegate.strokeColor != strokeColor;
  }
}

class TalhaoSheetPrimaryChip extends StatelessWidget {
  const TalhaoSheetPrimaryChip({
    super.key,
    required this.name,
    required this.areaHa,
    this.vertices = const [],
  });

  final String name;
  final double areaHa;
  final List<LatLng> vertices;

  @override
  Widget build(BuildContext context) {
    final visuals = ClientSheetVisuals.of(context);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: visuals.cardBg,
        borderRadius: BorderRadius.circular(visuals.cardRadius),
        border: Border.all(color: visuals.accent, width: 1.5),
      ),
      child: Row(
        children: [
          TalhaoPolygonThumb(vertices: vertices, size: 48),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Talhão principal',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: visuals.muted,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: visuals.titleColor,
                  ),
                ),
                Text(
                  '${formatLinkedFieldAreaHa(areaHa)} ha',
                  style: TextStyle(fontSize: 13, color: visuals.muted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class TalhaoUnionCandidateRow extends StatelessWidget {
  const TalhaoUnionCandidateRow({
    super.key,
    required this.name,
    required this.areaHa,
    required this.vertices,
    required this.selected,
    required this.onTap,
    this.showDivider = true,
  });

  final String name;
  final double areaHa;
  final List<LatLng> vertices;
  final bool selected;
  final VoidCallback onTap;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final visuals = ClientSheetVisuals.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              HapticFeedback.lightImpact();
              onTap();
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  ClientSheetIosRadio(
                    selected: selected,
                    accentColor: visuals.accent,
                    mutedColor: visuals.muted,
                  ),
                  const SizedBox(width: 10),
                  TalhaoPolygonThumb(vertices: vertices, size: 48),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: visuals.titleColor,
                          ),
                        ),
                        Text(
                          '${formatLinkedFieldAreaHa(areaHa)} ha',
                          style: TextStyle(fontSize: 13, color: visuals.muted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (showDivider)
          Divider(
            height: 1,
            thickness: 0.5,
            indent: 44,
            color: visuals.dividerColor,
          ),
      ],
    );
  }
}

String buildTalhaoContextLine({
  required double areaHa,
  String? cultura,
  String? safra,
}) {
  final parts = <String>['${formatLinkedFieldAreaHa(areaHa)} ha'];
  if (cultura != null && cultura.trim().isNotEmpty) {
    parts.add(cultura.trim());
  } else if (safra != null && safra.trim().isNotEmpty) {
    parts.add('Safra ${safra.trim()}');
  }
  return parts.join(' · ');
}
