import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:soloforte_app/ui/theme/premium/design_tokens.dart';

enum OportunidadesChartMode { categoria, produtor }

/// Toggle Produtor | Categoria — controla apenas o agrupamento do gráfico.
class OportunidadesChartModeToggle extends StatelessWidget {
  const OportunidadesChartModeToggle({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final OportunidadesChartMode value;
  final ValueChanged<OportunidadesChartMode> onChanged;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final trackColor = isDark
        ? const Color(0xFF242426)
        : const Color(0xFFE5E5EA);
    final selectedFill = isDark ? context.premiumSurface : Colors.white;

    return Container(
      height: 34,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: trackColor,
        borderRadius: BorderRadius.circular(9),
      ),
      child: Row(
        children: [
          _Side(
            label: 'Categoria',
            isSelected: value == OportunidadesChartMode.categoria,
            selectedFill: selectedFill,
            onTap: () {
              if (value == OportunidadesChartMode.categoria) return;
              HapticFeedback.selectionClick();
              onChanged(OportunidadesChartMode.categoria);
            },
          ),
          _Side(
            label: 'Produtor',
            isSelected: value == OportunidadesChartMode.produtor,
            selectedFill: selectedFill,
            onTap: () {
              if (value == OportunidadesChartMode.produtor) return;
              HapticFeedback.selectionClick();
              onChanged(OportunidadesChartMode.produtor);
            },
          ),
        ],
      ),
    );
  }
}

class _Side extends StatelessWidget {
  const _Side({
    required this.label,
    required this.isSelected,
    required this.selectedFill,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final Color selectedFill;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOut,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? selectedFill : Colors.transparent,
            borderRadius: BorderRadius.circular(7),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 3,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              color: isSelected
                  ? context.premiumTextPrimary
                  : context.premiumTextSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
