/// Layout math for the login glass sheet when the software keyboard is visible.
class LoginSheetKeyboardLayout {
  const LoginSheetKeyboardLayout._();

  static double sheetBottomOffset(double keyboardInset) => keyboardInset;

  /// Max height of the bottom sheet; shrinks when [keyboardInset] > 0 so fields stay above the keyboard.
  static double sheetMaxHeight({
    required double viewportHeight,
    required double keyboardInset,
    required double topSafePadding,
    double fractionWithoutKeyboard = 0.80,
    double minHeight = 220,
  }) {
    if (keyboardInset <= 0) {
      return viewportHeight * fractionWithoutKeyboard;
    }
    final available =
        viewportHeight - keyboardInset - topSafePadding;
    return available.clamp(minHeight, viewportHeight * 0.95);
  }
}
