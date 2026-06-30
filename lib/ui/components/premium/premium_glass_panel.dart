import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../../theme/premium/design_tokens.dart';

/// Um painel premium de vidro fosco (Glassmorphism) com iOS blur extremo.
/// Usado para Docks suspensos no mapa, bottom sheets deslizantes e FABs complexos.
class PremiumGlassPanel extends StatelessWidget {
  final Widget child;
  final BorderRadiusGeometry? borderRadius;
  final EdgeInsetsGeometry padding;
  final bool
  isDark; // Se forçar estilo Dark no glass. Se nulo, pega do contexto mas pode ser ignorado

  const PremiumGlassPanel({
    super.key,
    required this.child,
    this.borderRadius,
    this.padding = EdgeInsets.zero,
    this.isDark = false,
  });

  @override
  Widget build(BuildContext context) {
    final brighten = Theme.of(context).brightness == Brightness.light;
    final glassColor = isDark || !brighten
        ? PremiumTokens.glassBlack
        : PremiumTokens.glassWhite;

    final borderColor = isDark || !brighten
        ? Colors.white.withValues(alpha: 0.1)
        : Colors.white.withValues(alpha: 0.5);

    return ClipRRect(
      borderRadius:
          borderRadius ?? BorderRadius.circular(PremiumTokens.borderRadiusLg),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: glassColor,
            borderRadius:
                borderRadius ??
                BorderRadius.circular(PremiumTokens.borderRadiusLg),
            border: Border.all(
              color: borderColor,
              width: PremiumTokens.hairlineThickness,
            ),
            boxShadow: PremiumTokens.premiumShadow,
          ),
          child: child,
        ),
      ),
    );
  }
}
