// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/ui/sheets/sheet_tokens.dart';
import '../../../../modules/marketing/presentation/providers/marketing_providers.dart';
import '../../../../modules/marketing/presentation/screens/novo_case_sheet.dart';
import '../../../../modules/marketing/presentation/widgets/draft_saved_sheet.dart';
import '../../../../modules/planos/presentation/providers/plano_providers.dart';
import '../../widgets/plano_block_sheet.dart';

/// Lança o fluxo completo de criação de novo case a partir de um long-press
/// no mapa. Verifica plano ativo, limite de cases e exibe os sheets adequados.
class NovoCaseModalLauncher {
  const NovoCaseModalLauncher._();

  static Future<void> launch({
    required LatLng position,
    required BuildContext context,
    required WidgetRef ref,
  }) async {
    if (!context.mounted) return;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        decoration: const BoxDecoration(
          color: SoloForteSheetTokens.sheetBackground,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).dividerColor.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Flexible(
              child: NovoCaseSheet(
                lat: position.latitude,
                lng: position.longitude,
                onClose: () => Navigator.of(context).pop(),
                onPublicar: (newCase) async {
                  // Verifica plano APÓS preenchimento do formulário
                  final plano = ref.read(planoAtivoProvider).valueOrNull;

                  if (plano == null || plano.expirado) {
                    // Sem plano → salva como rascunho
                    try {
                      await ref
                          .read(marketingCasesProvider.notifier)
                          .saveAsDraft(newCase);

                      if (!context.mounted) return;

                      // Fecha o NovoCaseSheet
                      Navigator.of(context).pop();

                      // Exibe DraftSavedSheet e captura decisão do usuário.
                      final goToPlanos = await DraftSavedSheet.show(context);

                      if (!context.mounted) return;
                      if (goToPlanos == true) {
                        context.go('/planos');
                      }
                    } catch (e) {
                      if (!context.mounted) return;
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Erro ao salvar rascunho: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                    return;
                  }

                  // Com plano → verifica limite de cases publicados
                  final cases =
                      ref.read(marketingCasesProvider).valueOrNull ?? [];
                  final casesPublicados = cases
                      .where(
                        (c) =>
                            c.status.toValue() == 'published' &&
                            c.ativo &&
                            c.deletadoEm == null,
                      )
                      .length;

                  if (casesPublicados >= plano.limiteCases) {
                    if (!context.mounted) return;
                    Navigator.of(context).pop();
                    PlanoBlockSheet.show(
                      context,
                      motivo: 'limite_atingido',
                      planoLabel: plano.plano.label,
                    );
                    return;
                  }

                  // Publica normalmente
                  Navigator.of(context).pop();

                  final saved = await ref
                      .read(marketingCasesProvider.notifier)
                      .publishCase(newCase);

                  if (!context.mounted) return;
                  if (saved != null) {
                    HapticFeedback.heavyImpact();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Row(
                          children: [
                            Icon(
                              Icons.check_circle,
                              color: Colors.white,
                              size: 18,
                            ),
                            SizedBox(width: 8),
                            Text('Case publicado com sucesso! 📈'),
                          ],
                        ),
                        backgroundColor: const Color(0xFF34C759),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Row(
                          children: [
                            Icon(
                              Icons.cloud_off,
                              color: Colors.white,
                              size: 18,
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Sem conexão — case salvo localmente e será sincronizado.',
                              ),
                            ),
                          ],
                        ),
                        backgroundColor: Colors.orange,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        duration: const Duration(seconds: 4),
                      ),
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
