// lib/core/ui/sheets/soloforte_sheet.dart

import 'package:flutter/material.dart';
import 'sheet_tokens.dart';

/// Resolve a cor de fundo do modal conforme tema e flags do caller.
///
/// Extraído para teste de contrato (REGRA-SHEET-BLAST-1).
@visibleForTesting
Color? resolveSoloForteSheetBackgroundColor({
  required SoloForteSheetVariant variant,
  required bool preserveMaterialDefaults,
  Color? backgroundColor,
}) {
  if (preserveMaterialDefaults) {
    return backgroundColor;
  }
  final defaultBg = switch (variant) {
    SoloForteSheetVariant.ios => SoloForteSheetSkinIos.background,
    SoloForteSheetVariant.light => SoloForteSheetSkinLight.background,
    SoloForteSheetVariant.dark => SoloForteSheetTokens.sheetBackground,
  };
  if (backgroundColor == null || backgroundColor == Colors.transparent) {
    return defaultBg;
  }
  return backgroundColor;
}

/// Variante ativa do sheet (Verde claro · Azul iOS · Black escuro).
SoloForteSheetVariant soloForteSheetVariant(BuildContext context) {
  final scope = SoloForteSheetSkinScope.of(context);
  if (scope != null) return scope.variant;
  final ext = Theme.of(context).extension<SoloForteThemeExtension>();
  return soloForteSheetVariantFromThemeId(ext?.themeId);
}

/// Propaga a skin ativa do sheet para widgets filhos (headers, inputs, etc.).
class SoloForteSheetSkinScope extends InheritedWidget {
  final SoloForteSheetVariant variant;

  const SoloForteSheetSkinScope({
    required this.variant,
    required super.child,
    super.key,
  });

  bool get isIos => variant == SoloForteSheetVariant.ios;

  static SoloForteSheetSkinScope? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<SoloForteSheetSkinScope>();

  @override
  bool updateShouldNotify(SoloForteSheetSkinScope old) =>
      old.variant != variant;
}

/// Resolve se a skin iOS Azul está ativa.
///
/// Preferência: [SoloForteSheetSkinScope] (dentro de [showSoloForteSheet]).
/// Fallback: [SoloForteThemeExtension.themeId] — para hosts próprios
/// ([MapBottomSheet]) que não passam pelo wrapper modal.
bool soloForteSheetIsIos(BuildContext context) {
  final scope = SoloForteSheetSkinScope.of(context);
  if (scope != null) return scope.isIos;
  final ext = Theme.of(context).extension<SoloForteThemeExtension>();
  return ext?.themeId == 'blue';
}

/// Wrapper padrão para todos os bottom sheets do SoloForte.
///
/// Encapsula parâmetros visuais fixos definidos em [SoloForteSheetTokens].
/// Com tema azul (`SoloForteThemeExtension.themeId == 'blue'`), aplica
/// [SoloForteSheetSkinIos] automaticamente — zero mudança nos chamadores.
///
/// **Chrome iOS (Ago/2026):** fundo/borda/radius no [ModalBottomSheet] apenas.
/// Não envolve o conteúdo em `Column`+handle — isso duplicava o painel
/// (“dois sheets”) e quebrava drag/scroll (`mainAxisSize: min`).
/// Handle: `showDragHandle` do Material (respeita o caller) ou handle
/// desenhado pelo conteúdo.
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
  bool useRootNavigator = false,
}) {
  final ext = Theme.of(context).extension<SoloForteThemeExtension>();
  final variant = preserveMaterialDefaults
      ? SoloForteSheetVariant.light
      : soloForteSheetVariantFromThemeId(ext?.themeId);
  final bool isIos = variant == SoloForteSheetVariant.ios;

  final resolvedBackground = resolveSoloForteSheetBackgroundColor(
    variant: variant,
    preserveMaterialDefaults: preserveMaterialDefaults,
    backgroundColor: backgroundColor,
  );

  final resolvedRadius = switch (variant) {
    SoloForteSheetVariant.ios => SoloForteSheetSkinIos.sheetRadius,
    SoloForteSheetVariant.light => SoloForteSheetSkinLight.sheetRadius,
    SoloForteSheetVariant.dark => SoloForteSheetTokens.borderRadius,
  };

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

  // Respeita o caller em todos os temas. Antes o Azul forçava `false` e
  // desenhava handle no Column-chrome — causa de drag quebrado + sheet duplo.
  final resolvedShowDragHandle = showDragHandle;

  final baseTheme = Theme.of(context);
  final handleColor = switch (variant) {
    SoloForteSheetVariant.ios => SoloForteSheetSkinIos.handleColor,
    SoloForteSheetVariant.light => SoloForteSheetSkinLight.handleColor,
    SoloForteSheetVariant.dark => const Color(0xFF5C5C5E),
  };
  final handleSize = switch (variant) {
    SoloForteSheetVariant.ios => SoloForteSheetSkinIos.handleSize,
    SoloForteSheetVariant.light => SoloForteSheetSkinLight.handleSize,
    SoloForteSheetVariant.dark => const Size(36, 4),
  };
  final sheetTheme = preserveMaterialDefaults
      ? baseTheme
      : baseTheme.copyWith(
          bottomSheetTheme: baseTheme.bottomSheetTheme.copyWith(
            dragHandleColor: handleColor,
            dragHandleSize: handleSize,
          ),
        );

  return showModalBottomSheet<T>(
    context: context,
    useRootNavigator: useRootNavigator,
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
      // Opt-out explícito: scope isIos=false evita fallback themeId nos widgets
      // internos quando preserveMaterialDefaults=true.
      if (preserveMaterialDefaults) {
        return SoloForteSheetSkinScope(
          variant: SoloForteSheetVariant.light,
          child: sheet,
        );
      }
      return Theme(
        data: sheetTheme,
        child: SoloForteSheetSkinScope(
          variant: variant,
          child: Material(
            color: Colors.transparent,
            child: sheet,
          ),
        ),
      );
    },
  );
}
