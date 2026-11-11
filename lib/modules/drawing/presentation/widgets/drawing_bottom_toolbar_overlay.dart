import 'package:flutter/material.dart';
import 'package:soloforte_app/core/state/map_state.dart';

import '../../../../core/constants/layout_constants.dart';
import 'drawing_bottom_toolbar.dart';
import 'vertex_handle_drag_preview.dart';

/// Miolo da [DrawingBottomToolbar] para o host ancorar na base da tela.
///
/// Safe area inferior e recuos horizontais (16 à esquerda,
/// [kDrawingBottomToolbarRightInset] à direita) ficam no padding. O host
/// compõe este widget acima da borda, sem [Positioned].
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
    this.vertexDragPreview,
    this.measurementAzimuthDeg,
    this.gpsAccuracyM = 0,
    this.areaUnit = AreaDisplayUnit.hectare,
    this.onAreaUnit,
    this.showMeasurementDetails = false,
    this.onToggleMeasurementDetails,
    this.distanceUnit = DistanceDisplayUnit.kilometer,
    this.onDistanceUnit,
    this.onStartHoleCut,
    this.canStartHoleCut = true,
    this.onRemoveHoleRing,
    this.showRemoveHoleRing = false,
    this.canRemoveHoleRing = false,
  });

  final VoidCallback onConfirm;
  final VoidCallback onUndo;
  final VoidCallback onCancel;
  final bool canUndo;
  final bool canConfirm;

  final double measurementAreaHa;
  final double measurementPerimeterKm;
  final VertexHandleDragPreview? vertexDragPreview;
  final double? measurementAzimuthDeg;
  final double gpsAccuracyM;
  final AreaDisplayUnit areaUnit;
  final ValueChanged<AreaDisplayUnit>? onAreaUnit;
  final bool showMeasurementDetails;
  final VoidCallback? onToggleMeasurementDetails;
  final DistanceDisplayUnit distanceUnit;
  final ValueChanged<DistanceDisplayUnit>? onDistanceUnit;
  final VoidCallback? onStartHoleCut;
  final bool canStartHoleCut;
  final VoidCallback? onRemoveHoleRing;
  final bool showRemoveHoleRing;
  final bool canRemoveHoleRing;

  @override
  Widget build(BuildContext context) {
    final safeBottom = MediaQuery.paddingOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: kDrawingBottomToolbarRightInset,
        bottom: safeBottom,
      ),
      child: DrawingBottomToolbar(
        onConfirm: onConfirm,
        onUndo: onUndo,
        onCancel: onCancel,
        canUndo: canUndo,
        canConfirm: canConfirm,
        measurementAreaHa: measurementAreaHa,
        measurementPerimeterKm: measurementPerimeterKm,
        vertexDragPreview: vertexDragPreview,
        measurementAzimuthDeg: measurementAzimuthDeg,
        gpsAccuracyM: gpsAccuracyM,
        areaUnit: areaUnit,
        onAreaUnit: onAreaUnit,
        showMeasurementDetails: showMeasurementDetails,
        onToggleMeasurementDetails: onToggleMeasurementDetails,
        distanceUnit: distanceUnit,
        onDistanceUnit: onDistanceUnit,
        onStartHoleCut: onStartHoleCut,
        canStartHoleCut: canStartHoleCut,
        onRemoveHoleRing: onRemoveHoleRing,
        showRemoveHoleRing: showRemoveHoleRing,
        canRemoveHoleRing: canRemoveHoleRing,
      ),
    );
  }
}
