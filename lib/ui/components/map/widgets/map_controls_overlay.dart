import 'dart:async';

// Removed dart:ui
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:latlong2/latlong.dart';
import '../../../../../../core/design/sf_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../modules/dashboard/providers/location_providers.dart';
import '../../../../modules/dashboard/domain/location_state.dart';
import '../../../../modules/map/presentation/providers/map_location_mode_provider.dart';
import '../../../../modules/settings/presentation/providers/settings_providers.dart';
import '../../../../core/constants/layout_constants.dart';
import '../../../../core/providers/connectivity_provider.dart';
import '../../../../modules/clima/presentation/providers/radar_providers.dart';
import '../../../../core/state/map_state.dart';
import '../../../../modules/drawing/domain/drawing_state.dart';
import '../../../../modules/drawing/presentation/widgets/drawing_bottom_toolbar_overlay.dart';
import '../../../../core/utils/app_logger.dart';
import '../../../../modules/map/presentation/widgets/visit_active_card.dart';
import '../../../theme/premium/design_tokens.dart';
import 'selected_talhao_card.dart';

part 'map_controls_location_button.dart';
part 'map_controls_measurement.dart';

Color _themeColor(String theme) {
  switch (theme) {
    case 'green':
      return const Color(0xFF4CAF50);
    case 'black':
      return const Color(0xFF212121);
    case 'blue':
    default:
      return const Color(0xFF1976D2);
  }
}

/// Overlay de controles do mapa (header, botões, check-in).
/// Observa apenas locationStateProvider para status do GPS.
class MapControlsOverlay extends ConsumerStatefulWidget {
  final VoidCallback onCenterUser;
  final ValueChanged<MapLocationMode> onLocationModeChanged;
  final VoidCallback onToggleDrawMode;
  final VoidCallback onOpenMapTools;
  final Function(int, String) onTabSelected;
  final bool isDrawMode;
  final bool isCheckInActive;
  final bool showCheckInAction;
  final Widget? topLeftCard;
  final LatLng currentCenter;
  final double currentZoom;
  final DrawingState drawingState;
  final VoidCallback onFinishDrawing;
  final VoidCallback onCancelDrawing;
  final VoidCallback onSaveEdit;
  final VoidCallback onCancelEdit;
  final VoidCallback onUndoEdit;
  final VoidCallback? onRedoEdit;
  final VoidCallback? onUndoDrawing; // Undo no modo drawing
  final bool canUndo;
  final bool canRedo;
  final bool hasSelfIntersection;
  final double measurementAreaHa;
  final double measurementPerimeterKm;
  final double? measurementAzimuthDeg;
  final double gpsAccuracyM;

  const MapControlsOverlay({
    super.key,
    required this.onCenterUser,
    required this.onLocationModeChanged,
    required this.onToggleDrawMode,
    required this.onOpenMapTools,
    required this.isDrawMode,
    this.isCheckInActive = false,
    this.showCheckInAction = true,
    this.topLeftCard,
    required this.currentCenter,
    required this.currentZoom,
    required this.onTabSelected,
    required this.drawingState,
    required this.onFinishDrawing,
    required this.onCancelDrawing,
    required this.onSaveEdit,
    required this.onCancelEdit,
    required this.onUndoEdit,
    this.onRedoEdit,
    this.onUndoDrawing,
    this.canUndo = false,
    this.canRedo = false,
    this.hasSelfIntersection = false,
    this.measurementAreaHa = 0,
    this.measurementPerimeterKm = 0,
    this.measurementAzimuthDeg,
    this.gpsAccuracyM = 0,
  });

  @override
  ConsumerState<MapControlsOverlay> createState() => _MapControlsOverlayState();
}

class _MapControlsOverlayState extends ConsumerState<MapControlsOverlay> {
  bool _showMeasurementDetails = false;

