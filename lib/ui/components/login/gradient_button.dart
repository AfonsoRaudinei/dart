import 'package:flutter/material.dart';
import '../../theme/soloforte_theme.dart';

class GradientButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final Gradient? gradient;
  final double height;
  final double? width;
  final List<BoxShadow>? boxShadow;

  const GradientButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.gradient,
    this.height = 50.0,
    this.width,
    this.boxShadow,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveGradient = gradient ?? SoloForteGradients.primary;
    final effectiveShadow = boxShadow ?? SoloShadows.shadowButton;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: height,
      width: width,
      decoration: BoxDecoration(
        gradient: onPressed == null && !isLoading ? null : effectiveGradient,
        borderRadius: SoloRadius.radiusLg,
        boxShadow: onPressed == null && !isLoading ? null : effectiveShadow,
        color: onPressed == null && !isLoading ? SoloForteColors.border : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLoading ? null : onPressed,
          borderRadius: SoloRadius.radiusLg,
          child: Container(
            alignment: Alignment.center,
            padding: SoloSpacing.paddingButton,
            child: isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  )
                : Text(
                    text,
                    style: const TextStyle(
                      fontSize: 15.2,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      letterSpacing: 0.3,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
