# SKILL: SoloForte Case — Flutter/Dart  
  
## Funções, Lógica e Estrutura Técnica Completa  
  
-----  
  
## VISÃO GERAL  
  
Aplicação Flutter para criação de cases agrícolas. Formulário com 3 tipos de conteúdo, comparações dinâmicas, upload de imagens com compressão, cálculo de ROI automático e validações na publicação.  
  
**Arquitetura:** Single screen `StatefulWidget` com `setState()` para gerenciamento de estado local.  
  
-----  
  
## PACKAGES NECESSÁRIOS  
  
```yaml  
# pubspec.yaml  
dependencies:  
  flutter:  
    sdk: flutter  
  image_picker: ^1.0.4          # Seleção de imagens da galeria/câmera  
  flutter_image_compress: ^2.1.0 # Compressão de imagens  
```  
  
**Permissões Android** — `android/app/src/main/AndroidManifest.xml`:  
  
```xml  
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>  
<uses-permission android:name="android.permission.CAMERA"/>  
```  
  
**Permissões iOS** — `ios/Runner/Info.plist`:  
  
```xml  
<key>NSPhotoLibraryUsageDescription</key>  
<string>Necessário para adicionar fotos aos cases</string>  
<key>NSCameraUsageDescription</key>  
<string>Necessário para tirar fotos dos cases</string>  
```  
  
-----  
  
## ESTADO GLOBAL — State Variables  
  
```dart  
class _NovoCaseScreenState extends State<NovoCaseScreen> {  
  
  // ── Tipo e visibilidade ──────────────────────────────  
  String selectedType = 'resultado';   // 'resultado' | 'antes-depois' | 'avaliacao'  
  String selectedSize = 'silver';      // 'bronze' | 'silver' | 'gold'  
  String selectedUnit = 'sc/ha';       // 'sc/ha' | 'ton/ha' | 'kg/ha'  
  
  // ── Fotos principais ────────────────────────────────  
  File? photoAntes;  
  File? photoDepois;  
  File? photoResultado;  
  
  // ── Comparações dinâmicas ───────────────────────────  
  List<ComparisonModel> comparisons = [];  
  int comparisonCount = 0;   // Contador incremental — nunca decrementa  
  
  // ── Menu adicionar ──────────────────────────────────  
  bool showAddMenu = false;  
  
  // ── Blocos singleton ────────────────────────────────  
  bool hasConclusao = false; // Só 1 conclusão permitida  
  bool hasROI = false;       // Só 1 ROI permitido  
  String conclusaoText = '';  
  double? investimento;  
  double? retorno;  
  
  // ── Image Picker ────────────────────────────────────  
  final ImagePicker _picker = ImagePicker();  
  
  // ── TextEditingControllers ──────────────────────────  
  final _produtorController    = TextEditingController();  
  final _produtoController     = TextEditingController();  
  final _localController       = TextEditingController();  
  final _talhaoController      = TextEditingController();  
  final _tamanhoHaController   = TextEditingController();  
  final _valorController       = TextEditingController();  
  final _ganhoController       = TextEditingController();  
  final _economiaADController  = TextEditingController();  
  final _quantidadeController  = TextEditingController();  
  final _economiaRController   = TextEditingController();  
  final _vendedorController    = TextEditingController();  
  final _telefoneController    = TextEditingController();  
  final _descricaoController   = TextEditingController();  
  final _conclusaoController   = TextEditingController();  
  final _investimentoController = TextEditingController();  
  final _retornoController     = TextEditingController();  
}  
```  
  
-----  
  
## MODELO DE DADOS  
  
### `ComparisonModel`  
  
```dart  
class ComparisonModel {  
  final int id;  
  bool collapsed;  
  String labelA;  
  String labelB;  
  File? photoA;  
  File? photoB;  
  String culturaA;  
  String culturaB;  
  String obsA;  
  String obsB;  
  String layout; // '2' = 2 fotos | '1' = 1 foto  
  
  ComparisonModel({  
    required this.id,  
    this.collapsed  = false,  
    this.labelA     = 'Produto A',  
    this.labelB     = 'Produto B',  
    this.photoA,  
    this.photoB,  
    this.culturaA   = '',  
    this.culturaB   = '',  
    this.obsA       = '',  
    this.obsB       = '',  
    this.layout     = '2',  
  });  
}  
```  
  
