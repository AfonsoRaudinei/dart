# Prompt para Criação de Aplicativo de Relatório de Visitas Agrícolas em Flutter/Dart

## Contexto
Criar um aplicativo mobile em Flutter/Dart para registro de visitas técnicas agrícolas, seguindo rigorosamente os princípios de design iOS/Apple com estética minimalista, profissional e funcional.

## Filosofia de Design - "Menos é Mais"

### Paleta de Cores Principal
```dart
// Verde iOS (cor primária SoloForte)
Color verde = Color(0xFF34C759);
Color verdeEscuro = Color(0xFF28A745);

// Backgrounds
Color bgPrincipal = Color(0xFFF5F5F7);
Color bgSecundario = Color(0xFFFFFFFF);
Color bgCard = Color(0xFFFFFFFF).withOpacity(0.95);

// Textos
Color textoPrincipal = Color(0xFF1D1D1F);
Color textoSecundario = Color(0xFF86868B);
Color textoTerciario = Color(0xFFC7C7CC);

// Bordas
Color borda = Color(0xFFD1D1D6);
Color bordaSuave = Color(0xFFE5E5E7);

// Estados
Color sucesso = Color(0xFF34C759);
Color erro = Color(0xFFFF3B30);
Color bgSucesso = Color(0xFFE8F5E9);
Color bgErro = Color(0xFFFFEBEE);
```

### Tipografia
```dart
TextStyle titleStyle = TextStyle(
  fontFamily: 'SF Pro Text',
  fontSize: 13,
  fontWeight: FontWeight.w500,
  letterSpacing: 0.5,
  color: textoSecundario,
);

TextStyle normalStyle = TextStyle(
  fontFamily: 'SF Pro Text',
  fontSize: 15,
  fontWeight: FontWeight.w400,
  color: textoPrincipal,
);

TextStyle valorStyle = TextStyle(
  fontFamily: 'SF Pro Text',
  fontSize: 17,
  fontWeight: FontWeight.w600,
  color: textoPrincipal,
);
```

### Espaçamentos
```dart
double paddingCard = 20;
double paddingInput = 12;
double marginEntreCards = 16;
double radiusCard = 12;
double radiusInput = 8;
double radiusBotao = 10;
```

## Estrutura do Aplicativo

### 1. Tela Principal - Formulário de Visita

#### Seções (Cards com glassmorphism sutil):

**A. Informações da Visita**
- Produtor (TextField)
- Propriedade (TextField)
- Data (DatePicker iOS style)
- Área em hectares (NumberInput, max 7 dígitos)
- Cultivar (TextField com sugestões)
- Data de Plantio (DatePicker)
- **Cálculo automático DAP** (Days After Planting) em badge verde

**B. Estádio Fenológico**
- Dropdown iOS style com estágios:
  - VE, VC, V1-V5 (Vegetativo)
  - R1-R8 (Reprodutivo)
- Card de visualização do estágio selecionado:
  - Ícone grande centralizado
  - Nome do estágio
  - Descrição técnica
  - Badge com DAP esperado
  - Lista de "⚠️ Pontos de Atenção" específicos

**C. Categorias de Ocorrência**
Grid horizontal com 5 categorias (círculos com ícones):
```dart
// Categorias clicáveis
1. Doenças (🦠 vermelho suave)
2. Insetos (🐛 laranja suave)  
3. Ervas Daninhas (🌿 verde suave)
4. Nutrientes (💊 azul suave)
5. Água/Estresse (💧 azul escuro suave)
```

**Comportamento**: 
- Ao tocar em uma categoria, ela fica "ativa" (borda verde, escala 1.05)
- Botão flutuante aparece com a categoria ativa
- Permite múltiplas categorias simultaneamente