  @override
  Widget build(BuildContext context) {
    // Use SafeArea top padding to ensure elements are below the status bar/notch
    final safeTop = MediaQuery.of(context).padding.top;
    final safeBottom = MediaQuery.of(context).padding.bottom;
    final activeColor = _themeColor(ref.watch(themeProvider));
    final areaUnit = ref.watch(areaDisplayUnitProvider);
    final distanceUnit = ref.watch(distanceDisplayUnitProvider);
    return Stack(
      children: [
        // 1. Card de contexto (Top Left) + talhão selected (consultor)
        Positioned(
          top: safeTop + 8,
          left: 12,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              widget.topLeftCard ?? const VisitActiveCard(),
              // Produtor já tem contexto no ProducerMapContextCard.
              if (widget.topLeftCard == null) ...[
                const SizedBox(height: 8),
                const SelectedTalhaoCard(),
              ],
            ],
          ),
        ),

        // 2. Botão de Localização + Indicador de Conectividade (canto superior direito)
        Positioned(
          top: safeTop + 12, // Respeita safe area (Dynamic Island / notch)
          right: 12,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Indicador unificado: offline / online / clima no mapa
              const _MapStatusIndicator(),
              const SizedBox(width: 6),
              // Botão de Localização com 3 estados
              _LocationButton(
                onCenterUser: widget.onCenterUser,
                onLocationModeChanged: widget.onLocationModeChanged,
                activeColor: activeColor,
              ),
            ],
          ),
        ),
        if ((widget.measurementAreaHa > 0 ||
                widget.measurementPerimeterKm > 0) &&
            widget.drawingState != DrawingState.drawing)
          Positioned(
            top: safeTop + 56,
            left: 12,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _FieldMeasurementCard(
                  areaHa: widget.measurementAreaHa,
                  areaUnit: areaUnit,
                  showDetails: _showMeasurementDetails,
                  onAreaUnit: (u) =>
                      ref.read(areaDisplayUnitProvider.notifier).setUnit(u),
                  onToggleDetails: () {
                    setState(() {
                      _showMeasurementDetails = !_showMeasurementDetails;
                    });
                  },
                ),
                if (_showMeasurementDetails) ...[
                  const SizedBox(height: 8),
                  _MeasurementDetailsCard(
                    perimeterKm: widget.measurementPerimeterKm,
                    azimuthDeg: widget.measurementAzimuthDeg,
                    gpsAccuracyM: widget.gpsAccuracyM,
                    distanceUnit: distanceUnit,
                    onDistanceUnit: (u) => ref
                        .read(distanceDisplayUnitProvider.notifier)
                        .setUnit(u),
                  ),
                ],
              ],
            ),
          ),

        // 3. Coluna de ações verticais (direita) — posição travada (REGRA-MAP-CHROME-1).
        // Não reage ao sheet: evita “pulo” ao arrastar detent ou retomar o app.
        Positioned(
          right: kMapActionColumnRightInset,
          bottom:
              kMapActionColumnBottomInset +
              safeBottom +
              (widget.isDrawMode ? kMapActionColumnDrawModeCompensation : 0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _MapToolsFab(
                isActive: widget.isDrawMode,
                activeColor: activeColor,
                onTap: widget.onOpenMapTools,
              ),
              if (!widget.isDrawMode && widget.showCheckInAction) ...[
                const SizedBox(height: kMapActionColumnSpacingAboveCheckIn),
                _MapActionButton(
                  buttonKey: const Key('map_control_check_in'),
                  icon: SFIcons.checkCircle,
                  label: 'Check-in',
                  isActive: widget.isCheckInActive,
                  activeColor: activeColor,
                  onTap: () => widget.onTabSelected(3, 'Button_CheckIn'),
                ),
              ],
            ],
          ),
        ),

        // 4. Drawing Actions (Conditional)
        if (widget.drawingState == DrawingState.drawing)
          DrawingBottomToolbarOverlay(
            onConfirm: widget.onFinishDrawing,
            onUndo: widget.onUndoDrawing ?? () {},
            onCancel: widget.onCancelDrawing,
            canUndo: widget.canUndo,
            // canConfirm espelha DrawingController.hasSelfIntersection
            // (_updateRealTimeIntersection → findSelfIntersectingSegments).
            // Widget permanece puro; validação de geometria fica no host.
            canConfirm: !widget.hasSelfIntersection,
            measurementAreaHa: widget.measurementAreaHa,
            measurementPerimeterKm: widget.measurementPerimeterKm,
            measurementAzimuthDeg: widget.measurementAzimuthDeg,
            gpsAccuracyM: widget.gpsAccuracyM,
            areaUnit: areaUnit,
            onAreaUnit: (u) =>
                ref.read(areaDisplayUnitProvider.notifier).setUnit(u),
            showMeasurementDetails: _showMeasurementDetails,
            onToggleMeasurementDetails: () {
              setState(() {
                _showMeasurementDetails = !_showMeasurementDetails;
              });
            },
            distanceUnit: distanceUnit,
            onDistanceUnit: (u) =>
                ref.read(distanceDisplayUnitProvider.notifier).setUnit(u),
          ),

        // 5. Editing Controls (Conditional)
        if (widget.drawingState == DrawingState.editing)
          Positioned(
            bottom: 120,
            right: 16,
            child: EditingControlsCluster(
              onSave: widget.onSaveEdit,
              onCancel: widget.onCancelEdit,
              onUndo: widget.onUndoEdit,
              onRedo: widget.onRedoEdit,
              canUndo: widget.canUndo,
              canRedo: widget.canRedo,
            ),
          ),
      ],
    );
  }
}

