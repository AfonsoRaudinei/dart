import 'package:flutter/material.dart';
import 'package:soloforte_app/ui/theme/premium/design_tokens.dart';

enum CarteiraSegment { clientes, categorias, metas, oportunidades }

extension CarteiraSegmentLabel on CarteiraSegment {
  String get label => switch (this) {
    CarteiraSegment.clientes => 'Clientes',
    CarteiraSegment.categorias => 'Categorias',
    CarteiraSegment.metas => 'Metas',
    CarteiraSegment.oportunidades => 'Oportunidades',
  };
}

class CarteiraSegmentBar extends StatelessWidget {
  const CarteiraSegmentBar({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final CarteiraSegment selected;
  final ValueChanged<CarteiraSegment> onSelected;

  static const _segments = CarteiraSegment.values;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final trackColor = isDark
        ? const Color(0xFF242426)
        : const Color(0xFFE5E5EA);
    final selectedFill = isDark ? context.premiumSurface : Colors.white;

    return Container(
      height: 40,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: trackColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          for (final segment in _segments)
            _SegmentItem(
              label: segment.label,
              isSelected: selected == segment,
              selectedFill: selectedFill,
              onTap: () => onSelected(segment),
            ),
        ],
      ),
    );
  }
}

class _SegmentItem extends StatelessWidget {
  const _SegmentItem({
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
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? selectedFill : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 6,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              letterSpacing: -0.2,
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