**D. Problemas Identificados** (dinâmico)
Para cada categoria ativa, criar card expansível:
```dart
Card {
  - Título da categoria
  - TextField: Nome do problema
  - Slider: Severidade (0-100%)
  - Galeria de fotos horizontal
  - Botão: "+ Adicionar Foto"
  - Botão discreto: "Remover problema" (ícone lixeira)
}
```

**E. Galeria Completa de Fotos**
- Grid 2 colunas
- Thumbnails com categoria em badge
- Tap para visualizar fullscreen
- Swipe para deletar

**F. Configurações de PDF**
```dart
Card minimalista {
  - Qualidade: [Baixa | Média ✓ | Alta]
  - Fotos/Página: [1 ✓ | 2 | 3]
  - Estimativa de tamanho: "~2.5 MB"
}
```

**G. Observações** (TextField multiline)

**H. Recomendações** (TextField multiline)

**I. Responsável Técnico** (TextField)

**J. Localização**
- Campo readonly com coordenadas
- Botão: "📍 Definir localização atual" (GPS)

**K. Tipo de Ocorrência**
Radio buttons iOS style:
- ( ) Sazonal (padrão)
- ( ) Permanente

**L. Amostras**
Checkbox iOS style:
- ☐ Amostra de solo coletada

### 2. Componentes Especiais

#### Botão Flutuante de Câmera (sempre visível)
```dart
FloatingActionButton {
  position: bottom-right (30px, 30px)
  size: 60x60
  borderRadius: 30 (círculo perfeito)
  gradient: LinearGradient(verde, verdeEscuro)
  shadow: elevation 8
  
  Conteúdo:
  - Ícone 📷 grande
  - Badge com categoria ativa
}
```

**Comportamento ao clicar**:
1. Abre câmera nativa
2. Captura foto
3. Comprime automaticamente
4. Adiciona à categoria ativa
5. Mostra preview rápido
6. Salva em localStorage

#### Header Bar (opcional, tipo Cupertino)
```dart
AppBar {
  backgroundColor: transparent blur
  leading: IconButton("🗑️ Limpar dados")
  title: "Relatório de Visita"
  actions: [
    IconButton("PDF"),
    IconButton("🖨️ Imprimir")
  ]
}
```

### 3. Funcionalidades Críticas

#### Persistência Local
```dart
// Usar shared_preferences ou Hive
- Auto-save a cada alteração (debounce 1s)
- Indicador discreto: "✓ Salvo" (fade in/out)
- Recuperação automática ao reabrir app
```

#### Cálculo DAP Automático
```dart
int calcularDAP(DateTime plantio) {
  return DateTime.now().difference(plantio).inDays;
}

// Atualizar badge em tempo real
```

#### Gerenciamento de Fotos
```dart
// Usar image_picker + image package
1. Capturar foto (camera ou galeria)
2. Comprimir para qualidade média (60-70%)
3. Converter para base64 ou salvar path
4. Gerar thumbnail 150x150
5. Associar à categoria específica
6. Permitir exclusão individual
```

#### Geolocalização
```dart
// Usar geolocator package
Future<void> getLocation() async {
  Position position = await Geolocator.getCurrentPosition(
    desiredAccuracy: LocationAccuracy.high
  );
  
  setState(() {
    coordenadas = "${position.latitude}, ${position.longitude}";
  });
}
```

#### Geração de PDF
```dart
// Usar pdf package + printing
import 'package:pdf/widgets.dart' as pw;

Future<void> gerarPDF() async {
  final pdf = pw.Document();
  
  // Página 1: Dados da visita
  // Página 2+: Fotos (1-3 por página)
  // Layout profissional com:
  // - Logo SoloForte
  // - Dados em tabela limpa
  // - Fotos com legendas
  // - Rodapé com data/técnico
  
  await Printing.sharePdf(
    bytes: await pdf.save(),
    filename: 'visita_${DateTime.now()}.pdf'
  );
}
```

