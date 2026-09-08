import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/layout_constants.dart';
import '../../../../core/design/sf_icons.dart';
import '../../../screens/map/providers/pin_position_correction_provider.dart';
import '../../../theme/premium/design_tokens.dart';

/// Barra flutuante Cancelar / Salvar durante correção de posição de pin.
class PinPositionCorrectionOverlay extends ConsumerWidget {
  const PinPositionCorrectionOverlay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(pinPositionCorrectionProvider);
    if (session == null) return const SizedBox.shrink();

    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Positioned(
      left: 16,
      right: 16,
      bottom: kFabSafeArea + bottomInset + 8,
      child: Material(
        color: Colors.transparent,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: PremiumTokens.hairlineLight),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      ref.cancelPinCorrection();
                    },
                    child: const Text('Cancelar'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: PremiumTokens.brandGreen,
                    ),
                    onPressed: () async {
                      HapticFeedback.mediumImpact();
                      final saved = await ref.confirmPinCorrection();
                      if (!context.mounted) return;
                      if (!saved) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Não foi possível salvar a posição. Verifique as coordenadas.',
                            ),
                          ),
                        );
                        return;
                      }
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Posição do pin atualizada'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                    icon: const Icon(SFIcons.pinFill, size: 18),
                    label: const Text('Salvar posição'),
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
