# ⚫🟡 SoloForte Design System - Black & Gold
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
9. [Efeitos Especiais](#efeitos-especiais)
10. [Exemplo de Implementação](#exemplo-de-implementação)

---

## 🎨 Paleta de Cores

### Código Dart
```dart
class SoloForteColors {
  // OURO - CORES PRIMÁRIAS
  static const Color gold = Color(0xFFD4AF37);
  static const Color goldLight = Color(0xFFE8C547);
  static const Color goldDark = Color(0xFFC19B2F);
  static const Color bronze = Color(0xFFCD7F32);
  static const Color champagne = Color(0xFFF7E7CE);
  
  // PRETO E CINZA
  static const Color black = Color(0xFF000000);
  static const Color grayDark = Color(0xFF1A1A1A);
  static const Color grayMedium = Color(0xFF2D2D2D);
  static const Color gray = Color(0xFF404040);
  static const Color grayLight = Color(0xFFB8B8B8);
  static const Color white = Color(0xFFFFFFFF);
  
  // TEXTO
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB8B8B8);
  static const Color textTertiary = Color(0xFF808080);
  static const Color textOnLight = Color(0xFF1A1A1A);
  
  // ESTADO
  static const Color success = Color(0xFF10B981);
  static const Color error = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);
  static const Color info = Color(0xFFD4AF37);
  
  static const Color bgSuccess = Color(0xFFECFDF5);
  static const Color bgError = Color(0xFFFEF2F2);
  
  // BORDAS
  static const Color border = Color(0xFF404040);
  static const Color borderLight = Color(0xFF2D2D2D);
  static const Color borderGold = Color(0xFFD4AF37);
}
```

### Gradientes
```dart
class SoloForteGradients {
  // Gradiente Ouro
  static const LinearGradient gold = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFE8C547), Color(0xFFC19B2F)],
  );
  
  // Gradiente Preto
  static const LinearGradient black = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1A1A1A), Color(0xFF000000)],
  );
  
  // Gradiente Escuro
  static const LinearGradient dark = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF2D2D2D), Color(0xFF1A1A1A)],
  );
  
  // Gradiente Ouro → Preto
  static const LinearGradient goldBlack = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFD4AF37), Color(0xFF1A1A1A)],
  );
  
  // Gradiente Bronze
  static const LinearGradient bronze = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFCD7F32), Color(0xFFA0522D)],
  );
  
  // Background
  static const LinearGradient background = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF0A0A0A), Color(0xFF000000)],
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
  static const FontWeight bold = FontWeight.w700;
}
```

### Text Styles
```dart
class SoloTextStyles {
  static const TextStyle headingLarge = TextStyle(
    fontSize: 32.0,
    fontWeight: FontWeight.w600,
    color: Color(0xFFFFFFFF),
    height: 1.2,
  );
  
  static const TextStyle headingMedium = TextStyle(
    fontSize: 19.2,
    fontWeight: FontWeight.w600,
    color: Color(0xFFFFFFFF),
    height: 1.3,
  );
  
  // Label com ouro
  static const TextStyle label = TextStyle(
    fontSize: 12.0,
    fontWeight: FontWeight.w500,
    color: Color(0xFFD4AF37),
    letterSpacing: 1.0,
  );
  
  static const TextStyle body = TextStyle(
    fontSize: 15.2,
    fontWeight: FontWeight.w400,
    color: Color(0xFFFFFFFF),
  );
  
  static const TextStyle textGold = TextStyle(
    fontSize: 15.2,
    color: Color(0xFFD4AF37),
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
  // Sombras escuras (mais fortes)
  static const BoxShadow shadowSm = BoxShadow(
    color: Color.fromRGBO(0, 0, 0, 0.3),
    offset: Offset(0, 1),
    blurRadius: 3,
  );
  
  static const BoxShadow shadowMd = BoxShadow(
    color: Color.fromRGBO(0, 0, 0, 0.2),
    offset: Offset(0, 2),
    blurRadius: 8,
  );
  
  static const List<BoxShadow> shadowCard = [
    BoxShadow(
      color: Color.fromRGBO(0, 0, 0, 0.3),
      offset: Offset(0, 2),
      blurRadius: 8,
    ),
  ];
  
  // Sombra Dourada
  static const List<BoxShadow> shadowGold = [
    BoxShadow(
      color: Color.fromRGBO(212, 175, 55, 0.4),
      offset: Offset(0, 4),
      blurRadius: 12,
    ),
  ];
  
  // Gold Glow (Brilho Dourado)
  static const List<BoxShadow> glowGold = [
    BoxShadow(
      color: Color.fromRGBO(212, 175, 55, 0.3),
      offset: Offset(0, 0),
      blurRadius: 20,
    ),
  ];
}
```

---

## 🔘 Botões

### Botão Primário (Ouro)
```dart
Container(
  decoration: BoxDecoration(
    gradient: const LinearGradient(
      colors: [Color(0xFFE8C547), Color(0xFFC19B2F)],
    ),
    borderRadius: BorderRadius.circular(10),
    boxShadow: const [
      BoxShadow(
        color: Color.fromRGBO(212, 175, 55, 0.4),
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
    child: const Text(
      'Adicionar Visita',
      style: TextStyle(
        fontSize: 15.2,
        fontWeight: FontWeight.w600,
        color: Color(0xFF000000),
      ),
    ),
  ),
)
```

### Botão Preto com Borda Dourada
```dart
Container(
  decoration: BoxDecoration(
    gradient: const LinearGradient(
      colors: [Color(0xFF1A1A1A), Color(0xFF000000)],
    ),
    borderRadius: BorderRadius.circular(10),
    border: Border.all(color: const Color(0xFFD4AF37), width: 1),
    boxShadow: const [
      BoxShadow(
        color: Color.fromRGBO(0, 0, 0, 0.2),
        offset: Offset(0, 2),
        blurRadius: 8,
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
    child: const Text(
      'Preto com Ouro',
      style: TextStyle(
        fontSize: 15.2,
        fontWeight: FontWeight.w600,
        color: Color(0xFFD4AF37),
      ),
    ),
  ),
)
```

### Botão Bronze
```dart
Container(
  decoration: BoxDecoration(
    gradient: const LinearGradient(
      colors: [Color(0xFFCD7F32), Color(0xFFA0522D)],
    ),
    borderRadius: BorderRadius.circular(10),
    boxShadow: const [
      BoxShadow(
        color: Color.fromRGBO(205, 127, 50, 0.3),
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
    child: const Text(
      'Bronze',
      style: TextStyle(
        fontSize: 15.2,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
    ),
  ),
)
```

### Botão Outline Ouro
```dart
OutlinedButton(
  onPressed: () {},
  style: OutlinedButton.styleFrom(
    foregroundColor: const Color(0xFFD4AF37),
    side: const BorderSide(color: Color(0xFFD4AF37), width: 2),
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(10),
    ),
  ),
  child: const Text('Outline Ouro'),
)
```

### FAB (Floating Action Button) - Ouro
```dart
Container(
  width: 60,
  height: 60,
  decoration: BoxDecoration(
    gradient: const LinearGradient(
      colors: [Color(0xFFE8C547), Color(0xFFC19B2F)],
    ),
    borderRadius: BorderRadius.circular(30),
    boxShadow: const [
      BoxShadow(
        color: Color.fromRGBO(212, 175, 55, 0.4),
        offset: Offset(0, 4),
        blurRadius: 16,
      ),
      BoxShadow(
        color: Color.fromRGBO(212, 175, 55, 0.3),
        offset: Offset(0, 0),
        blurRadius: 20,
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
        color: Color(0xFF000000),
        size: 28,
      ),
    ),
  ),
)
```

---

## 🃏 Cards

### Card Padrão (Escuro)
```dart
Container(
  padding: const EdgeInsets.all(20),
  decoration: BoxDecoration(
    color: const Color(0xFF1A1A1A).withOpacity(0.95),
    borderRadius: BorderRadius.circular(12),
    border: Border.all(color: const Color(0xFF2D2D2D)),
    boxShadow: const [
      BoxShadow(
        color: Color.fromRGBO(0, 0, 0, 0.3),
        offset: Offset(0, 2),
        blurRadius: 8,
      ),
    ],
  ),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: const [
      Text(
        'Título',
        style: TextStyle(
          fontSize: 19.2,
          fontWeight: FontWeight.w600,
          color: Color(0xFFFFFFFF),
        ),
      ),
      SizedBox(height: 8),
      Text(
        'Descrição',
        style: TextStyle(
          fontSize: 15.2,
          color: Color(0xFFB8B8B8),
        ),
      ),
    ],
  ),
)
```

### Card Ouro (Destaque Máximo)
```dart
Container(
  padding: const EdgeInsets.all(30),
  decoration: BoxDecoration(
    gradient: const LinearGradient(
      colors: [Color(0xFFE8C547), Color(0xFFC19B2F)],
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
          color: Color(0xFF000000),
        ),
      ),
      SizedBox(height: 8),
      Text(
        '87%',
        style: TextStyle(
          fontSize: 48,
          fontWeight: FontWeight.w700,
          color: Color(0xFF000000),
        ),
      ),
    ],
  ),
)
```

### Card Preto com Borda Dourada
```dart
Container(
  padding: const EdgeInsets.all(20),
  decoration: BoxDecoration(
    gradient: const LinearGradient(
      colors: [Color(0xFF1A1A1A), Color(0xFF000000)],
    ),
    borderRadius: BorderRadius.circular(12),
    border: Border.all(color: const Color(0xFFD4AF37), width: 1),
  ),
  child: const Text(
    'Card Preto Premium',
    style: TextStyle(
      fontSize: 16,
      color: Color(0xFFD4AF37),
    ),
  ),
)
```

### Card com Acento Dourado (Barra Lateral)
```dart
Container(
  padding: const EdgeInsets.all(20),
  decoration: BoxDecoration(
    color: const Color(0xFF1A1A1A),
    borderRadius: BorderRadius.circular(12),
    border: const Border(
      left: BorderSide(color: Color(0xFFD4AF37), width: 4),
    ),
  ),
  child: const Text(
    'Card com acento',
    style: TextStyle(color: Colors.white),
  ),
)
```

### Card Métrica (Ouro)
```dart
Container(
  padding: const EdgeInsets.all(16),
  decoration: BoxDecoration(
    color: const Color(0xFFD4AF37).withOpacity(0.1),
    border: Border.all(color: const Color(0xFFD4AF37)),
    borderRadius: BorderRadius.circular(10),
  ),
  child: Column(
    children: const [
      Text(
        'CRESCIMENTO',
        style: TextStyle(
          fontSize: 12,
          letterSpacing: 1,
          color: Color(0xFFD4AF37),
        ),
      ),
      SizedBox(height: 8),
      Text(
        '+24%',
        style: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w700,
          color: Color(0xFFE8C547),
        ),
      ),
    ],
  ),
)
```

---

## 📝 Inputs

### TextField (Tema Escuro)
```dart
TextField(
  style: const TextStyle(color: Color(0xFFFFFFFF)),
  decoration: InputDecoration(
    labelText: 'Nome do Cliente',
    labelStyle: const TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w500,
      color: Color(0xFFD4AF37),
      letterSpacing: 1.0,
    ),
    hintText: 'Digite o nome',
    hintStyle: const TextStyle(color: Color(0xFF808080)),
    filled: true,
    fillColor: const Color(0xFF1A1A1A),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: Color(0xFF404040)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: Color(0xFF404040)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: Color(0xFFD4AF37), width: 2),
    ),
    contentPadding: const EdgeInsets.all(12),
  ),
)
```

### DropdownButton (Dourado)
```dart
Container(
  padding: const EdgeInsets.symmetric(horizontal: 12),
  decoration: BoxDecoration(
    color: const Color(0xFF1A1A1A),
    border: Border.all(color: const Color(0xFF404040)),
    borderRadius: BorderRadius.circular(8),
  ),
  child: DropdownButton<String>(
    value: 'Soja',
    isExpanded: true,
    underline: const SizedBox(),
    dropdownColor: const Color(0xFF1A1A1A),
    style: const TextStyle(color: Color(0xFFFFFFFF)),
    icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFFD4AF37)),
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

## ✨ Efeitos Especiais

### Gold Glow (Brilho Dourado)
```dart
Container(
  padding: const EdgeInsets.all(30),
  decoration: BoxDecoration(
    color: const Color(0xFF1A1A1A),
    borderRadius: BorderRadius.circular(12),
    boxShadow: const [
      BoxShadow(
        color: Color.fromRGBO(212, 175, 55, 0.3),
        offset: Offset(0, 0),
        blurRadius: 20,
      ),
    ],
  ),
  child: const Text(
    'Elemento com Gold Glow',
    style: TextStyle(color: Color(0xFFD4AF37)),
  ),
)
```

### Glow Pulse (Animação de Pulsação)
```dart
class GlowPulseWidget extends StatefulWidget {
  final Widget child;
  
  const GlowPulseWidget({Key? key, required this.child}) : super(key: key);

  @override
  State<GlowPulseWidget> createState() => _GlowPulseWidgetState();
}

class _GlowPulseWidgetState extends State<GlowPulseWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    
    _animation = Tween<double>(begin: 10.0, end: 20.0).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFD4AF37).withOpacity(0.3),
                offset: Offset.zero,
                blurRadius: _animation.value,
              ),
            ],
          ),
          child: widget.child,
        );
      },
    );
  }
}
```

### Divider com Gradiente Ouro
```dart
Container(
  height: 1,
  decoration: const BoxDecoration(
    gradient: LinearGradient(
      colors: [
        Colors.transparent,
        Color(0xFFD4AF37),
        Colors.transparent,
      ],
    ),
  ),
)
```

---

## 💡 Exemplo de Implementação Completa

### theme.dart
```dart
import 'package:flutter/material.dart';

