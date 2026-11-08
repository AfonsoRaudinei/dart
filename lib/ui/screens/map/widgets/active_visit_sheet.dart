import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/design/sf_icons.dart';
import '../../../../core/ui/sheets/sheet_tokens.dart';
import '../../../../core/ui/sheets/solo_forte_sheet_visuals.dart';
import '../../../../core/ui/sheets/soloforte_sheet.dart';
import '../../../../ui/theme/premium/design_tokens.dart';
import '../../../../modules/visitas/presentation/controllers/visit_controller.dart';
import 'package:soloforte_app/core/utils/user_facing_error.dart';

/// Widget independente que exibe a UI de visita ativa no checkIn sheet.
///
/// Extraído de `_PrivateMapSheets._buildActiveVisitContent` — ADR-031 F2.
/// Responsabilidade: botão "Encerrar Visita" + feedback de resultado.
/// Lê: [visitControllerProvider].
/// NÃO acessa _PrivateMapScreenState diretamente.
class ActiveVisitSheet extends ConsumerWidget {
  const ActiveVisitSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final v = SoloForteSheetVisuals.of(context);
    // Host de check-in usa preserveMaterialDefaults (Scope forçado em light);
    // re-propaga a variante real do tema para o conteúdo.
    return SoloForteSheetSkinScope(
      variant: soloForteSheetVariantFromThemeId(
        Theme.of(context).extension<SoloForteThemeExtension>()?.themeId,
      ),
      child: Builder(builder: (context) => _buildContent(context, ref)),
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref) {
    final v = SoloForteSheetVisuals.of(context);
    final isIos = v.isIos;
    final titleColor = v.titleColor;
    final ghostFg = v.ghostText;
    final ghostBorder = v.ghostBorder;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            SFIcons.checkCircle,
            size: 64,
            color: isIos
                ? v.ctaBackground
                : PremiumTokens.brandGreen,
          ),
          const SizedBox(height: 16),
          Text(
            'Visita em Andamento',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: titleColor,
              fontWeight: isIos ? FontWeight.w700 : null,
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () async {
              try {
                await ref.read(visitControllerProvider.notifier).endSession();
                if (context.mounted) {
                  HapticFeedback.mediumImpact();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Visita encerrada com sucesso.'),
                      backgroundColor: PremiumTokens.brandGreenDark,
                    ),
                  );
                  Navigator.of(context).pop();
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
              backgroundColor: PremiumTokens.alertError,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                  v.ctaRadius,
                ),
              ),
            ),
            child: const Text('Encerrar Visita'),
          ),
          if (isIos) ...[
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: OutlinedButton.styleFrom(
                foregroundColor: ghostFg,
                side: BorderSide(color: ghostBorder),
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    v.ghostRadius,
                  ),
                ),
              ),
              child: const Text('Fechar'),
            ),
          ],
        ],
      ),
    );
  }
}
