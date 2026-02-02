import 'package:flutter/material.dart';

class SoloForteColors {
  // VERDE IOS - CORES PRIMÁRIAS
  static const Color greenIOS = Color(0xFF34C759);
  static const Color greenDark = Color(0xFF2DA94D);
  static const Color white = Color(0xFFFFFFFF);
  static const Color grayLight = Color(0xFFF5F5F7);
  
  // TEXTO
  static const Color textPrimary = Color(0xFF1D1D1F);
  static const Color textSecondary = Color(0xFF86868B);
  static const Color textTertiary = Color(0xFFC7C7CC);
  
  // ESTADO
  static const Color success = Color(0xFF34C759);
  static const Color error = Color(0xFFFF3B30);
  static const Color bgSuccess = Color(0xFFE8F5E9);
  static const Color bgError = Color(0xFFFFEBEE);
  static const Color textSuccess = Color(0xFF2E7D32);
  static const Color textError = Color(0xFFC62828);
  
  // BORDAS
  static const Color border = Color(0xFFD1D1D6);
  static const Color borderLight = Color(0xFFE5E5E7);
  
  // BRAND
  static const Color brand = Color(0xFF0057FF);
}

class SoloForteGradients {
  static const LinearGradient primary = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF34C759), Color(0xFF2DA94D)],
  );
  
  static const LinearGradient background = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFF5F5F7), Color(0xFFE5E5E7)],
  );
}

class SoloFontSizes {
  static const double xs = 12.0;      // 0.75em
  static const double sm = 13.6;      // 0.85em
  static const double base = 15.2;    // 0.95em
  static const double lg = 17.6;      // 1.1em
  static const double xl = 19.2;      // 1.2em
  static const double xxl = 32.0;     // 2em
}

class SoloFontWeights {
  static const FontWeight regular = FontWeight.w400;
  static const FontWeight medium = FontWeight.w500;
  static const FontWeight semibold = FontWeight.w600;
}

class SoloTextStyles {
  // We can't use const with .copy with GoogleFonts if we were using it inside here dynamically,
  // but to match the design file identically, we keep these static constants.
  // In usage, we might wrap them with GoogleFonts if strictly required, or rely on Theme.
  
  static const TextStyle headingLarge = TextStyle(
    fontSize: 32.0,
    fontWeight: FontWeight.w600,
    color: Color(0xFF1D1D1F),
    height: 1.2,
  );
  
  static const TextStyle headingMedium = TextStyle(
    fontSize: 19.2,
    fontWeight: FontWeight.w600,
    color: Color(0xFF1D1D1F),
    height: 1.3,
  );
  
  static const TextStyle label = TextStyle(
    fontSize: 12.0,
    fontWeight: FontWeight.w500,
    color: Color(0xFF86868B),
    letterSpacing: 0.5,
  );
  
  static const TextStyle body = TextStyle(
    fontSize: 15.2,
    fontWeight: FontWeight.w400,
    color: Color(0xFF1D1D1F),
  );
}

class SoloSpacing {
  static const double xs = 8.0;
  static const double sm = 12.0;
  static const double md = 16.0;
  static const double lg = 20.0;
  static const double xl = 24.0;
  static const double xxl = 30.0;
  
  static const EdgeInsets paddingCard = EdgeInsets.all(20.0);
  static const EdgeInsets paddingInput = EdgeInsets.all(12.0);
  static const EdgeInsets paddingButton = EdgeInsets.symmetric(
    horizontal: 16.0,
    vertical: 10.0,
  );
}

class SoloRadius {
  static const double sm = 6.0;
  static const double md = 8.0;
  static const double lg = 10.0;
  static const double xl = 12.0;
  static const double circle = 999.0;
  
  static final BorderRadius radiusSm = BorderRadius.circular(6.0);
  static final BorderRadius radiusMd = BorderRadius.circular(8.0);
  static final BorderRadius radiusLg = BorderRadius.circular(10.0);
  static final BorderRadius radiusXl = BorderRadius.circular(12.0);
}

class SoloShadows {
  static const BoxShadow shadowSm = BoxShadow(
    color: Color.fromRGBO(0, 0, 0, 0.08),
    offset: Offset(0, 1),
    blurRadius: 3,
  );
  
  static const BoxShadow shadowMd = BoxShadow(
    color: Color.fromRGBO(0, 0, 0, 0.04),
    offset: Offset(0, 2),
    blurRadius: 8,
  );
  
  static const List<BoxShadow> shadowCard = [
    BoxShadow(
      color: Color.fromRGBO(0, 0, 0, 0.08),
      offset: Offset(0, 1),
      blurRadius: 3,
    ),
    BoxShadow(
      color: Color.fromRGBO(0, 0, 0, 0.04),
      offset: Offset(0, 2),
      blurRadius: 8,
    ),
  ];
  
  static const List<BoxShadow> shadowButton = [
    BoxShadow(
      color: Color.fromRGBO(52, 199, 89, 0.3),
      offset: Offset(0, 4),
      blurRadius: 12,
    ),
  ];
}

class SoloForteTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      primaryColor: const Color(0xFF34C759),
      scaffoldBackgroundColor: const Color(0xFFF5F5F7),
      fontFamily: 'SF Pro Text', // Will use fallback or system default if not loaded
      
      colorScheme: const ColorScheme.light(
        primary: Color(0xFF34C759),
        secondary: Color(0xFF2DA94D),
        error: Color(0xFFFF3B30),
        surface: Color(0xFFFFFFFF),
        onPrimary: Color(0xFFFFFFFF),
        onSecondary: Color(0xFFFFFFFF),
        onSurface: Color(0xFF1D1D1F),
      ),
      
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w600,
          color: Color(0xFF1D1D1F),
        ),
        headlineMedium: TextStyle(
          fontSize: 19.2,
          fontWeight: FontWeight.w600,
          color: Color(0xFF1D1D1F),
        ),
        bodyLarge: TextStyle(
          fontSize: 15.2,
          fontWeight: FontWeight.w400,
          color: Color(0xFF1D1D1F),
        ),
        bodyMedium: TextStyle(
          fontSize: 15.2,
          color: Color(0xFF86868B),
        ),
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
      
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFD1D1D6)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF34C759), width: 2),
        ),
        contentPadding: const EdgeInsets.all(12),
      ),
    );
  }
}
