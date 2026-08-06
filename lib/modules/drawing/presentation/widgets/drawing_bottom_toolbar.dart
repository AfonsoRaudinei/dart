import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:soloforte_app/core/state/map_state.dart';

/// Toolbar horizontal flutuante para ações de desenho (cancelar, desfazer, confirmar)
/// com seção opcional de medição de área na base do mesmo card.
///
/// Widget puro — sem acesso a providers. Callbacks injetados pelo host.
class DrawingBottomToolbar extends StatefulWidget {
  const DrawingBottomToolbar({
    super.key,
    required this.onConfirm,
    required this.onUndo,
    required this.onCancel,
    required this.canUndo,
    this.canConfirm = true,
    this.measurementAreaHa = 0,
    this.measurementPerimeterKm = 0,
    this.measurementAzimuthDeg,
    this.gpsAccuracyM = 0,
    this.areaUnit = AreaDisplayUnit.hectare,
    this.onAreaUnit,
    this.showMeasurementDetails = false,
    this.onToggleMeasurementDetails,
    this.distanceUnit = DistanceDisplayUnit.kilometer,
    this.onDistanceUnit,
  });

  final VoidCallback onConfirm;
  final VoidCallback onUndo;
  final VoidCallback onCancel;
  final bool canUndo;
  final bool canConfirm;

  final double measurementAreaHa;
  final double measurementPerimeterKm;
  final double? measurementAzimuthDeg;
  final double gpsAccuracyM;
  final AreaDisplayUnit areaUnit;
  final ValueChanged<AreaDisplayUnit>? onAreaUnit;
  final bool showMeasurementDetails;
  final VoidCallback? onToggleMeasurementDetails;
  final DistanceDisplayUnit distanceUnit;
  final ValueChanged<DistanceDisplayUnit>? onDistanceUnit;

  bool get _showsMeasurement =>
      measurementAreaHa > 0 || measurementPerimeterKm > 0;

  @override
  State<DrawingBottomToolbar> createState() => _DrawingBottomToolbarState();
}

