import 'package:flutter/material.dart';
import '../../theme/soloforte_theme.dart';
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
        ? SoloForteColors.primary
        : SoloForteColors.surfaceLight; // Disabled

    final Color textColor = isEnabled
        ? Colors
              .white // Contraste no verde
        : SoloForteColors.textTertiary;

    final List<BoxShadow> effectiveShadow = isEnabled
        ? (boxShadow ?? SoloShadows.shadowButton)
        : [];

    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(SoloRadius.md), // 16px
        boxShadow: effectiveShadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isEnabled ? onPressed : null,
          borderRadius: BorderRadius.circular(SoloRadius.md),
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
                      fontSize: SoloFontSizes.base,
                      fontWeight: SoloFontWeights.semibold,
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
