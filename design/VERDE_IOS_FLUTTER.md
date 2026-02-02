# 🟢 SoloForte Design System - Verde iOS
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
```

### Gradientes
```dart
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
  static const double circle = 999.0; // Para botões circulares
  
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
  
  static const List<BoxShadow> shadowButton = [
    BoxShadow(
      color: Color.fromRGBO(52, 199, 89, 0.3),
      offset: Offset(0, 4),
      blurRadius: 12,
    ),
  ];
}
```

---

## 🔘 Botões

### Botão Primário (Verde)
```dart
ElevatedButton(
  onPressed: () {},
  style: ElevatedButton.styleFrom(
    backgroundColor: SoloForteColors.greenIOS,
    foregroundColor: Colors.white,
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(10),
    ),
    elevation: 0,
    shadowColor: SoloForteColors.greenIOS.withOpacity(0.3),
  ),
  child: const Text(
    'Adicionar Visita',
    style: TextStyle(
      fontSize: 15.2,
      fontWeight: FontWeight.w600,
    ),
  ),
)
```

### Botão Secundário
```dart
ElevatedButton(
  onPressed: () {},
  style: ElevatedButton.styleFrom(
    backgroundColor: const Color(0xFFE5E5E7),
    foregroundColor: const Color(0xFF86868B),
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
    ),
    elevation: 0,
  ),
  child: const Text('Cancelar'),
)
```

### Botão Outline
```dart
OutlinedButton(
  onPressed: () {},
  style: OutlinedButton.styleFrom(
    foregroundColor: SoloForteColors.textPrimary,
    side: const BorderSide(color: Color(0xFFD1D1D6)),
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(10),
    ),
  ),
  child: const Text('Ver Todos'),
)
```

### Botão Ícone
```dart
Container(
  width: 48,
  height: 48,
  decoration: BoxDecoration(
    gradient: const LinearGradient(
      colors: [Color(0xFF34C759), Color(0xFF2DA94D)],
    ),
    borderRadius: BorderRadius.circular(24),
    boxShadow: const [
      BoxShadow(
        color: Color.fromRGBO(52, 199, 89, 0.3),
        offset: Offset(0, 4),
        blurRadius: 12,
      ),
    ],
  ),
  child: IconButton(
    onPressed: () {},
    icon: const Icon(Icons.add, color: Colors.white),
  ),
)
```

### FAB (Floating Action Button)
```dart
FloatingActionButton(
  onPressed: () {},
  backgroundColor: SoloForteColors.greenIOS,
  elevation: 8,
  child: const Icon(Icons.print, size: 28),
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

### Card Verde (Destaque)
```dart
Container(
  padding: const EdgeInsets.all(30),
  decoration: BoxDecoration(
    gradient: const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF1C4532), Color(0xFF0F2419)],
    ),
    borderRadius: BorderRadius.circular(12),
  ),
  child: Column(
    children: [
      const Text(
        'EFICIÊNCIA DE VISITAS',
        style: TextStyle(
          fontSize: 13.6,
          letterSpacing: 1,
          color: Colors.white,
        ),
      ),
      const SizedBox(height: 8),
      const Text(
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

### Card Métrica
```dart
Container(
  padding: const EdgeInsets.all(16),
  decoration: BoxDecoration(
    color: const Color(0xFFE8F5E9),
    borderRadius: BorderRadius.circular(10),
  ),
  child: Column(
    children: [
      const Text(
        'CRESCIMENTO',
        style: TextStyle(
          fontSize: 12,
          letterSpacing: 0.5,
          color: Color(0xFF2E7D32),
        ),
      ),
      const SizedBox(height: 8),
      const Text(
        '+24%',
        style: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w600,
          color: Color(0xFF2E7D32),
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
      borderSide: const BorderSide(color: Color(0xFF34C759), width: 2),
    ),
    contentPadding: const EdgeInsets.all(12),
  ),
)
```

### DropdownButton
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
    icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF86868B)),
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
```

### main.dart
```dart
void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SoloForte',
      theme: SoloForteTheme.lightTheme,
      home: const HomePage(),
    );
  }
}
```

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

## 🎯 Princípios de Design

1. **Menos é Mais**: Remover elementos desnecessários
2. **Hierarquia Visual**: Títulos discretos, dados em destaque
3. **Feedback Instantâneo**: Animações suaves (200ms)
4. **Consistência iOS**: Seguir padrões nativos
5. **Mobile First**: Design para 480px primeiro

---

**Versão**: 1.0  
**Baseado em**: Apple Human Interface Guidelines  
**Cor Principal**: Verde iOS (#34C759)
