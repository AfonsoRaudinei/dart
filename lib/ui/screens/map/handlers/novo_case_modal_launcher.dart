// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/ui/sheets/soloforte_sheet.dart';
import '../../../../modules/marketing/presentation/providers/marketing_providers.dart';
import '../../../../modules/marketing/presentation/screens/novo_case_sheet.dart';
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

    await showSoloForteSheet(
      context: context,
      showDragHandle: false,
      maxHeightFraction: 0.85,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
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
                  color: Theme.of(
                    sheetContext,
                  ).dividerColor.withValues(alpha: 0.3),
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
                  // Lê plano — nunca null após PROMPT-A (retorna UserPlan.free())
                  final plano = ref.read(planoAtivoProvider).valueOrNull;

                  // 1. Admin bypass — sem verificação de limite
                  if (plano?.isAdmin == true) {
                    Navigator.of(context).pop();
                    final saved = await ref
                        .read(marketingCasesProvider.notifier)
                        .publishCase(newCase);
                    if (!context.mounted) return;
                    _showPublishResult(context, saved);
                    return;
                  }

                  // 2. Contar cases publicados do usuário
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

                  // 3. Limite: free tier = 3, plano padrão conforme UserPlan
                  final limite = plano?.limiteCases ?? 3;

                  if (casesPublicados >= limite) {
                    if (!context.mounted) return;
                    Navigator.of(context).pop();
                    PlanoBlockSheet.show(
                      context,
                      motivo: 'limite_atingido',
                      planoLabel: plano?.plano.label,
                      limite: limite,
                    );
                    return;
                  }

                  // 4. Publica normalmente
                  Navigator.of(context).pop();

                  final saved = await ref
                      .read(marketingCasesProvider.notifier)
                      .publishCase(newCase);

                  if (!context.mounted) return;
                  _showPublishResult(context, saved);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Exibe snackbar de resultado de publicação (sucesso ou offline).
  static void _showPublishResult(BuildContext context, dynamic saved) {
    if (saved != null) {
      HapticFeedback.heavyImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white, size: 18),
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
              Icon(Icons.cloud_off, color: Colors.white, size: 18),
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
  }
}
