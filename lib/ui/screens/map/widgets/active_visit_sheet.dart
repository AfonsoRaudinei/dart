import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soloforte_app/core/utils/user_facing_error.dart';

import '../../../../core/design/sf_icons.dart';
import '../../../../core/ui/sheets/sheet_tokens.dart';
import '../../../../modules/visitas/presentation/controllers/visit_controller.dart';
import '../../../../ui/theme/premium/design_tokens.dart';

/// Sheet compacto de visita ativa — padrão SoloForte (ADR-027).
///
/// Conteúdo mínimo: status + Encerrar. O tamanho do modal é controlado por
/// [MapSheetController] (detent compacto quando há visita ativa).
class ActiveVisitSheet extends ConsumerWidget {
  /// Se informado (caminho Stack), fecha via callback em vez de [Navigator.pop].
  final VoidCallback? onDismissed;

  const ActiveVisitSheet({super.key, this.onDismissed});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bottomSafe = MediaQuery.paddingOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 8, 20, math.max(16, bottomSafe + 12)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: SoloForteSheetTokens.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const Icon(
            SFIcons.checkCircle,
            size: 40,
            color: PremiumTokens.brandGreen,
          ),
          const SizedBox(height: 10),
          const Text(
            'Visita em Andamento',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: SoloForteSheetTokens.titleColor,
              fontSize: SoloForteSheetTokens.titleFontSize,
              fontWeight: SoloForteSheetTokens.titleWeight,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () async {
                try {
                  await ref
                      .read(visitControllerProvider.notifier)
                      .endSession();
                  if (context.mounted) {
                    HapticFeedback.mediumImpact();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Visita encerrada com sucesso.'),
                        backgroundColor: PremiumTokens.brandGreenDark,
                      ),
                    );
                    if (onDismissed != null) {
                      onDismissed!();
                    } else {
                      Navigator.of(context).pop();
                    }
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          userFacingError(e, action: 'Erro ao encerrar visita'),
                        ),
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                elevation: 0,
                backgroundColor: PremiumTokens.alertError,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    SoloForteSheetTokens.inputRadius,
                  ),
                ),
              ),
              child: const Text(
                'Encerrar Visita',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