-----  
  
## FUNÇÕES — DESCRIÇÃO COMPLETA  
  
-----  
  
### 1. `_handleTypeChange(String type)`  
  
**Gatilho:** `onChanged` no `DropdownButton` de tipo  
  
**O que faz:** Atualiza `selectedType` via `setState()`. O `build()` reconstrói o layout automaticamente com condicionais `if (selectedType == '...')`.  
  
```dart  
void _handleTypeChange(String type) {  
  setState(() {  
    selectedType = type;  
  });  
}  
```  
  
**Tabela de visibilidade por tipo — controle via `if` no `build()`:**  
  
|Widget/Seção                    |resultado|antes-depois|avaliacao|  
|--------------------------------|:-------:|:----------:|:-------:|  
|`_buildResultadoSection()`      |✅        |❌           |❌        |  
|`_buildAntesDepoisSection()`    |❌        |✅           |❌        |  
|`_buildAvaliacaoSection()`      |❌        |❌           |✅        |  
|`_buildProdutividadeSection()`  |✅        |✅           |❌        |  
|`_buildResultadoFieldsSection()`|✅        |❌           |❌        |  
|`_buildGanhosSection()`         |❌        |✅           |❌        |  
  
**Implementação no `build()`:**  
  
```dart  
Column(  
  children: [  
    _buildTipoSection(),  
    _buildVisibilidadeSection(),  
    if (selectedType == 'antes-depois') _buildAntesDepoisSection(),  
    if (selectedType == 'resultado')    _buildResultadoSection(),  
    if (selectedType == 'avaliacao')    _buildAvaliacaoSection(),  
    _buildInformacoesSection(),  
    if (selectedType != 'avaliacao')    _buildProdutividadeSection(),  
    if (selectedType == 'antes-depois') _buildGanhosSection(),  
    if (selectedType == 'resultado')    _buildResultadoFieldsSection(),  
    _buildVendedorSection(),  
    _buildDescricaoSection(),  
  ],  
)  
```  
  
-----  
  
### 2. `_selectSize(String size)`  
  
**Gatilho:** `onTap` nos botões de medalha (`GestureDetector`)  
  
**O que faz:** Atualiza `selectedSize`. O `AnimatedContainer` reage automaticamente ao rebuild.  
  
```dart  
void _selectSize(String size) {  
  setState(() {  
    selectedSize = size;  
  });  
}  
```  
  
**Lógica de gradiente por medalha:**  
  
```dart  
LinearGradient? _getSizeGradient(String size) {  
  if (selectedSize != size) return null;  
  switch (size) {  
    case 'bronze':  
      return const LinearGradient(  
        begin: Alignment.topLeft,  
        end: Alignment.bottomRight,  
        colors: [Color(0xFFCD7F32), Color(0xFFA0522D)],  
      );  
    case 'silver':  
      return const LinearGradient(  
        begin: Alignment.topLeft,  
        end: Alignment.bottomRight,  
        colors: [Color(0xFFE8E8E8), Color(0xFFA9A9A9)],  
      );  
    case 'gold':  
      return const LinearGradient(  
        begin: Alignment.topLeft,  
        end: Alignment.bottomRight,  
        colors: [Color(0xFFFFD700), Color(0xFFFFA500)],  
      );  
    default:  
      return null;  
  }  
}  
```  
  
**`AnimatedContainer` com scale ativo:**  
  
```dart  
AnimatedContainer(  
  duration: const Duration(milliseconds: 200),  
  transform: selectedSize == size  
      ? (Matrix4.identity()..scale(1.05))  
      : Matrix4.identity(),  
  decoration: BoxDecoration(  
    gradient: _getSizeGradient(size),  
    color: selectedSize != size ? const Color(0xFFF5F5F7) : null,  
    borderRadius: BorderRadius.circular(14),  
    boxShadow: selectedSize == size  
        ? [BoxShadow(  
            color: Colors.black.withOpacity(0.15),  
            blurRadius: 12,  
            offset: const Offset(0, 4),  
          )]  
        : null,  
  ),  
)  
```  
  
