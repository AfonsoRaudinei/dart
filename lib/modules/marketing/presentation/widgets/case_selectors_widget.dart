import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/ui/sheets/sheet_tokens.dart';
import '../../../../core/ui/sheets/soloforte_sheet.dart';
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
    final isIos = soloForteSheetIsIos(context);
    final selectedBg =
        isIos ? SoloForteSheetSkinIos.ctaBackground : PremiumTokens.brandGreen;
    final selectedBorder =
        isIos ? SoloForteSheetSkinIos.ctaBackground : PremiumTokens.brandGreen;
    final inactiveBorder =
        isIos ? SoloForteSheetSkinIos.cardBorder : PremiumTokens.hairlineLight;
    final selectedFg =
        isIos ? SoloForteSheetSkinIos.ctaText : Colors.white;
    final inactiveFg =
        isIos ? SoloForteSheetSkinIos.subtitleColor : const Color(0xFF8E8E93);

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
                  isIos ? SoloForteSheetSkinIos.ctaRadius : 12,
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
  final PlanoMarketing selectedPlano;
  final ValueChanged<PlanoMarketing> onChanged;

  const PlanoMarketingSelector({
    super.key,
    required this.selectedPlano,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isIos = soloForteSheetIsIos(context);
    final inactiveBorder =
        isIos ? SoloForteSheetSkinIos.cardBorder : PremiumTokens.hairlineLight;

    final colors = {
      PlanoMarketing.ouro: const Color(0xFFFFB800),
      PlanoMarketing.prata: const Color(0xFF9EA9B2),
      PlanoMarketing.bronze: const Color(0xFFA0522D),
    };
    return Row(
      children: PlanoMarketing.values.map((p) {
        final isSelected = selectedPlano == p;
        final color = colors[p]!;
        return Expanded(
          child: GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              onChanged(p);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: isSelected
                    ? color.withValues(alpha: 0.15)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(
                  isIos ? SoloForteSheetSkinIos.ctaRadius : 12,
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
                  color: color,
                  fontWeight: isSelected
                      ? FontWeight.w700
                      : FontWeight.normal,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
