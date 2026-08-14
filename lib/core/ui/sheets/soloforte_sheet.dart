// lib/core/ui/sheets/soloforte_sheet.dart

import 'package:flutter/material.dart';
import 'sheet_tokens.dart';

/// Propaga a skin ativa do sheet para widgets filhos (headers, inputs, etc.).
class SoloForteSheetSkinScope extends InheritedWidget {
  final bool isIos;

  const SoloForteSheetSkinScope({
    required this.isIos,
    required super.child,
    super.key,
  });

  static SoloForteSheetSkinScope? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<SoloForteSheetSkinScope>();

  @override
  bool updateShouldNotify(SoloForteSheetSkinScope old) => old.isIos != isIos;
}

/// Chrome privado: handle + borda iOS quando [isIos]; senão passa o child.
class _SoloForteSheetChrome extends StatelessWidget {
  final bool isIos;
  final Widget child;

  const _SoloForteSheetChrome({
    required this.isIos,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    if (!isIos) return child;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 10, bottom: 8),
          child: Center(
            child: Container(
              width: SoloForteSheetSkinIos.handleSize.width,
              height: SoloForteSheetSkinIos.handleSize.height,
              decoration: BoxDecoration(
                color: SoloForteSheetSkinIos.handleColor,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
        ),
        child,
      ],
    );
  }
}

/// Wrapper padrão para todos os bottom sheets do SoloForte.
///
/// Encapsula parâmetros visuais fixos definidos em [SoloForteSheetTokens].
/// Com tema azul (`SoloForteThemeExtension.themeId == 'blue'`), aplica
/// [SoloForteSheetSkinIos] automaticamente — zero mudança nos chamadores.
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
  final ext = Theme.of(context).extension<SoloForteThemeExtension>();
  final bool isIos = !preserveMaterialDefaults && ext?.themeId == 'blue';

  final resolvedBackground = preserveMaterialDefaults
      ? backgroundColor
      : (backgroundColor ??
          (isIos
              ? SoloForteSheetSkinIos.background
              : SoloForteSheetTokens.sheetBackground));

  final resolvedRadius =
      isIos ? SoloForteSheetSkinIos.sheetRadius : SoloForteSheetTokens.borderRadius;

  final resolvedShape = preserveMaterialDefaults
      ? shape
      : (shape ??
          RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(resolvedRadius),
            ),
            side: isIos
                ? const BorderSide(color: SoloForteSheetSkinIos.sheetBorder)
                : BorderSide.none,
          ));

  // Handle nativo do Material só no skin escuro; iOS usa handle do chrome.
  final resolvedShowDragHandle = preserveMaterialDefaults
      ? showDragHandle
      : (isIos ? false : showDragHandle);

  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: isScrollControlled,
    isDismissible: isDismissible,
    enableDrag: enableDrag,
    showDragHandle: resolvedShowDragHandle,
    useSafeArea: useSafeArea,
    clipBehavior: preserveMaterialDefaults
        ? clipBehavior
        : (clipBehavior ?? Clip.antiAlias),
    backgroundColor: resolvedBackground,
    barrierColor: barrierColor,
    shape: resolvedShape,
    constraints:
        constraints ??
        (maxHeightFraction != null
            ? BoxConstraints(
                maxHeight:
                    MediaQuery.of(context).size.height * maxHeightFraction,
              )
            : null),
    builder: (ctx) {
      final sheet = builder(ctx);
      if (preserveMaterialDefaults) return sheet;
      // Flutter 3.44+ exige ancestral Material para ListTile dentro de sheet
      // com backgroundColor (DecoratedBox). Material transparente satisfaz o
      // contrato sem alterar a aparência do token visual.
      return SoloForteSheetSkinScope(
        isIos: isIos,
        child: _SoloForteSheetChrome(
          isIos: isIos,
          child: Material(
            color: Colors.transparent,
            child: sheet,
          ),
        ),
      );
    },
  );
}
