# SKILL: Relatório de Visita Técnica — Flutter/Dart  
  
> Skill de referência para construção do app de registro de visitas agronômicas  
> a campo em Flutter/Dart. Contexto: Brasil, mercado de defensivos e sementes,  
> técnicos e consultores do agronegócio. Design iOS/Apple minimalista.  
  
-----  
  
## 1. VISÃO GERAL DO APP  
  
**Nome:** Relatório de Visita Técnica    
**Framework:** Flutter (stable channel)    
**Linguagem:** Dart    
**Persistência:** SharedPreferences + sqflite (offline-first)    
**Exportação:** PDF via `pdf` + `printing` packages    
**Idioma:** Português Brasileiro (`pt_BR`)    
**Design:** iOS/Apple minimalista com `Cupertino` widgets quando aplicável    
**Plataformas alvo:** iOS e Android  
  
### pubspec.yaml — dependências essenciais  
  
```yaml  
dependencies:  
  flutter:  
    sdk: flutter  
  
  # Persistência  
  shared_preferences: ^2.2.2  
  sqflite: ^2.3.0  
  path: ^1.8.3  
  
  # PDF  
  pdf: ^3.10.7  
  printing: ^5.11.1  
  
  # Fotos  
  image_picker: ^1.0.7  
  image: ^4.1.3  
  flutter_image_compress: ^2.1.0  
  
  # GPS  
  geolocator: ^11.0.0  
  
  # Utilitários  
  intl: ^0.19.0  
  uuid: ^4.3.3  
  path_provider: ^2.1.2  
  
dev_dependencies:  
  flutter_test:  
    sdk: flutter  
  flutter_lints: ^3.0.0  
```  
  
-----  
  
## 2. ESTRUTURA DE PASTAS  
  
```  
lib/  
├── main.dart  
├── app.dart  
│  
├── core/  
│   ├── constants/  
│   │   ├── app_colors.dart  
│   │   ├── app_text_styles.dart  
│   │   └── app_strings.dart  
│   ├── theme/  
│   │   └── app_theme.dart  
│   └── utils/  
│       ├── date_utils.dart  
│       ├── format_utils.dart  
│       └── image_utils.dart  
│  
├── data/  
│   ├── models/  
│   │   ├── visita_model.dart  
│   │   ├── categoria_model.dart  
│   │   ├── problema_model.dart  
│   │   └── foto_model.dart  
│   ├── repositories/  
│   │   └── visita_repository.dart  
│   └── services/  
│       ├── storage_service.dart  
│       ├── gps_service.dart  
│       └── pdf_service.dart  
│  
├── presentation/  
│   ├── screens/  
│   │   ├── home_screen.dart  
│   │   ├── visita_screen.dart  
│   │   └── pdf_preview_screen.dart  
│   ├── widgets/  
│   │   ├── section_card.dart  
│   │   ├── form_field_row.dart  
│   │   ├── category_grid.dart  
│   │   ├── category_panel.dart  
│   │   ├── stage_selector.dart  
│   │   ├── attention_points.dart  
│   │   ├── photo_grid.dart  
│   │   ├── floating_camera_btn.dart  
│   │   └── save_indicator.dart  
│   └── providers/ (ou controllers/)  
│       └── visita_provider.dart  
│  
└── assets/  
    ├── images/  
    │   ├── doencas.png  
    │   ├── insetos.png  
    │   ├── ervas.png  
    │   ├── nutricional.png  
    │   ├── estresse.png  
    │   └── logo.png  
    └── fonts/  
```  
  
-----  
  
## 3. DESIGN SYSTEM — FLUTTER  
  
### 3.1 Paleta de Cores (`app_colors.dart`)  
  
```dart  
import 'package:flutter/material.dart';  
  
class AppColors {  
  // Primárias  
  static const Color blue       = Color(0xFF007AFF);  
  static const Color blueDark   = Color(0xFF0051D5);  
  static const Color white      = Color(0xFFFFFFFF);  
  static const Color grayLight  = Color(0xFFF5F5F7);  
  static const Color grayMedium = Color(0xFFE5E5E7);  
  
  // Texto  
  static const Color textPrimary   = Color(0xFF1D1D1F);  
  static const Color textSecondary = Color(0xFF86868B);  
  static const Color textTertiary  = Color(0xFFC7C7CC);  
  
  // Estado  
  static const Color green  = Color(0xFF34C759);  
  static const Color red    = Color(0xFFFF3B30);  
  static const Color orange = Color(0xFFFF9500);  
  static const Color yellow = Color(0xFFFFCC00);  
  
  // Bordas  
  static const Color border     = Color(0xFFD1D1D6);  
  static const Color borderSoft = Color(0xFFE5E5E7);  
  
  // Categorias  
  static const Color doenca    = Color(0xFFE53935);  
  static const Color insetos   = Color(0xFFF57C00);  
  static const Color ervas     = Color(0xFF388E3C);  
  static const Color nutrientes = Color(0xFF1565C0);  
  static const Color agua      = Color(0xFF0288D1);  
  
  // Background positivo/negativo  
  static const Color bgPositive = Color(0xFFE8F5E9);  
  static const Color bgNegative = Color(0xFFFFEBEE);  
}  
```  
  
### 3.2 Tipografia (`app_text_styles.dart`)  
  
```dart  
import 'package:flutter/material.dart';  
import 'app_colors.dart';  
  
class AppTextStyles {  
  static const String _fontFamily = '.SF Pro Text'; // iOS system font  
  
  static const TextStyle sectionTitle = TextStyle(  
    fontSize: 11,  
    fontWeight: FontWeight.w600,  
    letterSpacing: 0.5,  
    color: AppColors.textSecondary,  
  );  
  
  static const TextStyle label = TextStyle(  
    fontSize: 14,  
    fontWeight: FontWeight.w500,  
    color: AppColors.textPrimary,  
  );  
  
  static const TextStyle body = TextStyle(  
    fontSize: 15,  
    fontWeight: FontWeight.w400,  
    color: AppColors.textPrimary,  
  );  
  
  static const TextStyle placeholder = TextStyle(  
    fontSize: 15,  
    fontWeight: FontWeight.w400,  
    color: AppColors.textTertiary,  
  );  
  
  static const TextStyle highlight = TextStyle(  
    fontSize: 17,  
    fontWeight: FontWeight.w600,  
    color: AppColors.textPrimary,  
  );  
  
  static const TextStyle caption = TextStyle(  
    fontSize: 12,  
    fontWeight: FontWeight.w400,  
    color: AppColors.textSecondary,  
  );  
}  
```  
  
### 3.3 Tema (`app_theme.dart`)  
  
