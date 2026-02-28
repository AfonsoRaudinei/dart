// Removed dart:ui
import 'package:flutter/material.dart';
import 'package:soloforte_app/ui/theme/premium/design_tokens.dart';
import 'package:flutter/services.dart';
import 'package:latlong2/latlong.dart';
import '../../../../../../modules/map/design/sf_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../modules/dashboard/controllers/location_controller.dart';
import '../../../../modules/dashboard/domain/location_state.dart';

import '../../premium/premium_glass_panel.dart';
import '../../../../modules/drawing/domain/drawing_state.dart';
import '../../../../core/utils/app_logger.dart';
import './editing_controls_overlay.dart';

/// Overlay de controles do mapa (header, botões, check-in).
/// Observa apenas locationStateProvider para status do GPS.
class MapControlsOverlay extends ConsumerStatefulWidget {
  final VoidCallback onCenterUser;
  final VoidCallback onToggleDrawMode;
  final VoidCallback? onToggleOccurrenceMode;
  final Function(int, String) onTabSelected;
  final bool isDrawMode;
  final bool isOccurrenceMode;
  final LatLng currentCenter;
  final double currentZoom;
  final DrawingState drawingState;
  final VoidCallback onFinishDrawing;
  final VoidCallback onCancelDrawing;
  final VoidCallback onSaveEdit;
  final VoidCallback onCancelEdit;
  final VoidCallback onUndoEdit;

  const MapControlsOverlay({
    super.key,
    required this.onCenterUser,
    required this.onToggleDrawMode,
    this.onToggleOccurrenceMode,
    required this.isDrawMode,
    this.isOccurrenceMode = false,
    required this.currentCenter,
    required this.currentZoom,
    required this.onTabSelected,
    required this.drawingState,
    required this.onFinishDrawing,
    required this.onCancelDrawing,
    required this.onSaveEdit,
    required this.onCancelEdit,
    required this.onUndoEdit,
  });

  @override
  ConsumerState<MapControlsOverlay> createState() => _MapControlsOverlayState();
}

class _MapControlsOverlayState extends ConsumerState<MapControlsOverlay> {
  String _getGPSStatusText(LocationState state) {
    switch (state) {
      case LocationState.available:
        return 'GPS OK';
      case LocationState.permissionDenied:
        return 'GPS: Sem permissão';
      case LocationState.serviceDisabled:
        return 'GPS: Desligado';
      case LocationState.checking:
        return 'GPS: Verificando...';
    }
  }

  @override
  Widget build(BuildContext context) {
    // ⚡ Otimização: Observar apenas o LocationState (não toda a posição)
    final locationState = ref.watch(locationStateProvider);

    // Use SafeArea top padding to ensure elements are below the status bar/notch
    final safeTop = MediaQuery.of(context).padding.top;

    return Stack(
      children: [
        // 1. Header with Data Trust (Top Left)
        Positioned(
          top: 60, // Mantendo posição original do header
          left: 20,
          child: PremiumGlassPanel(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: PremiumTokens.brandGreen,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: PremiumTokens.brandGreen.withValues(
                              alpha: 0.4,
                            ),
                            blurRadius: 6,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'SoloForte Privado',
                      style: Theme.of(
                        context,
                      ).textTheme.titleMedium?.copyWith(fontSize: 14),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: Row(
                    children: [
                      Icon(
                        locationState == LocationState.available
                            ? SFIcons.nearMe
                            : SFIcons.locationDisabled,
                        size: 12,
                        color: locationState == LocationState.available
                            ? PremiumTokens.textSecondaryLight
                            : PremiumTokens.alertError,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _getGPSStatusText(locationState),
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          fontSize: 10,
                          color: PremiumTokens.textSecondaryLight,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // 2. Botão de Localização (isolado, canto superior direito)
        Positioned(
          top: safeTop + 16, // Abaixo do SafeArea
          right: 16, // Layout pedido: 16
          child: GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              AppLogger.debug(
                "MapOverlay: Clique em 'Centralizar Usuário'",
                tag: 'MapControls',
              );
              widget.onCenterUser();
            },
            behavior: HitTestBehavior.opaque,
            child: PremiumGlassPanel(
              borderRadius: BorderRadius.circular(99.0),
              child: Container(
                width: 52,
                height: 52,
                alignment: Alignment.center,
                child: Icon(
                  SFIcons.myLocation,
                  size: 24,
                  color: locationState == LocationState.available
                      ? PremiumTokens.brandGreen
                      : PremiumTokens.textPrimaryLight,
                ),
              ),
            ),
          ),
        ),

        // 3. Ações verticais do mapa (direita)
        Positioned(
          top:
              safeTop +
              120, // Ajustado para não colidir com o botão de localização
          right: 16, // Layout pedido: 16
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
                  // Se tivermos callback de toggle, usamos ele (prioridade para armado)
                  if (widget.onToggleOccurrenceMode != null) {
                    widget.onToggleOccurrenceMode!();
                  } else {
                    // Fallback antigo: abre a tab direto
                    widget.onTabSelected(2, 'Button_Occurrences');
                  }
                },
              ),
              const SizedBox(height: 12),
              _MapActionButton(
                icon: SFIcons.articleOutlined,
                onTap: () => widget.onTabSelected(1, 'Button_Publications'),
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
                FloatingActionButton(
                  heroTag: 'complete_drawing_overlay',
                  backgroundColor: PremiumTokens.brandGreen,
                  onPressed: widget.onFinishDrawing,
                  child: const Icon(SFIcons.check, color: Colors.white),
                ),
                const SizedBox(height: 12),
                FloatingActionButton(
                  heroTag: 'cancel_drawing_overlay',
                  backgroundColor: Colors.redAccent,
                  onPressed: widget.onCancelDrawing,
                  child: const Icon(SFIcons.close, color: Colors.white),
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