-----  
  
### 3. `_pickImage(String type)`  
  
**Gatilho:** `onTap` nas áreas de foto (`GestureDetector`)  
  
**Parâmetros:**  
  
- `type` — `'antes'` | `'depois'` | `'resultado'` | `'comparison-A-{id}'` | `'comparison-B-{id}'`  
  
**O que faz:** Abre a galeria via `ImagePicker`, recebe o arquivo e chama `_compressImage()`. Atualiza o `File?` correspondente via `setState()`.  
  
```dart  
Future<void> _pickImage(String type) async {  
  final XFile? picked = await _picker.pickImage(  
    source: ImageSource.gallery,  
    imageQuality: 85,       // Qualidade inicial no picker  
    maxWidth: 1200,         // Limite de largura no picker  
  );  
  if (picked == null) return;  
  
  final compressed = await _compressImage(File(picked.path));  
  
  setState(() {  
    switch (type) {  
      case 'antes':  
        photoAntes = compressed;  
        break;  
      case 'depois':  
        photoDepois = compressed;  
        break;  
      case 'resultado':  
        photoResultado = compressed;  
        break;  
      default:  
        // Comparações: 'comparison-A-1', 'comparison-B-2', etc.  
        if (type.startsWith('comparison-A-')) {  
          final id = int.parse(type.split('-').last);  
          final index = comparisons.indexWhere((c) => c.id == id);  
          if (index != -1) comparisons[index].photoA = compressed;  
        } else if (type.startsWith('comparison-B-')) {  
          final id = int.parse(type.split('-').last);  
          final index = comparisons.indexWhere((c) => c.id == id);  
          if (index != -1) comparisons[index].photoB = compressed;  
        }  
    }  
  });  
}  
```  
  
-----  
  
### 4. `_compressImage(File file)`  
  
**Tipo:** `async` — retorna `Future<File>`  
  
**O que faz:** Comprime a imagem para máximo `1200px` de largura com qualidade `85`. Usa o package `flutter_image_compress`.  
  
```dart  
Future<File> _compressImage(File file) async {  
  final filePath = file.path;  
  final lastIndex = filePath.lastIndexOf('.');  
  final newPath = filePath.substring(0, lastIndex) + '_compressed.jpg';  
  
  final compressed = await FlutterImageCompress.compressAndGetFile(  
    filePath,  
    newPath,  
    minWidth: 1200,  
    minHeight: 1200,  
    quality: 85,  
    format: CompressFormat.jpeg,  
  );  
  
  return compressed != null ? File(compressed.path) : file;  
}  
```  
  
**Fallback:** Se a compressão falhar, retorna o arquivo original sem quebrar o fluxo.  
  
-----  
  
### 5. `_removePhoto(String type)`  
  
**Gatilho:** `onTap` no botão `×` sobre a foto  
  
**O que faz:** Seta o `File?` correspondente como `null` via `setState()`.  
  
```dart  
void _removePhoto(String type) {  
  setState(() {  
    switch (type) {  
      case 'antes':     photoAntes    = null; break;  
      case 'depois':    photoDepois   = null; break;  
      case 'resultado': photoResultado = null; break;  
      default:  
        if (type.startsWith('comparison-A-')) {  
          final id = int.parse(type.split('-').last);  
          final index = comparisons.indexWhere((c) => c.id == id);  
          if (index != -1) comparisons[index].photoA = null;  
        } else if (type.startsWith('comparison-B-')) {  
          final id = int.parse(type.split('-').last);  
          final index = comparisons.indexWhere((c) => c.id == id);  
          if (index != -1) comparisons[index].photoB = null;  
        }  
    }  
  });  
}  
```  
  
-----  
  
### 6. `_toggleAddMenu()`  
  
**Gatilho:** `onTap` no botão `+ Adicionar`  
  
**O que faz:** Alterna `showAddMenu` entre `true` e `false`.  
  
```dart  
void _toggleAddMenu() {  
  setState(() {  
    showAddMenu = !showAddMenu;  
  });  
}  
```  
  
**Fechamento ao tocar fora** — usar `GestureDetector` na raiz da tela:  
  
