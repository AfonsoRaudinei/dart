import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../../core/ui/sheets/sheet_tokens.dart';
import '../../../../../../ui/theme/premium/design_tokens.dart';

class OccurrenceDetailCloseButton extends StatefulWidget {
  final bool isDark;
  final bool isIos;
  final VoidCallback onTap;

  const OccurrenceDetailCloseButton({
    super.key,
    required this.isDark,
    this.isIos = false,
    required this.onTap,
  });

  @override
  State<OccurrenceDetailCloseButton> createState() =>
      _OccurrenceDetailCloseButtonState();
}

class _OccurrenceDetailCloseButtonState
    extends State<OccurrenceDetailCloseButton> {
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
