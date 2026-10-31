import 'package:flutter/material.dart';

import 'sheet_tokens.dart';
import 'soloforte_sheet.dart';

/// Cores e raios de sheet resolvidos por tema (Verde claro · Azul iOS · Black escuro).
class SoloForteSheetVisuals {
  SoloForteSheetVisuals._(this.variant, this.accent);

  final SoloForteSheetVariant variant;
  final Color accent;

  factory SoloForteSheetVisuals.of(BuildContext context) {
    final variant = soloForteSheetVariant(context);
    return SoloForteSheetVisuals._(
      variant,
      Theme.of(context).colorScheme.primary,
    );
  }

  bool get isIos => variant == SoloForteSheetVariant.ios;
  bool get isDark => variant == SoloForteSheetVariant.dark;
  bool get isLight => variant == SoloForteSheetVariant.light;

  Color get sheetBackground => switch (variant) {
        SoloForteSheetVariant.ios => SoloForteSheetSkinIos.background,
        SoloForteSheetVariant.light => SoloForteSheetSkinLight.background,
        SoloForteSheetVariant.dark => SoloForteSheetTokens.sheetBackground,
      };

  double get sheetRadius => switch (variant) {
        SoloForteSheetVariant.ios => SoloForteSheetSkinIos.sheetRadius,
        SoloForteSheetVariant.light => SoloForteSheetSkinLight.sheetRadius,
        SoloForteSheetVariant.dark => SoloForteSheetTokens.borderRadius,
      };

  Color get titleColor => switch (variant) {
        SoloForteSheetVariant.ios => SoloForteSheetSkinIos.titleColor,
        SoloForteSheetVariant.light => SoloForteSheetSkinLight.titleColor,
        SoloForteSheetVariant.dark => SoloForteSheetTokens.titleColor,
      };

  Color get subtitleColor => switch (variant) {
        SoloForteSheetVariant.ios => SoloForteSheetSkinIos.subtitleColor,
        SoloForteSheetVariant.light => SoloForteSheetSkinLight.subtitleColor,
        SoloForteSheetVariant.dark => SoloForteSheetTokens.inputHint,
      };

  Color get inputFill => switch (variant) {
        SoloForteSheetVariant.ios => SoloForteSheetSkinIos.cardBackground,
        SoloForteSheetVariant.light => SoloForteSheetSkinLight.inputBackground,
        SoloForteSheetVariant.dark => SoloForteSheetTokens.inputBackground,
      };

  Color get inputText => switch (variant) {
        SoloForteSheetVariant.ios => SoloForteSheetSkinIos.titleColor,
        SoloForteSheetVariant.light => SoloForteSheetSkinLight.inputText,
        SoloForteSheetVariant.dark => SoloForteSheetTokens.inputText,
      };

  Color get inputHint => subtitleColor;

  Color get focusBorder => switch (variant) {
        SoloForteSheetVariant.ios => SoloForteSheetSkinIos.iconStroke,
        SoloForteSheetVariant.light => accent,
        SoloForteSheetVariant.dark => SoloForteSheetTokens.chipBorderActive,
      };

  Color get inputBorder => switch (variant) {
        SoloForteSheetVariant.ios => SoloForteSheetSkinIos.cardBorder,
        SoloForteSheetVariant.light => SoloForteSheetSkinLight.cardBorder,
        SoloForteSheetVariant.dark => Colors.transparent,
      };

  double get inputRadius => switch (variant) {
        SoloForteSheetVariant.ios => SoloForteSheetSkinIos.cardRadius,
        SoloForteSheetVariant.light => SoloForteSheetSkinLight.inputRadius,
        SoloForteSheetVariant.dark => SoloForteSheetTokens.inputRadius,
      };

  Color get sectionLabelColor => titleColor;

  Color get dividerColor => switch (variant) {
        SoloForteSheetVariant.ios => SoloForteSheetSkinIos.rowDivider,
        SoloForteSheetVariant.light => SoloForteSheetSkinLight.rowDivider,
        SoloForteSheetVariant.dark => SoloForteSheetTokens.divider,
      };

  Color get chipBorderActive => switch (variant) {
        SoloForteSheetVariant.ios => SoloForteSheetSkinIos.iconStroke,
        SoloForteSheetVariant.light => accent,
        SoloForteSheetVariant.dark => SoloForteSheetTokens.chipBorderActive,
      };

  Color get chipBorderInactive => switch (variant) {
        SoloForteSheetVariant.ios => SoloForteSheetSkinIos.cardBorder,
        SoloForteSheetVariant.light => SoloForteSheetSkinLight.chipBorderInactive,
        SoloForteSheetVariant.dark => SoloForteSheetTokens.chipBorderInactive,
      };

  Color get chipTextActive => chipBorderActive;

  Color get chipTextInactive => switch (variant) {
        SoloForteSheetVariant.ios => SoloForteSheetSkinIos.subtitleColor,
        SoloForteSheetVariant.light => SoloForteSheetSkinLight.chipTextInactive,
        SoloForteSheetVariant.dark => SoloForteSheetTokens.chipTextInactive,
      };

