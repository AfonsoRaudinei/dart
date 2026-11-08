import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:soloforte_app/core/ui/sheets/solo_forte_sheet_visuals.dart';
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
    final v = SoloForteSheetVisuals.of(context);
    final session = ref.watch(pinPositionCorrectionProvider);
    if (session == null) return const SizedBox.shrink();

    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final isIos = v.isIos;

    return Positioned(
      left: 16,
      right: 16,
      bottom: kFabSafeArea + bottomInset + 8,
      child: Material(
        color: Colors.transparent,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: isIos
                ? CupertinoColors.systemBackground.resolveFrom(context)
                : v.sheetBackground.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(
              isIos ? v.ghostRadius + 3 : 16,
            ),
            border: Border.all(
              color: isIos
                  ? v.ghostBorder.withValues(alpha: 0.55)
                  : PremiumTokens.hairlineLight,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isIos ? 0.08 : 0.12),
                blurRadius: isIos ? 24 : 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: OutlinedButton(
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        ref.cancelPinCorrection();
                      },
                      style: isIos
                          ? OutlinedButton.styleFrom(
                              foregroundColor: v.ghostText,
                              side: BorderSide(color: v.ghostBorder,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  v.ghostRadius,
                                ),
                              ),
                            )
                          : null,
                      child: const Text('Cancelar'),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: isIos
                            ? v.ctaBackground
                            : PremiumTokens.brandGreen,
                        foregroundColor: v.ctaText,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            v.ctaRadius,
                          ),
                        ),
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
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
