import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'design_tokens.dart';

/// O novo Tema Premium do aplicativo (Responsável pela Fase 1)
class PremiumAppTheme {
  static const Color _greenAccent = PremiumTokens.brandGreen;
  static const Color _blueAccent = Color(0xFF1B6EE0);

  static ThemeData themeFor(String mode) {
    return switch (mode) {
      'blue' => _buildLightTheme(_blueAccent),
      'black' => darkTheme,
      'green' || _ => lightTheme,
    };
  }

  static ThemeMode themeModeFor(String mode) {
    return mode == 'black' ? ThemeMode.dark : ThemeMode.light;
  }

  // ============================================
  // TEXT THEMES: Geometria de texto iOS com Fonte Inter
  // ============================================

  static TextTheme _buildTextTheme(
    Color primaryTextColor,
    Color secondaryTextColor,
  ) {
    return TextTheme(
      // Large Title
      displayLarge: GoogleFonts.inter(
        fontSize: 34,
        fontWeight: FontWeight.w700,
        color: primaryTextColor,
        letterSpacing: 0.37,
      ),
      // Small Titles (Header Dialogs)
      titleMedium: GoogleFonts.inter(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        color: primaryTextColor,
        letterSpacing: -0.4,
      ),
      // Body (Reading)
      bodyLarge: GoogleFonts.inter(
        fontSize: 17,
        fontWeight: FontWeight.w400,
        color: primaryTextColor,
        letterSpacing: -0.4,
      ),
      // Small body / Metadados Explicativos
      bodyMedium: GoogleFonts.inter(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        color: secondaryTextColor,
        letterSpacing: 0,
      ),
      // Mínimos
      labelSmall: GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: secondaryTextColor,
        letterSpacing: 0.07,
      ),
    );
  }

  // ============================================
  // COMPONENTES PREMIUM (Inputs e Botões M3 Adaptados)
  // ============================================

  static InputDecorationTheme _buildInputDecoration(bool isDark, Color accent) {
    final fillColor = isDark ? PremiumTokens.surfaceDark : Colors.white;
    final borderColor = isDark
        ? PremiumTokens.hairlineDark
        : PremiumTokens.hairlineLight;

    return InputDecorationTheme(
      filled: true,
      fillColor: fillColor,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(PremiumTokens.borderRadiusMd),
        borderSide: BorderSide(
          color: borderColor,
          width: PremiumTokens.hairlineThickness,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(PremiumTokens.borderRadiusMd),
        borderSide: BorderSide(
          color: borderColor,
          width: PremiumTokens.hairlineThickness,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(PremiumTokens.borderRadiusMd),
        borderSide: BorderSide(color: accent, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(PremiumTokens.borderRadiusMd),
        borderSide: const BorderSide(
          color: PremiumTokens.alertError,
          width: 1.5,
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(PremiumTokens.borderRadiusMd),
        borderSide: const BorderSide(color: PremiumTokens.alertError, width: 2),
      ),
      labelStyle: GoogleFonts.inter(
        color: isDark
            ? PremiumTokens.textSecondaryDark
            : PremiumTokens.textSecondaryLight,
        fontSize: 12.0,
      ),
      hintStyle: GoogleFonts.inter(
        color: isDark
            ? PremiumTokens.textTertiaryDark
            : PremiumTokens.textTertiaryLight,
        fontSize: 15.0,
      ),
    );
  }

  static ElevatedButtonThemeData _buildElevatedButtonTheme(Color accent) {
    return ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: accent,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(PremiumTokens.borderRadiusMd),
        ),
        elevation:
            0, // Design flat/premium por default, sombras via BoxShadow nas views se precisar
        textStyle: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    );
  }

  // ============================================
  // TEMA GLOBAL CLARO
  // ============================================

  static ThemeData get lightTheme {
    return _buildLightTheme(_greenAccent);
  }

  static ThemeData _buildLightTheme(Color accent) {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      fontFamily: GoogleFonts.inter().fontFamily,

      // DESLIGAMENTO DAS FÍSICAS DO ANDROID (Sem círculos de água)
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      hoverColor: Colors.transparent,

      // Cores Massivas
      primaryColor: accent,
      scaffoldBackgroundColor: PremiumTokens.backgroundLight,

      // Esquema Oficial iOS (Monocromo com Destaque de TintColor)
      colorScheme: ColorScheme.light(
        primary: accent,
        secondary: accent,
        surface: PremiumTokens.surfaceLight,
        error: PremiumTokens.alertError,
        onPrimary: Colors.white,
        onSurface: PremiumTokens.textPrimaryLight,
      ),

      appBarTheme: const AppBarTheme(
        backgroundColor: PremiumTokens.backgroundLight,
        elevation: 0,
        scrolledUnderElevation: 0, // Desliga efeito feio nativo ao scrolar
        centerTitle: true,
        iconTheme: IconThemeData(color: PremiumTokens.textPrimaryLight),
        titleTextStyle: TextStyle(
          color: PremiumTokens.textPrimaryLight,
          fontSize: 17,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.4,
        ),
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),

      textTheme: _buildTextTheme(
        PremiumTokens.textPrimaryLight,
        PremiumTokens.textSecondaryLight,
      ),

      inputDecorationTheme: _buildInputDecoration(false, accent),
      elevatedButtonTheme: _buildElevatedButtonTheme(accent),

      // Retirando fundos duros dos divisores (Finíssimos igual cabelo)
      dividerTheme: const DividerThemeData(
        color: PremiumTokens.hairlineLight,
        thickness: PremiumTokens.hairlineThickness,
        space: 1,
      ),
    );
  }

  // ============================================
  // TEMA GLOBAL ESCURO
  // ============================================

  static ThemeData get darkTheme {
    const accent = PremiumTokens.brandGreenDark;

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      fontFamily: GoogleFonts.inter().fontFamily,

      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      hoverColor: Colors.transparent,

      primaryColor: PremiumTokens.brandGreenDark,
      scaffoldBackgroundColor: PremiumTokens.backgroundDark, // Preto profundo

      colorScheme: const ColorScheme.dark(
        primary: PremiumTokens.brandGreenDark,
        secondary: PremiumTokens.brandGreenDark,
        surface: PremiumTokens.surfaceDark,
        error: PremiumTokens.alertError,
        onPrimary: Colors.white,
        onSurface: PremiumTokens.textPrimaryDark,
      ),

      appBarTheme: const AppBarTheme(
        backgroundColor: PremiumTokens.backgroundDark,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: PremiumTokens.textPrimaryDark),
        titleTextStyle: TextStyle(
          color: PremiumTokens.textPrimaryDark,
          fontSize: 17,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.4,
        ),
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),

      textTheme: _buildTextTheme(
        PremiumTokens.textPrimaryDark,
        PremiumTokens.textSecondaryDark,
      ),

      inputDecorationTheme: _buildInputDecoration(true, accent),
      elevatedButtonTheme: _buildElevatedButtonTheme(accent),

      dividerTheme: const DividerThemeData(
        color: PremiumTokens.hairlineDark,
        thickness: PremiumTokens.hairlineThickness,
        space: 1,
      ),
    );
  }
}
