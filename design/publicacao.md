# PROMPT: CRIAR ARQUIVO MAIN.DART COMPLETO - SOLOFORTE CASE

Crie um arquivo `main.dart` completo e funcional em Flutter/Dart para uma aplicação de gerenciamento de cases agrícolas chamada "SoloForte Case". O código deve ser um arquivo único, pronto para rodar, seguindo rigorosamente o design minimalista iOS.

## ESPECIFICAÇÕES TÉCNICAS

### Packages necessários no pubspec.yaml:
```yaml
dependencies:
  flutter:
    sdk: flutter
  image_picker: ^1.0.4
  flutter_image_compress: ^2.1.0
```

### Imports obrigatórios:
```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
```

## CORES EXATAS (use Color())

```dart
// Principais
const primaryBlue = Color(0xFF0057FF);
const white = Color(0xFFFFFFFF);

// Grays
const gray100 = Color(0xFFF5F5F7);  // Backgrounds
const gray200 = Color(0xFFE5E5EA);  // Bordas
const gray400 = Color(0xFFAEAEB2);  // Placeholders
const gray600 = Color(0xFF8E8E93);  // Labels
const gray900 = Color(0xFF1C1C1E);  // Texto principal

// Medalhas (usar LinearGradient)
Bronze: [Color(0xFFCD7F32), Color(0xFFA0522D)]
Prata: [Color(0xFFE8E8E8), Color(0xFFA9A9A9)]
Ouro: [Color(0xFFFFD700), Color(0xFFFFA500)]
```

## ESTRUTURA PRINCIPAL

### 1. Main App
```dart
void main() => runApp(const SoloForteApp());

class SoloForteApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SoloForte',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: Color(0xFF0057FF),
        scaffoldBackgroundColor: Colors.white,
      ),
      home: const NovoCaseScreen(),
    );
  }
}
```

### 2. Screen Principal
```dart
class NovoCaseScreen extends StatefulWidget {
  @override
  State<NovoCaseScreen> createState() => _NovoCaseScreenState();
}
```

### 3. State com todas as variáveis:

```dart
class _NovoCaseScreenState extends State<NovoCaseScreen> {
  // Controllers (criar para TODOS os campos)
  final _produtorController = TextEditingController();
  final _produtoController = TextEditingController();
  final _localController = TextEditingController();
  final _talhaoController = TextEditingController();
  final _tamanhoHaController = TextEditingController();
  final _valorController = TextEditingController();
  final _ganhoController = TextEditingController();
  final _economiaADController = TextEditingController();
  final _quantidadeController = TextEditingController();
  final _economiaRController = TextEditingController();
  final _vendedorController = TextEditingController();
  final _telefoneController = TextEditingController();
  final _descricaoController = TextEditingController();
  
  // State
  String selectedType = 'resultado';
  String selectedSize = 'silver';
  String selectedUnit = 'sc/ha';
  
  File? photoAntes;
  File? photoDepois;
  File? photoResultado;
  
  List<Comparison> comparisons = [];
  bool showAddMenu = false;
  
  final ImagePicker _picker = ImagePicker();
  
  @override
  void dispose() {
    // Dispose TODOS os controllers
    _produtorController.dispose();
    // ... etc
    super.dispose();
  }
}
```

## LAYOUT COMPLETO

### Build Method:
```dart
@override
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: Colors.white,
    body: SafeArea(
      child: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildTipoSection(),
                  _buildVisibilidadeSection(),
                  if (selectedType == 'antes-depois') _buildAntesDepoisSection(),
                  if (selectedType == 'resultado') _buildResultadoSection(),
                  if (selectedType == 'avaliacao') _buildAvaliacaoSection(),
                  _buildInformacoesSection(),
                  if (selectedType != 'avaliacao') _buildProdutividadeSection(),
                  if (selectedType == 'antes-depois') _buildGanhosSection(),
                  if (selectedType == 'resultado') _buildResultadoFieldsSection(),
                  _buildVendedorSection(),
                  _buildDescricaoSection(),
                  SizedBox(height: 100), // Espaço para footer
                ],
              ),
            ),
          ),
          _buildFooter(),
        ],
      ),
    ),
  );
}
```

