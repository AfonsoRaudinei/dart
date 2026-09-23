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
import '../../../../core/contracts/i_radar_overlay_controller_provider.dart';
import '../../../../core/state/map_state.dart';
import '../../../../core/utils/area_display_format.dart';
import '../../../../modules/drawing/domain/drawing_state.dart';
import '../../../../modules/drawing/presentation/widgets/drawing_bottom_toolbar_overlay.dart';
import '../../../../core/utils/app_logger.dart';
import '../../../../modules/map/presentation/widgets/visit_active_card.dart';
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
  final VoidCallback? onUndoDrawing; // Undo no modo drawing
  final bool canUndo;
  final bool hasSelfIntersection;
  final double measurementAreaHa;
  final double measurementPerimeterKm;
  final double? measurementAzimuthDeg;
  final double gpsAccuracyM;
  final String? editingFieldName;

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
    this.onUndoDrawing,
    this.canUndo = false,
    this.hasSelfIntersection = false,
    this.measurementAreaHa = 0,
    this.measurementPerimeterKm = 0,
    this.measurementAzimuthDeg,
    this.gpsAccuracyM = 0,
    this.editingFieldName,
  });

  @override
  ConsumerState<MapControlsOverlay> createState() => _MapControlsOverlayState();
}

class _MapControlsOverlayState extends ConsumerState<MapControlsOverlay> {
  bool _showMeasurementDetails = false;

  bool get _hidesCheckInForDrawing =>
      widget.isDrawMode ||
      widget.drawingState == DrawingState.drawing ||
      widget.drawingState == DrawingState.editing;

  @override
  Widget build(BuildContext context) {
    // Use SafeArea top padding to ensure elements are below the status bar/notch
    final safeTop = MediaQuery.of(context).padding.top;
    final safeBottom = MediaQuery.of(context).padding.bottom;
    final activeColor = _themeColor(ref.watch(themeProvider));
    final areaUnit = ref.watch(areaDisplayUnitProvider);
    final distanceUnit = ref.watch(distanceDisplayUnitProvider);
    final showEditingPill = widget.drawingState == DrawingState.editing &&
        widget.editingFieldName != null &&
        widget.editingFieldName!.trim().isNotEmpty;
    final contextCardTop = safeTop + (showEditingPill ? 72 : 8);
    return Stack(
      children: [
        // 1. Card de contexto (Top Left) + talhão selected (consultor)
        Positioned(
          top: contextCardTop,
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

        if (showEditingPill)
          Positioned(
            top: safeTop + 8,
            left: 72,
            right: 72,
            child: Center(
              child: _EditingContextPill(label: widget.editingFieldName!),
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
              const _MapPinsToggle(),
              const SizedBox(width: 6),
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
            widget.drawingState != DrawingState.drawing &&
            widget.drawingState != DrawingState.editing)
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
                enabled: widget.drawingState != DrawingState.editing,
                activeColor: activeColor,
                onTap: widget.onOpenMapTools,
              ),
              if (!_hidesCheckInForDrawing && widget.showCheckInAction) ...[
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

        // 4. Drawing / editing actions — mesmo chrome inferior (toolbar + medição).
        // Redo não entra na toolbar (paridade com desenho / modelo Imagem 4).
        // DrawingController.redoEdit() permanece no domínio para uso futuro.
        if (widget.drawingState == DrawingState.drawing ||
            widget.drawingState == DrawingState.editing)
          DrawingBottomToolbarOverlay(
            onConfirm: widget.drawingState == DrawingState.editing
                ? widget.onSaveEdit
                : widget.onFinishDrawing,
            onUndo: widget.drawingState == DrawingState.editing
                ? widget.onUndoEdit
                : (widget.onUndoDrawing ?? () {}),
            onCancel: widget.drawingState == DrawingState.editing
                ? widget.onCancelEdit
                : widget.onCancelDrawing,
            canUndo: widget.canUndo,
            // canConfirm espelha DrawingController.hasSelfIntersection
            // (_updateRealTimeIntersection → findSelfIntersectingSegments).
            // Widget permanece puro; validação de geometria fica no host.
            canConfirm: widget.drawingState == DrawingState.editing
                ? true
                : !widget.hasSelfIntersection,
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
      ],
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
        Semantics(
          button: true,
          label: widget.label,
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
  final bool enabled;
  final Color activeColor;
  final VoidCallback onTap;

  const _MapToolsFab({
    required this.isActive,
    this.enabled = true,
    required this.activeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Ferramentas do mapa',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: enabled
            ? () {
                HapticFeedback.selectionClick();
                onTap();
              }
            : null,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 180),
          opacity: enabled ? 1 : 0.45,
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
              )
            : const SizedBox.shrink(),
      ),
    );
  }
}

/// Botão circular do topo direito (Pinos / Chuva / Localização).
/// Diferencia da coluna direita, que permanece quadrado com r=12.
class _MapRoundToggleButton extends StatelessWidget {
  const _MapRoundToggleButton({
    this.buttonKey,
    required this.icon,
    required this.iconColor,
    required this.isOn,
    this.showSlash,
    this.iconSize = 22,
    this.onTap,
    this.onLongPress,
  });

  final Key? buttonKey;
  final IconData icon;
  final Color iconColor;
  final bool isOn;

  /// Quando null, o risco segue `!isOn`. Offline da chuva passa `false`
  /// (`wifi_off` já comunica desligado).
  final bool? showSlash;
  final double iconSize;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final slash = showSlash ?? !isOn;
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      behavior: HitTestBehavior.opaque,
      child: Container(
        key: buttonKey,
        width: kMapActionColumnButtonSize,
        height: kMapActionColumnButtonSize,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipOval(
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(icon, size: iconSize, color: iconColor),
              if (slash) const Positioned.fill(child: _IconOffSlash()),
            ],
          ),
        ),
      ),
    );
  }
}