```dart  
import 'package:flutter/material.dart';  
import 'package:flutter/cupertino.dart';  
import '../constants/app_colors.dart';  
import '../constants/app_text_styles.dart';  
  
class AppTheme {  
  static ThemeData get theme => ThemeData(  
    useMaterial3: true,  
    colorScheme: ColorScheme.fromSeed(  
      seedColor: AppColors.blue,  
      brightness: Brightness.light,  
    ),  
    scaffoldBackgroundColor: AppColors.grayLight,  
    fontFamily: '.SF Pro Text',  
  
    // AppBar estilo iOS  
    appBarTheme: const AppBarTheme(  
      backgroundColor: Color(0xF2FFFFFF), // rgba(255,255,255,0.95)  
      elevation: 0,  
      scrolledUnderElevation: 0.5,  
      titleTextStyle: TextStyle(  
        fontSize: 17,  
        fontWeight: FontWeight.w600,  
        color: AppColors.textPrimary,  
      ),  
      iconTheme: IconThemeData(color: AppColors.blue),  
    ),  
  
    // Input decoration global  
    inputDecorationTheme: InputDecorationTheme(  
      filled: true,  
      fillColor: AppColors.white,  
      border: OutlineInputBorder(  
        borderRadius: BorderRadius.circular(10),  
        borderSide: const BorderSide(color: AppColors.border),  
      ),  
      enabledBorder: OutlineInputBorder(  
        borderRadius: BorderRadius.circular(10),  
        borderSide: const BorderSide(color: AppColors.border),  
      ),  
      focusedBorder: OutlineInputBorder(  
        borderRadius: BorderRadius.circular(10),  
        borderSide: const BorderSide(color: AppColors.blue, width: 1.5),  
      ),  
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),  
      hintStyle: AppTextStyles.placeholder,  
    ),  
  
    // ElevatedButton estilo iOS  
    elevatedButtonTheme: ElevatedButtonThemeData(  
      style: ElevatedButton.styleFrom(  
        backgroundColor: AppColors.blue,  
        foregroundColor: AppColors.white,  
        shape: RoundedRectangleBorder(  
          borderRadius: BorderRadius.circular(12),  
        ),  
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),  
        textStyle: const TextStyle(  
          fontSize: 15,  
          fontWeight: FontWeight.w600,  
        ),  
      ),  
    ),  
  );  
}  
```  
  
### 3.4 SectionCard Widget  
  
```dart  
class SectionCard extends StatelessWidget {  
  final String title;  
  final List<Widget> children;  
  final EdgeInsetsGeometry? padding;  
  
  const SectionCard({  
    super.key,  
    required this.title,  
    required this.children,  
    this.padding,  
  });  
  
  @override  
  Widget build(BuildContext context) {  
    return Container(  
      margin: const EdgeInsets.only(bottom: 12),  
      decoration: BoxDecoration(  
        color: Colors.white.withOpacity(0.95),  
        borderRadius: BorderRadius.circular(16),  
        boxShadow: [  
          BoxShadow(  
            color: Colors.black.withOpacity(0.06),  
            blurRadius: 8,  
            offset: const Offset(0, 2),  
          ),  
          BoxShadow(  
            color: Colors.black.withOpacity(0.03),  
            blurRadius: 2,  
            offset: const Offset(0, 1),  
          ),  
        ],  
      ),  
      child: Padding(  
        padding: padding ?? const EdgeInsets.all(20),  
        child: Column(  
          crossAxisAlignment: CrossAxisAlignment.start,  
          children: [  
            Text(  
              title.toUpperCase(),  
              style: AppTextStyles.sectionTitle,  
            ),  
            const SizedBox(height: 16),  
            ...children,  
          ],  
        ),  
      ),  
    );  
  }  
}  
```  
  
-----  
  
## 4. MÓDULO: DADOS DA VISITA  
  
### 4.1 Model (`visita_model.dart`)  
  
```dart  
class VisitaModel {  
  String id;  
  String produtor;  
  String propriedade;  
  DateTime? dataVisita;  
  double? area;  
  String cultivar;  
  DateTime? dataPlantio;  
  String estagio;  
  String observacoes;  
  String recomendacoes;  
  String tecnico;  
  String coordenadas;  
  String tipoOcorrencia; // 'sazonal' | 'permanente'  
  bool amostaSolo;  
  bool amostraPlanta;  
  bool amostraLaboratorio;  
  List<ProblemaModel> problemas;  
  DateTime createdAt;  
  DateTime updatedAt;  
  
  VisitaModel({  
    String? id,  
    this.produtor = '',  
    this.propriedade = '',  
    this.dataVisita,  
    this.area,  
    this.cultivar = '',  
    this.dataPlantio,  
    this.estagio = '',  
    this.observacoes = '',  
    this.recomendacoes = '',  
    this.tecnico = '',  
    this.coordenadas = '',  
    this.tipoOcorrencia = 'sazonal',  
    this.amostaSolo = false,  
    this.amostraPlanta = false,  
    this.amostraLaboratorio = false,  
    List<ProblemaModel>? problemas,  
    DateTime? createdAt,  
    DateTime? updatedAt,  
  })  : id = id ?? const Uuid().v4(),  
        problemas = problemas ?? [],  
        createdAt = createdAt ?? DateTime.now(),  
        updatedAt = updatedAt ?? DateTime.now();  
  
  // DAP calculado  
  int get dap {  
    if (dataVisita == null || dataPlantio == null) return 0;  
    final diff = dataVisita!.difference(dataPlantio!).inDays;  
    return diff < 0 ? 0 : diff;  
  }  
  
  Map<String, dynamic> toJson() => {  
    'id': id,  
    'produtor': produtor,  
    'propriedade': propriedade,  
    'dataVisita': dataVisita?.toIso8601String(),  
    'area': area,  
    'cultivar': cultivar,  
    'dataPlantio': dataPlantio?.toIso8601String(),  
    'estagio': estagio,  
    'observacoes': observacoes,  
    'recomendacoes': recomendacoes,  
    'tecnico': tecnico,  
    'coordenadas': coordenadas,  
    'tipoOcorrencia': tipoOcorrencia,  
    'amostaSolo': amostaSolo,  
    'amostraPlanta': amostraPlanta,  
    'amostraLaboratorio': amostraLaboratorio,  
    'problemas': problemas.map((p) => p.toJson()).toList(),  
    'createdAt': createdAt.toIso8601String(),  
    'updatedAt': updatedAt.toIso8601String(),  
  };  
  
  factory VisitaModel.fromJson(Map<String, dynamic> json) => VisitaModel(  
    id: json['id'],  
    produtor: json['produtor'] ?? '',  
    propriedade: json['propriedade'] ?? '',  
    dataVisita: json['dataVisita'] != null  
        ? DateTime.parse(json['dataVisita'])  
        : null,  
    area: json['area']?.toDouble(),  
    cultivar: json['cultivar'] ?? '',  
    dataPlantio: json['dataPlantio'] != null  
        ? DateTime.parse(json['dataPlantio'])  
        : null,  
    estagio: json['estagio'] ?? '',  
    observacoes: json['observacoes'] ?? '',  
    recomendacoes: json['recomendacoes'] ?? '',  
    tecnico: json['tecnico'] ?? '',  
    coordenadas: json['coordenadas'] ?? '',  
    tipoOcorrencia: json['tipoOcorrencia'] ?? 'sazonal',  
    amostaSolo: json['amostaSolo'] ?? false,  
    amostraPlanta: json['amostraPlanta'] ?? false,  
    amostraLaboratorio: json['amostraLaboratorio'] ?? false,  
    problemas: (json['problemas'] as List<dynamic>?)  
        ?.map((p) => ProblemaModel.fromJson(p))  
        .toList() ?? [],  
    createdAt: DateTime.parse(json['createdAt']),  
    updatedAt: DateTime.parse(json['updatedAt']),  
  );  
}  
```  
  
