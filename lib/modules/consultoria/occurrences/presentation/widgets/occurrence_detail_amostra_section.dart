import 'package:flutter/material.dart';
import 'package:soloforte_app/core/ui/sheets/solo_forte_sheet_visuals.dart';
import 'package:soloforte_app/ui/theme/premium/design_tokens.dart';

import '../../domain/occurrence.dart';
import '../../domain/occurrence_amostra_solo.dart';

/// Bloco read-only de amostra de solo no detalhe da ocorrência.
class OccurrenceDetailAmostraSection extends StatelessWidget {
  final Occurrence occurrence;
  final Color cardBg;
  final double cardRadius;
  final bool isIos;
  final bool isDark;

  const OccurrenceDetailAmostraSection({
    super.key,
    required this.occurrence,
    required this.cardBg,
    required this.cardRadius,
    required this.isIos,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final v = SoloForteSheetVisuals.of(context);
    if (!occurrenceIsAmostraSolo(occurrence)) return const SizedBox.shrink();

    final tramite = OccurrenceAmostraTramite.fromStorage(occurrence.amostraTramite);
    final codigo = occurrence.amostraCodigo?.trim() ?? '';
    final coletor = occurrence.amostraColetor?.trim() ?? '';
    final laudo = occurrence.amostraLaudoTexto?.trim() ?? '';
    final hasContent = codigo.isNotEmpty ||
        coletor.isNotEmpty ||
        tramite != null ||
        laudo.isNotEmpty;
    if (!hasContent) return const SizedBox.shrink();

    final labelStyle = TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      color: isIos
          ? v.subtitleColor
          : PremiumTokens.textSecondaryDark,
    );
    final valueStyle = TextStyle(
      fontSize: 14,
      color: isIos
          ? v.titleColor
          : (isDark
              ? PremiumTokens.textPrimaryDark
              : Theme.of(context).colorScheme.onSurface),
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(cardRadius),
          border: isIos
              ? Border.all(color: v.cardBorder)
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Amostra de solo', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            if (codigo.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text('Código', style: labelStyle),
              Text(codigo, style: valueStyle),
            ],
            if (coletor.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text('Coletor', style: labelStyle),
              Text(coletor, style: valueStyle),
            ],
            if (tramite != null) ...[
              const SizedBox(height: 10),
              Text('Trâmite', style: labelStyle),
              Text(tramite.label, style: valueStyle),
            ],
            if (tramite == OccurrenceAmostraTramite.laudoPronto &&
                laudo.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text('Resumo do laudo', style: labelStyle),
              Text(laudo, style: valueStyle),
            ],
          ],
        ),
      ),
    );
  }
}