### 4. Estágios Fenológicos (dados completos)
```dart
Map<String, Map<String, dynamic>> estagios = {
  'VE': {
    'nome': 'VE - Emergência',
    'descricao': 'Cotilédones acima do solo',
    'dapEsperado': '3-5 dias',
    'atencoes': [
      'Verificar stand de plantas',
      'Controle de formigas',
      'Umidade do solo adequada'
    ]
  },
  'VC': {
    'nome': 'VC - Cotilédones',
    'descricao': 'Cotilédones completamente abertos',
    'dapEsperado': '5-7 dias',
    'atencoes': [
      'Monitorar pragas de solo',
      'Avaliar emergência uniforme',
      'Verificar profundidade de plantio'
    ]
  },
  'V1': {
    'nome': 'V1 - Primeira Trifoliolada',
    'descricao': 'Folhas unifolioladas completamente desenvolvidas',
    'dapEsperado': '10-12 dias',
    'atencoes': [
      'Início controle de plantas daninhas',
      'Monitorar lagartas',
      'Avaliar necessidade de cobertura'
    ]
  },
  'V2': {
    'nome': 'V2 - Segunda Trifoliolada',
    'descricao': 'Segunda folha trifoliolada desenvolvida',
    'dapEsperado': '15-17 dias',
    'atencoes': [
      'Janela ideal para herbicidas pós-emergentes',
      'Controle de percevejos',
      'Avaliar nodulação'
    ]
  },
  'V3': {
    'nome': 'V3 - Terceira Trifoliolada',
    'descricao': 'Terceira folha trifoliolada desenvolvida',
    'dapEsperado': '20-22 dias',
    'atencoes': [
      'Última aplicação de herbicidas',
      'Monitorar deficiências nutricionais',
      'Controle de lagartas e percevejos'
    ]
  },
  'V4': {
    'nome': 'V4 - Quarta Trifoliolada',
    'descricao': 'Quarta folha trifoliolada desenvolvida',
    'dapEsperado': '25-27 dias',
    'atencoes': [
      'Período de rápido crescimento',
      'Alta demanda por água',
      'Monitorar doenças foliares iniciais'
    ]
  },
  'V5': {
    'nome': 'V5 - Quinta Trifoliolada',
    'descricao': 'Quinta folha trifoliolada desenvolvida',
    'dapEsperado': '30-32 dias',
    'atencoes': [
      'Pré-fechamento entrelinhas',
      'Controle rigoroso de percevejos',
      'Atenção a ferrugem asiática'
    ]
  },
  'R1': {
    'nome': 'R1 - Florescimento',
    'descricao': 'Uma flor aberta em qualquer nó',
    'dapEsperado': '35-40 dias',
    'atencoes': [
      'Período crítico de água inicia',
      'Controle preventivo de doenças',
      'Monitorar percevejo intensivamente'
    ]
  },
  'R2': {
    'nome': 'R2 - Floração Plena',
    'descricao': 'Flor aberta no penúltimo nó do caule',
    'dapEsperado': '40-45 dias',
    'atencoes': [
      'Definição do número de vagens',
      'Alta sensibilidade ao estresse hídrico',
      'Controle de lagartas e percevejos'
    ]
  },
  'R3': {
    'nome': 'R3 - Vagens 1cm',
    'descricao': 'Vagem com 1cm no nó superior',
    'dapEsperado': '45-50 dias',
    'atencoes': [
      'Início fixação de nitrogênio plena',
      'Controle de doenças essencial',
      'Monitorar deficiências de potássio'
    ]
  },
  'R4': {
    'nome': 'R4 - Vagens 2cm',
    'descricao': 'Vagem com 2cm no nó superior',
    'dapEsperado': '50-55 dias',
    'atencoes': [
      'Definição número de grãos/vagem',
      'Alta demanda nutricional',
      'Percevejo - dano direto aos grãos'
    ]
  },
  'R5.1': {
    'nome': 'R5.1 - Início Enchimento',
    'descricao': 'Grãos com 10% do enchimento máximo',
    'dapEsperado': '55-65 dias',
    'atencoes': [
      'Período mais crítico de água',
      'Ferrugem - aplicações preventivas',
      'Monitorar doenças de final de ciclo'
    ]
  },
  'R5.3': {
    'nome': 'R5.3 - 50% Enchimento',
    'descricao': 'Grãos com 50% do enchimento máximo',
    'dapEsperado': '65-75 dias',
    'atencoes': [
      'Máxima demanda hídrica',
      'Controle de percevejos crítico',
      'Monitorar podridão de vagens'
    ]
  },
  'R5.5': {
    'nome': 'R5.5 - 100% Enchimento',
    'descricao': 'Grãos tangenciando-se nas vagens',
    'dapEsperado': '80-90 dias',
    'atencoes': [
      'Período crítico de água termina',
      'Ferrugem - última janela de controle',
      'Definição final de produtividade'
    ]
  },
  'R6': {
    'nome': 'R6 - Grãos Formados',
    'descricao': 'Vagens com grãos verdes preenchendo cavidades',
    'dapEsperado': '90-100 dias',
    'atencoes': [
      'Plantas começam a amarelar',
      'Não aplicar mais defensivos',
      'Monitorar umidade para colheita'
    ]
  },
  'R7': {
    'nome': 'R7 - Início Maturação',
    'descricao': 'Uma vagem madura no caule principal',
    'dapEsperado': '100-110 dias',
    'atencoes': [
      'Dessecação pode ser considerada',
      'Definir ponto de colheita',
      'Atenção a chuvas excessivas'
    ]
  },
  'R8': {
    'nome': 'R8 - Maturação Plena',
    'descricao': '95% das vagens maduras',
    'dapEsperado': '110-120 dias',
    'atencoes': [
      'Ponto de colheita',
      'Umidade ideal 13-15%',
      'Atenção a perdas por degrane'
    ]
  }
};
```