### 4.2 FormFieldRow Widget  
  
```dart  
class FormFieldRow extends StatelessWidget {  
  final String label;  
  final Widget child;  
  
  const FormFieldRow({  
    super.key,  
    required this.label,  
    required this.child,  
  });  
  
  @override  
  Widget build(BuildContext context) {  
    return Padding(  
      padding: const EdgeInsets.only(bottom: 12),  
      child: Column(  
        crossAxisAlignment: CrossAxisAlignment.start,  
        children: [  
          Text(label, style: AppTextStyles.label),  
          const SizedBox(height: 6),  
          child,  
        ],  
      ),  
    );  
  }  
}  
```  
  
### 4.3 DAP Badge Widget  
  
```dart  
class DapBadge extends StatelessWidget {  
  final int dap;  
  
  const DapBadge({super.key, required this.dap});  
  
  @override  
  Widget build(BuildContext context) {  
    return Container(  
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),  
      decoration: BoxDecoration(  
        color: dap > 0  
            ? AppColors.green.withOpacity(0.12)  
            : AppColors.grayLight,  
        borderRadius: BorderRadius.circular(10),  
        border: Border.all(  
          color: dap > 0  
              ? AppColors.green.withOpacity(0.3)  
              : AppColors.border,  
        ),  
      ),  
      child: Row(  
        mainAxisSize: MainAxisSize.min,  
        children: [  
          Text(  
            'DAP: ',  
            style: AppTextStyles.caption,  
          ),  
          Text(  
            '$dap dias',  
            style: TextStyle(  
              fontSize: 14,  
              fontWeight: FontWeight.w600,  
              color: dap > 0 ? AppColors.green : AppColors.textSecondary,  
            ),  
          ),  
        ],  
      ),  
    );  
  }  
}  
```  
  
### 4.4 Input numérico — limitação de 7 dígitos  
  
```dart  
TextFormField(  
  keyboardType: TextInputType.number,  
  inputFormatters: [  
    FilteringTextInputFormatter.digitsOnly,  
    LengthLimitingTextInputFormatter(7),  
  ],  
  decoration: const InputDecoration(  
    hintText: '0',  
    suffixText: 'ha',  
  ),  
)  
```  
  
-----  
  
## 5. MÓDULO: ESTÁDIO FENOLÓGICO  
  
### 5.1 Dados dos estádios  
  