/// Risco diagonal SW→NE (estilo iOS mute) para estado desligado.
class _IconOffSlash extends StatelessWidget {
  const _IconOffSlash();

  @override
  Widget build(BuildContext context) {
    return const IgnorePointer(
      child: CustomPaint(
        painter: _IconOffSlashPainter(),
        child: SizedBox.expand(),
      ),
    );
  }
}

class _IconOffSlashPainter extends CustomPainter {
  const _IconOffSlashPainter();

  static const _haloWidth = 3.5;
  static const _strokeWidth = 1.8;
  static const _strokeColor = Color(0xFF3A3A3C);

  @override
  void paint(Canvas canvas, Size size) {
    final inset = size.shortestSide * 0.22;
    final start = Offset(inset, size.height - inset);
    final end = Offset(size.width - inset, inset);

    final halo = Paint()
      ..color = Colors.white
      ..strokeWidth = _haloWidth
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final stroke = Paint()
      ..color = _strokeColor
      ..strokeWidth = _strokeWidth
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    canvas.drawLine(start, end, halo);
    canvas.drawLine(start, end, stroke);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Toggle de pinos no mapa (`showMarkersProvider`).
class _MapPinsToggle extends ConsumerWidget {
  const _MapPinsToggle();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final show = ref.watch(showMarkersProvider);
    return Semantics(
      button: true,
      label: show ? 'Ocultar pinos' : 'Mostrar pinos',
      child: _MapRoundToggleButton(
        buttonKey: const Key('map_control_pins'),
        icon: SFIcons.pinFill,
        iconSize: 20,
        iconColor: show ? const Color(0xFF1976D2) : Colors.grey.shade600,
        isOn: show,
        onTap: () {
          HapticFeedback.selectionClick();
          ref.read(showMarkersProvider.notifier).toggle();
        },
      ),
    );
  }
}

/// Indicador unificado do mapa:
/// offline = wifi_off vermelho (sem slash) · online = drop cinza + slash ·
/// radar on = drop azul. Long-press exibe rótulo.
class _MapStatusIndicator extends ConsumerStatefulWidget {
  static const Color _offlineColor = Color(0xFFFF3B30);
  static const Color _climaActiveColor = Color(0xFF1428A0);

  const _MapStatusIndicator();

  @override
  ConsumerState<_MapStatusIndicator> createState() =>
      _MapStatusIndicatorState();
}

class _MapStatusIndicatorState extends ConsumerState<_MapStatusIndicator> {
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
      if (mounted) setState(() => _showLabel = false);
    });
  }

  String _statusLabel({required bool isOnline, required bool isRadarEnabled}) {
    if (!isOnline) return 'Sem conexão';
    if (isRadarEnabled) return 'Online · chuva no mapa';
    return 'Online';
  }

  @override
  Widget build(BuildContext context) {
    final isOnline = ref.watch(isOnlineProvider).asData?.value ?? false;
    final isRadarEnabled = ref.watch(climaRadarEnabledProvider);
    final label = _statusLabel(
      isOnline: isOnline,
      isRadarEnabled: isRadarEnabled,
    );

    final IconData icon;
    final Color iconColor;
    final bool showSlash;
    if (!isOnline) {
      icon = Icons.wifi_off_rounded;
      iconColor = _MapStatusIndicator._offlineColor;
      showSlash = false;
    } else if (isRadarEnabled) {
      icon = Icons.water_drop_rounded;
      iconColor = _MapStatusIndicator._climaActiveColor;
      showSlash = false;
    } else {
      icon = Icons.water_drop_rounded;
      iconColor = Colors.grey.shade600;
      showSlash = true;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _MapButtonLabel(text: label, isVisible: _showLabel),
        const SizedBox(width: 6),
        Semantics(
          button: true,
          label: label,
          child: _MapRoundToggleButton(
            buttonKey: const Key('map_status_indicator'),
            icon: icon,
            iconColor: iconColor,
            isOn: isOnline && isRadarEnabled,
            showSlash: showSlash,
            onTap: () {
              final enabling = !ref.read(climaRadarEnabledProvider);
              ref.read(radarOverlayControllerProvider).setEnabled(
                    enabling,
                    preferSatelliteLayer: enabling,
                  );
            },
            onLongPress: _showTemporaryLabel,
          ),
        ),
      ],
    );
  }
}

class _EditingContextPill extends StatelessWidget {
  const _EditingContextPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: Text(
          'Editando: $label',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
