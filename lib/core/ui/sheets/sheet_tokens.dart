// lib/core/ui/sheets/sheet_tokens.dart

import 'package:flutter/material.dart';

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
  static const Color chipBorderActive   = Color(0xFFF59E0B);
  static const Color chipTextActive     = Color(0xFFF59E0B);
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