```dart  
class EstagioSoja {  
  final String codigo;  
  final String nome;  
  final String descricao;  
  final String emoji;  
  final String dapEsperado;  
  final EstagioTipo tipo;  
  final List<String> alertas;  
  
  const EstagioSoja({  
    required this.codigo,  
    required this.nome,  
    required this.descricao,  
    required this.emoji,  
    required this.dapEsperado,  
    required this.tipo,  
    required this.alertas,  
  });  
}  
  
enum EstagioTipo { vegetativo, reprodutivo }  
  
const List<EstagioSoja> estagiosSoja = [  
  EstagioSoja(  
    codigo: 'VE',  
    nome: 'Emergência',  
    descricao: 'Cotilédones acima do solo',  
    emoji: '🌱',  
    dapEsperado: '5–7 dias',  
    tipo: EstagioTipo.vegetativo,  
    alertas: [  
      'Monitorar tombamento (Rhizoctonia, Pythium)',  
      'Verificar estande e uniformidade de emergência',  
      'Checar pragas de solo (corós, lagarta-elasmo)',  
    ],  
  ),  
  EstagioSoja(  
    codigo: 'VC',  
    nome: 'Cotilédones',  
    descricao: 'Cotilédones completamente abertos',  
    emoji: '🌿',  
    dapEsperado: '7–10 dias',  
    tipo: EstagioTipo.vegetativo,  
    alertas: [  
      'Iniciar monitoramento de pragas',  
      'Verificar nodulação nas raízes',  
    ],  
  ),  
  EstagioSoja(  
    codigo: 'V1',  
    nome: '1ª Trifoliolada',  
    descricao: 'Primeiro nó com folha trifoliolada aberta',  
    emoji: '🍃',  
    dapEsperado: '10–14 dias',  
    tipo: EstagioTipo.vegetativo,  
    alertas: [  
      'Início de monitoramento de percevejos',  
      'Aplicar herbicida pré-emergente se necessário',  
      'Verificar deficiência de ferro (clorose ferruginosa)',  
    ],  
  ),  
  EstagioSoja(  
    codigo: 'V2',  
    nome: '2ª Trifoliolada',  
    descricao: 'Segundo nó com folha trifoliolada aberta',  
    emoji: '🍃',  
    dapEsperado: '14–20 dias',  
    tipo: EstagioTipo.vegetativo,  
    alertas: [  
      'Monitorar lagarta-da-soja',  
      'Avaliar necessidade de herbicida pós-emergente',  
    ],  
  ),  
  EstagioSoja(  
    codigo: 'V3',  
    nome: '3ª Trifoliolada',  
    descricao: 'Terceiro nó com folha trifoliolada aberta',  
    emoji: '🍃',  
    dapEsperado: '20–28 dias',  
    tipo: EstagioTipo.vegetativo,  
    alertas: [  
      'Monitorar oídio em condições de baixa umidade',  
      'Verificar deficiência de manganês',  
    ],  
  ),  
  EstagioSoja(  
    codigo: 'V4',  
    nome: '4ª Trifoliolada',  
    descricao: 'Quarto nó com folha trifoliolada aberta',  
    emoji: '🌳',  
    dapEsperado: '28–35 dias',  
    tipo: EstagioTipo.vegetativo,  
    alertas: [  
      'Aplicar herbicida pós-emergente antes de V5',  
      'Monitorar tripes e mosca-branca',  
    ],  
  ),  
  EstagioSoja(  
    codigo: 'V5',  
    nome: '5ª Trifoliolada',  
    descricao: 'Quinto nó com folha trifoliolada aberta',  
    emoji: '🌳',  
    dapEsperado: '35–42 dias',  
    tipo: EstagioTipo.vegetativo,  
    alertas: [  
      'Último momento para herbicida pós-emergente',  
      'Monitorar percevejo-marrom e percevejo-verde',  
    ],  
  ),  
  EstagioSoja(  
    codigo: 'R1',  
    nome: 'Início do Florescimento',  
    descricao: 'Uma flor aberta em qualquer nó',  
    emoji: '🌸',  
    dapEsperado: '45–55 dias',  
    tipo: EstagioTipo.reprodutivo,  
    alertas: [  
      'Pico de demanda hídrica — atenção ao estresse',  
      'Monitorar ferrugem asiática (Phakopsora pachyrhizi)',  
      'Aplicar fungicida protetor se necessário',  
      'Atenção ao ataque de percevejo-marrom',  
    ],  
  ),  
  EstagioSoja(  
    codigo: 'R2',  
    nome: 'Floração Plena',  
    descricao: 'Flor aberta em um dos dois nós superiores',  
    emoji: '🌺',  
    dapEsperado: '50–60 dias',  
    tipo: EstagioTipo.reprodutivo,  
    alertas: [  
      'Monitorar mancha alvo e antracnose',  
      'Evitar aplicações no horário de voo das abelhas',  
      'Monitorar percevejo — nível de dano 1 por pano',  
    ],  
  ),  
  EstagioSoja(  
    codigo: 'R3',  
    nome: 'Vagens com 1 cm',  
    descricao: 'Vagem com 1 cm nos 4 nós superiores',  
    emoji: '🫛',  
    dapEsperado: '55–65 dias',  
    tipo: EstagioTipo.reprodutivo,  
    alertas: [  
      'Período crítico — dano de percevejo reduz enchimento',  
      'Monitorar lagarta-da-soja (nível de dano: 20 lagartas/m)',  
      'Avaliar necessidade de segunda aplicação de fungicida',  
    ],  
  ),  
  EstagioSoja(  
    codigo: 'R4',  
    nome: 'Vagens com 2 cm',  
    descricao: 'Vagem com 2 cm nos 4 nós superiores',  
    emoji: '🫛',  
    dapEsperado: '60–70 dias',  
    tipo: EstagioTipo.reprodutivo,  
    alertas: [  
      'Monitorar percevejo com rigor',  
      'Aplicar inseticida se > 2 percevejos por pano',  
    ],  
  ),  
  EstagioSoja(  
    codigo: 'R5.1',  
    nome: 'Início do Enchimento de Grãos',  
    descricao: 'Grão perceptível ao tato nas vagens superiores',  
    emoji: '🌾',  
    dapEsperado: '65–80 dias',  
    tipo: EstagioTipo.reprodutivo,  
    alertas: [  
      'Máxima demanda hídrica — irrigar se disponível',  
      'Percevejo: dano irreversível nesse estádio',  
      'Monitorar helmintosporiose e mancha-alvo',  
    ],  
  ),  
  EstagioSoja(  
    codigo: 'R5.3',  
    nome: '50% do Enchimento',  
    descricao: 'Grãos com 50% do tamanho final',  
    emoji: '🌾',  
    dapEsperado: '80–90 dias',  
    tipo: EstagioTipo.reprodutivo,  
    alertas: [  
      'Monitorar DFC — doenças de final de ciclo',  
      'Reduzir pressão de percevejo para <1 por pano',  
    ],  
  ),  
  EstagioSoja(  
    codigo: 'R5.5',  
    nome: '100% do Enchimento',  
    descricao: 'Grãos com tamanho final',  
    emoji: '🌾',  
    dapEsperado: '90–100 dias',  
    tipo: EstagioTipo.reprodutivo,  
    alertas: [  
      'Início da desfolha natural',  
      'Monitorar podridão de vagens em alta umidade',  
    ],  
  ),  
  EstagioSoja(  
    codigo: 'R6',  
    nome: 'Grãos Totalmente Formados',  
    descricao: 'Grãos verdes preenchem completamente a cavidade da vagem',  
    emoji: '🟡',  
    dapEsperado: '100–110 dias',  
    tipo: EstagioTipo.reprodutivo,  
    alertas: [  
      'Monitorar deiscência precoce',  
      'Evitar aplicações — resíduo nos grãos',  
    ],  
  ),  
  EstagioSoja(  
    codigo: 'R7',  
    nome: 'Início da Maturação',  
    descricao: 'Uma vagem com cor de maturação normal na haste',  
    emoji: '🟠',  
    dapEsperado: '110–120 dias',  
    tipo: EstagioTipo.reprodutivo,  
    alertas: [  
      'Verificar uniformidade de maturação',  
      'Estimar data de colheita (R8 = 7–14 dias após R7)',  
      'Avaliar perdas potenciais de colhedora',  
    ],  
  ),  
  EstagioSoja(  
    codigo: 'R8',  
    nome: 'Maturação Plena',  
    descricao: '95% das vagens com cor de maturação',  
    emoji: '🟤',  
    dapEsperado: '120–135 dias',  
    tipo: EstagioTipo.reprodutivo,  
    alertas: [  
      'Umidade dos grãos: ideal 14% para colheita',  
      'Risco de deiscência de vagens se houver atraso',  
      'Agendar colhedora com urgência',  
    ],  
  ),  
];  
```  
  
### 5.2 StageSelector Widget  
  
```dart  
class StageSelector extends StatelessWidget {  
  final String? selectedStage;  
  final ValueChanged<String?> onChanged;  
  
  const StageSelector({  
    super.key,  
    required this.selectedStage,  
    required this.onChanged,  
  });  
  
  @override  
  Widget build(BuildContext context) {  
    return DropdownButtonFormField<String>(  
      value: selectedStage?.isEmpty ?? true ? null : selectedStage,  
      hint: const Text('Selecione o estádio'),  
      isExpanded: true,  
      items: estagiosSoja.map((e) {  
        return DropdownMenuItem(  
          value: e.codigo,  
          child: Text('${e.codigo} — ${e.nome}'),  
        );  
      }).toList(),  
      onChanged: onChanged,  
      decoration: InputDecoration(  
        border: OutlineInputBorder(  
          borderRadius: BorderRadius.circular(10),  
        ),  
      ),  
    );  
  }  
}  
```  
  
### 5.3 AttentionPoints Widget  
  
```dart  
class AttentionPoints extends StatelessWidget {  
  final EstagioSoja estagio;  
  
  const AttentionPoints({super.key, required this.estagio});  
  
  @override  
  Widget build(BuildContext context) {  
    return Container(  
      padding: const EdgeInsets.all(14),  
      decoration: BoxDecoration(  
        color: AppColors.yellow.withOpacity(0.08),  
        borderRadius: BorderRadius.circular(12),  
        border: Border.all(  
          color: AppColors.yellow.withOpacity(0.3),  
        ),  
      ),  
      child: Column(  
        crossAxisAlignment: CrossAxisAlignment.start,  
        children: [  
          const Row(  
            children: [  
              Text('⚠️', style: TextStyle(fontSize: 14)),  
              SizedBox(width: 6),  
              Text(  
                'PONTOS DE ATENÇÃO',  
                style: AppTextStyles.sectionTitle,  
              ),  
            ],  
          ),  
          const SizedBox(height: 10),  
          ...estagio.alertas.map((alerta) => Padding(  
            padding: const EdgeInsets.only(bottom: 6),  
            child: Row(  
              crossAxisAlignment: CrossAxisAlignment.start,  
              children: [  
                Container(  
                  margin: const EdgeInsets.only(top: 6, right: 8),  
                  width: 5,  
                  height: 5,  
                  decoration: const BoxDecoration(  
                    color: AppColors.textSecondary,  
                    shape: BoxShape.circle,  
                  ),  
                ),  
                Expanded(  
                  child: Text(alerta, style: AppTextStyles.body),  
                ),  
              ],  
            ),  
          )),  
        ],  
      ),  
    );  
  }  
}  
```  
  