## WIDGETS OBRIGATÓRIOS

### 1. Header (fixo no topo)
```dart
Widget _buildHeader() {
  return Container(
    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.95),
      border: Border(bottom: BorderSide(color: Color(0xFFE5E5EA), width: 0.5)),
    ),
    child: Center(
      child: Text(
        'Novo Case',
        style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, letterSpacing: -0.4),
      ),
    ),
  );
}
```

### 2. Section Helper (reutilizável)
```dart
Widget _buildSection({required String title, required Widget child}) {
  return Container(
    padding: EdgeInsets.all(20),
    decoration: BoxDecoration(
      border: Border(bottom: BorderSide(color: Color(0xFFE5E5EA), width: 0.5)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF8E8E93),
            letterSpacing: -0.08,
          ),
        ),
        SizedBox(height: 12),
        child,
      ],
    ),
  );
}
```

### 3. TextField Helper
```dart
Widget _buildTextField({
  TextEditingController? controller,
  String? label,
  String? placeholder,
  TextInputType? keyboardType,
  int maxLines = 1,
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      if (label != null) ...[
        Text(label, style: TextStyle(fontSize: 13, color: Color(0xFF8E8E93))),
        SizedBox(height: 6),
      ],
      TextField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        style: TextStyle(fontSize: 17, color: Color(0xFF1C1C1E)),
        decoration: InputDecoration(
          hintText: placeholder,
          hintStyle: TextStyle(color: Color(0xFFAEAEB2)),
          filled: true,
          fillColor: Color(0xFFF5F5F7),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
          contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
      ),
    ],
  );
}
```

### 4. Tipo Section (Dropdown)
```dart
Widget _buildTipoSection() {
  return _buildSection(
    title: 'TIPO',
    child: Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Color(0xFFF5F5F7),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedType,
          isExpanded: true,
          icon: Icon(Icons.keyboard_arrow_down, color: Color(0xFFAEAEB2)),
          style: TextStyle(fontSize: 17, color: Color(0xFF1C1C1E)),
          items: [
            DropdownMenuItem(value: 'resultado', child: Text('Resultado')),
            DropdownMenuItem(value: 'antes-depois', child: Text('Antes/Depois')),
            DropdownMenuItem(value: 'avaliacao', child: Text('Avaliação/Campo')),
          ],
          onChanged: (value) => setState(() => selectedType = value!),
        ),
      ),
    ),
  );
}
```

### 5. Visibilidade Section (Medalhas)
```dart
Widget _buildVisibilidadeSection() {
  return _buildSection(
    title: 'VISIBILIDADE',
    child: Row(
      children: [
        Expanded(child: _buildSizeButton('bronze', 'Bronze')),
        SizedBox(width: 10),
        Expanded(child: _buildSizeButton('silver', 'Prata')),
        SizedBox(width: 10),
        Expanded(child: _buildSizeButton('gold', 'Ouro')),
      ],
    ),
  );
}

Widget _buildSizeButton(String size, String label) {
  final isActive = selectedSize == size;
  
  return GestureDetector(
    onTap: () => setState(() => selectedSize = size),
    child: AnimatedContainer(
      duration: Duration(milliseconds: 200),
      padding: EdgeInsets.symmetric(vertical: 18),
      decoration: BoxDecoration(
        gradient: isActive && size == 'bronze'
            ? LinearGradient(colors: [Color(0xFFCD7F32), Color(0xFFA0522D)])
            : isActive && size == 'silver'
                ? LinearGradient(colors: [Color(0xFFE8E8E8), Color(0xFFA9A9A9)])
                : isActive && size == 'gold'
                    ? LinearGradient(colors: [Color(0xFFFFD700), Color(0xFFFFA500)])
                    : null,
        color: !isActive ? Color(0xFFF5F5F7) : null,
        borderRadius: BorderRadius.circular(14),
        boxShadow: isActive ? [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 12, offset: Offset(0, 4))] : null,
      ),
      transform: isActive ? (Matrix4.identity()..scale(1.05)) : Matrix4.identity(),
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: !isActive ? Color(0xFF8E8E93) : (size == 'silver' || size == 'gold' ? Color(0xFF2C2C2C) : Colors.white),
          ),
        ),
      ),
    ),
  );
}
```

