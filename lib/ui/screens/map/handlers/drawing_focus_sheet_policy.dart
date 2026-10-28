/// Compact deep-link (cliente "Abrir no mapa") seleciona a feature
/// mas não abre Ferramentas de Desenho — o card MapTalhaoSelectionToolbar
/// é a entrada compacta (PR #317).
bool shouldOpenDrawSheetOnDrawingFocus({
  required bool edit,
  required bool union,
  required bool ferramentasCompleto,
}) {
  if (edit) return false;
  return union || ferramentasCompleto;
}