### 5. Packages Necessários
```yaml
dependencies:
  flutter:
    sdk: flutter
  
  # UI/UX
  cupertino_icons: ^1.0.2
  google_fonts: ^6.1.0  # SF Pro Text
  
  # Dados
  shared_preferences: ^2.2.2
  hive: ^2.2.3
  hive_flutter: ^1.1.0
  
  # Imagens
  image_picker: ^1.0.7
  image: ^4.1.6
  path_provider: ^2.1.2
  
  # Geolocalização
  geolocator: ^11.0.0
  permission_handler: ^11.2.0
  
  # PDF
  pdf: ^3.10.7
  printing: ^5.12.0
  
  # Utilitários
  intl: ^0.19.0  # Formatação de datas
  flutter_slidable: ^3.0.1  # Swipe actions
```

### 6. Estrutura de Pastas
```
lib/
├── main.dart
├── models/
│   ├── visita.dart
│   ├── problema.dart
│   ├── foto.dart
│   └── estagio_fenologico.dart
├── screens/
│   ├── home_screen.dart
│   ├── photo_viewer_screen.dart
│   └── pdf_preview_screen.dart
├── widgets/
│   ├── section_card.dart
│   ├── category_button.dart
│   ├── problem_card.dart
│   ├── photo_grid.dart
│   ├── floating_camera_button.dart
│   ├── dap_badge.dart
│   └── stage_card.dart
├── services/
│   ├── storage_service.dart
│   ├── photo_service.dart
│   ├── location_service.dart
│   └── pdf_service.dart
├── utils/
│   ├── constants.dart
│   ├── theme.dart
│   ├── validators.dart
│   └── date_utils.dart
└── data/
    ├── fenologia_data.dart
    └── categorias_data.dart
```

