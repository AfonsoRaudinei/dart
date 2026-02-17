import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SoloForteColors {
  // === PALETA OFICIAL (Design System v2) ===

  // BRAND & ACENTS
  static const Color primary = Color(0xFF4ADE80); // Verde Técnico
  static const Color primaryDark = Color(0xFF1E3A2F); // Verde Profundo
  static const Color accent = Color(0xFFD1FAE5); // Mint (Feedback)

  // BASE - LIGHT MODE
  static const Color backgroundLight = Color(0xFFFFFFFF);
  static const Color surfaceLight = Color(0xFFF3F4F6);
  static const Color surfaceElevatedLight = Color(0xFFFFFFFF);

  // BASE - DARK MODE (Técnico)
  static const Color backgroundDark = Color(0xFF0F1113);
  static const Color surfaceDark = Color(0xFF161A1D);
  static const Color surfaceElevatedDark = Color(0xFF1E2428);

  // TEXTO
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textTertiary = Color(0xFF9CA3AF); // Placeholder/Disabled

  static const Color textPrimaryDark = Color(0xFFE6E6E6);
  static const Color textSecondaryDark = Color(0xFF9CA3AF);

  // FEEDBACK E ESTADOS
  static const Color success = Color(0xFF4ADE80);
  static const Color error = Color(0xFFDC2626); // Vermelho Técnico
  static const Color warning = Color(0xFFF59E0B);
  static const Color info = Color(0xFF0EA5E9);

  // BORDAS E DIVISORES
  static const Color border = Color(0xFFE5E7EB);
  static const Color borderDark = Color(0xFF2A3136);

  // === LEGADO ( Mantido para compatibilidade, mas mapeado para novas cores ou depreciado) ===
  static const Color white = Color(0xFFFFFFFF);
  static const Color grayLight = surfaceLight;
  static const Color brand = primary;

  // LEGACY BLUES (Mantidos apenas para evitar quebra de compilação)
  // O Design System proíbe o uso de cores fora da paleta oficial.
  static const Color blueSamsung = Color(0xFF1B6EE0);
  static const Color blueDark = Color(0xFF0F5FC9);
  static const Color blueLight = Color(0xFF2E7FED);
  static const Color bluePetrol = Color(0xFF0D7C8C);
  static const Color bluePetrolLight = Color(0xFF1A9BAD);
  static const Color cyanBright = Color(0xFF00BCD4);
  static const Color skyBlue = Color(0xFF0EA5E9);

  // LEGACY GREENS
  static const Color greenIOS = primary;
  static const Color greenDark = primaryDark;

  // LEGACY STATES
  static const Color bgSuccess = Color(0xFFECFDF5);
  static const Color bgError = Color(0xFFFEF2F2);
  static const Color bgWarning = Color(0xFFFFFBEB);
  static const Color bgInfo = Color(0xFFEFF6FF);

  static const Color textSuccess = Color(0xFF047857);
  static const Color textError = Color(0xFFDC2626);
  static const Color textWarning = Color(0xFFD97706);
  static const Color textInfo = Color(0xFF1E40AF);

  static const Color borderLight = border;
}

class SoloForteGradients {
  // O Design System v2 proíbe gradientes dramáticos.
  // Mantemos os tipos LinearGradient para compatibilidade, mas as cores são visualmente sólidas.

  // Primary agora é visualmente sólido (Verde Técnico)
  static const LinearGradient primary = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [SoloForteColors.primary, SoloForteColors.primary],
  );

  // Legacy Blues - "Achatados" para reduzir ruído visual
  static const LinearGradient blue = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1B6EE0), Color(0xFF1B6EE0)],
  );

  static const LinearGradient petrol = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0D7C8C), Color(0xFF0D7C8C)],
  );

  static const LinearGradient sky = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0EA5E9), Color(0xFF0EA5E9)],
  );

  static const LinearGradient dark = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0A1F16), Color(0xFF0A1F16)],
  );

  static const LinearGradient background = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [SoloForteColors.backgroundLight, SoloForteColors.surfaceLight],
  );

  static const LinearGradient green = primary;
}

