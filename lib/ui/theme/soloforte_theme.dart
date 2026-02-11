import 'package:flutter/material.dart';

class SoloForteColors {
  // DESIGN SYSTEM - CORES PRIMÁRIAS
  static const Color primary = Color(0xFF4ADE80); // Verde Vibrante
  static const Color primaryDark = Color(0xFF1E3A2F); // Verde Escuro
  static const Color accent = Color(0xFFD1FAE5); // Verde Menta Claro

  // AZUL SAMSUNG - MANTIDO PARA LEGADO (mas desencorajado)
  static const Color blueSamsung = Color(0xFF1B6EE0);
  static const Color blueDark = Color(0xFF0F5FC9);
  static const Color blueLight = Color(0xFF2E7FED);
  static const Color bluePetrol = Color(0xFF0D7C8C);
  static const Color bluePetrolLight = Color(0xFF1A9BAD);
  static const Color cyanBright = Color(0xFF00BCD4);
  static const Color skyBlue = Color(0xFF0EA5E9);

  // VERDE IOS - CORES LEGADAS
  static const Color greenIOS = Color(0xFF4ADE80); // Atualizado para nova cor
  static const Color greenDark = Color(0xFF1E3A2F); // Atualizado para nova cor

  // BÁSICAS
  static const Color white = Color(0xFFFFFFFF);
  static const Color grayLight = Color(
    0xFFF3F4F6,
  ); // Atualizado para tom do design

  // TEXTO
  static const Color textPrimary = Color(0xFF1A1A1A); // Atualizado
  static const Color textSecondary = Color(0xFF6B7280); // Atualizado
  static const Color textTertiary = Color(0xFF9CA3AF); // Atualizado

  // ESTADO
  static const Color success = Color(0xFF4ADE80); // Atualizado
  static const Color error = Color(0xFFDC2626); // Atualizado
  static const Color warning = Color(0xFFF59E0B);
  static const Color info = Color(0xFF0EA5E9); // Sky blue

  static const Color bgSuccess = Color(0xFFECFDF5);
  static const Color bgError = Color(0xFFFEF2F2);
  static const Color bgWarning = Color(0xFFFFFBEB);
  static const Color bgInfo = Color(0xFFEFF6FF);

  static const Color textSuccess = Color(0xFF047857);
  static const Color textError = Color(0xFFDC2626);
  static const Color textWarning = Color(0xFFD97706);
  static const Color textInfo = Color(0xFF1E40AF);

  // BORDAS
  static const Color border = Color(0xFFE5E7EB); // Atualizado
  static const Color borderLight = Color(0xFFF3F4F6);

  // BRAND
  static const Color brand = Color(0xFF4ADE80); // Atualizado para Verde
}

class SoloForteGradients {
  // Novo Gradiente Principal (Verde Vibrante -> Verde Escuro)
  static const LinearGradient primary = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF4ADE80), Color(0xFF1E3A2F)],
  );

  // Samsung → Petróleo (Legado)
  static const LinearGradient blue = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1B6EE0), Color(0xFF0D7C8C)],
  );

  // Petróleo Puro
  static const LinearGradient petrol = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0D7C8C), Color(0xFF0A5A66)],
  );

  // Sky Blue
  static const LinearGradient sky = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0EA5E9), Color(0xFF1B6EE0)],
  );

  // Azul Escuro (Marinho)
  static const LinearGradient dark = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0A3A5C), Color(0xFF041E31)],
  );

  // Background
  static const LinearGradient background = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFFFFFFF), Color(0xFFF3F4F6)],
  );

  // Verde legado
  static const LinearGradient green = primary;
}

class SoloFontSizes {
  static const double xs = 12.0; // 0.75em
  static const double sm = 13.6; // 0.85em
  static const double base = 15.2; // 0.95em
  static const double lg = 17.6; // 1.1em
  static const double xl = 19.2; // 1.2em
  static const double xxl = 32.0; // 2em
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

  static const TextStyle textBlue = TextStyle(
    fontSize: 15.2,
    color: Color(0xFF1B6EE0),
  );

  static const TextStyle caption = TextStyle(
    fontSize: 13.6,
    fontWeight: FontWeight.w400,
    color: Color(0xFF86868B),
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
      color: Color.fromRGBO(74, 222, 128, 0.3), // Green Shadow
      offset: Offset(0, 4),
      blurRadius: 12,
    ),
  ];

  static const List<BoxShadow> shadowPetrol = [
    BoxShadow(
      color: Color.fromRGBO(13, 124, 140, 0.3),
      offset: Offset(0, 4),
      blurRadius: 12,
    ),
  ];
}

class SoloForteTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      primaryColor: const Color(0xFF4ADE80), // Updated to Green
      scaffoldBackgroundColor: const Color(0xFFFFFFFF), // Updated to White
      fontFamily:
          'SF Pro Text', // Will use fallback or system default if not loaded

      colorScheme: const ColorScheme.light(
        primary: Color(0xFF4ADE80), // Green
        secondary: Color(0xFF1E3A2F), // Dark Green
        error: Color(0xFFDC2626), // Red
        surface: Color(0xFFFFFFFF),
        onPrimary: Color(0xFFFFFFFF),
        onSecondary: Color(0xFFFFFFFF),
        onSurface: Color(0xFF1A1A1A), // Dark Text
      ),

      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w600,
          color: Color(0xFF1A1A1A),
        ),
        headlineMedium: TextStyle(
          fontSize: 19.2,
          fontWeight: FontWeight.w600,
          color: Color(0xFF1A1A1A),
        ),
        bodyLarge: TextStyle(
          fontSize: 15.2,
          fontWeight: FontWeight.w400,
          color: Color(0xFF1A1A1A),
        ),
        bodyMedium: TextStyle(fontSize: 15.2, color: Color(0xFF6B7280)),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF4ADE80),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF4ADE80), width: 2),
        ),
        contentPadding: const EdgeInsets.all(16),
      ),
    );
  }
}