-----  
  
## 6. MÓDULO: CATEGORIAS DE PROBLEMAS  
  
### 6.1 Model de categoria  
  
```dart  
enum CategoriaId { doenca, insetos, ervas, nutrientes, agua }  
  
class CategoriaModel {  
  final CategoriaId id;  
  final String nome;  
  final Color cor;  
  final String asset;  
  bool ativa;  
  
  CategoriaModel({  
    required this.id,  
    required this.nome,  
    required this.cor,  
    required this.asset,  
    this.ativa = false,  
  });  
}  
  
final List<CategoriaModel> categorias = [  
  CategoriaModel(  
    id: CategoriaId.doenca,  
    nome: 'Doença',  
    cor: AppColors.doenca,  
    asset: 'assets/images/doencas.png',  
  ),  
  CategoriaModel(  
    id: CategoriaId.insetos,  
    nome: 'Insetos',  
    cor: AppColors.insetos,  
    asset: 'assets/images/insetos.png',  
  ),  
  CategoriaModel(  
    id: CategoriaId.ervas,  
    nome: 'Ervas daninhas',  
    cor: AppColors.ervas,  
    asset: 'assets/images/ervas.png',  
  ),  
  CategoriaModel(  
    id: CategoriaId.nutrientes,  
    nome: 'Nutrientes',  
    cor: AppColors.nutrientes,  
    asset: 'assets/images/nutricional.png',  
  ),  
  CategoriaModel(  
    id: CategoriaId.agua,  
    nome: 'Estresse Hídrico',  
    cor: AppColors.agua,  
    asset: 'assets/images/estresse.png',  
  ),  
];  
```  
  
### 6.2 Model de problema  
  
```dart  
class ProblemaModel {  
  String id;  
  CategoriaId categoria;  
  String problema;  
  String severidade; // 'leve' | 'medio' | 'alto'  
  double? areaAfetada; // percentual  
  String recomendacao;  
  String produto;  
  List<FotoModel> fotos;  
  
  ProblemaModel({  
    String? id,  
    required this.categoria,  
    this.problema = '',  
    this.severidade = '',  
    this.areaAfetada,  
    this.recomendacao = '',  
    this.produto = '',  
    List<FotoModel>? fotos,  
  })  : id = id ?? const Uuid().v4(),  
        fotos = fotos ?? [];  
  
  Map<String, dynamic> toJson() => {  
    'id': id,  
    'categoria': categoria.name,  
    'problema': problema,  
    'severidade': severidade,  
    'areaAfetada': areaAfetada,  
    'recomendacao': recomendacao,  
    'produto': produto,  
    'fotos': fotos.map((f) => f.toJson()).toList(),  
  };  
  
  factory ProblemaModel.fromJson(Map<String, dynamic> json) => ProblemaModel(  
    id: json['id'],  
    categoria: CategoriaId.values.firstWhere(  
      (c) => c.name == json['categoria'],  
    ),  
    problema: json['problema'] ?? '',  
    severidade: json['severidade'] ?? '',  
    areaAfetada: json['areaAfetada']?.toDouble(),  
    recomendacao: json['recomendacao'] ?? '',  
    produto: json['produto'] ?? '',  
    fotos: (json['fotos'] as List<dynamic>?)  
        ?.map((f) => FotoModel.fromJson(f))  
        .toList() ?? [],  
  );  
}  
```  
  
### 6.3 Opções por categoria (constantes)  
  
```dart  
class ProblemasOptions {  
  static const Map<CategoriaId, List<String>> options = {  
    CategoriaId.doenca: [  
      'Ferrugem Asiática (Phakopsora pachyrhizi)',  
      'Mancha Alvo (Corynespora cassiicola)',  
      'Oídio (Erysiphe diffusa)',  
      'Mela / Rizoctoniose (Rhizoctonia solani)',  
      'Podridão Vermelha da Raiz (Fusarium solani)',  
      'Cancro da Haste (Diaporthe aspalathi)',  
      'DFC — Doenças de Final de Ciclo',  
      'Vírus do Mosaico',  
      'Outro',  
    ],  
    CategoriaId.insetos: [  
      'Percevejo-marrom (Euschistus heros)',  
      'Percevejo-verde (Nezara viridula)',  
      'Percevejo-pequeno (Piezodorus guildinii)',  
      'Lagarta-da-soja (Anticarsia gemmatalis)',  
      'Lagarta-falsa-medideira (Chrysodeixis includens)',  
      'Helicoverpa (Helicoverpa armigera)',  
      'Mosca-branca (Bemisia tabaci)',  
      'Tripes (Caliothrips phaseoli)',  
      'Ácaro-rajado (Tetranychus urticae)',  
      'Tamanduá-da-soja (Sternechus subsignatus)',  
      'Broca-das-axilas (Crocidosema aporema)',  
      'Corós (Phyllophaga sp.)',  
      'Outro',  
    ],  
    CategoriaId.ervas: [  
      'Capim-amargoso (Digitaria insularis)',  
      'Capim-colchão (Digitaria horizontalis)',  
      'Buva (Conyza spp.)',  
      'Caruru (Amaranthus hybridus)',  
      'Trapoeraba (Commelina benghalensis)',  
      'Corda-de-viola (Ipomoea spp.)',  
      'Falsa-serralha (Emilia sonchifolia)',  
      'Leiteiro (Euphorbia heterophylla)',  
      'Picão-preto (Bidens pilosa)',  
      'Outro',  
    ],  
    CategoriaId.nutrientes: [  
      'Deficiência de Nitrogênio (N)',  
      'Deficiência de Fósforo (P)',  
      'Deficiência de Potássio (K)',  
      'Deficiência de Enxofre (S)',  
      'Deficiência de Cálcio (Ca)',  
      'Deficiência de Magnésio (Mg)',  
      'Deficiência de Boro (B)',  
      'Deficiência de Manganês (Mn)',  
      'Deficiência de Ferro (Fe)',  
      'Deficiência de Zinco (Zn)',  
      'Toxidez de Alumínio',  
      'Outro',  
    ],  
    CategoriaId.agua: [  
      'Déficit hídrico (seca)',  
      'Excesso hídrico (encharcamento)',  
      'Veranico (seca temporária)',  
      'Compactação do solo',  
      'Outro',  
    ],  
  };  
}  
```  
  
### 6.4 CategoryGrid Widget  
  
