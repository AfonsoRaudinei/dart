/// Folga acima do teclado quando a barra sticky sobe.
const double kSheetKeyboardGap = 12;

/// Extra inferior de sheets compactos (busca / download).
const double kSheetFormBottomExtra = 16;

/// Padding da barra sticky (Cancelar/Salvar) em sheets de formulário longo.
///
/// Quando [liftForKeyboard] é false (host do mapa já encolheu o detent pelo
/// teclado), o inset do teclado é ignorado para não somar duas vezes.
double sheetStickyActionBottomPadding({
  required double safeBottom,
  required double keyboard,
  required bool liftForKeyboard,
  required double closedExtra,
  double keyboardGap = kSheetKeyboardGap,
}) {
  if (liftForKeyboard && keyboard > 0) {
    return keyboard + keyboardGap;
  }
  return safeBottom + closedExtra;
}

/// Padding inferior de sheets compactos com campo de texto + CTA.
double sheetFormKeyboardBottomPadding({
  required double safeBottom,
  required double keyboard,
  double extra = kSheetFormBottomExtra,
}) {
  return extra + safeBottom + keyboard;
}
