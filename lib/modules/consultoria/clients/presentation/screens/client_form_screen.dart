import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:soloforte_app/core/ui/sheets/soloforte_sheet.dart';
import 'package:uuid/uuid.dart';
import '../providers/clients_providers.dart';
import '../../domain/client.dart';
import '../../domain/client_cultura.dart';
import '../../domain/enums/cultura_tipo.dart';
import '../widgets/client_avatar_widget.dart';
import '../widgets/cultura_item_widget.dart';
import '../../../../../ui/theme/premium/design_tokens.dart';

class ClientFormScreen extends ConsumerStatefulWidget {
  const ClientFormScreen({super.key});

  @override
  ConsumerState<ClientFormScreen> createState() => _ClientFormScreenState();
}

class _ClientFormScreenState extends ConsumerState<ClientFormScreen> {
  final _formKey = GlobalKey<FormState>();

  // ── Seção 0 — Foto
  String? _fotoPath;

  // ── Seção 1 — Identificação
  final _nomeController = TextEditingController();
  final _emailController = TextEditingController();
  final _telefoneController = TextEditingController();
  final _cpfCnpjController = TextEditingController();
  DateTime? _dataNascimento;

  // ── Seção 2 — Localização
  final _cidadeController = TextEditingController();
  final _ufController = TextEditingController();

  // ── Seção 3 — Propriedade
  final _areaTotalController = TextEditingController();
  String? _tipoPropriedade;
  final List<_AreaPropriedade> _areas = [];
  String? _sistemaIrrigacao;
  String? _soloTipo;
  final _regiaoAgricolaController = TextEditingController();
  final _safraAtualController = TextEditingController();
  bool _usaAssistencia = false;
  final _tecnicoResponsavelController = TextEditingController();

  // ── Seção 4 — Culturas
  final List<ClientCultura> _culturas = [];

  // ── Seção 5 — Observações
  final _observacoesController = TextEditingController();