class SoloFontSizes {
  // Hierarquia Estrita
  static const double xs = 12.0; // Caption/Meta
  static const double sm = 14.0; // Body Small (Legacy fallback)
  static const double base = 16.0; // Body Default / Inputs
  static const double lg = 18.0; // Section Title
  static const double xl = 24.0; // Page Title
  static const double xxl = 32.0; // Key Metrics
}

class SoloFontWeights {
  static const FontWeight regular = FontWeight.w400;
  static const FontWeight medium = FontWeight.w500; // Uso moderado
  static const FontWeight semibold = FontWeight.w600; // Títulos e Botões
  static const FontWeight bold = FontWeight.w700; // Apenas destaques
}

class SoloTextStyles {
  // Compatibilidade com código existente
  static TextStyle get headingLarge => GoogleFonts.inter(
    fontSize: SoloFontSizes.xxl,
    fontWeight: SoloFontWeights.semibold,
    color: SoloForteColors.textPrimary,
    height: 1.2,
  );

  static TextStyle get headingMedium => GoogleFonts.inter(
    fontSize: 22.0,
    fontWeight: SoloFontWeights.semibold,
    color: SoloForteColors.textPrimary,
    height: 1.3,
  );

  static TextStyle get body => GoogleFonts.inter(
    fontSize: SoloFontSizes.base,
    fontWeight: SoloFontWeights.regular,
    color: SoloForteColors.textPrimary,
  );

  static TextStyle get label => GoogleFonts.inter(
    fontSize: SoloFontSizes.xs,
    fontWeight: SoloFontWeights.medium,
    color: SoloForteColors.textSecondary,
    letterSpacing: 0.5,
  );

  static TextStyle get caption => GoogleFonts.inter(
    fontSize: SoloFontSizes.xs,
    fontWeight: SoloFontWeights.regular,
    color: SoloForteColors.textSecondary,
  );

  static TextStyle get textBlue => GoogleFonts.inter(
    fontSize: SoloFontSizes.base,
    color: SoloForteColors.info,
  );
}

class SoloSpacing {
  // Sistema 8px Grid
  static const double xs = 8.0;
  static const double sm = 12.0; // Legado (evitar)
  static const double md = 16.0; // Padrão
  static const double lg = 24.0; // Seções
  static const double xl = 32.0; // Blocos maiores
  static const double xxl = 48.0;

  static const EdgeInsets paddingCard = EdgeInsets.all(md);
  static const EdgeInsets paddingInput = EdgeInsets.all(md);
  static const EdgeInsets paddingButton = EdgeInsets.symmetric(
    horizontal: md,
    vertical: 12.0,
  );
}

class SoloRadius {
  // Sistema Simplificado
  static const double sm = 8.0; // Pequenos elementos
  static const double md = 16.0; // Cards, Botões, Inputs (Padrão Ouro)
  static const double lg = 24.0; // Bottom Sheets
  static const double xl = 32.0;
  static const double circle = 99.0; // Pills

  static final BorderRadius radiusSm = BorderRadius.circular(sm);
  static final BorderRadius radiusMd = BorderRadius.circular(md);
  static final BorderRadius radiusLg = BorderRadius.circular(lg);
  static final BorderRadius radiusXl = BorderRadius.circular(xl);
  static final BorderRadius radiusCircle = BorderRadius.circular(circle);
}

class SoloShadows {
  // Sombras discretas e funcionais

  static const BoxShadow shadowSm = BoxShadow(
    color: Color.fromRGBO(0, 0, 0, 0.05),
    offset: Offset(0, 1),
    blurRadius: 2,
  );

  static const BoxShadow shadowMd = BoxShadow(
    color: Color.fromRGBO(0, 0, 0, 0.08),
    offset: Offset(0, 4),
    blurRadius: 12,
    spreadRadius: -2,
  );

  static const List<BoxShadow> shadowCard = [shadowSm];

  static const List<BoxShadow> shadowButton = [
    BoxShadow(
      color: Color.fromRGBO(0, 0, 0, 0.1),
      offset: Offset(0, 4),
      blurRadius: 6,
    ),
  ];

  // Legado mapeado para shadowButton
  static const List<BoxShadow> shadowPetrol = shadowButton;
}

class SoloForteTheme {
  // Configuração Global de Design System