### 7. Comportamentos iOS Específicos
```dart
// Scroll com bounce physics
ScrollPhysics: BouncingScrollPhysics()

// Inputs com estilo Cupertino
CupertinoTextField()

// Date pickers iOS
showCupertinoModalPopup<DateTime>()

// Alertas iOS
CupertinoAlertDialog()

// Sliding actions
Slidable (package: flutter_slidable)

// Haptic feedback
HapticFeedback.lightImpact()

// Blur effects
BackdropFilter(
  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
  child: Container(...)
)
```

### 8. Validações e Regras de Negócio
```dart
// Antes de gerar PDF
bool validarFormulario() {
  if (produtor.isEmpty) {
    mostrarAlerta('Preencha o nome do produtor');
    return false;
  }
  if (propriedade.isEmpty) {
    mostrarAlerta('Preencha o nome da propriedade');
    return false;
  }
  if (data == null) {
    mostrarAlerta('Selecione a data da visita');
    return false;
  }
  if (area <= 0) {
    mostrarAlerta('Informe a área em hectares');
    return false;
  }
  if (problemas.isEmpty) {
    mostrarAlerta('Adicione pelo menos um problema identificado');
    return false;
  }
  if (tecnico.isEmpty) {
    mostrarAlerta('Informe o nome do responsável técnico');
    return false;
  }
  
  return true;
}

// Cálculo de tamanho estimado do PDF
String estimarTamanhoPDF() {
  int numFotos = todasAsFotos.length;
  double tamanhoPorFoto = qualidade == 'alta' ? 0.5 : 
                          qualidade == 'media' ? 0.25 : 0.1;
  double estimativa = 0.5 + (numFotos * tamanhoPorFoto);
  
  return "${estimativa.toStringAsFixed(1)} MB";
}

// Validação de número de fotos por problema
int maxFotosPorProblema = 10;

// Compressão de imagem
Future<File> comprimirImagem(File file, String qualidade) async {
  final bytes = await file.readAsBytes();
  final img = decodeImage(bytes);
  
  int quality = qualidade == 'alta' ? 85 : 
                qualidade == 'media' ? 60 : 40;
  
  final compressed = encodeJpg(img, quality: quality);
  
  final compressedFile = File(file.path)
    ..writeAsBytesSync(compressed);
  
  return compressedFile;
}
```

### 9. Experiência do Usuário (UX)

**Fluxo típico**:
1. Abrir app → Formulário vazio ou recuperar último rascunho
2. Preencher dados básicos da visita
3. Selecionar estágio fenológico → Ver orientações automáticas
4. Tocar em categoria (ex: "Doenças")
5. Botão flutuante atualiza para "📷 Doenças"
6. Clicar botão → Câmera abre
7. Tirar foto → Retorna com preview
8. Automático: Adiciona foto ao card "Doenças"
9. Preencher nome e severidade do problema
10. Repetir 4-9 para outras categorias
11. Preencher observações/recomendações
12. Tocar "PDF" → Gera e compartilha

**Transições suaves**:
```dart
// Expandir cards
AnimatedContainer(
  duration: Duration(milliseconds: 200),
  curve: Curves.easeInOut,
  ...
)

// Hero animations para fotos
Hero(
  tag: 'foto_${foto.id}',
  child: Image.file(foto.arquivo)
)

// Fade para indicadores
AnimatedOpacity(
  opacity: _salvando ? 1.0 : 0.0,
  duration: Duration(milliseconds: 300),
  child: Text('✓ Salvo')
)

// Scale para botões ativos
AnimatedScale(
  scale: _ativo ? 1.05 : 1.0,
  duration: Duration(milliseconds: 150),
  child: ...
)
```

### 10. Orientação e Suporte

**Tooltips discretos** (primeira vez):
```dart
Tooltip(
  message: 'Toque para ativar a categoria',
  child: CategoryButton(...)
)

// Mostrar apenas na primeira vez
SharedPreferences prefs = await SharedPreferences.getInstance();
bool primeiraVez = prefs.getBool('primeira_vez') ?? true;
if (primeiraVez) {
  // Mostrar tour rápido
  await mostrarTour();
  await prefs.setBool('primeira_vez', false);
}
```

