import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'solo_forte_sheet_visuals.dart';

/// Botão de fechar/remover discreto, no estilo iOS: círculo translúcido com
/// "x" fino. Substitui o `Icons.close` solto, que ficava grande e pesado.
class SheetCloseButton extends StatelessWidget {
  const SheetCloseButton({
    super.key,
    required this.onPressed,
    this.tooltip,
    this.size = 28,
    this.color,
    this.hitSize = 44,
  });

  final VoidCallback? onPressed;
  final String? tooltip;
  final double size;

  /// Cor de destaque (ex.: vermelho para fechar o sheet). Padrão: neutra.
  final Color? color;

  /// Lado da área de toque (o desenho continua em [size]).
  final double hitSize;

  @override
  Widget build(BuildContext context) {
    final v = SoloForteSheetVisuals.of(context);
    final tint = color ?? (v.isDark ? Colors.white : v.titleColor);
    final strong = color != null;
    final button = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onPressed,
      // Área de toque de 44 pt sem aumentar o desenho.
      child: SizedBox(
        width: hitSize,
        height: hitSize,
        child: Center(
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: tint.withValues(alpha: strong ? 0.14 : 0.08),
            ),
            child: Icon(
              CupertinoIcons.xmark,
              size: size * 0.46,
              color: tint.withValues(alpha: strong ? 0.95 : 0.55),
            ),
          ),
        ),
      ),
    );
    return tooltip == null ? button : Tooltip(message: tooltip!, child: button);
  }
}
