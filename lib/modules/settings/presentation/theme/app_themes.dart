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

  // --- Black (Gold) — design/BLACK_GOLD_FLUTTER.md ---
  static ThemeData get blackTheme {
    const gold = Color(0xFFD4AF37);
    const goldLight = Color(0xFFE8C547);
    const black = Color(0xFF000000);
    const surface = Color(0xFF1A1A1A);
    const border = Color(0xFF404040);
    const textPrimary = Color(0xFFFFFFFF);
    const textSecondary = Color(0xFFB8B8B8);

    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: gold,
      scaffoldBackgroundColor: black,
      fontFamily: 'SF Pro Text',
      colorScheme: const ColorScheme.dark(
        primary: gold,
        secondary: Color(0xFFCD7F32),
        error: Color(0xFFEF4444),
        surface: surface,
        onPrimary: Color(0xFF000000),
        onSecondary: Color(0xFFFFFFFF),
        onSurface: textPrimary,
        onSurfaceVariant: textSecondary,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: black,
        elevation: 0,
        foregroundColor: textPrimary,
        surfaceTintColor: Colors.transparent,
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w600,
          color: textPrimary,
          height: 1.2,
        ),
        headlineMedium: TextStyle(
          fontSize: 19.2,
          fontWeight: FontWeight.w600,
          color: textPrimary,
          height: 1.3,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        bodyLarge: TextStyle(
          fontSize: 15.2,
          fontWeight: FontWeight.w400,
          color: textPrimary,
        ),
        bodyMedium: TextStyle(
          fontSize: 15.2,
          color: textSecondary,
        ),
        labelMedium: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: gold,
          letterSpacing: 1.0,
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: border,
        thickness: 1,
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Color(0xFF2D2D2D)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        labelStyle: const TextStyle(color: gold),
        hintStyle: const TextStyle(color: textSecondary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: gold, width: 2),
        ),
        contentPadding: const EdgeInsets.all(12),
      ),
      listTileTheme: const ListTileThemeData(
        iconColor: textSecondary,
        textColor: textPrimary,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: gold,
        foregroundColor: Color(0xFF000000),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: goldLight,
          foregroundColor: const Color(0xFF000000),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          elevation: 0,
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        titleTextStyle: const TextStyle(
          fontSize: 19.2,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        contentTextStyle: const TextStyle(
          fontSize: 15.2,
          color: textSecondary,
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: surface,
        modalBackgroundColor: surface,
      ),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: surface,
        contentTextStyle: TextStyle(color: textPrimary),
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
