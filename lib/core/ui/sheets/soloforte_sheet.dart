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
  bool useSafeArea = true,
  double? maxHeightFraction,
  Color? backgroundColor,
  Color? barrierColor,
  ShapeBorder? shape,
  BoxConstraints? constraints,
  Clip? clipBehavior,
  bool preserveMaterialDefaults = false,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: isScrollControlled,
    isDismissible: isDismissible,
    enableDrag: enableDrag,
    showDragHandle: showDragHandle,
    useSafeArea: useSafeArea,
    clipBehavior: preserveMaterialDefaults
        ? clipBehavior
        : (clipBehavior ?? Clip.antiAlias),
    backgroundColor: preserveMaterialDefaults
        ? backgroundColor
        : (backgroundColor ?? SoloForteSheetTokens.sheetBackground),
    barrierColor: barrierColor,
    shape: preserveMaterialDefaults
        ? shape
        : (shape ??
              const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(SoloForteSheetTokens.borderRadius),
                ),
              )),
    constraints:
        constraints ??
        (maxHeightFraction != null
            ? BoxConstraints(
                maxHeight:
                    MediaQuery.of(context).size.height * maxHeightFraction,
              )
            : null),
    builder: builder,
  );
}
