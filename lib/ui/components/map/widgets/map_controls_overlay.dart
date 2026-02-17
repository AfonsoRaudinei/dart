import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../../../../../../modules/map/design/sf_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../modules/dashboard/controllers/location_controller.dart';
import '../../../../modules/dashboard/domain/location_state.dart';
import '../../../theme/soloforte_theme.dart';
import '../map_sheets.dart';
import '../../../../modules/visitas/presentation/controllers/visit_controller.dart';
import '../../../../modules/visitas/presentation/widgets/visit_sheet.dart';
import '../../../../modules/dashboard/services/location_service.dart';
import '../../../../modules/map/presentation/widgets/map_layers_bottom_sheet.dart';

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
  });

  @override
  ConsumerState<MapControlsOverlay> createState() => _MapControlsOverlayState();
}

class _MapControlsOverlayState extends ConsumerState<MapControlsOverlay> {
  void _handleCheckInTap() {
    final visitController = ref.read(visitControllerProvider.notifier);

    visitController.handleCheckInTap(
      onShowEndConfirmation: () => _showEndConfirmationDialog(),
      onShowStartSheet: () => _showStartVisitSheet(),
    );
  }

  void _showEndConfirmationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Encerrar Check-in'),
        content: const Text('Deseja realmente encerrar a visita atual?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(visitControllerProvider.notifier).endSession();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Visita encerrada com sucesso.')),
              );
            },
            child: const Text('Encerrar'),
          ),
        ],
      ),
    );
  }

  void _showStartVisitSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, controller) => VisitSheet(
          onConfirm: (clientId, areaId, activityType) async {
            final locService = LocationService();
            final pos = await locService.getCurrentPosition();

            if (pos == null) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Erro: Localização necessária para check-in.',
                    ),
                  ),
                );
              }
              return;
            }

            await ref
                .read(visitControllerProvider.notifier)
                .startSession(
                  clientId,
                  areaId,
                  activityType,
                  pos.latitude,
                  pos.longitude,
                );

            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Visita iniciada. Bom trabalho!'),
                  backgroundColor: SoloForteColors.greenIOS,
                ),
              );
            }
          },
        ),
      ),
    );
  }

  void _showSheet(BuildContext context, Widget sheet, String name) {
    debugPrint("📑 MapOverlay: Abrindo sheet '$name'");
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: sheet,
        ),
      ),
    );
  }

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
    // Observar o estado da visita real
    final visitAsync = ref.watch(visitControllerProvider);
    final isSessionActive = visitAsync.valueOrNull != null;
    final isLoading = visitAsync.isLoading;

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
                onTap: () {
                  debugPrint("✏️ MapOverlay: Clique em 'Desenhar'");
                  widget.onToggleDrawMode();
                },
              ),
              // REMOVIDO: Botão de localização duplicado
              const SizedBox(height: 12),
              _MapActionButton(
                icon: SFIcons.layers,
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => DraggableScrollableSheet(
                      initialChildSize: 0.6,
                      minChildSize: 0.4,
                      maxChildSize: 0.9,
                      expand: false,
                      builder: (context, scrollController) {
                        return MapLayersBottomSheet(
                          scrollController: scrollController,
                          currentCenter: widget.currentCenter,
                          currentZoom: widget.currentZoom,
                        );
                      },
                    ),
                  );
                },
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
                onTap: () => _showSheet(
                  context,
                  const PublicacoesSheet(),
                  'Publicações',
                ),
              ),
            ],
          ),
        ),

        // 4. Botão Check-in (CTA separado)
        Positioned(
          bottom: 120,
          right: 20,
          child: GestureDetector(
            onTap: isLoading
                ? null
                : () {
                    debugPrint("✅ MapOverlay: Clique em 'Check-in'");
                    _handleCheckInTap();
                  },
            behavior: HitTestBehavior.opaque,
            child: Opacity(
              opacity: isLoading ? 0.6 : 1.0,
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: isSessionActive
                      ? SoloForteColors.greenIOS
                      : SoloForteColors.white,
                  shape: BoxShape.circle,
                  boxShadow: SoloShadows.shadowButton,
                  border: Border.all(color: SoloForteColors.greenIOS, width: 2),
                ),
                child: isLoading
                    ? Center(
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              isSessionActive
                                  ? Colors.white
                                  : SoloForteColors.greenIOS,
                            ),
                          ),
                        ),
                      )
                    : Icon(
                        isSessionActive ? SFIcons.check : SFIcons.syncAlt,
                        size: 28,
                        color: isSessionActive
                            ? Colors.white
                            : SoloForteColors.greenIOS,
                      ),
              ),
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