```dart  
class CategoryGrid extends StatelessWidget {  
  final List<CategoriaModel> categorias;  
  final ValueChanged<CategoriaId> onToggle;  
  
  const CategoryGrid({  
    super.key,  
    required this.categorias,  
    required this.onToggle,  
  });  
  
  @override  
  Widget build(BuildContext context) {  
    return GridView.count(  
      crossAxisCount: 5,  
      shrinkWrap: true,  
      physics: const NeverScrollableScrollPhysics(),  
      mainAxisSpacing: 8,  
      crossAxisSpacing: 8,  
      children: categorias.map((cat) {  
        return GestureDetector(  
          onTap: () => onToggle(cat.id),  
          child: AnimatedContainer(  
            duration: const Duration(milliseconds: 200),  
            decoration: BoxDecoration(  
              color: cat.ativa  
                  ? cat.cor.withOpacity(0.1)  
                  : Colors.transparent,  
              borderRadius: BorderRadius.circular(12),  
              border: Border.all(  
                color: cat.ativa ? cat.cor : AppColors.border,  
                width: cat.ativa ? 1.5 : 1,  
              ),  
            ),  
            child: Column(  
              mainAxisAlignment: MainAxisAlignment.center,  
              children: [  
                Image.asset(cat.asset, width: 32, height: 32),  
                const SizedBox(height: 4),  
                Text(  
                  cat.nome,  
                  style: TextStyle(  
                    fontSize: 9,  
                    color: cat.ativa ? cat.cor : AppColors.textSecondary,  
                    fontWeight: cat.ativa  
                        ? FontWeight.w600  
                        : FontWeight.w400,  
                  ),  
                  textAlign: TextAlign.center,  
                  maxLines: 2,  
                ),  
              ],  
            ),  
          ),  
        );  
      }).toList(),  
    );  
  }  
}  
```  
  
-----  
  
## 7. MÓDULO: FOTOS  
  
### 7.1 FotoModel  
  
```dart  
class FotoModel {  
  String id;  
  CategoriaId categoria;  
  String path; // caminho no sistema de arquivos  
  DateTime capturedAt;  
  
  FotoModel({  
    String? id,  
    required this.categoria,  
    required this.path,  
    DateTime? capturedAt,  
  })  : id = id ?? const Uuid().v4(),  
        capturedAt = capturedAt ?? DateTime.now();  
  
  Map<String, dynamic> toJson() => {  
    'id': id,  
    'categoria': categoria.name,  
    'path': path,  
    'capturedAt': capturedAt.toIso8601String(),  
  };  
  
  factory FotoModel.fromJson(Map<String, dynamic> json) => FotoModel(  
    id: json['id'],  
    categoria: CategoriaId.values.firstWhere(  
      (c) => c.name == json['categoria'],  
    ),  
    path: json['path'],  
    capturedAt: DateTime.parse(json['capturedAt']),  
  );  
}  
```  
  
### 7.2 ImageService — captura e compressão  
  
```dart  
import 'package:image_picker/image_picker.dart';  
import 'package:flutter_image_compress/flutter_image_compress.dart';  
import 'package:path_provider/path_provider.dart';  
import 'package:path/path.dart' as p;  
import 'dart:io';  
  
class ImageService {  
  static final _picker = ImagePicker();  
  
  static Future<String?> captureFromCamera() async {  
    final XFile? file = await _picker.pickImage(  
      source: ImageSource.camera,  
      imageQuality: 70,  
      maxWidth: 1200,  
      maxHeight: 1200,  
    );  
    if (file == null) return null;  
    return await _compressAndSave(file.path);  
  }  
  
  static Future<String?> pickFromGallery() async {  
    final XFile? file = await _picker.pickImage(  
      source: ImageSource.gallery,  
      imageQuality: 70,  
      maxWidth: 1200,  
      maxHeight: 1200,  
    );  
    if (file == null) return null;  
    return await _compressAndSave(file.path);  
  }  
  
  static Future<String> _compressAndSave(String sourcePath) async {  
    final dir = await getApplicationDocumentsDirectory();  
    final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';  
    final targetPath = p.join(dir.path, 'visita_fotos', fileName);  
  
    // Garantir pasta  
    await Directory(p.dirname(targetPath)).create(recursive: true);  
  
    await FlutterImageCompress.compressAndGetFile(  
      sourcePath,  
      targetPath,  
      quality: 70,  
      minWidth: 800,  
      minHeight: 800,  
    );  
  
    return targetPath;  
  }  
  
  static Future<void> deletePhoto(String path) async {  
    final file = File(path);  
    if (await file.exists()) await file.delete();  
  }  
}  
```  
  
### 7.3 PhotoGrid Widget  
  
```dart  
class PhotoGrid extends StatelessWidget {  
  final List<FotoModel> fotos;  
  final VoidCallback onAdd;  
  final ValueChanged<FotoModel> onRemove;  
  final ValueChanged<FotoModel> onTap;  
  
  const PhotoGrid({  
    super.key,  
    required this.fotos,  
    required this.onAdd,  
    required this.onRemove,  
    required this.onTap,  
  });  
  
  @override  
  Widget build(BuildContext context) {  
    return Wrap(  
      spacing: 8,  
      runSpacing: 8,  
      children: [  
        ...fotos.map((foto) => _PhotoThumbnail(  
          foto: foto,  
          onTap: () => onTap(foto),  
          onRemove: () => onRemove(foto),  
        )),  
        _AddPhotoButton(onTap: onAdd),  
      ],  
    );  
  }  
}  
  
class _PhotoThumbnail extends StatelessWidget {  
  final FotoModel foto;  
  final VoidCallback onTap;  
  final VoidCallback onRemove;  
  
  const _PhotoThumbnail({  
    required this.foto,  
    required this.onTap,  
    required this.onRemove,  
  });  
  
  @override  
  Widget build(BuildContext context) {  
    return Stack(  
      children: [  
        GestureDetector(  
          onTap: onTap,  
          child: ClipRRect(  
            borderRadius: BorderRadius.circular(8),  
            child: Image.file(  
              File(foto.path),  
              width: 80,  
              height: 80,  
              fit: BoxFit.cover,  
            ),  
          ),  
        ),  
        Positioned(  
          top: 2,  
          right: 2,  
          child: GestureDetector(  
            onTap: onRemove,  
            child: Container(  
              width: 20,  
              height: 20,  
              decoration: const BoxDecoration(  
                color: AppColors.red,  
                shape: BoxShape.circle,  
              ),  
              child: const Icon(  
                Icons.close,  
                size: 12,  
                color: Colors.white,  
              ),  
            ),  
          ),  
        ),  
      ],  
    );  
  }  
}  
  
class _AddPhotoButton extends StatelessWidget {  
  final VoidCallback onTap;  
  
  const _AddPhotoButton({required this.onTap});  
  
  @override  
  Widget build(BuildContext context) {  
    return GestureDetector(  
      onTap: onTap,  
      child: Container(  
        width: 80,  
        height: 80,  
        decoration: BoxDecoration(  
          border: Border.all(  
            color: AppColors.border,  
            width: 1.5,  
            style: BorderStyle.solid,  
          ),  
          borderRadius: BorderRadius.circular(8),  
        ),  
        child: const Column(  
          mainAxisAlignment: MainAxisAlignment.center,  
          children: [  
            Icon(Icons.camera_alt, color: AppColors.textTertiary, size: 24),  
            SizedBox(height: 4),  
            Text(  
              'Foto',  
              style: TextStyle(  
                fontSize: 11,  
                color: AppColors.textTertiary,  
              ),  
            ),  
          ],  
        ),  
      ),  
    );  
  }  
}  
```  
  