**Estados vazios informativos**:
```dart
// Quando não há fotos
Center(
  child: Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Icon(
        Icons.photo_camera_outlined, 
        size: 48, 
        color: Color(0xFFD1D1D6)
      ),
      SizedBox(height: 12),
      Text(
        'Nenhuma foto ainda',
        style: TextStyle(
          fontSize: 15,
          color: Color(0xFF86868B)
        )
      ),
      SizedBox(height: 4),
      Text(
        'Toque no botão verde para adicionar',
        style: TextStyle(
          fontSize: 13,
          color: Color(0xFFC7C7CC)
        )
      )
    ]
  )
)

// Quando não há problemas
Card(
  child: Padding(
    padding: EdgeInsets.all(20),
    child: Column(
      children: [
        Icon(Icons.check_circle_outline, size: 48, color: verde),
        SizedBox(height: 12),
        Text('Nenhum problema identificado'),
        SizedBox(height: 8),
        Text(
          'Selecione uma categoria acima para começar',
          style: TextStyle(color: textoSecundario),
          textAlign: TextAlign.center
        )
      ]
    )
  )
)
```

### 11. Layouts de Cards (Glassmorphism)
```dart
Widget buildCard({required Widget child}) {
  return Container(
    margin: EdgeInsets.only(bottom: 16),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.95),
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.08),
          blurRadius: 3,
          offset: Offset(0, 1)
        ),
        BoxShadow(
          color: Colors.black.withOpacity(0.04),
          blurRadius: 8,
          offset: Offset(0, 2)
        )
      ]
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Padding(
          padding: EdgeInsets.all(20),
          child: child
        )
      )
    )
  );
}
```

### 12. Layout do PDF
```dart
Future<pw.Document> gerarPDF() async {
  final pdf = pw.Document();
  
  // Página 1: Cabeçalho e Dados
  pdf.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      build: (context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // Logo e título
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'RELATÓRIO DE VISITA TÉCNICA',
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold
                  )
                ),
                pw.Text(
                  DateFormat('dd/MM/yyyy').format(data),
                  style: pw.TextStyle(fontSize: 12)
                )
              ]
            ),
            pw.SizedBox(height: 20),
            
            // Dados da visita em tabela
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300),
              children: [
                buildTableRow('Produtor', produtor),
                buildTableRow('Propriedade', propriedade),
                buildTableRow('Área', '$area ha'),
                buildTableRow('Cultivar', cultivar),
                buildTableRow('Data de Plantio', 
                  DateFormat('dd/MM/yyyy').format(plantio)),
                buildTableRow('DAP', '$dap dias'),
                buildTableRow('Estádio', estagioSelecionado),
              ]
            ),
            
            pw.SizedBox(height: 20),
            
            // Problemas identificados
            pw.Text(
              'PROBLEMAS IDENTIFICADOS',
              style: pw.TextStyle(
                fontSize: 14,
                fontWeight: pw.FontWeight.bold
              )
            ),
            pw.SizedBox(height: 10),
            
            ...problemas.map((p) => pw.Container(
              margin: pw.EdgeInsets.only(bottom: 8),
              padding: pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey300),
                borderRadius: pw.BorderRadius.circular(4)
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    '${p.categoria.toUpperCase()}: ${p.nome}',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold)
                  ),
                  pw.Text('Severidade: ${p.severidade}%')
                ]
              )
            )),
            
            pw.SizedBox(height: 20),
            
            // Observações e recomendações
            if (observacoes.isNotEmpty) ...[
              pw.Text(
                'OBSERVAÇÕES',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold
                )
              ),
              pw.SizedBox(height: 8),
              pw.Text(observacoes),
              pw.SizedBox(height: 16)
            ],
            
            if (recomendacoes.isNotEmpty) ...[
              pw.Text(
                'RECOMENDAÇÕES',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold
                )
              ),
              pw.SizedBox(height: 8),
              pw.Text(recomendacoes)
            ],
            
            pw.Spacer(),
            
            // Rodapé
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Responsável Técnico'),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      tecnico,
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold)
                    )
                  ]
                ),
                if (coordenadas.isNotEmpty)
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('Coordenadas'),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        coordenadas,
                        style: pw.TextStyle(fontSize: 10)
                      )
                    ]
                  )
              ]
            )
          ]
        );
      }
    )
  );
  
  // Páginas de fotos (1-3 por página)
  for (int i = 0; i < fotos.length; i += fotosPorPagina) {
    final fotosPage = fotos.skip(i).take(fotosPorPagina).toList();
    
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (context) {
          return pw.Column(
            children: fotosPage.map((foto) {
              return pw.Container(
                margin: pw.EdgeInsets.only(bottom: 20),
                child: pw.Column(
                  children: [
                    pw.Image(
                      pw.MemoryImage(foto.bytes),
                      fit: pw.BoxFit.contain,
                      height: fotosPorPagina == 1 ? 500 :
                              fotosPorPagina == 2 ? 300 : 200
                    ),
                    pw.SizedBox(height: 8),
                    pw.Text(
                      '${foto.categoria} - ${foto.problema}',
                      style: pw.TextStyle(fontSize: 10)
                    )
                  ]
                )
              );
            }).toList()
          );
        }
      )
    );
  }
  
  return pdf;
}
```

