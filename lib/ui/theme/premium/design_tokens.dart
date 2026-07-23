import 'package:flutter/material.dart';

/// Define os tokens exatos do Design System Premium iOS
class PremiumTokens {
  // === CORES SOBERANAS ===

  // A 'Tint Color' única. Verde vibrante iOS que comanda as ações do App
  static const Color brandGreen = Color(0xFF34C759);
  static const Color brandGreenDark = Color(0xFF32D74B);

  // Gradiente vibrante para Call to Actions principais
  static const LinearGradient brandGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF4ADE80), // Verde mais claro/vibrante no topo
      Color(0xFF248A3D), // Verde SoloForte na base
    ],
  );

  // === SUPERFÍCIES (SEM CORES FORTES AQUI) ===

  // Light Mode
  static const Color backgroundLight = Color(
    0xFFF2F2F7,
  ); // Fundo cinza de sistema do iOS
  static const Color surfaceLight = Color(
    0xFFFFFFFF,
  ); // Cards, formulários brancos limpos

  // Dark Mode
  static const Color backgroundDark = Color(0xFF000000); // Preto puro
  static const Color surfaceDark = Color(
    0xFF1C1C1E,
  ); // Cinza chumbo claro (cards)

  // === VIDROS (GLASSMORPHISM) ===

  static const Color glassWhite = Color(
    0xCCFFFFFF,
  ); // Branco a 80% opacity para Blur
  static const Color glassBlack = Color(
    0xCC1E1E1E,
  ); // Escuro a 80% opacity para Blur

  // === ALERTAS E STATUS !===

  static const Color alertError = Color(0xFFFF3B30); // iOS System Red
  static const Color alertWarning = Color(0xFFFFCC00); // iOS System Yellow

  // === TEXTOS !===

  static const Color textPrimaryLight = Color(0xFF000000);
  static const Color textSecondaryLight = Color(
    0xFF3C3C43,
  ); // iOS Secondary Label Light
  static const Color textTertiaryLight = Color(0x4D3C3C43);

  static const Color textPrimaryDark = Color(0xFFFFFFFF);
  static const Color textSecondaryDark = Color(0x99ebebf5); // Opacidade de 60%
  static const Color textTertiaryDark = Color(0x4DEBEBF5);

  // === GEOMETRIA (SQUIRCLES) E BORDAS ===

  static const double borderRadiusSm = 12.0; // Listas internas (Inset Group)
  static const double borderRadiusMd = 16.0; // Cards, botões flutuantes
  static const double borderRadiusLg = 32.0; // Modais e BottomSheets

  // Linhas divisórias iOS são milimétricas
  static const double hairlineThickness = 0.5;
  static const Color hairlineLight = Color(0x4D3C3C43);
  static const Color hairlineDark = Color(0x99545458);

  // === SOMBRAS DE DISPERSÃO (FLUTUAÇÃO MACIA) ===

  static final List<BoxShadow> premiumShadow = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.08),
      offset: const Offset(0, 10),
      blurRadius: 32,
      spreadRadius: 0,
    ),
  ];

  static final List<BoxShadow> tightShadow = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.12),
      offset: const Offset(0, 2),
      blurRadius: 8,
      spreadRadius: 0,
    ),
  ];
}

/// Resolve os tokens Premium (Light/Dark) conforme o brightness do tema
/// ativo. Várias telas fixavam a variante "Light" direto no Scaffold/AppBar,
/// ignorando o tema Black selecionado pelo usuário — use estes getters em
/// vez de `PremiumTokens.xLight` quando o valor deve reagir ao tema.
extension PremiumThemeAware on BuildContext {
  bool get isPremiumDark => Theme.of(this).brightness == Brightness.dark;

  Color get premiumBackground =>
      isPremiumDark ? PremiumTokens.backgroundDark : PremiumTokens.backgroundLight;

  Color get premiumSurface =>
      isPremiumDark ? PremiumTokens.surfaceDark : PremiumTokens.surfaceLight;

  Color get premiumTextPrimary =>
      isPremiumDark ? PremiumTokens.textPrimaryDark : PremiumTokens.textPrimaryLight;

  Color get premiumTextSecondary => isPremiumDark
      ? PremiumTokens.textSecondaryDark
      : PremiumTokens.textSecondaryLight;

  Color get premiumTextTertiary => isPremiumDark
      ? PremiumTokens.textTertiaryDark
      : PremiumTokens.textTertiaryLight;

  Color get premiumHairline =>
      isPremiumDark ? PremiumTokens.hairlineDark : PremiumTokens.hairlineLight;
}
