// ADR-030 F2 — Widget extraído de private_map_screen.dart (B12)
// Indicador visual efêmero: modo seleção de ponto para ocorrência.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/map_armed_mode_provider.dart';

/// Banner exibido quando [armedModeProvider] == [ArmedMode.occurrences].
/// Posicionado no topo da tela, ignora ponteiro (IgnorePointer).
class ArmedModeBanner extends ConsumerWidget {
  const ArmedModeBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final armedMode = ref.watch(armedModeProvider);
    if (armedMode != ArmedMode.occurrences) return const SizedBox.shrink();

    return Positioned(
      top: MediaQuery.of(context).padding.top + 8,
      left: 0,
      right: 0,
      child: IgnorePointer(
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black87,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.location_pin,
                  color: Colors.orangeAccent,
                  size: 16,
                ),
                SizedBox(width: 8),
                Text(
                  'Toque no mapa para marcar o ponto',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
