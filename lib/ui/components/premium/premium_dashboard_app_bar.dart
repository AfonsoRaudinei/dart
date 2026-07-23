import 'dart:ui';
import 'package:flutter/material.dart';
import '../../theme/premium/design_tokens.dart';

class PremiumDashboardAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  final String title;
  final Widget? trailing;
  final PreferredSizeWidget? bottom;
  final ScrollController?
  scrollController; // Para ouvir quando tem scroll e borrar

  const PremiumDashboardAppBar({
    super.key,
    required this.title,
    this.trailing,
    this.bottom,
    this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    // Nós podemos usar um ValueListenableBuilder se usarmos um ScrollController
    // mas a forma mais simples (se não houver controller passado) é ter blur permanente
    // com cor ligeiramente translúcida.
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            color:
                (isDark
                        ? PremiumTokens.backgroundDark
                        : context.premiumBackground)
                    .withValues(alpha: 0.8),
            border: Border(
              bottom: BorderSide(
                color: isDark
                    ? PremiumTokens.hairlineDark
                    : context.premiumHairline,
                width: PremiumTokens.hairlineThickness,
              ),
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 12.0,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                letterSpacing: -0.5,
                              ),
                        ),
                      ),
                      if (trailing != null) trailing!,
                    ],
                  ),
                ),
                if (bottom != null) bottom!,
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Size get preferredSize {
    double height = 70.0; // aprox for large title
    if (bottom != null) {
      height += bottom!.preferredSize.height;
    }
    return Size.fromHeight(height);
  }
}