```dart  
GestureDetector(  
  onTap: () {  
    if (showAddMenu) setState(() => showAddMenu = false);  
  },  
  child: Scaffold(...),  
)  
```  
  
-----  
  
### 7. `_addComparison()`  
  
**Gatilho:** Item “Avaliação” no menu adicionar  
  
**O que faz:** Incrementa `comparisonCount`, cria um `ComparisonModel` com ID único e adiciona à lista `comparisons`.  
  
```dart  
void _addComparison() {  
  setState(() {  
    comparisonCount++;  
    comparisons.add(ComparisonModel(id: comparisonCount));  
    showAddMenu = false;  
  });  
}  
```  
  
**Regra do ID:** `comparisonCount` nunca decrementa. Se o usuário deletar a comparação 2 e criar uma nova, ela receberá ID 3. Isso garante IDs únicos mesmo após deleções.  
  
-----  
  
### 8. `_toggleCollapse(int id)`  
  
**Gatilho:** `onTap` no botão `−` / `+` de cada comparação  
  
**Parâmetros:**  
  
- `id` — ID único da comparação  
  
**O que faz:** Encontra o índice na lista e alterna `collapsed`.  
  
```dart  
void _toggleCollapse(int id) {  
  setState(() {  
    final index = comparisons.indexWhere((c) => c.id == id);  
    if (index != -1) {  
      comparisons[index].collapsed = !comparisons[index].collapsed;  
    }  
  });  
}  
```  
  
**Animação de colapso** — usar `AnimatedCrossFade` ou `AnimatedSize`:  
  
```dart  
AnimatedSize(  
  duration: const Duration(milliseconds: 300),  
  curve: Curves.easeInOut,  
  child: comparison.collapsed  
      ? const SizedBox.shrink()  // Altura 0  
      : _buildComparisonContent(comparison),  
)  
```  
  
-----  
  
### 9. `_togglePhotoLayout(int id, String layout)`  
  
**Gatilho:** `onChanged` no `DropdownButton` de layout dentro de cada comparação  
  
**Parâmetros:**  
  
- `id` — ID da comparação  
- `layout` — `'1'` | `'2'`  
  
**O que faz:** Atualiza `layout` no `ComparisonModel`.  
  
```dart  
void _togglePhotoLayout(int id, String layout) {  
  setState(() {  
    final index = comparisons.indexWhere((c) => c.id == id);  
    if (index != -1) {  
      comparisons[index].layout = layout;  
    }  
  });  
}  
```  
  
**Renderização condicional por layout:**  
  
```dart  
layout == '2'  
  ? Row(  
      children: [  
        Expanded(child: _buildComparisonSide(comparison, 'A')),  
        const SizedBox(width: 12),  
        Expanded(child: _buildComparisonSide(comparison, 'B')),  
      ],  
    )  
  : _buildComparisonSide(comparison, 'A')  
```  
  
-----  
  
### 10. `_deleteComparison(int id)`  
  
**Gatilho:** `onTap` no botão `×` (vermelho) de cada comparação  
  
**O que faz:** Remove o `ComparisonModel` da lista pelo ID.  
  
```dart  
void _deleteComparison(int id) {  
  showDialog(  
    context: context,  
    builder: (ctx) => AlertDialog(  
      title: const Text('Remover avaliação?'),  
      actions: [  
        TextButton(  
          onPressed: () => Navigator.pop(ctx),  
          child: const Text('Cancelar'),  
        ),  
        TextButton(  
          onPressed: () {  
            setState(() {  
              comparisons.removeWhere((c) => c.id == id);  
            });  
            Navigator.pop(ctx);  
          },  
          child: const Text('Remover', style: TextStyle(color: Color(0xFFFF3B30))),  
        ),  
      ],  
    ),  
  );  
}  
```  
  
-----  
  
### 11. `_addConclusao()`  
  
**Gatilho:** Item “Conclusão” no menu adicionar  
  
**Regra Singleton:** Só pode existir uma conclusão. Verificado via `hasConclusao`.  
  
```dart  
void _addConclusao() {  
  if (hasConclusao) return; // Bloqueia segundo item  
  setState(() {  
    hasConclusao = true;  
    showAddMenu = false;  
  });  
}  
  
void _removeConclusao() {  
  setState(() {  
    hasConclusao = false;  
    _conclusaoController.clear();  
  });  
}  
```  
  
