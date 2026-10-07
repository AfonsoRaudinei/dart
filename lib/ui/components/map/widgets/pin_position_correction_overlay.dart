import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/layout_constants.dart';
import '../../../../core/design/sf_icons.dart';
import '../../../../core/ui/sheets/sheet_tokens.dart';
import '../../../../core/ui/sheets/soloforte_sheet.dart';
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
    final isIos = soloForteSheetIsIos(context);

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
                : Colors.white.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(
              isIos ? SoloForteSheetSkinIos.ghostRadius + 3 : 16,
            ),
            border: Border.all(
              color: isIos
                  ? SoloForteSheetSkinIos.ghostBorder.withValues(alpha: 0.55)
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
                              foregroundColor: SoloForteSheetSkinIos.ghostText,
                              side: const BorderSide(
                                color: SoloForteSheetSkinIos.ghostBorder,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  SoloForteSheetSkinIos.ghostRadius,
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
                            ? SoloForteSheetSkinIos.ctaBackground
                            : PremiumTokens.brandGreen,
                        foregroundColor: isIos
                            ? SoloForteSheetSkinIos.ctaText
                            : Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            isIos
                                ? SoloForteSheetSkinIos.ctaRadius
                                : 12,
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
