import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../../../../../../modules/map/design/sf_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../modules/dashboard/controllers/location_controller.dart';
import '../../../../modules/dashboard/domain/location_state.dart';
import '../../../theme/soloforte_theme.dart';
// unused imports removed

import '../../../../modules/drawing/domain/drawing_state.dart';
import './editing_controls_overlay.dart';

/// Overlay de controles do mapa (header, botões, check-in).
/// Observa apenas locationStateProvider para status do GPS.
class MapControlsOverlay extends ConsumerStatefulWidget {
  final VoidCallback onCenterUser;
  final VoidCallback onToggleDrawMode;
  final VoidCallback? onToggleOccurrenceMode;
  final Function(int) onTabSelected;
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
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: SoloForteColors.white.withValues(alpha: 0.90),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.2),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      offset: const Offset(0, 4),
                      blurRadius: 16,
                    ),
                  ],
                ),
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
                            color: SoloForteColors.greenIOS,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: SoloForteColors.greenIOS.withValues(
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
                          style: SoloTextStyles.headingMedium.copyWith(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.5,
                          ),
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
                                ? SoloForteColors.textSecondary
                                : SoloForteColors.error,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _getGPSStatusText(locationState),
                            style: SoloTextStyles.label.copyWith(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: SoloForteColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        // 2. Botão de Localização (isolado, canto superior direito)
        Positioned(
          top: safeTop + 16, // Abaixo do SafeArea
          right: 16, // Layout pedido: 16
          child: GestureDetector(
            onTap: () {
              debugPrint(
                "🎯 MapOverlay: Clique em 'Centralizar Usuário' (Topo)",
              );
              widget.onCenterUser();
            },
            behavior: HitTestBehavior.opaque,
            child: Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: SoloForteColors.white.withValues(alpha: 0.95),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    offset: const Offset(0, 4),
                    blurRadius: 12,
                  ),
                ],
              ),
              child: Icon(
                SFIcons.myLocation,
                size: 24,
                color: Colors.black.withValues(alpha: 0.85),
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
                onTap: () => widget.onTabSelected(0),
              ),
              // REMOVIDO: Botão de localização duplicado
              const SizedBox(height: 12),
              _MapActionButton(
                icon: SFIcons.layers,
                onTap: () => widget.onTabSelected(0),
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
                    widget.onTabSelected(2);
                  }
                },
              ),
              const SizedBox(height: 12),
              _MapActionButton(
                icon: SFIcons.articleOutlined,
                onTap: () => widget.onTabSelected(1),
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
                  backgroundColor: SoloForteColors.greenIOS,
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
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: isActive ? SoloForteColors.greenIOS : SoloForteColors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: isActive
                  ? SoloForteColors.greenIOS.withValues(alpha: 0.4)
                  : Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(
          icon,
          color: isActive ? Colors.white : SoloForteColors.textPrimary,
        ),
      ),
    );
  }
}