-----  
  
## 8. MÓDULO: GPS  
  
```dart  
import 'package:geolocator/geolocator.dart';  
  
class GpsService {  
  static Future<String?> getCurrentLocation() async {  
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();  
    if (!serviceEnabled) return null;  
  
    LocationPermission permission = await Geolocator.checkPermission();  
    if (permission == LocationPermission.denied) {  
      permission = await Geolocator.requestPermission();  
      if (permission == LocationPermission.denied) return null;  
    }  
    if (permission == LocationPermission.deniedForever) return null;  
  
    try {  
      final Position pos = await Geolocator.getCurrentPosition(  
        desiredAccuracy: LocationAccuracy.high,  
        timeLimit: const Duration(seconds: 10),  
      );  
      return '${pos.latitude.toStringAsFixed(6)}, '  
             '${pos.longitude.toStringAsFixed(6)}';  
    } catch (_) {  
      return null;  
    }  
  }  
  
  static String getMapsUrl(String coordenadas) {  
    return 'https://maps.google.com/?q=$coordenadas';  
  }  
}  
```  
  
-----  
  
## 9. PERSISTÊNCIA  
  
### StorageService com SharedPreferences  
  
```dart  
import 'package:shared_preferences/shared_preferences.dart';  
import 'dart:convert';  
  
class StorageService {  
  static const String _key = 'relatorio_visita_atual';  
  
  static Future<void> save(VisitaModel visita) async {  
    final prefs = await SharedPreferences.getInstance();  
    await prefs.setString(_key, jsonEncode(visita.toJson()));  
  }  
  
  static Future<VisitaModel?> load() async {  
    final prefs = await SharedPreferences.getInstance();  
    final json = prefs.getString(_key);  
    if (json == null) return null;  
    return VisitaModel.fromJson(jsonDecode(json));  
  }  
  
  static Future<void> clear() async {  
    final prefs = await SharedPreferences.getInstance();  
    await prefs.remove(_key);  
  }  
}  
```  
  
### Histórico com sqflite  
  
```dart  
import 'package:sqflite/sqflite.dart';  
import 'package:path/path.dart';  
  
class VisitaRepository {  
  static Database? _db;  
  
  static Future<Database> get db async {  
    _db ??= await _initDb();  
    return _db!;  
  }  
  
  static Future<Database> _initDb() async {  
    final path = join(await getDatabasesPath(), 'visitas.db');  
    return openDatabase(  
      path,  
      version: 1,  
      onCreate: (db, version) async {  
        await db.execute('''  
          CREATE TABLE visitas (  
            id TEXT PRIMARY KEY,  
            data TEXT NOT NULL,  
            produtor TEXT,  
            propriedade TEXT,  
            estagio TEXT,  
            json TEXT NOT NULL  
          )  
        ''');  
      },  
    );  
  }  
  
  static Future<void> insert(VisitaModel visita) async {  
    final database = await db;  
    await database.insert(  
      'visitas',  
      {  
        'id': visita.id,  
        'data': visita.dataVisita?.toIso8601String() ?? '',  
        'produtor': visita.produtor,  
        'propriedade': visita.propriedade,  
        'estagio': visita.estagio,  
        'json': jsonEncode(visita.toJson()),  
      },  
      conflictAlgorithm: ConflictAlgorithm.replace,  
    );  
  }  
  
  static Future<List<VisitaModel>> getAll() async {  
    final database = await db;  
    final maps = await database.query(  
      'visitas',  
      orderBy: 'data DESC',  
    );  
    return maps  
        .map((m) => VisitaModel.fromJson(jsonDecode(m['json'] as String)))  
        .toList();  
  }  
  
  static Future<void> delete(String id) async {  
    final database = await db;  
    await database.delete('visitas', where: 'id = ?', whereArgs: [id]);  
  }  
}  
```  
  
-----  
  
## 10. EXPORTAÇÃO PDF  
  
```dart  
import 'package:pdf/pdf.dart';  
import 'package:pdf/widgets.dart' as pw;  
import 'package:printing/printing.dart';  
import 'dart:io';  
  
class PdfService {  
  static Future<void> generateAndShare(VisitaModel visita) async {  
    final doc = pw.Document();  
  
    // Cores PDF  
    final pdfBlue = PdfColor.fromHex('#007AFF');  
    final pdfGreen = PdfColor.fromHex('#34C759');  
    final pdfText = PdfColor.fromHex('#1D1D1F');  
    final pdfGray = PdfColor.fromHex('#86868B');  
  
    // Página 1: Capa  
    doc.addPage(pw.Page(  
      pageFormat: PdfPageFormat.a4,  
      build: (pw.Context context) {  
        return pw.Column(  
          crossAxisAlignment: pw.CrossAxisAlignment.start,  
          children: [  
            pw.Container(  
              width: double.infinity,  
              padding: const pw.EdgeInsets.all(24),  
              decoration: pw.BoxDecoration(  
                color: pdfBlue,  
                borderRadius: pw.BorderRadius.circular(12),  
              ),  
              child: pw.Column(  
                crossAxisAlignment: pw.CrossAxisAlignment.start,  
                children: [  
                  pw.Text(  
                    'RELATÓRIO DE VISITA TÉCNICA',  
                    style: pw.TextStyle(  
                      color: PdfColors.white,  
                      fontSize: 10,  
                      letterSpacing: 1,  
                    ),  
                  ),  
                  pw.SizedBox(height: 8),  
                  pw.Text(  
                    visita.produtor,  
                    style: pw.TextStyle(  
                      color: PdfColors.white,  
                      fontSize: 22,  
                      fontWeight: pw.FontWeight.bold,  
                    ),  
                  ),  
                  pw.Text(  
                    visita.propriedade,  
                    style: pw.TextStyle(  
                      color: PdfColors.white.shade(0.8),  
                      fontSize: 14,  
                    ),  
                  ),  
                ],  
              ),  
            ),  
            // ... demais seções  
          ],  
        );  
      },  
    ));  
  
    // Páginas por categoria ativa  
    for (final problema in visita.problemas) {  
      doc.addPage(pw.Page(  
        pageFormat: PdfPageFormat.a4,  
        build: (context) => _buildCategoriaPage(problema, visita),  
      ));  
    }  
  
    // Compartilhar/Imprimir  
    await Printing.sharePdf(  
      bytes: await doc.save(),  
      filename: 'relatorio_${visita.produtor}_'  
                '${visita.dataVisita?.toIso8601String().substring(0, 10)}.pdf',  
    );  
  }  
  
  static pw.Widget _buildCategoriaPage(  
    ProblemaModel problema,  
    VisitaModel visita,  
  ) {  
    return pw.Column(  
      crossAxisAlignment: pw.CrossAxisAlignment.start,  
      children: [  
        pw.Text(  
          problema.categoria.name.toUpperCase(),  
          style: pw.TextStyle(  
            fontSize: 10,  
            letterSpacing: 0.5,  
            color: PdfColor.fromHex('#86868B'),  
          ),  
        ),  
        pw.SizedBox(height: 12),  
        pw.Text(  
          problema.problema,  
          style: pw.TextStyle(  
            fontSize: 18,  
            fontWeight: pw.FontWeight.bold,  
          ),  
        ),  
        // fotos, recomendações, etc.  
      ],  
    );  
  }  
}  
```  
  