-----  
  
### 12. `_addROI()`  
  
**Gatilho:** Item “ROI” no menu adicionar  
  
**Regra Singleton:** Só pode existir um ROI. Verificado via `hasROI`.  
  
```dart  
void _addROI() {  
  if (hasROI) return; // Bloqueia segundo item  
  setState(() {  
    hasROI = true;  
    showAddMenu = false;  
  });  
}  
  
void _removeROI() {  
  setState(() {  
    hasROI = false;  
    _investimentoController.clear();  
    _retornoController.clear();  
  });  
}  
```  
  
-----  
  
### 13. `_calculateROI()`  
  
**Gatilho:** `onChanged` nos `TextField` de Investimento e Retorno  
  
**Fórmula:**  
  
```  
ROI (%) = ((Retorno - Investimento) / Investimento) × 100  
```  
  
**Regra:** Se `investimento == 0` ou `null`, retorna `0.0` para evitar divisão por zero.  
  
```dart  
double _calculateROI() {  
  final inv = double.tryParse(_investimentoController.text) ?? 0.0;  
  final ret = double.tryParse(_retornoController.text) ?? 0.0;  
  
  if (inv <= 0) return 0.0;  
  return ((ret - inv) / inv) * 100;  
}  
  
// Formatar para exibição  
String get roiFormatted {  
  final roi = _calculateROI();  
  return '${roi.toStringAsFixed(2)}%';  
}  
```  
  
**Uso no widget ROI:**  
  
```dart  
TextField(  
  controller: _investimentoController,  
  onChanged: (_) => setState(() {}), // Rebuild para atualizar display  
  keyboardType: const TextInputType.numberWithOptions(decimal: true),  
),  
  
// Display do resultado  
Text(roiFormatted, style: TextStyle(...)),  
```  
  
-----  
  
### 14. `_handleSave()`  
  
**Gatilho:** `onPressed` no botão “Salvar” do footer  
  
**Sem validações.** Apenas exibe um `SnackBar`.  
  
```dart  
void _handleSave() {  
  ScaffoldMessenger.of(context).showSnackBar(  
    const SnackBar(  
      content: Text('💾 Rascunho salvo!'),  
      behavior: SnackBarBehavior.floating,  
    ),  
  );  
}  
```  
  
-----  
  
### 15. `_handlePublish()`  
  
**Gatilho:** `onPressed` no botão “Publicar” do footer  
  
**Validações em ordem:**  
  
|#|Condição                                                 |Mensagem                              |  
|-|---------------------------------------------------------|--------------------------------------|  
|1|`_produtorController.text.isEmpty`                       |`'Preencha o campo Produtor/Fazenda'` |  
|2|`_produtoController.text.isEmpty`                        |`'Preencha o campo Produto Utilizado'`|  
|3|`selectedType == 'antes-depois'` && `photoAntes == null` |`'Adicione a foto de Antes'`          |  
|4|`selectedType == 'antes-depois'` && `photoDepois == null`|`'Adicione a foto de Depois'`         |  
|5|`selectedType == 'resultado'` && `photoResultado == null`|`'Adicione a foto do Resultado'`      |  
|✅|Todas passaram                                           |`'✅ Case publicado com sucesso!'`     |  
  
```dart  
void _handlePublish() {  
  // Validação 1 e 2 — campos obrigatórios  
  if (_produtorController.text.isEmpty || _produtoController.text.isEmpty) {  
    _showSnackBar('Preencha os campos obrigatórios');  
    return;  
  }  
  
  // Validação 3 e 4 — fotos antes/depois  
  if (selectedType == 'antes-depois') {  
    if (photoAntes == null || photoDepois == null) {  
      _showSnackBar('Adicione as fotos de antes e depois');  
      return;  
    }  
  }  
  
  // Validação 5 — foto resultado  
  if (selectedType == 'resultado' && photoResultado == null) {  
    _showSnackBar('Adicione a foto do resultado');  
    return;  
  }  
  
  _showSnackBar('✅ Case publicado com sucesso!');  
}  
  
void _showSnackBar(String message) {  
  ScaffoldMessenger.of(context).showSnackBar(  
    SnackBar(  
      content: Text(message),  
      behavior: SnackBarBehavior.floating,  
    ),  
  );  
}  
```  
  