### 6. Photo Box
```dart
Widget _buildPhotoBox({
  required String label,
  required File? photo,
  required VoidCallback onTap,
  required VoidCallback onRemove,
  bool tall = false,
  bool showTag = false,
}) {
  return GestureDetector(
    onTap: onTap,
    child: AspectRatio(
      aspectRatio: tall ? 9 / 16 : 1,
      child: Container(
        constraints: tall ? BoxConstraints(maxHeight: 280) : null,
        decoration: BoxDecoration(
          color: Color(0xFFF5F5F7),
          borderRadius: BorderRadius.circular(12),
        ),
        child: photo != null
            ? Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(photo, fit: BoxFit.cover),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: onRemove,
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.close, color: Colors.white, size: 16),
                      ),
                    ),
                  ),
                  if (showTag)
                    Positioned(
                      bottom: 8,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            label.toUpperCase(),
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white, letterSpacing: 0.5),
                          ),
                        ),
                      ),
                    ),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.camera_alt_outlined, size: 48, color: Color(0xFF8E8E93).withOpacity(0.3)),
                  SizedBox(height: 8),
                  Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF8E8E93))),
                ],
              ),
      ),
    ),
  );
}
```

### 7. Antes/Depois Section
```dart
Widget _buildAntesDepoisSection() {
  return _buildSection(
    title: 'FOTOS',
    child: Row(
      children: [
        Expanded(
          child: _buildPhotoBox(
            label: 'Antes',
            photo: photoAntes,
            onTap: () => _pickImage('antes'),
            onRemove: () => setState(() => photoAntes = null),
            showTag: true,
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: _buildPhotoBox(
            label: 'Depois',
            photo: photoDepois,
            onTap: () => _pickImage('depois'),
            onRemove: () => setState(() => photoDepois = null),
            showTag: true,
          ),
        ),
      ],
    ),
  );
}
```

### 8. Resultado Section
```dart
Widget _buildResultadoSection() {
  return _buildSection(
    title: 'FOTO',
    child: _buildPhotoBox(
      label: 'Adicionar foto',
      photo: photoResultado,
      onTap: () => _pickImage('resultado'),
      onRemove: () => setState(() => photoResultado = null),
      tall: true,
    ),
  );
}
```

### 9. Avaliação Section (básico)
```dart
Widget _buildAvaliacaoSection() {
  return _buildSection(
    title: 'TALHÃO',
    child: Column(
      children: [
        _buildTextField(
          controller: _talhaoController,
          label: 'Nome do Talhão',
          placeholder: 'Ex: Talhão Norte',
        ),
        SizedBox(height: 16),
        _buildTextField(
          controller: _tamanhoHaController,
          label: 'Tamanho (ha)',
          placeholder: '0.00',
          keyboardType: TextInputType.number,
        ),
        SizedBox(height: 20),
        // Aqui viriam as comparações (simplificado)
        _buildAddMenu(),
      ],
    ),
  );
}
```

### 10. Add Menu
```dart
Widget _buildAddMenu() {
  return Column(
    children: [
      GestureDetector(
        onTap: () => setState(() => showAddMenu = !showAddMenu),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Color(0xFFE5E5EA), width: 2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              '+ Adicionar',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w400, color: Color(0xFF0057FF)),
            ),
          ),
        ),
      ),
      if (showAddMenu)
        Container(
          margin: EdgeInsets.only(top: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 20, offset: Offset(0, 4))],
          ),
          child: Column(
            children: [
              _buildMenuItem('Avaliação', () => setState(() => showAddMenu = false)),
              _buildMenuItem('Conclusão', () => setState(() => showAddMenu = false)),
              _buildMenuItem('ROI', () => setState(() => showAddMenu = false), isLast: true),
            ],
          ),
        ),
    ],
  );
}

Widget _buildMenuItem(String label, VoidCallback onTap, {bool isLast = false}) {
  return InkWell(
    onTap: onTap,
    child: Container(
      width: double.infinity,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: isLast ? null : Border(bottom: BorderSide(color: Color(0xFFE5E5EA), width: 0.5)),
      ),
      child: Text(label, style: TextStyle(fontSize: 17)),
    ),
  );
}
```

