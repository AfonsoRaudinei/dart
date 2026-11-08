import 'package:flutter/material.dart';

/// Dispensa o teclado ao tocar fora de campos ou em transições de navegação.
///
/// Usado nos shells de módulos com abas/segmentos e em fechamento de modais.
class SoloforteKeyboardDismiss extends StatelessWidget {
  const SoloforteKeyboardDismiss({super.key, required this.child});

  final Widget child;

  static void dismiss() {
    FocusManager.instance.primaryFocus?.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: dismiss,
      child: child,
    );
  }
}
