import 'package:flutter/material.dart';
import 'package:soloforte_app/core/ui/sheets/sheet_tokens.dart';
import 'package:soloforte_app/core/ui/sheets/soloforte_sheet.dart';

/// Bottom sheet exibido após salvar um rascunho ou atingir limite de publicações.
class DraftSavedSheet extends StatelessWidget {
  const DraftSavedSheet({
    super.key,
    this.title = 'Case salvo com sucesso!',
    this.message =
        'Seu case foi salvo como rascunho (Não gerado). '
        'Para publicá-lo no mapa, libere espaço no limite do seu plano '
        'ou mantenha em Relatórios → Marketing.',
  });

  final String title;
  final String message;

  static Future<bool?> show(
    BuildContext context, {
    String? title,
    String? message,
  }) {
    return showSoloForteSheet<bool>(
      context: context,
      showDragHandle: false,
      builder: (_) => DraftSavedSheet(
        title: title ?? 'Case salvo com sucesso!',
        message:
            message ??
            'Seu case foi salvo como rascunho (Não gerado). '
                'Para publicá-lo no mapa, libere espaço no limite do seu plano '
                'ou mantenha em Relatórios → Marketing.',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isIos = soloForteSheetIsIos(context);
    final bg = isIos
        ? Colors.transparent
        : SoloForteSheetTokens.sheetBackground;
    final radius = isIos ? SoloForteSheetSkinIos.sheetRadius : 24.0;
    final titleColor = isIos ? SoloForteSheetSkinIos.titleColor : null;
    final messageColor = isIos
        ? SoloForteSheetSkinIos.subtitleColor
        : Theme.of(context).textTheme.bodySmall?.color;
    final secondaryColor = isIos
        ? SoloForteSheetSkinIos.ghostText
        : Theme.of(context).textTheme.bodyLarge?.color;
    final handleColor = isIos
        ? SoloForteSheetSkinIos.handleColor
        : Theme.of(context).dividerColor.withValues(alpha: 0.3);

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(radius)),
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
                color: handleColor,
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
              Icons.check_circle,
              size: 32,
              color: Color(0xFF34C759),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: titleColor,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: messageColor,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
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
                  fontWeight: FontWeight.w600,
                  color: secondaryColor,
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