class SoloForteTheme {
  static ThemeData get darkTheme {
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
        background: Color(0xFF000000),
      ),
      
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w700,
          color: Color(0xFFFFFFFF),
        ),
        headlineMedium: TextStyle(
          fontSize: 19.2,
          fontWeight: FontWeight.w600,
          color: Color(0xFFFFFFFF),
        ),
        bodyLarge: TextStyle(
          fontSize: 15.2,
          fontWeight: FontWeight.w400,
          color: Color(0xFFFFFFFF),
        ),
        bodyMedium: TextStyle(
          fontSize: 15.2,
          color: Color(0xFFB8B8B8),
        ),
      ),
      
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFD4AF37),
          foregroundColor: const Color(0xFF000000),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          elevation: 0,
        ),
      ),
      
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF1A1A1A),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF404040)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFD4AF37), width: 2),
        ),
        labelStyle: const TextStyle(color: Color(0xFFD4AF37)),
        contentPadding: const EdgeInsets.all(12),
      ),
      
      cardTheme: CardTheme(
        color: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Color(0xFF2D2D2D)),
        ),
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
      title: 'SoloForte Black & Gold',
      theme: SoloForteTheme.darkTheme,
      home: const HomePage(),
    );
  }
}
```

---

## 🎯 Quando Usar Cada Elemento

- **⚫ Preto (#1A1A1A)**: 90% da interface - backgrounds, cards, áreas de conteúdo
- **🟡 Ouro (#D4AF37)**: 10% em detalhes - botões, bordas, destaques, CTAs
- **🟤 Bronze (#CD7F32)**: Elementos secundários, variações, estados alternativos

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

## 💎 Regra 90/10

**90% Preto + 10% Ouro = Luxo Perfeito**

- Use preto para a maior parte da interface
- Reserve ouro APENAS para elementos importantes
- Detalhes curtos e estratégicos em ouro
- Nunca exagere no dourado

---

**Versão**: 1.0  
**Paleta**: Black & Gold Premium  
**Cor Principal**: Ouro (#D4AF37)  
**Ideal para**: Produtos premium, eventos VIP, marcas luxuosas
