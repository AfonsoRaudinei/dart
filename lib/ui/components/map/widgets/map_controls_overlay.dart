import 'dart:async';

// Removed dart:ui
import 'package:flutter/material.dart';
import 'package:soloforte_app/ui/theme/premium/design_tokens.dart';
import 'package:flutter/services.dart';
import 'package:latlong2/latlong.dart';
import '../../../../../../core/design/sf_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../modules/dashboard/providers/location_providers.dart';
import '../../../../modules/dashboard/domain/location_state.dart';
import '../../../../modules/consultoria/quick_photo/presentation/quick_photo_flow.dart';
import '../../../../modules/map/presentation/providers/map_location_mode_provider.dart';
import '../../../../core/constants/layout_constants.dart';
import '../../../../core/providers/connectivity_provider.dart';

import '../../premium/premium_glass_panel.dart';
import '../../../../modules/drawing/domain/drawing_state.dart';
import '../../../../core/utils/app_logger.dart';
import './editing_controls_overlay.dart';
import '../../../../modules/map/presentation/widgets/visit_active_card.dart';
import 'map_action_fab_menu.dart';

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
  });

  @override
  ConsumerState<MapControlsOverlay> createState() => _MapControlsOverlayState();
}

class _MapControlsOverlayState extends ConsumerState<MapControlsOverlay> {
  @override
  Widget build(BuildContext context) {
    // Use SafeArea top padding to ensure elements are below the status bar/notch
    final safeTop = MediaQuery.of(context).padding.top;
    final safeBottom = MediaQuery.of(context).padding.bottom;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Stack(
      children: [
        // 1. Card de Visita Ativa (Top Left) — visível apenas com sessão ativa
        Positioned(top: safeTop + 8, left: 12, child: const VisitActiveCard()),

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
              ),
            ],
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
              QuickPhotoFlow.open(
                context,
                lat: widget.currentCenter.latitude,
                lng: widget.currentCenter.longitude,
              );
            },
          ),
        ),

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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Material(
                  elevation: 4,
                  shape: const CircleBorder(),
                  color: widget.hasSelfIntersection
                      ? Colors.grey
                      : primaryColor,
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: widget.hasSelfIntersection
                        ? null
                        : widget.onFinishDrawing,
                    child: const Padding(
                      padding: EdgeInsets.all(16),
                      child: Icon(SFIcons.check, color: Colors.white, size: 24),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Undo último ponto de desenho
                Opacity(
                  opacity: widget.canUndo ? 1.0 : 0.4,
                  child: Material(
                    elevation: 4,
                    shape: const CircleBorder(),
                    color: Colors.white,
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: widget.canUndo ? widget.onUndoDrawing : null,
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
                    onTap: widget.onCancelDrawing,
                    child: const Padding(
                      padding: EdgeInsets.all(16),
                      child: Icon(SFIcons.close, color: Colors.white, size: 24),
                    ),
                  ),
                ),
              ],
            ),
          ),

        // 5. Editing Controls (Conditional)
        if (widget.drawingState == DrawingState.editing)
          Positioned(
            bottom: 120,
            left: 20,
            right: 20,
            child: Center(
              child: EditingControlsOverlay(
                onSave: widget.onSaveEdit,
                onCancel: widget.onCancelEdit,
                onUndo: widget.onUndoEdit,
                onRedo: widget.onRedoEdit,
                canUndo: widget.canUndo,
                canRedo: widget.canRedo,
              ),
            ),
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

  const _MapActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
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
    final primaryColor = Theme.of(context).colorScheme.primary;

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
            child: PremiumGlassPanel(
              borderRadius: BorderRadius.circular(99.0), // Totalmente Redondo
              isDark: widget
                  .isActive, // Quando ativo, usa glass Escuro/Verde (faremos custom se precisar, mas isDark ou mudar container interno ajuda)
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: widget.isActive ? primaryColor : Colors.transparent,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  widget.icon,
                  color: widget.isActive
                      ? Colors.white
                      : PremiumTokens.textPrimaryLight,
                ),
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
  final VoidCallback onTap;

  const _MapToolsFab({required this.isActive, required this.onTap});

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
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF007AFF),
            border: Border.all(
              color: isActive
                  ? PremiumTokens.brandGreen.withValues(alpha: 0.88)
                  : Colors.white.withValues(alpha: 0.08),
              width: isActive ? 2 : 0.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.22),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(SFIcons.layers, color: Colors.white, size: 27),
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

    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isOnline
            ? const Color(0xFF34C759) // Verde iOS
            : const Color(0xFFFF3B30), // Vermelho iOS
        boxShadow: [
          BoxShadow(
            color:
                (isOnline ? const Color(0xFF34C759) : const Color(0xFFFF3B30))
                    .withValues(alpha: 0.4),
            blurRadius: 4,
            spreadRadius: 1,
          ),
        ],
      ),
    );
  }
}