-----  
  
## DROPDOWNS — OPÇÕES COMPLETAS  
  
### Tipo do Case  
  
```dart  
const List<DropdownMenuItem<String>> tipoItems = [  
  DropdownMenuItem(value: 'resultado',    child: Text('Resultado')),  
  DropdownMenuItem(value: 'antes-depois', child: Text('Antes/Depois')),  
  DropdownMenuItem(value: 'avaliacao',    child: Text('Avaliação/Campo')),  
];  
```  
  
### Unidade de Produtividade  
  
```dart  
const List<DropdownMenuItem<String>> unidadeItems = [  
  DropdownMenuItem(value: 'sc/ha',  child: Text('sc/ha')),  
  DropdownMenuItem(value: 'ton/ha', child: Text('ton/ha')),  
  DropdownMenuItem(value: 'kg/ha',  child: Text('kg/ha')),  
];  
```  
  
### Layout de Fotos (por comparação)  
  
```dart  
const List<DropdownMenuItem<String>> layoutItems = [  
  DropdownMenuItem(value: '2', child: Text('2 fotos')),  
  DropdownMenuItem(value: '1', child: Text('1 foto')),  
];  
```  
  
### Tipo de Cultura (por comparação)  
  
```dart  
const List<DropdownMenuItem<String>> culturaItems = [  
  DropdownMenuItem(value: '',      child: Text('Tipo de cultura')),  
  DropdownMenuItem(value: 'soja',  child: Text('Soja')),  
  DropdownMenuItem(value: 'milho', child: Text('Milho')),  
  DropdownMenuItem(value: 'trigo', child: Text('Trigo')),  
  DropdownMenuItem(value: 'cafe',  child: Text('Café')),  
];  
```  
  
-----  
  
## CAMPOS DO FORMULÁRIO  
  
|Controller               |Tipo Input |Seção        |Obrigatório|  
|-------------------------|-----------|-------------|:---------:|  
|`_produtorController`    |`text`     |Informações  |✅          |  
|`_produtoController`     |`text`     |Informações  |✅          |  
|`_localController`       |`text`     |Informações  |❌          |  
|`_valorController`       |`number`   |Produtividade|❌          |  
|`_ganhoController`       |`text`     |Ganhos       |❌          |  
|`_economiaADController`  |`text`     |Ganhos       |❌          |  
|`_quantidadeController`  |`number`   |Resultado    |❌          |  
|`_economiaRController`   |`text`     |Resultado    |❌          |  
|`_vendedorController`    |`text`     |Vendedor     |❌          |  
|`_telefoneController`    |`phone`    |Vendedor     |❌          |  
|`_descricaoController`   |`multiline`|Descrição    |❌          |  
|`_talhaoController`      |`text`     |Talhão       |❌          |  
|`_tamanhoHaController`   |`number`   |Talhão       |❌          |  
|`_conclusaoController`   |`multiline`|Conclusão    |❌          |  
|`_investimentoController`|`decimal`  |ROI          |❌          |  
|`_retornoController`     |`decimal`  |ROI          |❌          |  
  
**Mapeamento de `TextInputType` por campo:**  
  
```dart  
TextInputType.text              // text padrão  
TextInputType.number            // inteiros  
TextInputType.numberWithOptions(decimal: true)  // decimais (ha, ROI)  
TextInputType.phone             // telefone  
TextInputType.multiline         // descrição e conclusão  
```  
  
-----  
  
## FOTOS — STATE E RENDERIZAÇÃO  
  
|Variável           |Tipo   |Usada em              |  
|-------------------|-------|----------------------|  
|`photoAntes`       |`File?`|tipo `antes-depois`   |  
|`photoDepois`      |`File?`|tipo `antes-depois`   |  
|`photoResultado`   |`File?`|tipo `resultado`      |  
|`comparison.photoA`|`File?`|cada `ComparisonModel`|  
|`comparison.photoB`|`File?`|cada `ComparisonModel`|  
  
**Renderização condicional da photo box:**  
  