  static TextTheme _buildTextTheme(Color primaryColor, Color secondaryColor) {
    return TextTheme(
      displayLarge: GoogleFonts.inter(
        fontSize: SoloFontSizes.xxl,
        fontWeight: SoloFontWeights.bold,
        color: primaryColor,
      ),
      headlineMedium: GoogleFonts.inter(
        fontSize: 22.0,
        fontWeight: SoloFontWeights.semibold,
        color: primaryColor,
      ),
      titleMedium: GoogleFonts.inter(
        fontSize: SoloFontSizes.lg,
        fontWeight: SoloFontWeights.semibold,
        color: primaryColor,
      ),
      bodyLarge: GoogleFonts.inter(
        fontSize: SoloFontSizes.base,
        fontWeight: SoloFontWeights.regular,
        color: primaryColor,
      ),
      bodyMedium: GoogleFonts.inter(
        fontSize: SoloFontSizes.sm, // Ajustado para 14 no legado, mas ideal 16
        fontWeight: SoloFontWeights.regular,
        color: secondaryColor,
      ),
      labelSmall: GoogleFonts.inter(
        fontSize: SoloFontSizes.xs,
        fontWeight: SoloFontWeights.medium,
        color: secondaryColor,
        letterSpacing: 0.5,
      ),
    );
  }

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: SoloForteColors.primary,
      scaffoldBackgroundColor: SoloForteColors.backgroundLight,

      colorScheme: const ColorScheme.light(
        primary: SoloForteColors.primary,
        secondary: SoloForteColors.primaryDark,
        surface: SoloForteColors.surfaceLight,
        error: SoloForteColors.error,
        onPrimary: Colors.white,
        onSurface: SoloForteColors.textPrimary,
      ),

      textTheme: _buildTextTheme(
        SoloForteColors.textPrimary,
        SoloForteColors.textSecondary,
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: SoloForteColors.primary,
          foregroundColor: Colors.white,
          padding: SoloSpacing.paddingButton,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(SoloRadius.md),
          ),
          elevation: 0,
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: SoloSpacing.paddingInput,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(SoloRadius.md),
          borderSide: const BorderSide(color: SoloForteColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(SoloRadius.md),
          borderSide: const BorderSide(color: SoloForteColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(SoloRadius.md),
          borderSide: const BorderSide(
            color: SoloForteColors.primary,
            width: 2,
          ),
        ),
        labelStyle: TextStyle(
          color: SoloForteColors.textSecondary,
          fontSize: SoloFontSizes.sm,
        ),
      ),

      dividerTheme: const DividerThemeData(
        color: SoloForteColors.border,
        thickness: 1,
        space: 1,
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: SoloForteColors.primary,
      scaffoldBackgroundColor: SoloForteColors.backgroundDark,

      colorScheme: const ColorScheme.dark(
        primary: SoloForteColors.primary,
        secondary: SoloForteColors.accent,
        surface: SoloForteColors.surfaceDark,
        error: SoloForteColors.error,
        onPrimary: Colors.black, // Contraste no verde
        onSurface: SoloForteColors.textPrimaryDark,
      ),

      textTheme: _buildTextTheme(
        SoloForteColors.textPrimaryDark,
        SoloForteColors.textSecondaryDark,
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: SoloForteColors.primary,
          foregroundColor: Colors.black, // Contraste
          padding: SoloSpacing.paddingButton,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(SoloRadius.md),
          ),
          elevation: 0,
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: SoloForteColors.surfaceElevatedDark,
        contentPadding: SoloSpacing.paddingInput,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(SoloRadius.md),
          borderSide: const BorderSide(color: SoloForteColors.borderDark),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(SoloRadius.md),
          borderSide: const BorderSide(color: SoloForteColors.borderDark),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(SoloRadius.md),
          borderSide: const BorderSide(
            color: SoloForteColors.primary,
            width: 1.5,
          ),
        ),
        labelStyle: TextStyle(
          color: SoloForteColors.textSecondaryDark,
          fontSize: SoloFontSizes.sm,
        ),
      ),

      dividerTheme: const DividerThemeData(
        color: SoloForteColors.borderDark,
        thickness: 1,
        space: 1,
      ),
    );
  }
}