/// Botão de localização com 3 estados (idle / following / northLocked)
class _LocationButton extends ConsumerStatefulWidget {
  final VoidCallback onCenterUser;
  final ValueChanged<MapLocationMode> onLocationModeChanged;

  const _LocationButton({
    required this.onCenterUser,
    required this.onLocationModeChanged,
  });

  @override
  ConsumerState<_LocationButton> createState() => _LocationButtonState();
}

class _LocationButtonState extends ConsumerState<_LocationButton> {
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
    final locationMode = ref.watch(mapLocationModeProvider);
    final locationState = ref.watch(locationStateProvider);
    const label = 'Localização';
    final isAvailable = locationState == LocationState.available;
    final iconColor = _colorForMode(locationMode, isAvailable);
    final backgroundColor = _backgroundForMode(locationMode);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _MapButtonLabel(text: label, isVisible: _showLabel),
        const SizedBox(width: 8),
        Tooltip(
          message: label,
          waitDuration: const Duration(milliseconds: 450),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {
                HapticFeedback.selectionClick();
                _showTemporaryLabel();

                // Ciclo de estados: idle → following → northLocked → idle
                final nextMode = switch (locationMode) {
                  MapLocationMode.idle => MapLocationMode.following,
                  MapLocationMode.following => MapLocationMode.northLocked,
                  MapLocationMode.northLocked => MapLocationMode.idle,
                };

                ref.read(mapLocationModeProvider.notifier).state = nextMode;
                widget.onLocationModeChanged(nextMode);

                // Centralizar usuário quando entra em following
                if (nextMode == MapLocationMode.following ||
                    nextMode == MapLocationMode.northLocked) {
                  widget.onCenterUser();
                }

                AppLogger.debug(
                  "MapOverlay: Modo de localização mudou para $nextMode",
                  tag: 'MapControls',
                );
              },
              onLongPress: _showTemporaryLabel,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      blurRadius: locationMode == MapLocationMode.idle ? 8 : 10,
                      color: Colors.black12,
                      offset: const Offset(0, 3),
                    ),
                  ],
                  border: locationMode == MapLocationMode.idle
                      ? Border.all(
                          color: Colors.black.withValues(alpha: 0.06),
                          width: 0.5,
                        )
                      : null,
                ),
                child: Icon(
                  _iconForMode(locationMode),
                  size: 22,
                  color: isAvailable ? iconColor : Colors.grey.shade500,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  IconData _iconForMode(MapLocationMode mode) {
    return switch (mode) {
      MapLocationMode.idle => Icons.navigation_outlined,
      MapLocationMode.following => Icons.navigation,
      MapLocationMode.northLocked => Icons.explore,
    };
  }

  Color _colorForMode(MapLocationMode mode, bool isAvailable) {
    if (!isAvailable) return Colors.grey.shade500;

    return switch (mode) {
      MapLocationMode.idle => Colors.grey.shade600,
      MapLocationMode.following => Colors.blue,
      MapLocationMode.northLocked => Colors.white,
    };
  }

  Color _backgroundForMode(MapLocationMode mode) {
    return switch (mode) {
      MapLocationMode.idle => const Color(0xFFF9FAFB),
      MapLocationMode.following => Colors.white,
      MapLocationMode.northLocked => Colors.blue,
    };
  }
}
