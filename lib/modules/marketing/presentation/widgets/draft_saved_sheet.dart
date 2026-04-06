import 'package:flutter/material.dart';
import 'package:soloforte_app/core/ui/sheets/soloforte_sheet.dart';

/// Bottom sheet exibido após salvar um rascunho sem plano ativo.
/// Retorna [true] se o usuário quer ver os planos, [false] ou null para fechar.
class DraftSavedSheet extends StatelessWidget {
  const DraftSavedSheet({super.key});

  /// Exibe o sheet e retorna `true` se o usuário tocou em "Ver planos".
  /// A navegação fica a cargo do chamador após o modal fechar.
  static Future<bool?> show(BuildContext context) {
    return showSoloForteSheet<bool>(
      context: context,
      showDragHandle: false,
      builder: (_) => const DraftSavedSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle visual
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

          // Ícone
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: const Color(0xFF34C759).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle,
              size: 32,
              color: Color(0xFF34C759),
            ),
          ),

          const SizedBox(height: 16),

          // Título
          Text(
            'Case salvo com sucesso!',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 8),

          // Mensagem
          Text(
            'Seu case foi salvo como rascunho. Para publicá-lo no mapa e compartilhar com outros usuários, ative um plano.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 24),

          // Botão primário: Ver planos
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              // Fecha o modal e sinaliza ao chamador para navegar para /planos.
              // A navegação fica NO PAI — nunca neste widget.
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF007AFF),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
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

          // Botão secundário: Ok (apenas fecha)
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () => Navigator.of(context).pop(false),
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
