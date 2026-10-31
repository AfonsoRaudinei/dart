import 'package:flutter/material.dart';
import 'package:soloforte_app/ui/theme/premium/design_tokens.dart';

/// Prova rápida dos papéis de [TextTheme] no tema ativo (Verde / Azul / Black).
class ThemeTypographyPreview extends StatelessWidget {
  const ThemeTypographyPreview({super.key});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    Widget row(String label, TextStyle? style) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 72,
              child: Text(
                label,
                style: text.labelSmall,
              ),
            ),
            Expanded(
              child: Text(
                'Aa — $label',
                style: style,
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Prévia de tipografia',
            style: text.labelMedium?.copyWith(
              color: context.premiumTextSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          row('Título', text.titleLarge),
          row('Subtítulo', text.titleMedium),
          row('Corpo', text.bodyLarge),
          row('Metadado', text.bodyMedium),
          row('Label', text.labelMedium),
        ],
      ),
    );
  }
}
