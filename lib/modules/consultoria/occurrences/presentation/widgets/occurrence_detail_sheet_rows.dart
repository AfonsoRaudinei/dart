part of 'occurrence_detail_sheet.dart';

class _DetailRowData {
  final IconData icon;
  final String label;
  final String? value;
  final WidgetBuilder? valueBuilder;
  final bool selectable;

  const _DetailRowData({
    required this.icon,
    required this.label,
    this.value,
    this.valueBuilder,
    this.selectable = false,
  });
}

class _HeaderChip extends StatelessWidget {
  final String label;
  final Color color;

  const _HeaderChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final bool isDark;
  final bool isIos;
  final IconData icon;
  final String label;
  final String? value;
  final WidgetBuilder? valueBuilder;
  final bool showDivider;
  final bool selectable;

  const _DetailRow({
    required this.isDark,
    this.isIos = false,
    required this.icon,
    required this.label,
    this.value,
    this.valueBuilder,
    required this.showDivider,
    this.selectable = false,
  });

  static TextStyle valueStyle(bool isDark, {bool isIos = false}) {
    return TextStyle(
      fontSize: 15,
      fontWeight: FontWeight.w400,
      letterSpacing: -0.4,
      color: isIos
          ? SoloForteSheetSkinIos.titleColor
          : (isDark
              ? PremiumTokens.textPrimaryDark
              : PremiumTokens.textPrimaryLight),
    );
  }

  @override
  Widget build(BuildContext context) {
    final iconColor = isIos
        ? SoloForteSheetSkinIos.iconStroke
        : (isDark ? const Color(0xFF8E8E93) : const Color(0xFF6C6C70));
    final labelColor = isIos
        ? SoloForteSheetSkinIos.subtitleColor
        : (isDark ? const Color(0xFF8E8E93) : const Color(0xFF6C6C70));
    final dividerColor = isIos
        ? SoloForteSheetSkinIos.rowDivider
        : (isDark ? PremiumTokens.hairlineDark : context.premiumHairline);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 18, color: iconColor),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.07,
                        color: labelColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    if (valueBuilder != null)
                      valueBuilder!(context)
                    else if (selectable)
                      SelectableText(
                        value ?? '—',
                        style: valueStyle(isDark, isIos: isIos),
                      )
                    else
                      Text(value ?? '—', style: valueStyle(isDark, isIos: isIos)),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (showDivider)
          Padding(
            padding: const EdgeInsets.only(left: 46),
            child: Divider(
              thickness: PremiumTokens.hairlineThickness,
              color: dividerColor,
              height: 1,
            ),
          ),
      ],
    );
  }
}

class CupertinoCloseButton extends StatefulWidget {
  final bool isDark;
  final bool isIos;
  final VoidCallback onTap;

  const CupertinoCloseButton({
    super.key,
    required this.isDark,
    this.isIos = false,
    required this.onTap,
  });

  @override
  State<CupertinoCloseButton> createState() => _CupertinoCloseButtonState();
}

class _CupertinoCloseButtonState extends State<CupertinoCloseButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final bg = widget.isIos
        ? SoloForteSheetSkinIos.cardBackground
        : (widget.isDark
            ? const Color(0xFF2C2C2E)
            : context.premiumBackground);
    final textColor = widget.isIos
        ? SoloForteSheetSkinIos.titleColor
        : (widget.isDark
            ? PremiumTokens.textPrimaryDark
            : context.premiumTextPrimary);

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        HapticFeedback.lightImpact();
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedOpacity(
        opacity: _pressed ? 0.6 : 1.0,
        duration: const Duration(milliseconds: 80),
        child: AnimatedScale(
          scale: _pressed ? 0.97 : 1.0,
          duration: const Duration(milliseconds: 80),
          child: Container(
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(
                widget.isIos
                    ? SoloForteSheetSkinIos.ctaRadius
                    : PremiumTokens.borderRadiusMd,
              ),
              border: widget.isIos
                  ? Border.all(color: SoloForteSheetSkinIos.cardBorder)
                  : null,
            ),
            alignment: Alignment.center,
            child: Text(
              'Fechar',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.4,
                color: textColor,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
