import 'package:flutter/material.dart';

/// Encapsula telas da Carteira para dispensar o teclado ao tocar fora de campos.
class CarteiraKeyboardDismiss extends StatelessWidget {
  const CarteiraKeyboardDismiss({super.key, required this.child});

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
