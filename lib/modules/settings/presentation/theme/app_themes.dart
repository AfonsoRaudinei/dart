import 'package:flutter/material.dart';

class AppThemes {
  // --- Design System - Estilo iOS Profissional ---
  static ThemeData get greenTheme {
    // Design System Tokens
    const primaryColor = Color(0xFF4ADE80); // Verde Vibrante
    const secondaryColor = Color(0xFF1E3A2F); // Verde Escuro
    const backgroundColor = Color(0xFFFFFFFF); // Branco principal
    const errorColor = Color(0xFFDC2626); // Vermelho
    const textColor = Color(0xFF1A1A1A); // Preto/Carvão
    const secondaryTextColor = Color(0xFF6B7280); // Cinza Médio
    const borderColor = Color(0xFFE5E7EB); // Cinza Claro (Bordas)

    return ThemeData(
      primaryColor: primaryColor,
      scaffoldBackgroundColor: backgroundColor,
      fontFamily: 'SF Pro Text', // Mantendo a fonte do sistema iOS/Android

      colorScheme: const ColorScheme.light(
        primary: primaryColor,
        secondary: secondaryColor,
        error: errorColor,
        surface: backgroundColor,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: textColor,
      ),

      appBarTheme: const AppBarTheme(
        backgroundColor: backgroundColor,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: textColor),
        titleTextStyle: TextStyle(
          color: textColor,
          fontSize: 17,
          fontWeight: FontWeight.w600,
          fontFamily: 'SF Pro Text',
        ),
      ),

      textTheme: const TextTheme(
        // Título de Página (24-28px Bold)
        headlineMedium: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: textColor,
          height: 1.2,
        ),
        // Card Title (18-20px Semibold)
        titleLarge: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: textColor,
          height: 1.3,
        ),
        // Body (16px Regular)
        bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: textColor,
        ),
        // Body Secundário / Labels
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: secondaryTextColor,
        ),
        // Caption / Small Labels
        bodySmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: secondaryTextColor,
        ),
        // Valores Monetários (20-32px Bold)
        displaySmall: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.all(16), // Aumentado padding interno
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12), // Arredondamento maior
          borderSide: const BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        labelStyle: const TextStyle(color: secondaryTextColor),
        hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16), // 12-16px conforme design
          ),
          elevation: 4, // Sombra sutil para destaque CTA
          shadowColor: primaryColor.withValues(alpha: 0.3),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600, // Semibold
          ),
        ),
      ),

      // Adicionando CardTheme para consistência
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 2,
        shadowColor: Colors.black.withValues(alpha: 0.08),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.only(bottom: 16),
      ),

      iconTheme: const IconThemeData(color: textColor, size: 24),

      dividerTheme: const DividerThemeData(
        color: borderColor,
        thickness: 1,
        space: 1,
      ),
    );
  }

  // --- Blue (Samsung) ---
  static ThemeData get blueTheme {
    return ThemeData(
      primaryColor: const Color(0xFF1B6EE0),
      scaffoldBackgroundColor: const Color(0xFFF5F7FA),
      fontFamily: 'SF Pro Text',
      colorScheme: const ColorScheme.light(
        primary: Color(0xFF1B6EE0),
        secondary: Color(0xFF0D7C8C),
        error: Color(0xFFEF4444),
        surface: Color(0xFFFFFFFF),
        onPrimary: Color(0xFFFFFFFF),
        onSecondary: Color(0xFFFFFFFF),
        onSurface: Color(0xFF1D1D1F),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFFF5F7FA),
        elevation: 0,
        foregroundColor: Color(0xFF1D1D1F),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1B6EE0),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          elevation: 0,
        ),
      ),
    );
  }

  // --- Black (Gold) ---
  static ThemeData get blackTheme {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: const Color(0xFFD4AF37),
      scaffoldBackgroundColor: const Color(0xFF000000),
      fontFamily: 'SF Pro Text',
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFFD4AF37),
        secondary: Color(0xFFCD7F32),
        error: Color(0xFFEF4444),
        surface: Color(0xFF1A1A1A),
        onPrimary: Color(0xFF000000),
        onSecondary: Color(0xFFFFFFFF),
        onSurface: Color(0xFFFFFFFF),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF000000),
        elevation: 0,
        foregroundColor: Color(0xFFFFFFFF),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(
            0xFFE8C547,
          ), // Gold gradient start approximation
          foregroundColor: const Color(0xFF000000),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          elevation: 0,
        ),
      ),
    );
  }

  static ThemeData getTheme(String mode) {
    switch (mode) {
      case 'blue':
        return blueTheme;
      case 'black':
        return blackTheme;
      case 'green':
      default:
        return greenTheme;
    }
  }
}
