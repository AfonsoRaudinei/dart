// Removed dart:ui
import 'package:flutter/material.dart';
import 'package:soloforte_app/ui/theme/premium/design_tokens.dart';
import 'package:flutter/services.dart';
import 'package:latlong2/latlong.dart';
import '../../../../../../core/design/sf_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../modules/dashboard/controllers/location_controller.dart';
import '../../../../modules/dashboard/domain/location_state.dart';
import '../../../../modules/map/presentation/providers/map_location_mode_provider.dart';
import '../../../../core/providers/connectivity_provider.dart';

import '../../premium/premium_glass_panel.dart';
import '../../../../modules/drawing/domain/drawing_state.dart';
import '../../../../core/utils/app_logger.dart';
import './editing_controls_overlay.dart';
import '../../../../modules/map/presentation/widgets/visit_active_card.dart';

/// Overlay de controles do mapa (header, botões, check-in).
/// Observa apenas locationStateProvider para status do GPS.
class MapControlsOverlay extends ConsumerStatefulWidget {
  final VoidCallback onCenterUser;
  final VoidCallback onToggleDrawMode;
  final VoidCallback? onToggleOccurrenceMode;
  final VoidCallback? onToggleMarketingMode;
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
  // ADR-028 — Radar de Precipitação
  final bool isRadarActive;
  final VoidCallback? onToggleRadar;

  const MapControlsOverlay({
    super.key,
    required this.onCenterUser,
    required this.onToggleDrawMode,
    this.onToggleOccurrenceMode,
    this.onToggleMarketingMode,
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
    this.isRadarActive = false,
    this.onToggleRadar,
  });

  @override
  ConsumerState<MapControlsOverlay> createState() => _MapControlsOverlayState();
}

class _MapControlsOverlayState extends ConsumerState<MapControlsOverlay> {
  @override
  Widget build(BuildContext context) {
    // Use SafeArea top padding to ensure elements are below the status bar/notch
    final safeTop = MediaQuery.of(context).padding.top;

    return Stack(
      children: [
        // 1. Card de Visita Ativa (Top Left) — visível apenas com sessão ativa
        Positioned(
          top: safeTop + 8,
          left: 12,
          child: const VisitActiveCard(),
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
              _LocationButton(onCenterUser: widget.onCenterUser),
            ],
          ),
        ),

        // 3. Ações verticais do mapa (direita)
        Positioned(
          top: safeTop + 80, // Ajustado para não colidir com o botão de localização menor
          right: 16,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _MapActionButton(
                icon: SFIcons.edit,
                isActive: widget.isDrawMode,
                onTap: widget.onToggleDrawMode,
              ),
              // REMOVIDO: Botão de localização duplicado
              const SizedBox(height: 12),
              _MapActionButton(
                icon: SFIcons.layers,
                onTap: () => widget.onTabSelected(4, 'Button_Layers'),
              ),
              const SizedBox(height: 12),
              _MapActionButton(
                icon: SFIcons.warning,
                isActive: widget.isOccurrenceMode,
                onTap: () {
                  // 🐛 BUGFIX: onToggleOccurrenceMode → _armOccurrenceMode → _openOccurrenceCreationSheet
                  if (widget.onToggleOccurrenceMode != null) {
                    widget.onToggleOccurrenceMode!();
                  } else {
                    widget.onTabSelected(2, 'Button_Occurrences');
                  }
                },
              ),
              const SizedBox(height: 12),
              _MapActionButton(
                icon: Icons.campaign_rounded,
                isActive: widget.isMarketingMode,
                onTap: () {
                  if (widget.onToggleMarketingMode != null) {
                    widget.onToggleMarketingMode!();
                  }
                },
              ),
              const SizedBox(height: 12),
              _MapActionButton(
                icon: SFIcons.checkCircle,
                isActive: widget.isCheckInActive,
                onTap: () => widget.onTabSelected(3, 'Button_CheckIn'),
              ),
              const SizedBox(height: 12),
              // ADR-028 — Toggle radar de chuva
              _MapActionButton(
                icon: Icons.water_drop_outlined,
                isActive: widget.isRadarActive,
                onTap: () {
                  HapticFeedback.selectionClick();
                  widget.onToggleRadar?.call();
                },
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
                      : PremiumTokens.brandGreen,
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: widget.hasSelfIntersection ? null : widget.onFinishDrawing,
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
                        child: Icon(Icons.undo_rounded, color: Colors.black87, size: 24),
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

class _MapActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool isActive;

  const _MapActionButton({
    required this.icon,
    required this.onTap,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      behavior: HitTestBehavior.opaque,
      child: PremiumGlassPanel(
        borderRadius: BorderRadius.circular(99.0), // Totalmente Redondo
        isDark:
            isActive, // Quando ativo, usa glass Escuro/Verde (faremos custom se precisar, mas isDark ou mudar container interno ajuda)
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: isActive ? PremiumTokens.brandGreen : Colors.transparent,
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: isActive ? Colors.white : PremiumTokens.textPrimaryLight,
          ),
        ),
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
            color: (isOnline 
                ? const Color(0xFF34C759) 
                : const Color(0xFFFF3B30)
            ).withValues(alpha: 0.4),
            blurRadius: 4,
            spreadRadius: 1,
          ),
        ],
      ),
    );
  }
}

/// Botão de localização com 3 estados (idle / following / northLocked)
class _LocationButton extends ConsumerWidget {
  final VoidCallback onCenterUser;

  const _LocationButton({required this.onCenterUser});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locationMode = ref.watch(mapLocationModeProvider);
    final locationState = ref.watch(locationStateProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      shape: const CircleBorder(),
      elevation: 2,
      color: Colors.white,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () {
          HapticFeedback.selectionClick();
          
          // Ciclo de estados: idle → following → northLocked → idle
          final nextMode = switch (locationMode) {
            MapLocationMode.idle => MapLocationMode.following,
            MapLocationMode.following => MapLocationMode.northLocked,
            MapLocationMode.northLocked => MapLocationMode.idle,
          };
          
          ref.read(mapLocationModeProvider.notifier).state = nextMode;
          
          // Centralizar usuário quando entra em following
          if (nextMode == MapLocationMode.following || 
              nextMode == MapLocationMode.northLocked) {
            onCenterUser();
          }
          
          AppLogger.debug(
            "MapOverlay: Modo de localização mudou para $nextMode",
            tag: 'MapControls',
          );
        },
        child: SizedBox(
          width: 36,
          height: 36,
          child: Icon(
            _iconForMode(locationMode),
            size: 18,
            color: _colorForMode(locationMode, locationState, colorScheme),
          ),
        ),
      ),
    );
  }

  IconData _iconForMode(MapLocationMode mode) {
    return switch (mode) {
      MapLocationMode.idle => Icons.navigation_outlined,
      MapLocationMode.following => Icons.navigation,
      MapLocationMode.northLocked => Icons.explore,
    };
  }

  Color _colorForMode(
    MapLocationMode mode,
    LocationState locationState,
    ColorScheme colorScheme,
  ) {
    // Se GPS indisponível, sempre preto
    if (locationState != LocationState.available) {
      return Colors.black87;
    }

    // Estados ativos (following / northLocked) usam cor primary
    return switch (mode) {
      MapLocationMode.idle => Colors.black87,
      MapLocationMode.following => colorScheme.primary,
      MapLocationMode.northLocked => colorScheme.primary,
    };
  }
}