class _DrawingBottomToolbarState extends State<DrawingBottomToolbar>
    with SingleTickerProviderStateMixin {
  static const Color _iosRed = Color(0xFFFF3B30);
  static const Color _iosGreen = Color(0xFF34C759);

  late final AnimationController _entryController;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: Curves.easeOutCubic,
      ),
    );
    _entryController.forward();
  }

  @override
  void dispose() {
    _entryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: ClipRRect(
        key: const Key('drawing_bottom_toolbar'),
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _ToolbarAction(
                          icon: Icons.close_rounded,
                          label: 'Cancelar',
                          iconColor: _iosRed,
                          labelColor: Colors.white70,
                          iconSize: 22,
                          semanticsLabel: 'Cancelar desenho',
                          onTap: widget.onCancel,
                        ),
                      ),
                      const _ToolbarDivider(),
                      Expanded(
                        child: _ToolbarAction(
                          icon: Icons.undo_rounded,
                          label: 'Desfazer',
                          iconColor: Colors.white70,
                          labelColor: Colors.white70,
                          iconSize: 22,
                          semanticsLabel: 'Desfazer último ponto',
                          enabled: widget.canUndo,
                          onTap: widget.canUndo ? widget.onUndo : null,
                        ),
                      ),
                      const _ToolbarDivider(),
                      Expanded(
                        child: _ToolbarAction(
                          icon: Icons.check_rounded,
                          label: 'Confirmar',
                          iconColor: _iosGreen,
                          labelColor: _iosGreen,
                          iconSize: 22,
                          semanticsLabel: 'Confirmar desenho',
                          enabled: widget.canConfirm,
                          onTap: widget.canConfirm
                              ? () {
                                  HapticFeedback.lightImpact();
                                  widget.onConfirm();
                                }
                              : null,
                        ),
                      ),
                    ],
                  ),
                ),
                if (widget._showsMeasurement) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Divider(
                      height: 1,
                      thickness: 0.5,
                      color: Colors.white.withValues(alpha: 0.22),
                    ),
                  ),
                  _DrawingToolbarMeasurementSection(
                    areaHa: widget.measurementAreaHa,
                    perimeterKm: widget.measurementPerimeterKm,
                    azimuthDeg: widget.measurementAzimuthDeg,
                    gpsAccuracyM: widget.gpsAccuracyM,
                    areaUnit: widget.areaUnit,
                    onAreaUnit: widget.onAreaUnit,
                    showDetails: widget.showMeasurementDetails,
                    onToggleDetails: widget.onToggleMeasurementDetails,
                    distanceUnit: widget.distanceUnit,
                    onDistanceUnit: widget.onDistanceUnit,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DrawingToolbarMeasurementSection extends StatelessWidget {
  const _DrawingToolbarMeasurementSection({
    required this.areaHa,
    required this.perimeterKm,
    required this.azimuthDeg,
    required this.gpsAccuracyM,
    required this.areaUnit,
    required this.onAreaUnit,
    required this.showDetails,
    required this.onToggleDetails,
    required this.distanceUnit,
    required this.onDistanceUnit,
  });

  final double areaHa;
  final double perimeterKm;
  final double? azimuthDeg;
  final double gpsAccuracyM;
  final AreaDisplayUnit areaUnit;
  final ValueChanged<AreaDisplayUnit>? onAreaUnit;
  final bool showDetails;
  final VoidCallback? onToggleDetails;
  final DistanceDisplayUnit distanceUnit;
  final ValueChanged<DistanceDisplayUnit>? onDistanceUnit;

  String _formatArea() {
    switch (areaUnit) {
      case AreaDisplayUnit.hectare:
        return '${areaHa.toStringAsFixed(3)} ha';
      case AreaDisplayUnit.squareMeter:
        return '${(areaHa * 10000).toStringAsFixed(0)} m²';
      case AreaDisplayUnit.alqueire:
        return '${(areaHa / 4.84).toStringAsFixed(3)} alq GO/MG';
    }
  }

  String _formatDistance() {
    switch (distanceUnit) {
      case DistanceDisplayUnit.kilometer:
        return '${perimeterKm.toStringAsFixed(3)} km';
      case DistanceDisplayUnit.meter:
        return '${(perimeterKm * 1000).toStringAsFixed(0)} m';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      key: const Key('measurement_area_card'),
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  _formatArea(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (onToggleDetails != null)
                GestureDetector(
                  key: const Key('measurement_details_toggle'),
                  behavior: HitTestBehavior.opaque,
                  onTap: onToggleDetails,
                  child: Padding(
                    padding: const EdgeInsets.all(2),
                    child: Icon(
                      showDetails ? Icons.expand_less : Icons.info_outline,
                      size: 20,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Row(
              children: [
                _DrawingToolbarUnitChip(
                  label: 'ha',
                  selected: areaUnit == AreaDisplayUnit.hectare,
                  onTap: onAreaUnit == null
                      ? null
                      : () => onAreaUnit!(AreaDisplayUnit.hectare),
                ),
                const SizedBox(width: 6),
                _DrawingToolbarUnitChip(
                  label: 'm²',
                  selected: areaUnit == AreaDisplayUnit.squareMeter,
                  onTap: onAreaUnit == null
                      ? null
                      : () => onAreaUnit!(AreaDisplayUnit.squareMeter),
                ),
                const SizedBox(width: 6),
                _DrawingToolbarUnitChip(
                  label: 'alq GO/MG',
                  selected: areaUnit == AreaDisplayUnit.alqueire,
                  onTap: onAreaUnit == null
                      ? null
                      : () => onAreaUnit!(AreaDisplayUnit.alqueire),
                ),
              ],
            ),
          ),
          if (showDetails) ...[
            const SizedBox(height: 10),
            Container(
              key: const Key('measurement_details_card'),
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Perímetro: ${_formatDistance()}',
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Azimute: ${azimuthDeg?.toStringAsFixed(1) ?? '--'}°',
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    gpsAccuracyM > 0
                        ? 'GPS: ±${gpsAccuracyM.toStringAsFixed(1)} m'
                        : 'GPS: --',
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      _DrawingToolbarUnitChip(
                        label: 'km',
                        selected:
                            distanceUnit == DistanceDisplayUnit.kilometer,
                        onTap: onDistanceUnit == null
                            ? null
                            : () =>
                                  onDistanceUnit!(DistanceDisplayUnit.kilometer),
                      ),
                      _DrawingToolbarUnitChip(
                        label: 'm',
                        selected: distanceUnit == DistanceDisplayUnit.meter,
                        onTap: onDistanceUnit == null
                            ? null
                            : () => onDistanceUnit!(DistanceDisplayUnit.meter),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DrawingToolbarUnitChip extends StatelessWidget {
  const _DrawingToolbarUnitChip({
    required this.label,
    required this.selected,
    this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFF34C759)
              : Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: const TextStyle(color: Colors.white, fontSize: 12),
        ),
      ),
    );
  }
}

class _ToolbarDivider extends StatelessWidget {
  const _ToolbarDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 0.5,
      height: 28,
      color: Colors.white.withValues(alpha: 0.22),
    );
  }
}

class _ToolbarAction extends StatelessWidget {
  const _ToolbarAction({
    required this.icon,
    required this.label,
    required this.iconColor,
    required this.labelColor,
    required this.iconSize,
    required this.semanticsLabel,
    this.enabled = true,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final Color iconColor;
  final Color labelColor;
  final double iconSize;
  final String semanticsLabel;
  final bool enabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final opacity = enabled ? 1.0 : 0.35;

    return Semantics(
      button: true,
      enabled: enabled,
      label: semanticsLabel,
      child: Opacity(
        opacity: opacity,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: enabled ? onTap : null,
            borderRadius: BorderRadius.circular(12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: iconColor, size: iconSize),
                const SizedBox(height: 2),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: labelColor),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
