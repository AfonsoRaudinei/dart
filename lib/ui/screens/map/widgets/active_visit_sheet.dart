import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/design/sf_icons.dart';
import '../../../../ui/theme/premium/design_tokens.dart';
import '../../../../modules/visitas/presentation/controllers/visit_controller.dart';

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
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            SFIcons.checkCircle,
            size: 64,
            color: PremiumTokens.brandGreen,
          ),
          const SizedBox(height: 16),
          Text(
            'Visita em Andamento',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () async {
              // ✅ FIX Causa A: ler sessão da mesma fonte que o card.
              // visitControllerProvider.endSession() acessa state.value
              // (SQLite offline-first) — sem depender de agendaProvider.
              // Após encerrar: state = null → card desaparece reativamente.
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
                  Navigator.of(context).pop();
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Erro ao encerrar visita: $e')),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: PremiumTokens.alertError,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
            child: const Text('Encerrar Visita'),
          ),
        ],
      ),
    );
  }
}