class EditingControlsCluster extends StatelessWidget {
  final VoidCallback onSave;
  final VoidCallback onCancel;
  final VoidCallback onUndo;
  final VoidCallback? onRedo;
  final bool canUndo;
  final bool canRedo;

  const EditingControlsCluster({
    super.key,
    required this.onSave,
    required this.onCancel,
    required this.onUndo,
    this.onRedo,
    this.canUndo = true,
    this.canRedo = false,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicWidth(
      child: Stack(
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                key: const Key('editing_controls_backplate'),
                decoration: BoxDecoration(
                  color: const Color(0xFF232326),
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.35),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Semantics(
                  button: true,
                  label: 'Salvar edição',
                  child: Material(
                    elevation: 4,
                    shape: const CircleBorder(),
                    color: PremiumTokens.brandGreen,
                    child: InkWell(
                      key: const Key('editing_control_save'),
                      customBorder: const CircleBorder(),
                      onTap: onSave,
                      child: const Padding(
                        padding: EdgeInsets.all(16),
                        child: Icon(
                          SFIcons.check,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Semantics(
                  button: true,
                  enabled: canUndo,
                  label: 'Desfazer edição',
                  child: Opacity(
                    opacity: canUndo ? 1.0 : 0.4,
                    child: Material(
                      elevation: 4,
                      shape: const CircleBorder(),
                      color: Colors.white,
                      child: InkWell(
                        key: const Key('editing_control_undo'),
                        customBorder: const CircleBorder(),
                        onTap: canUndo
                            ? () {
                                HapticFeedback.lightImpact();
                                onUndo();
                              }
                            : null,
                        child: const Padding(
                          padding: EdgeInsets.all(12),
                          child: Icon(
                            Icons.undo_rounded,
                            color: Colors.black87,
                            size: 24,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                if (onRedo != null) ...[
                  const SizedBox(height: 12),
                  Semantics(
                    button: true,
                    enabled: canRedo,
                    label: 'Refazer edição',
                    child: Opacity(
                      opacity: canRedo ? 1.0 : 0.4,
                      child: Material(
                        elevation: 4,
                        shape: const CircleBorder(),
                        color: Colors.white,
                        child: InkWell(
                          key: const Key('editing_control_redo'),
                          customBorder: const CircleBorder(),
                          onTap: canRedo
                              ? () {
                                  HapticFeedback.lightImpact();
                                  onRedo!();
                                }
                              : null,
                          child: const Padding(
                            padding: EdgeInsets.all(12),
                            child: Icon(
                              Icons.redo_rounded,
                              color: Colors.black87,
                              size: 24,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Semantics(
                  button: true,
                  label: 'Cancelar edição',
                  child: Material(
                    elevation: 4,
                    shape: const CircleBorder(),
                    color: Colors.redAccent,
                    child: InkWell(
                      key: const Key('editing_control_cancel'),
                      customBorder: const CircleBorder(),
                      onTap: onCancel,
                      child: const Padding(
                        padding: EdgeInsets.all(16),
                        child: Icon(
                          SFIcons.close,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MapActionButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isActive;
  final Color activeColor;
  final Key? buttonKey;

  const _MapActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.activeColor,
    this.buttonKey,
    this.isActive = false,
  });

  @override
  State<_MapActionButton> createState() => _MapActionButtonState();
}

class _MapActionButtonState extends State<_MapActionButton> {
  Timer? _labelTimer;
  bool _showLabel = false;

  @override
  void dispose() {
    _labelTimer?.cancel();
    super.dispose();
  }

  void _showTemporaryLabel() {
    _labelTimer?.cancel();
    setState(() => _showLabel = true);
    _labelTimer = Timer(const Duration(milliseconds: 1600), () {
      if (mounted) {
        setState(() => _showLabel = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _MapButtonLabel(text: widget.label, isVisible: _showLabel),
        const SizedBox(width: 8),
        Tooltip(
          message: widget.label,
          waitDuration: const Duration(milliseconds: 450),
          child: GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              widget.onTap();
            },
            onLongPress: _showTemporaryLabel,
            behavior: HitTestBehavior.opaque,
            child: Container(
              key: widget.buttonKey,
              width: kMapActionColumnButtonSize,
              height: kMapActionColumnButtonSize,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                widget.icon,
                size: 22,
                color: widget.isActive
                    ? widget.activeColor
                    : Colors.grey.shade600,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _MapToolsFab extends StatelessWidget {
  final bool isActive;
  final Color activeColor;
  final VoidCallback onTap;

  const _MapToolsFab({
    required this.isActive,
    required this.activeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Ferramentas do mapa',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: AnimatedContainer(
          key: const Key('map_control_layers_btn'),
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          width: kMapActionColumnButtonSize,
          height: kMapActionColumnButtonSize,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(
            SFIcons.layers,
            color: isActive ? activeColor : Colors.grey.shade600,
            size: 22,
          ),
        ),
      ),
    );
  }
}

class _MapButtonLabel extends StatelessWidget {
  final String text;
  final bool isVisible;

  const _MapButtonLabel({required this.text, required this.isVisible});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedSize(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOut,
        alignment: Alignment.centerRight,
        child: isVisible
            ? AnimatedOpacity(
                opacity: 1,
                duration: const Duration(milliseconds: 160),
                curve: Curves.easeOut,
                child: AnimatedScale(
                  scale: 1,
                  duration: const Duration(milliseconds: 160),
                  curve: Curves.easeOut,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.72),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 7,
                      ),
                      child: Text(
                        text,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              )
            : const SizedBox.shrink(),
      ),
    );
  }
}

/// Indicador unificado do mapa:
/// vermelho = sem internet · verde = online · azul Samsung = online + chuva no mapa.
class _MapStatusIndicator extends ConsumerWidget {
  static const Color _offlineColor = Color(0xFFFF3B30);
  static const Color _onlineColor = Color(0xFF34C759);
  static const Color _climaActiveColor = Color(0xFF1428A0);

  const _MapStatusIndicator();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOnline = ref.watch(isOnlineProvider).asData?.value ?? false;
    final isRadarEnabled = ref.watch(climaRadarEnabledProvider);

    final color = !isOnline
        ? _offlineColor
        : isRadarEnabled
        ? _climaActiveColor
        : _onlineColor;

    return Semantics(
      label: !isOnline
          ? 'Sem conexão com a internet'
          : isRadarEnabled
          ? 'Online com camada de chuva ativa'
          : 'Online',
      child: Container(
        key: const Key('map_status_indicator'),
        width: 16,
        height: 16,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.55),
              blurRadius: 10,
              spreadRadius: 3,
            ),
            BoxShadow(
              color: color.withValues(alpha: 0.28),
              blurRadius: 18,
              spreadRadius: 6,
            ),
          ],
        ),
      ),
    );
  }
}
