// lib/core/ui/sheets/soloforte_sheet.dart

import 'package:flutter/material.dart';
import 'sheet_tokens.dart';

/// Wrapper padrão para todos os bottom sheets do SoloForte.
///
/// Encapsula parâmetros visuais fixos definidos em [SoloForteSheetTokens].
/// O [builder] é delegado integralmente ao chamador — zero mudança de lógica.
///
/// Uso:
/// ```dart
/// await showSoloForteSheet(
///   context: context,
///   builder: (ctx) => MeuSheetWidget(),
/// );
/// ```
Future<T?> showSoloForteSheet<T>({
  required BuildContext context,
  required Widget Function(BuildContext) builder,
  bool isScrollControlled = true,
  bool isDismissible = true,
  bool enableDrag = true,
  bool showDragHandle = true,
  double? maxHeightFraction,
  Color? barrierColor,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: isScrollControlled,
    isDismissible: isDismissible,
    enableDrag: enableDrag,
    showDragHandle: showDragHandle,
    useSafeArea: true,
    clipBehavior: Clip.antiAliasWithSaveLayer,
    backgroundColor: SoloForteSheetTokens.sheetBackground,
    barrierColor: barrierColor,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(SoloForteSheetTokens.borderRadius),
      ),
    ),
    constraints: maxHeightFraction != null
        ? BoxConstraints(
            maxHeight:
                MediaQuery.of(context).size.height * maxHeightFraction,
          )
        : null,
    builder: builder,
  );
}
