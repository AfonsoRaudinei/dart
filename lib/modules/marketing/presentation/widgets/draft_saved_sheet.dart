import 'package:flutter/material.dart';
import 'package:soloforte_app/core/ui/sheets/soloforte_sheet.dart';

import 'package:soloforte_app/core/ui/sheets/sheet_tokens.dart';

/// Bottom sheet exibido após salvar um case como rascunho (limite de plano).
/// Retorna [DraftSavedAction] indicando a ação escolhida pelo usuário.
enum DraftSavedAction { dismiss, verPlanos, verRelatorios }

/// Bottom sheet exibido após salvar um rascunho quando a publicação não é possível.
class DraftSavedSheet extends StatelessWidget {
  final String? planoLabel;
  final int? limite;

  const DraftSavedSheet({
    super.key,
    this.planoLabel,
    this.limite,
  });

  /// Exibe o sheet e retorna a ação escolhida.
  static Future<DraftSavedAction?> show(
    BuildContext context, {
    String? planoLabel,
    int? limite,
  }) {
    return showSoloForteSheet<DraftSavedAction>(
      context: context,
      showDragHandle: false,
      builder: (_) => DraftSavedSheet(
        planoLabel: planoLabel,
        limite: limite,
      ),
    );
  }

  String get _limiteMessage {
    if (planoLabel != null && limite != null) {
      return 'Seu plano $planoLabel permite apenas $limite case(s) ativo(s). '
          'O case foi salvo como rascunho em Relatórios > Marketing. '
          'Faça upgrade para publicar mais.';
    }
    return 'O limite de cases ativos do seu plano foi atingido. '
        'O case foi salvo como rascunho em Relatórios > Marketing. '
        'Faça upgrade para publicar quando houver vaga.';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: SoloForteSheetTokens.sheetBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).dividerColor.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: const Color(0xFF34C759).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.save_outlined,
              size: 32,
              color: Color(0xFF34C759),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Case salvo como rascunho',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            _limiteMessage,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () =>
                  Navigator.of(context).pop(DraftSavedAction.verRelatorios),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF34C759),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                minimumSize: const Size(double.infinity, 52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Ver em Relatórios',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () =>
                  Navigator.of(context).pop(DraftSavedAction.verPlanos),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF59E0B),
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 16),
                minimumSize: const Size(double.infinity, 52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Ver planos',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () =>
                  Navigator.of(context).pop(DraftSavedAction.dismiss),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(
                'Ok, entendi',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
