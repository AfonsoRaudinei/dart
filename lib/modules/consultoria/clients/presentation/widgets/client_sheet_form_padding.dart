import 'package:flutter/material.dart';
import 'package:soloforte_app/core/ui/sheets/soloforte_sheet.dart';

/// Padding inferior padrão de sheets de formulário do hub de clientes.
///
/// Soma safe-area + teclado para evitar que campos fiquem cobertos.
/// Quando o sheet foi aberto via [showSoloForteSheet], o teclado já é
/// compensado no modal — neste caso só aplica safe-area + folga fixa.
EdgeInsets clientSheetFormPadding(BuildContext context) {
  return clientSheetFormPaddingFromMedia(
    MediaQuery.of(context),
    keyboardHandledByModal: soloForteSheetKeyboardHandled(context),
  );
}

/// Versão testável sem [BuildContext].
EdgeInsets clientSheetFormPaddingFromMedia(
  MediaQueryData media, {
  bool keyboardHandledByModal = false,
}) {
  final keyboardInset =
      keyboardHandledByModal ? 0.0 : media.viewInsets.bottom;
  return EdgeInsets.only(
    left: 24,
    right: 24,
    top: 12,
    bottom: media.padding.bottom + keyboardInset + 24,
  );
}
