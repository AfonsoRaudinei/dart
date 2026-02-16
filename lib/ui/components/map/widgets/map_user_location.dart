import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../modules/dashboard/controllers/location_controller.dart';
import '../../../../modules/dashboard/domain/location_state.dart';

/// Widget que observa apenas locationStateProvider e userPositionProvider.
/// Renderiza o pino azul do usuário quando GPS está ativo.
class MapUserLocationWidget extends ConsumerWidget {
  final bool isMapReady;

  const MapUserLocationWidget({
    super.key,
    required this.isMapReady,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ⚡ Otimização: Observar apenas se GPS está disponível (booleano)
    final isGPSAvailable = ref.watch(
      locationStateProvider.select((state) => state == LocationState.available),
    );
    final userPosition = ref.watch(userPositionProvider);

    if (!isMapReady || !isGPSAvailable || userPosition == null) {
      return const SizedBox.shrink();
    }

    return MarkerLayer(
      markers: [
        Marker(
          point: userPosition,
          width: 60,
          height: 60,
          alignment: Alignment.center,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFF007AFF).withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFF007AFF).withValues(alpha: 0.25),
                    width: 1.5,
                  ),
                ),
              ),
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: const Color(0xFF007AFF),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white,
                    width: 3,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
