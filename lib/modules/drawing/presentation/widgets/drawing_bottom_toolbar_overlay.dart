import 'package:flutter/material.dart';
import 'package:soloforte_app/core/state/map_state.dart';

import '../../../../core/constants/layout_constants.dart';
import 'drawing_bottom_toolbar.dart';

/// Posiciona [DrawingBottomToolbar] na base da tela durante o desenho.
///
/// A barra ocupa `bottom: 0` com safe area interna e recuo direito para
/// não conflitar com o SmartButton nem com a coluna flutuante do mapa.
class DrawingBottomToolbarOverlay extends StatelessWidget {
  const DrawingBottomToolbarOverlay({
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

  @override
  Widget build(BuildContext context) {
    final safeBottom = MediaQuery.paddingOf(context).bottom;

    return Positioned(
      left: 16,
      right: kDrawingBottomToolbarRightInset,
      bottom: 0,
      child: Padding(
        padding: EdgeInsets.only(bottom: safeBottom),
        child: DrawingBottomToolbar(
          onConfirm: onConfirm,
          onUndo: onUndo,
          onCancel: onCancel,
          canUndo: canUndo,
          canConfirm: canConfirm,
          measurementAreaHa: measurementAreaHa,
          measurementPerimeterKm: measurementPerimeterKm,
          measurementAzimuthDeg: measurementAzimuthDeg,
          gpsAccuracyM: gpsAccuracyM,
          areaUnit: areaUnit,
          onAreaUnit: onAreaUnit,
          showMeasurementDetails: showMeasurementDetails,
          onToggleMeasurementDetails: onToggleMeasurementDetails,
          distanceUnit: distanceUnit,
          onDistanceUnit: onDistanceUnit,
        ),
      ),
    );
  }
}
