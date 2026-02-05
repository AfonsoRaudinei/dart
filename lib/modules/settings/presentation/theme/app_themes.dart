import 'package:flutter/material.dart';

class AppThemes {
  // --- Green (Original) ---
  static ThemeData get greenTheme {
    return ThemeData(
      primaryColor: const Color(0xFF34C759),
      scaffoldBackgroundColor: const Color(0xFFF5F5F7),
      fontFamily: 'SF Pro Text',
      colorScheme: const ColorScheme.light(
        primary: Color(0xFF34C759),
        secondary: Color(0xFF2DA94D),
        error: Color(0xFFFF3B30),
        surface: Color(0xFFFFFFFF),
        onPrimary: Color(0xFFFFFFFF),
        onSecondary: Color(0xFFFFFFFF),
        onSurface: Color(0xFF1D1D1F),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFFF2F2F7),
        elevation: 0,
        foregroundColor: Color(0xFF1D1D1F),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF34C759),
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