  double get chipRadius => switch (variant) {
        SoloForteSheetVariant.ios => SoloForteSheetSkinIos.ctaRadius,
        SoloForteSheetVariant.light => SoloForteSheetSkinLight.chipRadius,
        SoloForteSheetVariant.dark => SoloForteSheetTokens.chipRadius,
      };

  Color? get chipActiveFill => isIos
      ? SoloForteSheetSkinIos.badgeBackground
      : (isLight ? accent.withValues(alpha: 0.12) : null);

  Color get handleColor => switch (variant) {
        SoloForteSheetVariant.ios => SoloForteSheetSkinIos.handleColor,
        SoloForteSheetVariant.light => SoloForteSheetSkinLight.handleColor,
        SoloForteSheetVariant.dark => const Color(0xFF5C5C5E),
      };

  Size get handleSize => switch (variant) {
        SoloForteSheetVariant.ios => SoloForteSheetSkinIos.handleSize,
        SoloForteSheetVariant.light => SoloForteSheetSkinLight.handleSize,
        SoloForteSheetVariant.dark => const Size(36, 4),
      };

  Color get cardBackground => switch (variant) {
        SoloForteSheetVariant.ios => SoloForteSheetSkinIos.cardBackground,
        SoloForteSheetVariant.light => SoloForteSheetSkinLight.cardBackground,
        SoloForteSheetVariant.dark => SoloForteSheetTokens.inputBackground,
      };

  Color get cardBorder => switch (variant) {
        SoloForteSheetVariant.ios => SoloForteSheetSkinIos.cardBorder,
        SoloForteSheetVariant.light => SoloForteSheetSkinLight.cardBorder,
        SoloForteSheetVariant.dark => SoloForteSheetTokens.divider,
      };

  double get cardRadius => switch (variant) {
        SoloForteSheetVariant.ios => SoloForteSheetSkinIos.cardRadius,
        SoloForteSheetVariant.light => SoloForteSheetSkinLight.cardRadius,
        SoloForteSheetVariant.dark => SoloForteSheetTokens.inputRadius,
      };

  Color get iconStroke => chipBorderActive;

  Color get iconBackground => switch (variant) {
        SoloForteSheetVariant.ios => SoloForteSheetSkinIos.iconBackground,
        SoloForteSheetVariant.light => accent.withValues(alpha: 0.12),
        SoloForteSheetVariant.dark => SoloForteSheetTokens.categoryBackground,
      };

  Color get arrowColor => switch (variant) {
        SoloForteSheetVariant.ios => SoloForteSheetSkinIos.arrowColor,
        SoloForteSheetVariant.light => accent,
        SoloForteSheetVariant.dark => subtitleColor,
      };

  Color get sheetBorder => switch (variant) {
        SoloForteSheetVariant.ios => SoloForteSheetSkinIos.sheetBorder,
        SoloForteSheetVariant.light => SoloForteSheetSkinLight.cardBorder,
        SoloForteSheetVariant.dark => Colors.transparent,
      };

  Color get rowDivider => dividerColor;

  Color get ctaBackground => switch (variant) {
        SoloForteSheetVariant.ios => SoloForteSheetSkinIos.ctaBackground,
        SoloForteSheetVariant.light => accent,
        SoloForteSheetVariant.dark => accent,
      };

  Color get ctaText => switch (variant) {
        SoloForteSheetVariant.ios => SoloForteSheetSkinIos.ctaText,
        SoloForteSheetVariant.light => Colors.white,
        SoloForteSheetVariant.dark => Colors.white,
      };

  double get ctaRadius => switch (variant) {
        SoloForteSheetVariant.ios => SoloForteSheetSkinIos.ctaRadius,
        SoloForteSheetVariant.light => 13.0,
        SoloForteSheetVariant.dark => SoloForteSheetTokens.chipRadius,
      };

  Color get ghostText => switch (variant) {
        SoloForteSheetVariant.ios => SoloForteSheetSkinIos.ghostText,
        SoloForteSheetVariant.light => accent,
        SoloForteSheetVariant.dark => accent,
      };

  Color get ghostBorder => switch (variant) {
        SoloForteSheetVariant.ios => SoloForteSheetSkinIos.ghostBorder,
        SoloForteSheetVariant.light => SoloForteSheetSkinLight.cardBorder,
        SoloForteSheetVariant.dark => SoloForteSheetTokens.chipBorderInactive,
      };

  double get ghostRadius => switch (variant) {
        SoloForteSheetVariant.ios => SoloForteSheetSkinIos.ghostRadius,
        SoloForteSheetVariant.light => 13.0,
        SoloForteSheetVariant.dark => SoloForteSheetTokens.chipRadius,
      };

  /// Texto principal dentro do sheet (substitui `Colors.white` no ramo escuro).
  Color get onSheetPrimary => titleColor;

  /// Texto secundário / hint dentro do sheet.
  Color get onSheetSecondary => subtitleColor;

  /// Divisor fraco dentro do conteúdo do sheet.
  Color get onSheetDivider => isDark
      ? Colors.white.withValues(alpha: 0.12)
      : dividerColor;
}