### 13. Permissões (Android & iOS)

**AndroidManifest.xml**:
```xml
<uses-permission android:name="android.permission.CAMERA"/>
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"/>
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
```

**Info.plist (iOS)**:
```xml
<key>NSCameraUsageDescription</key>
<string>Precisamos acessar a câmera para tirar fotos dos problemas na lavoura</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>Precisamos acessar a galeria para selecionar fotos</string>
<key>NSLocationWhenInUseUsageDescription</key>
<string>Precisamos da sua localização para registrar coordenadas da visita</string>
```

**Código de permissões**:
```dart
Future<bool> requestPermissions() async {
  Map<Permission, PermissionStatus> statuses = await [
    Permission.camera,
    Permission.storage,
    Permission.location,
  ].request();
  
  return statuses.values.every((status) => status.isGranted);
}
```

---

## Resultado Esperado

Aplicativo Flutter/Dart mobile-first que:
- ✅ Segue rigorosamente design iOS minimalista
- ✅ Funciona offline 100%
- ✅ Auto-salva constantemente
- ✅ Câmera integrada com categorização
- ✅ Gera PDFs profissionais
- ✅ Interface limpa, rápida, sem distrações
- ✅ Máximo 480px de largura (otimizado para celular)
- ✅ Animações suaves e naturais
- ✅ Feedback visual imediato em todas as ações
- ✅ Geolocalização GPS integrada
- ✅ Compressão inteligente de imagens
- ✅ Cálculo automático de DAP
- ✅ Orientações técnicas por estágio fenológico

**Filosofia**: O design não deve chamar atenção para si mesmo, mas para o trabalho do agrônomo. Simplicidade, clareza e profissionalismo acima de tudo. Cada toque deve ter um propósito, cada animação deve comunicar estado, cada cor deve ter significado.

---

## Observações Finais

1. **Priorize a experiência mobile**: Todos os elementos devem ser facilmente tocáveis (min 44x44pt)
2. **Performance é crítica**: App deve abrir em <2s e responder instantaneamente
3. **Offline-first**: Tudo funciona sem internet, sincronização futura é opcional
4. **Dados persistem**: Nunca perder dados do usuário, auto-save agressivo
5. **Visual profissional**: Este app representa o consultor perante o cliente
6. **Simplicidade radical**: Remova qualquer elemento que não seja essencial

**Brand**: SoloForte - Tecnologia Agrícola Profissional