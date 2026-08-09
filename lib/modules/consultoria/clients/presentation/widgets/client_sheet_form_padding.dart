import 'package:flutter/material.dart';

/// Padding inferior padrão de sheets de formulário do hub de clientes.
///
/// Soma safe-area + teclado para evitar que campos fiquem cobertos.
EdgeInsets clientSheetFormPadding(BuildContext context) {
  final media = MediaQuery.of(context);
  return EdgeInsets.only(
    left: 24,
    right: 24,
    top: 12,
    bottom: media.padding.bottom + media.viewInsets.bottom + 24,
  );
}

/// Versão testável sem [BuildContext].
EdgeInsets clientSheetFormPaddingFromMedia(MediaQueryData media) {
  return EdgeInsets.only(
    left: 24,
    right: 24,
    top: 12,
    bottom: media.padding.bottom + media.viewInsets.bottom + 24,
  );
}
