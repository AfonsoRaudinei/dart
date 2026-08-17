// lib/core/ui/sheets/soloforte_sheet.dart

import 'package:flutter/material.dart';
import 'sheet_tokens.dart';

/// Resolve a cor de fundo do modal conforme tema e flags do caller.
///
/// Extraído para teste de contrato (REGRA-SHEET-BLAST-1).
@visibleForTesting
Color? resolveSoloForteSheetBackgroundColor({
  required bool isIos,
  required bool preserveMaterialDefaults,
  Color? backgroundColor,
}) {
  if (preserveMaterialDefaults) {
    return backgroundColor;
  }
  if (isIos) {
    final transparentOverride =
        backgroundColor == null || backgroundColor == Colors.transparent;
    return transparentOverride
        ? SoloForteSheetSkinIos.background
        : backgroundColor;
  }
  return backgroundColor ?? SoloForteSheetTokens.sheetBackground;
}

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
}) {
  final ext = Theme.of(context).extension<SoloForteThemeExtension>();
  final bool isIos = !preserveMaterialDefaults && ext?.themeId == 'blue';

  // Fase 2: `Colors.transparent` não anula o fundo prata iOS — callers que
  // pintavam glass escuro por cima passam a herdar o chrome correto.
  final resolvedBackground = resolveSoloForteSheetBackgroundColor(
    isIos: isIos,
    preserveMaterialDefaults: preserveMaterialDefaults,
    backgroundColor: backgroundColor,
  );

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

  // Respeita o caller em todos os temas. Antes o Azul forçava `false` e
  // desenhava handle no Column-chrome — causa de drag quebrado + sheet duplo.
  final resolvedShowDragHandle = showDragHandle;

  final baseTheme = Theme.of(context);
  final sheetTheme = isIos
      ? baseTheme.copyWith(
          bottomSheetTheme: baseTheme.bottomSheetTheme.copyWith(
            dragHandleColor: SoloForteSheetSkinIos.handleColor,
            dragHandleSize: SoloForteSheetSkinIos.handleSize,
          ),
        )
      : baseTheme;

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
      // Opt-out explícito: scope isIos=false evita fallback themeId nos widgets
      // internos quando preserveMaterialDefaults=true.
      if (preserveMaterialDefaults) {
        return SoloForteSheetSkinScope(isIos: false, child: sheet);
      }
      // Flutter 3.44+ exige ancestral Material para ListTile dentro de sheet
      // com backgroundColor (DecoratedBox). Material transparente satisfaz o
      // contrato sem alterar a aparência do token visual.
      return Theme(
        data: sheetTheme,
        child: SoloForteSheetSkinScope(
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