-----  
  
## 11. FLOATING BUTTON — CÂMERA  
  
```dart  
class FloatingCameraButton extends StatelessWidget {  
  final CategoriaModel? categoriaAtiva;  
  final VoidCallback onPressed;  
  
  const FloatingCameraButton({  
    super.key,  
    required this.categoriaAtiva,  
    required this.onPressed,  
  });  
  
  @override  
  Widget build(BuildContext context) {  
    if (categoriaAtiva == null) return const SizedBox.shrink();  
  
    return Positioned(  
      bottom: 30,  
      right: 16,  
      child: GestureDetector(  
        onTap: onPressed,  
        child: AnimatedContainer(  
          duration: const Duration(milliseconds: 200),  
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),  
          decoration: BoxDecoration(  
            gradient: LinearGradient(  
              colors: [AppColors.green, Color(0xFF248A3D)],  
              begin: Alignment.topLeft,  
              end: Alignment.bottomRight,  
            ),  
            borderRadius: BorderRadius.circular(28),  
            boxShadow: [  
              BoxShadow(  
                color: AppColors.green.withOpacity(0.4),  
                blurRadius: 16,  
                offset: const Offset(0, 4),  
              ),  
            ],  
          ),  
          child: Row(  
            mainAxisSize: MainAxisSize.min,  
            children: [  
              const Icon(Icons.camera_alt, color: Colors.white, size: 20),  
              const SizedBox(width: 8),  
              Column(  
                crossAxisAlignment: CrossAxisAlignment.start,  
                mainAxisSize: MainAxisSize.min,  
                children: [  
                  const Text(  
                    'Próxima foto:',  
                    style: TextStyle(  
                      color: Colors.white70,  
                      fontSize: 10,  
                    ),  
                  ),  
                  Text(  
                    categoriaAtiva!.nome,  
                    style: const TextStyle(  
                      color: Colors.white,  
                      fontSize: 13,  
                      fontWeight: FontWeight.w600,  
                    ),  
                  ),  
                ],  
              ),  
            ],  
          ),  
        ),  
      ),  
    );  
  }  
}  
```  
  
-----  
  
## 12. REGRAS DE NEGÓCIO CRÍTICAS  
  
1. **DAP nunca negativo** — se `dataPlantio > dataVisita`, exibir aviso vermelho e retornar 0  
1. **Área — máximo 7 dígitos** — usar `LengthLimitingTextInputFormatter(7)`  
1. **Foto obrigatória** — alertar via `SnackBar` se categoria ativa não tem foto ao gerar PDF  
1. **GPS opcional** — nunca bloquear geração de PDF por falta de coordenadas  
1. **Compressão obrigatória** — nunca salvar imagem sem passar pelo `ImageService`  
1. **Limpeza com confirmação** — sempre usar `showCupertinoDialog` antes de limpar dados  
1. **PDF offline** — o package `pdf` funciona 100% sem internet  
1. **Cultivar livre** — campo de texto livre, sem lista fixa  
1. **Auto-save** — chamar `StorageService.save()` a cada mudança de campo via listener  
1. **Localização pt_BR** — inicializar `intl` com `initializeDateFormatting('pt_BR')`  
  
-----  
  
## 13. LOCALIZAÇÃO E FORMATAÇÃO  
  
```dart  
// main.dart  
import 'package:intl/date_symbol_data_local.dart';  
import 'package:flutter_localizations/flutter_localizations.dart';  
  
void main() async {  
  WidgetsFlutterBinding.ensureInitialized();  
  await initializeDateFormatting('pt_BR', null);  
  runApp(const App());  
}  
  
// App widget  
MaterialApp(  
  locale: const Locale('pt', 'BR'),  
  supportedLocales: const [Locale('pt', 'BR')],  
  localizationsDelegates: const [  
    GlobalMaterialLocalizations.delegate,  
    GlobalWidgetsLocalizations.delegate,  
    GlobalCupertinoLocalizations.delegate,  
  ],  
  ...  
)  
  
// Formatação de data  
String formatDate(DateTime? date) {  
  if (date == null) return '—';  
  return DateFormat('dd/MM/yyyy', 'pt_BR').format(date);  
}  
  
// Formatação de área  
String formatArea(double? area) {  
  if (area == null) return '—';  
  return NumberFormat('#,##0.00', 'pt_BR').format(area);  
}  
```  
  
-----  
  
## 14. FLUXO DO USUÁRIO (telas)  
  
```  
HomeScreen  
└── Lista de relatórios anteriores (sqflite)  
    └── Botão "+ Nova Visita"  
  
VisitaScreen  
├── AppBar: "Relatório de Visita" | [Lixeira] [PDF]  
├── SectionCard: Informações da Visita  
│   ├── Produtor, Propriedade, Data, Área, Cultivar  
│   ├── Data de Plantio → DAP badge automático  
├── SectionCard: Estádio Fenológico  
│   ├── StageSelector (dropdown)  
│   ├── Card do estádio selecionado (ícone + descrição)  
│   └── AttentionPoints (alertas automáticos)  
├── SectionCard: Categorias  
│   └── CategoryGrid (5 ícones toggleáveis)  
├── [painéis das categorias ativas — AnimatedSize]  
│   └── CategoryPanel (problema, severidade, área, produto, fotos)  
├── SectionCard: Observações  
├── SectionCard: Recomendações  
├── SectionCard: Responsável  
├── SectionCard: Localização GPS  
├── SectionCard: Tipo de Ocorrência (radio)  
└── SectionCard: Amostras (checkboxes)  
  
FloatingCameraButton (overlay)  
└── Vinculado à categoria ativa  
  
PdfPreviewScreen  
└── Preview do PDF gerado  
    └── Botão compartilhar / imprimir  
```  
  
-----  
  
## 15. CHECKLIST DE QUALIDADE  
  
- [ ] App funciona 100% sem internet (WiFi off, dados off)  
- [ ] Dados persistem após fechar o app  
- [ ] DAP calcula corretamente e nunca é negativo  
- [ ] Todos os dropdowns têm dados agronômicos completos  
- [ ] Fotos são comprimidas antes de salvar  
- [ ] PDF contém todas as informações preenchidas  
- [ ] PDF funciona sem internet  
- [ ] Layout responsivo em iPhone SE (375pt) e iPad (768pt)  
- [ ] Inputs numéricos limitados a 7 dígitos  
- [ ] Limpeza de dados exige confirmação via dialog  
- [ ] GPS trata permissão negada e timeout  
- [ ] Localização pt_BR aplicada em datas e números  
- [ ] Auto-save funciona a cada campo alterado  
- [ ] Histórico salvo no sqflite ao finalizar relatório  
  
-----  
  
*Skill criado para uso com Claude. Contexto: Nutrien/Soloforte, Flutter/Dart, Brasil. Fevereiro/2026.*  