  @override
  void dispose() {
    _nomeController.dispose();
    _emailController.dispose();
    _telefoneController.dispose();
    _cpfCnpjController.dispose();
    _cidadeController.dispose();
    _ufController.dispose();
    _areaTotalController.dispose();
    _regiaoAgricolaController.dispose();
    _safraAtualController.dispose();
    _tecnicoResponsavelController.dispose();
    _observacoesController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    await showSoloForteSheet<void>(
      context: context,
      showDragHandle: false,
      useSafeArea: false,
      preserveMaterialDefaults: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Câmera'),
              onTap: () async {
                Navigator.of(ctx).pop();
                final picked = await ImagePicker().pickImage(
                  source: ImageSource.camera,
                );
                if (!mounted) return;
                if (picked != null) setState(() => _fotoPath = picked.path);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Galeria'),
              onTap: () async {
                Navigator.of(ctx).pop();
                final picked = await ImagePicker().pickImage(
                  source: ImageSource.gallery,
                );
                if (!mounted) return;
                if (picked != null) setState(() => _fotoPath = picked.path);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDataNascimento() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dataNascimento ?? DateTime(1990),
      firstDate: DateTime(1920),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _dataNascimento = picked);
  }

  Future<void> _abrirBottomSheetCultura() async {
    final formKey = GlobalKey<FormState>();
    CulturaTipo? culturaSelecionada;
    final areaController = TextEditingController();
    final variedadeController = TextEditingController();
    final safraController = TextEditingController();
    final obsController = TextEditingController();

    await showSoloForteSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: false,
      useSafeArea: false,
      preserveMaterialDefaults: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Adicionar Cultura',
                    style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<CulturaTipo>(
                    decoration: _inputDeco('Cultura *'),
                    items: CulturaTipo.values
                        .map(
                          (c) =>
                              DropdownMenuItem(value: c, child: Text(c.label)),
                        )
                        .toList(),
                    onChanged: (v) =>
                        setModalState(() => culturaSelecionada = v),
                    validator: (v) =>
                        v == null ? 'Selecione uma cultura' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: areaController,
                    decoration: _inputDeco('Área (ha) *'),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    validator: (v) {
                      final d = double.tryParse(v ?? '');
                      if (d == null || d <= 0) return 'Informe área > 0';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: variedadeController,
                    decoration: _inputDeco('Variedade / Cultivar'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: safraController,
                    decoration: _inputDeco('Safra (ex: 2024/2025)'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: obsController,
                    decoration: _inputDeco('Observação'),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: PremiumTokens.brandGreen,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () {
                        if (formKey.currentState?.validate() != true) return;
                        final nova = ClientCultura(
                          id: const Uuid().v4(),
                          clientId: '',
                          cultura: culturaSelecionada!.name,
                          areaHa: double.parse(areaController.text),
                          variedade: variedadeController.text.isEmpty
                              ? null
                              : variedadeController.text,
                          safra: safraController.text.isEmpty
                              ? null
                              : safraController.text,
                          observacao: obsController.text.isEmpty
                              ? null
                              : obsController.text,
                          createdAt: DateTime.now(),
                          updatedAt: DateTime.now(),
                        );
                        Navigator.of(ctx).pop();
                        setState(() => _culturas.add(nova));
                      },
                      child: const Text('Confirmar'),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _abrirBottomSheetArea() async {
    final formKey = GlobalKey<FormState>();
    final areaController = TextEditingController();
    String? tipoSelecionado;

    await showSoloForteSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: false,
      useSafeArea: false,
      preserveMaterialDefaults: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Adicionar Área',
                    style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: areaController,
                    decoration: _inputDeco('Tamanho da área (ha) *'),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    validator: (value) {
                      final area = _parseArea(value);
                      if (area == null || area <= 0) return 'Informe área > 0';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    decoration: _inputDeco('Tipo da área *'),
                    items: const [
                      DropdownMenuItem(
                        value: 'propria',
                        child: Text('Própria'),
                      ),
                      DropdownMenuItem(
                        value: 'arrendada',
                        child: Text('Arrendada'),
                      ),
                    ],
                    onChanged: (value) =>
                        setModalState(() => tipoSelecionado = value),
                    validator: (value) =>
                        value == null ? 'Selecione o tipo da área' : null,
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: PremiumTokens.brandGreen,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () {
                        if (formKey.currentState?.validate() != true) return;
                        setState(() {
                          _areas.add(
                            _AreaPropriedade(
                              areaHa: _parseArea(areaController.text)!,
                              tipo: tipoSelecionado!,
                            ),
                          );
                          _atualizarResumoAreas();
                        });
                        Navigator.of(ctx).pop();
                      },
                      child: const Text('Adicionar'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  double? _parseArea(String? value) =>
      double.tryParse((value ?? '').trim().replaceAll(',', '.'));

  void _atualizarResumoAreas() {
    final total = _areas.fold<double>(0, (sum, area) => sum + area.areaHa);
    final tipos = _areas.map((area) => area.tipo).toSet();
    _areaTotalController.text = _areas.isEmpty ? '' : total.toString();
    _tipoPropriedade = tipos.length > 1 ? 'mista' : tipos.firstOrNull;
  }

  Future<void> _saveClient() async {
    if (_formKey.currentState?.validate() != true) return;
    HapticFeedback.mediumImpact();

    final clientId = const Uuid().v4();
    final cpfSoDigitos = _cpfCnpjController.text.isEmpty
        ? null
        : _cpfCnpjController.text.replaceAll(RegExp(r'\D'), '');

    final newClient = Client(
      id: clientId,
      name: _nomeController.text.trim(),
      phone: _telefoneController.text.trim(),
      city: _cidadeController.text.trim(),
      state: _ufController.text.trim().toUpperCase(),
      email: _emailController.text.trim().isEmpty
          ? null
          : _emailController.text.trim(),
      observation: _observacoesController.text.trim().isEmpty
          ? null
          : _observacoesController.text.trim(),
      photoPath: _fotoPath,
      active: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      dataNascimento: _dataNascimento,
      cpfCnpj: cpfSoDigitos,
      areaTotal: double.tryParse(_areaTotalController.text),
      tipoPropriedade: _tipoPropriedade,
      sistemaIrrigacao: _sistemaIrrigacao,
      soloTipo: _soloTipo,
      regiaoAgricola: _regiaoAgricolaController.text.trim().isEmpty
          ? null
          : _regiaoAgricolaController.text.trim(),
      safraAtual: _safraAtualController.text.trim().isEmpty
          ? null
          : _safraAtualController.text.trim(),
      usaAssistenciaTecnica: _usaAssistencia,
      tecnicoResponsavel:
          _usaAssistencia &&
              _tecnicoResponsavelController.text.trim().isNotEmpty
          ? _tecnicoResponsavelController.text.trim()
          : null,
    );

    final culturasComId = _culturas
        .map((c) => c.copyWith(clientId: clientId))
        .toList();

    await ref
        .read(clientsControllerProvider)
        .saveClient(newClient, culturas: culturasComId);

    if (!mounted) return;
    context.go('/consultoria/clientes');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildFotoSection(),
                      const SizedBox(height: 28),
                      _sectionTitle('Identificação'),
                      _buildIdentificacaoSection(),
                      const SizedBox(height: 28),
                      _sectionTitle('Localização'),
                      _buildLocalizacaoSection(),
                      const SizedBox(height: 28),
                      _sectionTitle('Propriedade'),
                      _buildPropriedadeSection(),
                      const SizedBox(height: 28),
                      _sectionTitle('Culturas'),
                      _buildCulturasSection(),
                      const SizedBox(height: 28),
                      _sectionTitle('Observações Gerais'),
                      TextFormField(
                        controller: _observacoesController,
                        decoration: _inputDeco('Observações'),
                        maxLines: 4,
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.go('/consultoria/clientes'),
          ),
          const Text(
            'Novo Cliente',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          TextButton(
            onPressed: _saveClient,
            child: const Text(
              'Salvar',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: PremiumTokens.brandGreen,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    ),
  );

  Widget _buildFotoSection() => Center(
    child: Column(
      children: [
        GestureDetector(
          onTap: _pickImage,
          child: ClientAvatarWidget(
            fotoPath: _fotoPath,
            nome: _nomeController.text.isEmpty ? '?' : _nomeController.text,
            radius: 48,
          ),
        ),
        const SizedBox(height: 8),
        const Text('Adicionar Foto', style: TextStyle(color: Colors.grey)),
      ],
    ),
  );

  Widget _buildIdentificacaoSection() => Column(
    children: [
      _field(
        controller: _nomeController,
        label: 'Nome Completo *',
        validator: (v) {
          if (v == null || v.trim().length < 2) return 'Mínimo 2 caracteres';
          return null;
        },
        onChanged: (_) => setState(() {}),
      ),
      const SizedBox(height: 12),
      _field(
        controller: _emailController,
        label: 'E-mail',
        keyboardType: TextInputType.emailAddress,
        validator: (v) {
          if (v == null || v.isEmpty) return null;
          if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v)) {
            return 'E-mail inválido';
          }
          return null;
        },
      ),
      const SizedBox(height: 12),
      _field(
        controller: _telefoneController,
        label: 'Telefone',
        keyboardType: TextInputType.phone,
      ),
      const SizedBox(height: 12),
      _field(
        controller: _cpfCnpjController,
        label: 'CPF / CNPJ',
        keyboardType: TextInputType.number,
      ),
      const SizedBox(height: 12),
      GestureDetector(
        onTap: _pickDataNascimento,
        child: AbsorbPointer(
          child: _field(
            controller: TextEditingController(
              text: _dataNascimento != null
                  ? '${_dataNascimento!.day.toString().padLeft(2, '0')}/${_dataNascimento!.month.toString().padLeft(2, '0')}/${_dataNascimento!.year}'
                  : '',
            ),
            label: 'Data de Nascimento',
            suffixIcon: const Icon(Icons.calendar_today, size: 18),
          ),
        ),
      ),
    ],
  );

  Widget _buildLocalizacaoSection() => Row(
    children: [
      Expanded(
        flex: 2,
        child: _field(controller: _cidadeController, label: 'Cidade'),
      ),
      const SizedBox(width: 12),
      Expanded(
        flex: 1,
        child: _field(
          controller: _ufController,
          label: 'UF',
          inputFormatters: [
            LengthLimitingTextInputFormatter(2),
            _UpperCaseFormatter(),
          ],
        ),
      ),
    ],
  );

  Widget _buildPropriedadeSection() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      if (_areas.isEmpty)
        Text(
          'Nenhuma área adicionada',
          style: TextStyle(color: Colors.grey[600]),
        )
      else ...[
        ...List.generate(_areas.length, (index) {
          final area = _areas[index];
          return ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(
              Icons.landscape_outlined,
              color: PremiumTokens.brandGreen,
            ),
            title: Text('${_formatArea(area.areaHa)} ha'),
            subtitle: Text(area.tipoLabel),
            trailing: IconButton(
              tooltip: 'Remover área',
              icon: const Icon(Icons.delete_outline),
              onPressed: () => setState(() {
                _areas.removeAt(index);
                _atualizarResumoAreas();
              }),
            ),
          );
        }),
        const SizedBox(height: 8),
        _buildResumoAreas(),
      ],
      TextButton.icon(
        onPressed: _abrirBottomSheetArea,
        icon: const Icon(Icons.add, color: PremiumTokens.brandGreen),
        label: const Text(
          'Adicionar Área',
          style: TextStyle(color: PremiumTokens.brandGreen),
        ),
      ),
      const SizedBox(height: 16),
      _chipRow(
        'Irrigação',
        const ['sequeiro', 'irrigado', 'misto'],
        const ['Sequeiro', 'Irrigado', 'Misto'],
        _sistemaIrrigacao,
        (v) => setState(() => _sistemaIrrigacao = v),
      ),
      const SizedBox(height: 16),
      _chipRow(
        'Solo',
        const ['arenoso', 'argiloso', 'misto', 'outro'],
        const ['Arenoso', 'Argiloso', 'Misto', 'Outro'],
        _soloTipo,
        (v) => setState(() => _soloTipo = v),
      ),
      const SizedBox(height: 16),
      _field(controller: _regiaoAgricolaController, label: 'Região Agrícola'),
      const SizedBox(height: 12),
      _field(
        controller: _safraAtualController,
        label: 'Safra Atual (ex: 2024/2025)',
      ),
      const SizedBox(height: 12),
      SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: const Text('Usa Assistência Técnica'),
        value: _usaAssistencia,
        activeThumbColor: PremiumTokens.brandGreen,
        onChanged: (v) => setState(() => _usaAssistencia = v),
      ),
      AnimatedSize(
        duration: const Duration(milliseconds: 200),
        child: Visibility(
          visible: _usaAssistencia,
          child: Padding(
            padding: const EdgeInsets.only(top: 12),
            child: _field(
              controller: _tecnicoResponsavelController,
              label: 'Técnico Responsável',
            ),
          ),
        ),
      ),
    ],
  );

  Widget _buildResumoAreas() {
    final total = _areas.fold<double>(0, (sum, area) => sum + area.areaHa);
    final propria = _areas
        .where((area) => area.tipo == 'propria')
        .fold<double>(0, (sum, area) => sum + area.areaHa);
    final arrendada = total - propria;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Área cultivada total: ${_formatArea(total)} ha',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Text('Própria: ${_formatPercentual(propria, total)}'),
          Text('Arrendada: ${_formatPercentual(arrendada, total)}'),
        ],
      ),
    );
  }

  String _formatArea(double value) => value == value.truncateToDouble()
      ? value.toStringAsFixed(0)
      : value.toStringAsFixed(2).replaceFirst(RegExp(r'0+$'), '');

  String _formatPercentual(double area, double total) =>
      '${total == 0 ? '0' : (area / total * 100).toStringAsFixed(1)}%';

  Widget _buildCulturasSection() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      if (_culturas.isEmpty)
        Container(
          padding: const EdgeInsets.all(24),
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Column(
            children: [
              Icon(Icons.eco, size: 36, color: Colors.grey[400]),
              const SizedBox(height: 8),
              Text(
                'Nenhuma cultura adicionada',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
        )
      else
        ...List.generate(
          _culturas.length,
          (i) => CulturaItemWidget(
            cultura: _culturas[i],
            onRemove: () => setState(() => _culturas.removeAt(i)),
          ),
        ),
      const SizedBox(height: 8),
      TextButton.icon(
        icon: const Icon(Icons.add, color: PremiumTokens.brandGreen),
        label: const Text(
          'Adicionar Cultura',
          style: TextStyle(color: PremiumTokens.brandGreen),
        ),
        onPressed: _abrirBottomSheetCultura,
      ),
    ],
  );

  Widget _field({
    required TextEditingController controller,
    required String label,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    Widget? suffixIcon,
    int maxLines = 1,
    List<TextInputFormatter>? inputFormatters,
    ValueChanged<String>? onChanged,
  }) => TextFormField(
    controller: controller,
    decoration: _inputDeco(label, suffixIcon: suffixIcon),
    keyboardType: maxLines > 1 ? TextInputType.multiline : keyboardType,
    maxLines: maxLines,
    validator: validator,
    inputFormatters: inputFormatters,
    onChanged: onChanged,
  );

  InputDecoration _inputDeco(String label, {Widget? suffixIcon}) =>
      InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.grey[50],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        suffixIcon: suffixIcon,
      );

  Widget _chipRow(
    String title,
    List<String> options,
    List<String> labels,
    String? selected,
    ValueChanged<String?> onSelected,
  ) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(title, style: const TextStyle(fontSize: 13, color: Colors.black54)),
      const SizedBox(height: 6),
      Wrap(
        spacing: 8,
        children: List.generate(options.length, (i) {
          final isSel = selected == options[i];
          return ChoiceChip(
            label: Text(labels[i]),
            selected: isSel,
            selectedColor: PremiumTokens.brandGreen,
            labelStyle: TextStyle(
              color: isSel ? Colors.white : Colors.black87,
              fontWeight: isSel ? FontWeight.w600 : FontWeight.normal,
            ),
            onSelected: (_) => onSelected(isSel ? null : options[i]),
          );
        }),
      ),
    ],
  );
}

class _UpperCaseFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue o, TextEditingValue n) =>
      n.copyWith(text: n.text.toUpperCase());
}

class _AreaPropriedade {
  final double areaHa;
  final String tipo;

  const _AreaPropriedade({required this.areaHa, required this.tipo});

  String get tipoLabel => tipo == 'propria' ? 'Própria' : 'Arrendada';
}
