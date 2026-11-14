import 'package:flutter/material.dart';
import 'package:soloforte_app/core/ui/sheets/solo_forte_sheet_visuals.dart';
import 'package:flutter/services.dart';
import '../../../../ui/theme/premium/design_tokens.dart';
import '../../domain/enums/case_tipo.dart';
import '../../domain/enums/plano_marketing.dart';

class CaseTipoSelector extends StatelessWidget {
  final CaseTipo selectedTipo;
  final ValueChanged<CaseTipo> onChanged;

  const CaseTipoSelector({
    super.key,
    required this.selectedTipo,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
        final v = SoloForteSheetVisuals.of(context);
    final isIos = v.isIos;
    final selectedBg =
        isIos ? v.ctaBackground : context.themeAccent;
    final selectedBorder =
        isIos ? v.ctaBackground : context.themeAccent;
    final inactiveBorder = v.cardBorder;
    final selectedFg = v.ctaText;
    final inactiveFg = v.subtitleColor;

    final labels = {
      CaseTipo.resultado: 'Resultado',
      CaseTipo.antesDepois: 'Antes/\nDepois',
      CaseTipo.avaliacao: 'Avaliação',
    };
    return Row(
      children: CaseTipo.values.map((t) {
        final isSelected = selectedTipo == t;
        return Expanded(
          child: GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              onChanged(t);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: isSelected ? selectedBg : Colors.transparent,
                borderRadius: BorderRadius.circular(
                  v.ctaRadius,
                ),
                border: Border.all(
                  color: isSelected ? selectedBorder : inactiveBorder,
                ),
              ),
              child: Text(
                labels[t]!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: isSelected ? selectedFg : inactiveFg,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.normal,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class PlanoMarketingSelector extends StatelessWidget {
  final PlanoMarketing? selectedPlano;
  final Set<PlanoMarketing> enabledMetals;
  final ValueChanged<PlanoMarketing> onChanged;

  const PlanoMarketingSelector({
    super.key,
    required this.selectedPlano,
    required this.enabledMetals,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
        final v = SoloForteSheetVisuals.of(context);
    final inactiveBorder = v.cardBorder;

    final colors = {
      PlanoMarketing.ouro: const Color(0xFFFFB800),
      PlanoMarketing.prata: const Color(0xFF9EA9B2),
      PlanoMarketing.bronze: const Color(0xFFA0522D),
    };
    return Row(
      children: PlanoMarketing.values.map((p) {
        final isEnabled = enabledMetals.contains(p);
        final isSelected = selectedPlano != null && selectedPlano == p;
        final color = colors[p]!;
        final displayColor = isEnabled
            ? color
            : color.withValues(alpha: isSelected ? 0.65 : 0.4);
        return Expanded(
          child: Opacity(
            opacity: isEnabled ? 1 : 0.55,
            child: GestureDetector(
              onTap: isEnabled
                  ? () {
                      HapticFeedback.selectionClick();
                      onChanged(p);
                    }
                  : null,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? color.withValues(alpha: 0.15)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(
                    v.ctaRadius,
                  ),
                  border: Border.all(
                    color: isSelected ? color : inactiveBorder,
                    width: isSelected ? 2.0 : 1.0,
                  ),
                ),
                child: Text(
                  p.name.toUpperCase(),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: displayColor,
                    fontWeight: isSelected
                        ? FontWeight.w700
                        : FontWeight.normal,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}