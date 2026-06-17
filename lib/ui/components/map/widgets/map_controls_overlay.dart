import 'dart:async';

// Removed dart:ui
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:latlong2/latlong.dart';
import '../../../../../../core/design/sf_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../modules/dashboard/providers/location_providers.dart';
import '../../../../modules/dashboard/domain/location_state.dart';
import '../../../../modules/consultoria/quick_photo/presentation/quick_photo_flow.dart';
import '../../../../modules/map/presentation/providers/map_location_mode_provider.dart';
import '../../../../modules/settings/presentation/providers/settings_providers.dart';
import '../../../../core/constants/layout_constants.dart';
import '../../../../core/contracts/i_visit_session_lookup_provider.dart';
import '../../../../core/providers/connectivity_provider.dart';
import '../../../../core/state/map_state.dart';
import '../../../../modules/drawing/domain/drawing_state.dart';
import '../../../../core/utils/app_logger.dart';
import '../../../../modules/map/presentation/widgets/visit_active_card.dart';
import '../../../theme/premium/design_tokens.dart';
import 'map_action_fab_menu.dart';

part 'map_controls_location_button.dart';

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
  final VoidCallback? onToggleOccurrenceMode;
  final VoidCallback? onCreateResultadoCase;
  final VoidCallback? onCreateAntesDepoisCase;
  final VoidCallback? onCreateAvaliacaoCase;
  final bool isMarketingMode;
  final Function(int, String) onTabSelected;
  final bool isDrawMode;
  final bool isOccurrenceMode;
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
    this.onToggleOccurrenceMode,
    this.onCreateResultadoCase,
    this.onCreateAntesDepoisCase,
    this.onCreateAvaliacaoCase,
    this.isMarketingMode = false,
    required this.isDrawMode,
    this.isOccurrenceMode = false,
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
  Future<void> _openQuickPhoto({required bool initialFilterActive}) async {
    String? visitSessionId;
    try {
      final activeSession = await ref
          .read(visitSessionLookupProvider)
          .getActiveSession();
      visitSessionId = activeSession?.isActive == true
          ? activeSession!.id
          : null;
    } catch (error) {
      AppLogger.warning(
        'Não foi possível vincular foto rápida à visita ativa',
        tag: 'QuickPhoto',
        error: error,
      );
    }

    if (!mounted) return;
    await QuickPhotoFlow.open(
      context,
      lat: widget.currentCenter.latitude,
      lng: widget.currentCenter.longitude,
      visitSessionId: visitSessionId,
      initialFilterActive: initialFilterActive,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Use SafeArea top padding to ensure elements are below the status bar/notch
    final safeTop = MediaQuery.of(context).padding.top;
    final safeBottom = MediaQuery.of(context).padding.bottom;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final activeColor = _themeColor(ref.watch(themeProvider));
    final areaUnit = ref.watch(areaDisplayUnitProvider);
    final distanceUnit = ref.watch(distanceDisplayUnitProvider);

    return Stack(
      children: [
        // 1. Card de contexto (Top Left)
        Positioned(
          top: safeTop + 8,
          left: 12,
          child: widget.topLeftCard ?? const VisitActiveCard(),
        ),

        // 2. Botão de Localização + Indicador de Conectividade (canto superior direito)
        Positioned(
          top: safeTop + 12, // Respeita safe area (Dynamic Island / notch)
          right: 12,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Indicador de Conectividade
              _ConnectivityDot(),
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
        if (widget.measurementAreaHa > 0 || widget.measurementPerimeterKm > 0)
          Positioned(
            top: safeTop + 56,
            left: 12,
            child: _FieldMeasurementCard(
              areaHa: widget.measurementAreaHa,
              perimeterKm: widget.measurementPerimeterKm,
              azimuthDeg: widget.measurementAzimuthDeg,
              gpsAccuracyM: widget.gpsAccuracyM,
              areaUnit: areaUnit,
              distanceUnit: distanceUnit,
              onAreaUnit: (u) =>
                  ref.read(areaDisplayUnitProvider.notifier).setUnit(u),
              onDistanceUnit: (u) =>
                  ref.read(distanceDisplayUnitProvider.notifier).setUnit(u),
            ),
          ),

        // 3. Ações verticais do mapa (direita)
        Positioned(
          right: 16,
          bottom: kFabSafeArea + safeBottom + 130,
          child: SafeArea(
            top: false,
            child: _MapToolsFab(
              isActive: widget.isDrawMode,
              activeColor: activeColor,
              onTap: widget.onOpenMapTools,
            ),
          ),
        ),

        Positioned.fill(
          child: MapActionFabMenu(
            right: 16,
            bottom: kFabSafeArea + safeBottom + 60,
            padding: EdgeInsets.zero,
            direction: MapActionFabMenuDirection.left,
            isActive: widget.isMarketingMode || widget.isOccurrenceMode,
            activeColor: activeColor,
            onResultado: widget.onCreateResultadoCase ?? () {},
            onAntesDepois: widget.onCreateAntesDepoisCase ?? () {},
            onAvaliacao: widget.onCreateAvaliacaoCase ?? () {},
            onOcorrencia: () {
              // Fluxo preservado: armar ocorrência e deixar o toque no mapa
              // abrir o OccurrenceCreationSheet atual.
              if (widget.onToggleOccurrenceMode != null) {
                widget.onToggleOccurrenceMode!();
              } else {
                widget.onTabSelected(2, 'Button_Occurrences');
              }
            },
            onFotoRapida: () {
              unawaited(_openQuickPhoto(initialFilterActive: false));
            },
            onInversaoVegetal: () {
              unawaited(_openQuickPhoto(initialFilterActive: true));
            },
          ),
        ),

        if (widget.showCheckInAction)
          Positioned(
            bottom: kFabSafeArea + safeBottom,
            right: 16,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _MapActionButton(
                  icon: SFIcons.checkCircle,
                  label: 'Check-in',
                  isActive: widget.isCheckInActive,
                  activeColor: activeColor,
                  onTap: () => widget.onTabSelected(3, 'Button_CheckIn'),
                ),
              ],
            ),
          ),

        // 4. Drawing Actions (Conditional)
        if (widget.drawingState == DrawingState.drawing)
          Positioned(
            bottom: 120,
            right: 16,
            child: DrawingControlsCluster(
              primaryColor: primaryColor,
              hasSelfIntersection: widget.hasSelfIntersection,
              onFinishDrawing: widget.onFinishDrawing,
              onUndoDrawing: widget.onUndoDrawing,
              onCancelDrawing: widget.onCancelDrawing,
              canUndo: widget.canUndo,
            ),
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

class DrawingControlsCluster extends StatelessWidget {
  final Color primaryColor;
  final bool hasSelfIntersection;
  final VoidCallback onFinishDrawing;
  final VoidCallback? onUndoDrawing;
  final VoidCallback onCancelDrawing;
  final bool canUndo;

  const DrawingControlsCluster({
    super.key,
    required this.primaryColor,
    required this.hasSelfIntersection,
    required this.onFinishDrawing,
    required this.onUndoDrawing,
    required this.onCancelDrawing,
    required this.canUndo,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('drawing_controls_backplate'),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.28),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Material(
            elevation: 4,
            shape: const CircleBorder(),
            color: hasSelfIntersection ? Colors.grey : primaryColor,
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: hasSelfIntersection ? null : onFinishDrawing,
              child: const Padding(
                padding: EdgeInsets.all(16),
                child: Icon(SFIcons.check, color: Colors.white, size: 24),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Opacity(
            opacity: canUndo ? 1.0 : 0.4,
            child: Material(
              elevation: 4,
              shape: const CircleBorder(),
              color: Colors.white,
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: canUndo ? onUndoDrawing : null,
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
          const SizedBox(height: 12),
          Material(
            elevation: 4,
            shape: const CircleBorder(),
            color: Colors.redAccent,
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onCancelDrawing,
              child: const Padding(
                padding: EdgeInsets.all(16),
                child: Icon(SFIcons.close, color: Colors.white, size: 24),
              ),
            ),
          ),
        ],
      ),
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
    return Container(
      key: const Key('editing_controls_backplate'),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.28),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Material(
            elevation: 4,
            shape: const CircleBorder(),
            color: PremiumTokens.brandGreen,
            child: InkWell(
              key: const Key('editing_control_save'),
              customBorder: const CircleBorder(),
              onTap: onSave,
              child: const Padding(
                padding: EdgeInsets.all(16),
                child: Icon(SFIcons.check, color: Colors.white, size: 24),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Opacity(
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
          if (onRedo != null) ...[
            const SizedBox(height: 12),
            Opacity(
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
          ],
          const SizedBox(height: 12),
          Material(
            elevation: 4,
            shape: const CircleBorder(),
            color: Colors.redAccent,
            child: InkWell(
              key: const Key('editing_control_cancel'),
              customBorder: const CircleBorder(),
              onTap: onCancel,
              child: const Padding(
                padding: EdgeInsets.all(16),
                child: Icon(SFIcons.close, color: Colors.white, size: 24),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FieldMeasurementCard extends StatelessWidget {
  final double areaHa;
  final double perimeterKm;
  final double? azimuthDeg;
  final double gpsAccuracyM;
  final AreaDisplayUnit areaUnit;
  final DistanceDisplayUnit distanceUnit;
  final ValueChanged<AreaDisplayUnit> onAreaUnit;
  final ValueChanged<DistanceDisplayUnit> onDistanceUnit;

  const _FieldMeasurementCard({
    required this.areaHa,
    required this.perimeterKm,
    required this.azimuthDeg,
    required this.gpsAccuracyM,
    required this.areaUnit,
    required this.distanceUnit,
    required this.onAreaUnit,
    required this.onDistanceUnit,
  });

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
    return Container(
      width: 234,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Medição',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            'Área: ${_formatArea()}',
            style: const TextStyle(color: Colors.white),
          ),
          Text(
            'Perímetro: ${_formatDistance()}',
            style: const TextStyle(color: Colors.white),
          ),
          Text(
            'Azimute: ${azimuthDeg?.toStringAsFixed(1) ?? '--'}°',
            style: const TextStyle(color: Colors.white),
          ),
          Text(
            gpsAccuracyM > 0
                ? 'GPS: ±${gpsAccuracyM.toStringAsFixed(1)} m'
                : 'GPS: --',
            style: const TextStyle(color: Colors.white),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _UnitChip(
                label: 'ha',
                selected: areaUnit == AreaDisplayUnit.hectare,
                onTap: () => onAreaUnit(AreaDisplayUnit.hectare),
              ),
              _UnitChip(
                label: 'm²',
                selected: areaUnit == AreaDisplayUnit.squareMeter,
                onTap: () => onAreaUnit(AreaDisplayUnit.squareMeter),
              ),
              _UnitChip(
                label: 'alq GO/MG',
                selected: areaUnit == AreaDisplayUnit.alqueire,
                onTap: () => onAreaUnit(AreaDisplayUnit.alqueire),
              ),
              _UnitChip(
                label: 'km',
                selected: distanceUnit == DistanceDisplayUnit.kilometer,
                onTap: () => onDistanceUnit(DistanceDisplayUnit.kilometer),
              ),
              _UnitChip(
                label: 'm',
                selected: distanceUnit == DistanceDisplayUnit.meter,
                onTap: () => onDistanceUnit(DistanceDisplayUnit.meter),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _UnitChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _UnitChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF34C759) : Colors.white12,
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

class _MapActionButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isActive;
  final Color activeColor;

  const _MapActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.activeColor,
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
              _showTemporaryLabel();
              widget.onTap();
            },
            onLongPress: _showTemporaryLabel,
            behavior: HitTestBehavior.opaque,
            child: Container(
              width: 44,
              height: 44,
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
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          width: 44,
          height: 44,
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

/// Indicador visual de conectividade (círculo verde/vermelho)
class _ConnectivityDot extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOnline = ref.watch(isOnlineProvider).valueOrNull ?? true;
    final color = isOnline ? const Color(0xFF34C759) : const Color(0xFFFF3B30);

    return Container(
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
    );
  }
}
