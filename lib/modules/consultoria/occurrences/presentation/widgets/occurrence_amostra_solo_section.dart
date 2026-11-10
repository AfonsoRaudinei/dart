import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:soloforte_app/core/ui/sheets/solo_forte_sheet_visuals.dart';
import 'package:soloforte_app/ui/theme/premium/design_tokens.dart';

import '../../domain/occurrence_amostra_solo.dart';
import 'occurrence_form_widgets.dart';

/// Formulário de amostra de solo (código, coletor, trâmite, laudo).
class OccurrenceAmostraSoloSection extends StatelessWidget {
  final TextEditingController codigoController;
  final TextEditingController coletorController;
  final TextEditingController laudoController;
  final OccurrenceAmostraTramite? tramite;
  final ValueChanged<OccurrenceAmostraTramite> onTramiteChanged;
  final bool enabled;

  const OccurrenceAmostraSoloSection({
    super.key,
    required this.codigoController,
    required this.coletorController,
    required this.laudoController,
    required this.tramite,
    required this.onTramiteChanged,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final isIos = occurrenceFormIsIos(context);
    final v = SoloForteSheetVisuals.of(context);
    final accent = isIos
        ? v.iconStroke
        : context.themeAccent;
    final selected = tramite ?? OccurrenceAmostraTramite.coletada;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(
          v.cardRadius,
        ),
        border: Border.all(color: accent.withValues(alpha: 0.55), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const OccurrenceSectionHeader(
            title: 'Amostra de solo',
          ),
          const SizedBox(height: 8),
          OccurrenceDarkField(
            controller: codigoController,
            label: 'Número / código da amostra',
            hint: 'Ex.: AS-2026-014',
            enabled: enabled,
          ),
          const SizedBox(height: 10),
          OccurrenceDarkField(
            controller: coletorController,
            label: 'Quem coletou',
            hint: 'Nome do técnico ou equipe',
            enabled: enabled,
          ),
          const SizedBox(height: 14),
          Text(
            'Trâmite',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isIos
                  ? v.subtitleColor
                  : PremiumTokens.textSecondaryDark,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: OccurrenceAmostraTramite.values.map((step) {
              final sel = selected == step;
              return FilterChip(
                selected: sel,
                onSelected: enabled
                    ? (_) {
                        HapticFeedback.selectionClick();
                        onTramiteChanged(step);
                      }
                    : null,
                label: Text(step.label),
                selectedColor: accent.withValues(alpha: 0.25),
                backgroundColor: v.cardBackground,
                checkmarkColor: accent,
                side: BorderSide(
                  color: sel ? accent : v.chipBorderInactive,
                ),
              );
            }).toList(),
          ),
          if (selected == OccurrenceAmostraTramite.laudoPronto) ...[
            const SizedBox(height: 12),
            OccurrenceDarkField(
              controller: laudoController,
              label: 'Resumo do laudo',
              hint: 'Resultado principal — base para análises futuras',
              maxLines: 4,
              enabled: enabled,
            ),
          ],
        ],
      ),
    );
  }
}
