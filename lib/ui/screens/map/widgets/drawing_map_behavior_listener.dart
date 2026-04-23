// ADR-030 F4 — Widget extraído de private_map_screen.dart (B5)
// ConsumerWidget invisível que gerencia side effects de drawing no mapa:
//   - auto-switch para satélite ao entrar em modo desenho/edição/GPS
//   - zoom para bounds ao importar KML/KMZ (importPreview)
// Retorna SizedBox.shrink() — zero impacto visual.

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/state/map_state.dart';
import '../../../../core/domain/map_models.dart';
import '../../../../modules/drawing/domain/drawing_state.dart';
import '../../../../modules/drawing/domain/drawing_utils.dart';
import '../../../../modules/drawing/presentation/providers/drawing_provider.dart';

/// Widget invisível responsável pelos side effects de [DrawingState] no mapa.
///
/// Recebe [mapController] e [isMapReady] porque o [MapController] não é
/// gerenciado por Riverpod — é estado de ciclo de vida do widget pai.
/// [onCenterOnUser] é passado como callback para evitar dependência direta
/// na lógica de GPS (encapsulada em [MapLocationHandler]).
class DrawingMapBehaviorListener extends ConsumerWidget {
  final MapController mapController;
  final bool isMapReady;
  final VoidCallback onCenterOnUser;

  const DrawingMapBehaviorListener({
    required this.mapController,
    required this.isMapReady,
    required this.onCenterOnUser,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch drawing state changes to switch layers
    ref.listen(drawingControllerProvider.select((s) => s.currentState), (
      prev,
      next,
    ) {
      // 🛡 LIFECYCLE GUARD: listener pode disparar após dispose do widget
      if (!context.mounted) return;

      if (next == DrawingState.drawing || next == DrawingState.editing) {
        // Auto-switch to Satellite
        final currentLayer = ref.read(activeLayerProvider);
        if (currentLayer != LayerType.satellite) {
          ref.read(activeLayerProvider.notifier).setLayer(LayerType.satellite);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Modo Satélite ativado para melhor visualização'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      }

      // 🆕 SPRINT 5: GPS Tracking → ativar satélite + centralizar no usuário
      if (next == DrawingState.gpsTracking) {
        final currentLayer = ref.read(activeLayerProvider);
        if (currentLayer != LayerType.satellite) {
          ref.read(activeLayerProvider.notifier).setLayer(LayerType.satellite);
        }
        // Centralizar mapa na posição atual do usuário para referência
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!context.mounted) return;
          onCenterOnUser();
        });
      }

      // 🆕 SPRINT 3: Zoom automático após import KML/KMZ
      // Quando a geometria importada entra em preview, move a câmera para ela
      if (next == DrawingState.importPreview && isMapReady) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!context.mounted) return;
          final geo = ref.read(drawingControllerProvider).liveGeometry;
          final bounds = DrawingUtils.getBoundsLatLng(geo);
          if (bounds != null) {
            try {
              mapController.fitCamera(
                CameraFit.bounds(
                  bounds: bounds,
                  padding: const EdgeInsets.all(60),
                ),
              );
            } catch (_) {
              // Guard: mapa pode estar em transição — ignora silenciosamente
            }
          }
        });
      }
    });

    return const SizedBox.shrink();
  }
}
