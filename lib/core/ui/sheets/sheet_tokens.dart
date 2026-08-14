// lib/core/ui/sheets/sheet_tokens.dart

import 'package:flutter/material.dart';

/// Identificador semântico do tema SoloForte ('green' | 'blue' | 'black').
///
/// Registrado em [PremiumAppTheme.themeFor] / darkTheme.
/// Permite que sheets em `core/` detectem o tema via [Theme.of]
/// sem importar `modules/settings/` nem comparar hex de accent.
class SoloForteThemeExtension extends ThemeExtension<SoloForteThemeExtension> {
  final String themeId; // 'green' | 'blue' | 'black'

  const SoloForteThemeExtension({required this.themeId});

  @override
  SoloForteThemeExtension copyWith({String? themeId}) =>
      SoloForteThemeExtension(themeId: themeId ?? this.themeId);

  @override
  SoloForteThemeExtension lerp(
    ThemeExtension<SoloForteThemeExtension>? other,
    double t,
  ) =>
      t < 0.5 ? this : (other as SoloForteThemeExtension? ?? this);
}

/// Tokens visuais oficiais dos bottom sheets do SoloForte.
/// Fonte da verdade: ADR-027 / IMG_3809.png (screenshot produção).
abstract final class SoloForteSheetTokens {
  // Container
  static const Color sheetBackground   = Color(0xFF1C1C1E);
  static const double borderRadius     = 20.0;

  // Inputs
  static const Color inputBackground   = Color(0xFF2C2C2E);
  static const double inputRadius      = 12.0;
  static const Color inputText         = Colors.white;
  static const Color inputHint         = Color(0xFF8E8E93);
  static const EdgeInsets inputPadding =
      EdgeInsets.symmetric(horizontal: 16, vertical: 14);

  // Seções / Headers
  static const Color sectionLabel      = Colors.white;
  static const double sectionFontSize  = 15.0;
  static const FontWeight sectionWeight = FontWeight.w600;
  static const Color divider           = Color(0xFF3A3A3C);

  // Botões de categoria (círculos)
  static const Color categoryBackground = Color(0xFF3A3A3C);
  static const Color categoryIcon       = Colors.white;
  static const Color categoryLabel      = Color(0xFFAEAEB2);
  static const double categoryDiameter  = 72.0;
  static const double categoryIconSize  = 28.0;

  // Seleção exclusiva (ex: Urgência)
  static const Color chipBorderInactive = Color(0xFF3A3A3C);
  static const Color chipTextInactive   = Color(0xFF8E8E93);
  static const Color chipBorderActive   = Color(0xFF1428A0);
  static const Color chipTextActive     = Color(0xFF1428A0);
  static const double chipBorderWidth   = 2.0;
  static const double chipRadius        = 12.0;

  // Chip de coordenadas
  static const Color coordBackground   = Color(0xFF1A2E1A);
  static const Color coordText         = Color(0xFF4ADE80);
  static const double coordRadius      = 20.0;
  static const double coordFontSize    = 13.0;

  // Título inline do sheet
  static const double titleFontSize    = 20.0;
  static const FontWeight titleWeight  = FontWeight.w700;
  static const Color titleColor        = Colors.white;
}

/// Skin iOS leve — aplicada quando `SoloForteThemeExtension.themeId == 'blue'`.
/// Não altera [SoloForteSheetTokens] (verde / black).
abstract final class SoloForteSheetSkinIos {
  // Fundo principal do sheet
  static const Color background = Color(0xFFF5F6F8); // prata suave iOS 17

  // Card interno agrupado
  static const Color cardBackground = Color(0xFFEBF5FF);
  static const Color cardBorder = Color(0xFFB3D9F5);
  static const double cardRadius = 14.0;

  // Handle
  static const Color handleColor = Color(0xFF7EC8F0);
  static const Size handleSize = Size(40, 4);

  // Borda superior do sheet
  static const Color sheetBorder = Color(0xFFB3D9F5);
  static const double sheetRadius = 22.0;

  // Ícones — circulares
  static const Color iconBackground = Color(0xFFB3D9F5);
  static const Color iconStroke = Color(0xFF0175C2);
  static const double iconRadius = 999.0; // circular

  // Textos
  static const Color titleColor = Color(0xFF003D6B);
  static const Color subtitleColor = Color(0xFF1A8FD1);
  static const Color arrowColor = Color(0xFF0175C2);

  // Badge role (ex: "consultor")
  static const Color badgeBackground = Color(0xFFD0EEFB);
  static const Color badgeText = Color(0xFF0175C2);
  static const Color badgeBorder = Color(0xFF7EC8F0);

  // Botão CTA principal
  static const Color ctaBackground = Color(0xFF0175C2); // Flutter Blue
  static const Color ctaText = Color(0xFFFFFFFF);
  static const double ctaRadius = 13.0;

  // Botão ghost (Cancelar)
  static const Color ghostBorder = Color(0xFF7EC8F0);
  static const Color ghostText = Color(0xFF0175C2);
  static const double ghostRadius = 13.0;

  // Separador entre rows do card
  static const Color rowDivider = Color(0x1A0175C2); // 10% opacity
}
