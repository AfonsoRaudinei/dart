import 'package:flutter/material.dart';
import 'package:soloforte_app/ui/theme/premium/design_tokens.dart';

import 'package:google_fonts/google_fonts.dart';

class GradientButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final Gradient?
  gradient; // Mantido para compatibilidade, mas ignorado visualmente pelo tema se null
  final double height;
  final double? width;
  final List<BoxShadow>? boxShadow;

  const GradientButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.gradient,
    this.height = 48.0, // Altura padrão do Design System
    this.width,
    this.boxShadow,
  });

  @override
  Widget build(BuildContext context) {
    // Definir estado
    final bool isEnabled = onPressed != null && !isLoading;

    // Cores baseadas no estado
    final Color backgroundColor = isEnabled
        ? PremiumTokens.brandGreen
        : PremiumTokens.backgroundLight; // Disabled

    final Color textColor = isEnabled
        ? Colors
              .white // Contraste no verde
        : PremiumTokens.textTertiaryLight;

    final List<BoxShadow> effectiveShadow = isEnabled
        ? (boxShadow ?? [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))])
        : [];

    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        gradient: isEnabled ? PremiumTokens.brandGradient : null,
        color: isEnabled ? null : backgroundColor,
        borderRadius: BorderRadius.circular(10.0), // 16px
        boxShadow: effectiveShadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isEnabled ? onPressed : null,
          borderRadius: BorderRadius.circular(10.0),
          splashColor: Colors.white.withOpacity(0.2),
          highlightColor: Colors.white.withOpacity(0.1),
          child: Center(
            child: isLoading
                ? SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: textColor,
                      strokeWidth: 2.5,
                    ),
                  )
                : Text(
                    text,
                    style: GoogleFonts.inter(
                      fontSize: 14.0,
                      fontWeight: FontWeight.w500,
                      color: textColor,
                      letterSpacing: 0.3,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
