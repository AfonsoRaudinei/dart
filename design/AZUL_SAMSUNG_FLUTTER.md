# 🔵 SoloForte Design System - Azul Samsung
## Guia de Implementação Flutter/Dart

---

## 📋 Índice
1. [Paleta de Cores](#paleta-de-cores)
2. [Tipografia](#tipografia)
3. [Espaçamentos](#espaçamentos)
4. [Border Radius](#border-radius)
5. [Sombras](#sombras)
6. [Botões](#botões)
7. [Cards](#cards)
8. [Inputs](#inputs)
9. [Exemplo de Implementação](#exemplo-de-implementação)

---

## 🎨 Paleta de Cores

### Código Dart
```dart
class SoloForteColors {
  // AZUL SAMSUNG - CORES PRIMÁRIAS
  static const Color blueSamsung = Color(0xFF1B6EE0);
  static const Color blueDark = Color(0xFF0F5FC9);
  static const Color blueLight = Color(0xFF2E7FED);
  static const Color bluePetrol = Color(0xFF0D7C8C);
  static const Color bluePetrolLight = Color(0xFF1A9BAD);
  static const Color cyanBright = Color(0xFF00BCD4);
  static const Color skyBlue = Color(0xFF0EA5E9);
  
  // BÁSICAS
  static const Color white = Color(0xFFFFFFFF);
  static const Color grayLight = Color(0xFFF5F7FA);
  
  // TEXTO
  static const Color textPrimary = Color(0xFF1D1D1F);
  static const Color textSecondary = Color(0xFF86868B);
  static const Color textTertiary = Color(0xFFC7C7CC);
  
  // ESTADO
  static const Color success = Color(0xFF10B981);
  static const Color error = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);
  static const Color info = Color(0xFF1B6EE0);
  
  static const Color bgSuccess = Color(0xFFECFDF5);
  static const Color bgError = Color(0xFFFEF2F2);
  static const Color bgWarning = Color(0xFFFFFBEB);
  static const Color bgInfo = Color(0xFFEFF6FF);
  
  static const Color textSuccess = Color(0xFF047857);
  static const Color textError = Color(0xFFDC2626);
  static const Color textWarning = Color(0xFFD97706);
  static const Color textInfo = Color(0xFF1E40AF);
  
  // BORDAS
  static const Color border = Color(0xFFD1D1D6);
  static const Color borderLight = Color(0xFFE5E5E7);
}
```

### Gradientes
```dart
class SoloForteGradients {
  // Samsung → Petróleo
  static const LinearGradient primary = LinearGradient(
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
    colors: [Color(0xFFF5F7FA), Color(0xFFE8EEF5)],
  );
}
```

---

## ✍️ Tipografia

### Font Family
```dart
// System Font (iOS/Android nativo)
static const String fontFamily = 'SF Pro Text'; // iOS
// Ou usar default do sistema
```

### Tamanhos
```dart
class SoloFontSizes {
  static const double xs = 12.0;      // 0.75em
  static const double sm = 13.6;      // 0.85em
  static const double base = 15.2;    // 0.95em
  static const double lg = 17.6;      // 1.1em
  static const double xl = 19.2;      // 1.2em
  static const double xxl = 32.0;     // 2em
}
```

### Pesos
```dart
class SoloFontWeights {
  static const FontWeight regular = FontWeight.w400;
  static const FontWeight medium = FontWeight.w500;
  static const FontWeight semibold = FontWeight.w600;
}
```

### Text Styles
```dart
class SoloTextStyles {
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
}
```

---

## 📐 Espaçamentos

```dart
class SoloSpacing {
  static const double xs = 8.0;
  static const double sm = 12.0;
  static const double md = 16.0;
  static const double lg = 20.0;
  static const double xl = 24.0;
  static const double xxl = 30.0;
  
  // Padding específico
  static const EdgeInsets paddingCard = EdgeInsets.all(20.0);
  static const EdgeInsets paddingInput = EdgeInsets.all(12.0);
  static const EdgeInsets paddingButton = EdgeInsets.symmetric(
    horizontal: 16.0,
    vertical: 10.0,
  );
}
```

---

## 🔲 Border Radius

```dart
class SoloRadius {
  static const double sm = 6.0;
  static const double md = 8.0;
  static const double lg = 10.0;
  static const double xl = 12.0;
  static const double circle = 999.0;
  
  // BorderRadius prontos
  static final BorderRadius radiusSm = BorderRadius.circular(6.0);
  static final BorderRadius radiusMd = BorderRadius.circular(8.0);
  static final BorderRadius radiusLg = BorderRadius.circular(10.0);
  static final BorderRadius radiusXl = BorderRadius.circular(12.0);
}
```

---

## ☁️ Sombras

```dart
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
  
  // Sombra Azul Samsung
  static const List<BoxShadow> shadowButton = [
    BoxShadow(
      color: Color.fromRGBO(27, 110, 224, 0.3),
      offset: Offset(0, 4),
      blurRadius: 12,
    ),
  ];
  
  // Sombra Petróleo
  static const List<BoxShadow> shadowPetrol = [
    BoxShadow(
      color: Color.fromRGBO(13, 124, 140, 0.3),
      offset: Offset(0, 4),
      blurRadius: 12,
    ),
  ];
}
```

---

## 🔘 Botões

### Botão Primário (Azul Samsung)
```dart
ElevatedButton(
  onPressed: () {},
  style: ElevatedButton.styleFrom(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(10),
    ),
    elevation: 0,
  ).copyWith(
    backgroundColor: MaterialStateProperty.all(Colors.transparent),
    shadowColor: MaterialStateProperty.all(
      const Color(0xFF1B6EE0).withOpacity(0.3),
    ),
  ),
  child: Ink(
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [Color(0xFF1B6EE0), Color(0xFF0D7C8C)],
      ),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Container(
      alignment: Alignment.center,
      constraints: const BoxConstraints(minHeight: 40),
      child: const Text(
        'Adicionar Visita',
        style: TextStyle(
          fontSize: 15.2,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    ),
  ),
)
```

### Botão Petróleo
```dart
Container(
  decoration: BoxDecoration(
    gradient: const LinearGradient(
      colors: [Color(0xFF0D7C8C), Color(0xFF0A5A66)],
    ),
    borderRadius: BorderRadius.circular(10),
    boxShadow: const [
      BoxShadow(
        color: Color.fromRGBO(13, 124, 140, 0.3),
        offset: Offset(0, 4),
        blurRadius: 12,
      ),
    ],
  ),
  child: ElevatedButton(
    onPressed: () {},
    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.transparent,
      shadowColor: Colors.transparent,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
    ),
    child: const Text('Petróleo'),
  ),
)
```

### Botão Outline Azul
```dart
OutlinedButton(
  onPressed: () {},
  style: OutlinedButton.styleFrom(
    foregroundColor: const Color(0xFF1B6EE0),
    side: const BorderSide(color: Color(0xFF1B6EE0), width: 2),
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(10),
    ),
  ),
  child: const Text('Outline Azul'),
)
```

### FAB (Floating Action Button)
```dart
Container(
  width: 60,
  height: 60,
  decoration: BoxDecoration(
    gradient: const LinearGradient(
      colors: [Color(0xFF1B6EE0), Color(0xFF0D7C8C)],
    ),
    borderRadius: BorderRadius.circular(30),
    boxShadow: const [
      BoxShadow(
        color: Color.fromRGBO(27, 110, 224, 0.4),
        offset: Offset(0, 4),
        blurRadius: 16,
      ),
    ],
  ),
  child: Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: () {},
      borderRadius: BorderRadius.circular(30),
      child: const Icon(
        Icons.print,
        color: Colors.white,
        size: 28,
      ),
    ),
  ),
)
```

---

## 🃏 Cards

### Card Padrão
```dart
Container(
  padding: const EdgeInsets.all(20),
  decoration: BoxDecoration(
    color: Colors.white.withOpacity(0.95),
    borderRadius: BorderRadius.circular(12),
    boxShadow: const [
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
    ],
  ),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('Título', style: SoloTextStyles.headingMedium),
      const SizedBox(height: 8),
      Text('Descrição', style: SoloTextStyles.body),
    ],
  ),
)
```

### Card Azul Samsung
```dart
Container(
  padding: const EdgeInsets.all(30),
  decoration: BoxDecoration(
    gradient: const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF1B6EE0), Color(0xFF0D7C8C)],
    ),
    borderRadius: BorderRadius.circular(12),
  ),
  child: Column(
    children: const [
      Text(
        'EFICIÊNCIA DE VISITAS',
        style: TextStyle(
          fontSize: 13.6,
          letterSpacing: 1,
          color: Colors.white,
        ),
      ),
      SizedBox(height: 8),
      Text(
        '87%',
        style: TextStyle(
          fontSize: 48,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    ],
  ),
)
```

### Card Petróleo
```dart
Container(
  padding: const EdgeInsets.all(20),
  decoration: BoxDecoration(
    gradient: const LinearGradient(
      colors: [Color(0xFF0D7C8C), Color(0xFF0A5A66)],
    ),
    borderRadius: BorderRadius.circular(12),
  ),
  child: const Text(
    'Card Petróleo',
    style: TextStyle(color: Colors.white, fontSize: 16),
  ),
)
```

### Card Métrica (Azul)
```dart
Container(
  padding: const EdgeInsets.all(16),
  decoration: BoxDecoration(
    color: const Color(0xFFEFF6FF),
    borderRadius: BorderRadius.circular(10),
  ),
  child: Column(
    children: const [
      Text(
        'CRESCIMENTO',
        style: TextStyle(
          fontSize: 12,
          letterSpacing: 0.5,
          color: Color(0xFF1E40AF),
        ),
      ),
      SizedBox(height: 8),
      Text(
        '+24%',
        style: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w600,
          color: Color(0xFF1B6EE0),
        ),
      ),
    ],
  ),
)
```

---

## 📝 Inputs

### TextField
```dart
TextField(
  decoration: InputDecoration(
    labelText: 'Nome do Cliente',
    labelStyle: const TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w500,
      color: Color(0xFF86868B),
      letterSpacing: 0.5,
    ),
    hintText: 'Digite o nome',
    hintStyle: const TextStyle(color: Color(0xFFC7C7CC)),
    filled: true,
    fillColor: Colors.white,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: Color(0xFFD1D1D6)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: Color(0xFFD1D1D6)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: Color(0xFF1B6EE0), width: 2),
    ),
    contentPadding: const EdgeInsets.all(12),
  ),
)
```

### DropdownButton (Azul)
```dart
Container(
  padding: const EdgeInsets.symmetric(horizontal: 12),
  decoration: BoxDecoration(
    color: Colors.white,
    border: Border.all(color: const Color(0xFFD1D1D6)),
    borderRadius: BorderRadius.circular(8),
  ),
  child: DropdownButton<String>(
    value: 'Soja',
    isExpanded: true,
    underline: const SizedBox(),
    icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF1B6EE0)),
    items: ['Soja', 'Milho', 'Café'].map((String value) {
      return DropdownMenuItem<String>(
        value: value,
        child: Text(value),
      );
    }).toList(),
    onChanged: (String? newValue) {},
  ),
)
```

---

## 💡 Exemplo de Implementação Completa

### theme.dart
```dart
import 'package:flutter/material.dart';

class SoloForteTheme {
  static ThemeData get lightTheme {
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
      
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFD1D1D6)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF1B6EE0), width: 2),
        ),
        contentPadding: const EdgeInsets.all(12),
      ),
    );
  }
}
```

---

## 🎯 Quando Usar Cada Cor

- **🔵 Azul Samsung (#1B6EE0)**: Botões principais, links, ações primárias
- **🔷 Azul Petróleo (#0D7C8C)**: Headers especiais, cards de destaque, variação
- **🔹 Sky Blue (#0EA5E9)**: Notificações, informações, badges
- **🌊 Azul Escuro**: Backgrounds especiais, modo noturno

---

## 📱 Responsividade

```dart
class SoloBreakpoints {
  static const double mobile = 480;
  static const double tablet = 768;
  static const double desktop = 1024;
}

// Uso
bool isMobile = MediaQuery.of(context).size.width < SoloBreakpoints.mobile;
```

---

**Versão**: 1.0  
**Paleta**: Azuis Samsung e Petróleo  
**Cor Principal**: Azul Samsung (#1B6EE0)