### 11. Informações Section
```dart
Widget _buildInformacoesSection() {
  return _buildSection(
    title: 'INFORMAÇÕES',
    child: Column(
      children: [
        _buildTextField(controller: _produtorController, label: 'Produtor / Fazenda', placeholder: 'Ex: Fazenda Santa Rita'),
        SizedBox(height: 16),
        _buildTextField(controller: _produtoController, label: 'Produto Utilizado', placeholder: 'Ex: Soja Olimpo'),
        SizedBox(height: 16),
        _buildTextField(controller: _localController, label: 'Localização', placeholder: 'Jataizinho - PR'),
      ],
    ),
  );
}
```

### 12. Footer (fixo no bottom)
```dart
Widget _buildFooter() {
  return Container(
    padding: EdgeInsets.fromLTRB(20, 16, 20, 28),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.95),
      border: Border(top: BorderSide(color: Color(0xFFE5E5EA), width: 0.5)),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ElevatedButton(
          onPressed: _handleSave,
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFFF5F5F7),
            foregroundColor: Color(0xFF1C1C1E),
            elevation: 0,
            padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
          ),
          child: Text('Salvar', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w500)),
        ),
        SizedBox(width: 12),
        ElevatedButton(
          onPressed: _handlePublish,
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFF0057FF),
            foregroundColor: Colors.white,
            elevation: 0,
            padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
          ),
          child: Text('Publicar', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w500)),
        ),
      ],
    ),
  );
}
```

## FUNÇÕES NECESSÁRIAS

### Upload de Imagem
```dart
Future<void> _pickImage(String type) async {
  final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
  if (image != null) {
    setState(() {
      switch (type) {
        case 'antes':
          photoAntes = File(image.path);
          break;
        case 'depois':
          photoDepois = File(image.path);
          break;
        case 'resultado':
          photoResultado = File(image.path);
          break;
      }
    });
  }
}
```

### Salvar (sem validação)
```dart
void _handleSave() {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('💾 Rascunho salvo!')),
  );
}
```

### Publicar (com validação)
```dart
void _handlePublish() {
  if (_produtorController.text.isEmpty || _produtoController.text.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Preencha os campos obrigatórios')),
    );
    return;
  }

  if (selectedType == 'antes-depois' && (photoAntes == null || photoDepois == null)) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Adicione as fotos de antes e depois')),
    );
    return;
  }

  if (selectedType == 'resultado' && photoResultado == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Adicione a foto do resultado')),
    );
    return;
  }

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('✅ Case publicado com sucesso!')),
  );
}
```

## CRIAR TAMBÉM AS OUTRAS SECTIONS

Use o mesmo padrão de _buildSection() para criar:
- _buildProdutividadeSection() - grid 2:1 com valor e dropdown de unidade
- _buildGanhosSection() - 2 campos (ganho e economia)
- _buildResultadoFieldsSection() - 2 campos (quantidade e economia)
- _buildVendedorSection() - 2 campos (nome e telefone)
- _buildDescricaoSection() - textarea com 5 linhas

## CLASS AUXILIAR

```dart
class Comparison {
  final int id;
  bool collapsed;
  
  Comparison({required this.id, this.collapsed = false});
}
```

## REQUISITOS FINAIS

1. ✅ Código deve compilar sem erros
2. ✅ Todas as cores EXATAS especificadas
3. ✅ Todos os tamanhos de fonte EXATOS
4. ✅ Animações suaves (200ms)
5. ✅ Design minimalista iOS
6. ✅ Validações funcionando
7. ✅ Upload de fotos operacional
8. ✅ Dispose de todos os controllers

**GERE O CÓDIGO COMPLETO DE main.dart PRONTO PARA USAR!**