```dart  
photo != null  
  ? Stack(  
      fit: StackFit.expand,  
      children: [  
        ClipRRect(  
          borderRadius: BorderRadius.circular(12),  
          child: Image.file(photo!, fit: BoxFit.cover),  
        ),  
        Positioned(  
          top: 8, right: 8,  
          child: GestureDetector(  
            onTap: () => _removePhoto(type),  
            child: Container(  
              width: 28, height: 28,  
              decoration: BoxDecoration(  
                color: Colors.black.withOpacity(0.5),  
                shape: BoxShape.circle,  
              ),  
              child: const Icon(Icons.close, color: Colors.white, size: 16),  
            ),  
          ),  
        ),  
      ],  
    )  
  : Column(  
      mainAxisAlignment: MainAxisAlignment.center,  
      children: [  
        Icon(Icons.camera_alt_outlined, size: 48,  
            color: const Color(0xFF8E8E93).withOpacity(0.3)),  
        const SizedBox(height: 8),  
        Text(label, style: const TextStyle(  
            fontSize: 13, color: Color(0xFF8E8E93))),  
      ],  
    )  
```  
  
-----  
  
## DISPOSE — OBRIGATÓRIO  
  
Todo `TextEditingController` deve ser descartado no `dispose()` para evitar memory leaks:  
  
```dart  
@override  
void dispose() {  
  _produtorController.dispose();  
  _produtoController.dispose();  
  _localController.dispose();  
  _talhaoController.dispose();  
  _tamanhoHaController.dispose();  
  _valorController.dispose();  
  _ganhoController.dispose();  
  _economiaADController.dispose();  
  _quantidadeController.dispose();  
  _economiaRController.dispose();  
  _vendedorController.dispose();  
  _telefoneController.dispose();  
  _descricaoController.dispose();  
  _conclusaoController.dispose();  
  _investimentoController.dispose();  
  _retornoController.dispose();  
  super.dispose();  
}  
```  
  
-----  
  
## FLUXO DE DADOS — CICLO COMPLETO  
  
```  
Usuário escolhe tipo  
        ↓  
_handleTypeChange() → setState() → build() reconstrói seções  
        ↓  
Usuário toca na photo box  
        ↓  
_pickImage(type) → ImagePicker.pickImage()  
        ↓  
_compressImage() → FlutterImageCompress → File comprimido  
        ↓  
setState() → File? atualizado → build() exibe preview  
        ↓  
[Opcional] _addComparison() → comparisonCount++ → comparisons.add()  
[Opcional] _addROI()        → hasROI = true  
[Opcional] _addConclusao()  → hasConclusao = true  
        ↓  
_calculateROI() via onChanged → setState() → display atualiza em tempo real  
        ↓  
_handleSave()    → SnackBar sem validação  
    OU  
_handlePublish() → validações → SnackBar de erro ou sucesso  
```  
  
-----  
  
## RESTRIÇÕES SINGLETON  
  
|Bloco      |Flag de controle|Bloqueio                   |  
|-----------|----------------|---------------------------|  
|Conclusão  |`hasConclusao`  |`if (hasConclusao) return;`|  
|ROI        |`hasROI`        |`if (hasROI) return;`      |  
|Comparações|—               |Sem limite                 |  
  
-----  
  
## NOTAS IMPORTANTES  
  
- **`comparisonCount` nunca decrementa** — garante IDs únicos mesmo após deleções. Ao deletar a comparação 2 e criar uma nova, ela recebe ID 3.  
- **`setState()`** após cada operação de foto, comparação, ROI e conclusão é obrigatório para o `build()` recriar a UI.  
- **`onChanged: (_) => setState(() {})`** nos campos de ROI força rebuild para atualizar o display do cálculo em tempo real.  
- **`GestureDetector` na raiz** para fechar o `addMenu` ao tocar fora garante UX consistente sem necessidade de `FocusNode`.  
- **`AnimatedSize`** é preferível ao `AnimatedCrossFade` para o colapso das comparações — mais simples e performático para variações de altura.  
- **`SnackBarBehavior.floating`** eleva o SnackBar acima do footer fixo, evitando sobreposição com os botões Salvar/Publicar.  
