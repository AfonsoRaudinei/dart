// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:soloforte_app/core/constants/layout_constants.dart';
import 'package:soloforte_app/ui/theme/premium/design_tokens.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import '../../domain/client.dart';
import '../../domain/client_cultura.dart';
import '../../domain/enums/cultura_tipo.dart';
import '../widgets/client_avatar_widget.dart';
import '../widgets/cultura_item_widget.dart';
import '../widgets/client_detail_sub_widgets.dart';

// ── Formulário de edição de cliente (extraído de client_detail_screen) ───
// Sprint 7 — Bounded Context Hygiene: mantém client_detail_screen < 900 linhas.

typedef ClientEditSaveCallback = void Function(
  Client clienteAtualizado,
  List<ClientCultura> culturasComId,
);

class ClientEditForm extends StatefulWidget {
  final Client client;
  final List<ClientCultura> culturas;
  final VoidCallback onCancel;
  final ClientEditSaveCallback onSave;

  const ClientEditForm({
    super.key,
    required this.client,
    required this.culturas,
    required this.onCancel,
    required this.onSave,
  });

  @override
  State<ClientEditForm> createState() => _ClientEditFormState();
}

class _ClientEditFormState extends State<ClientEditForm> {
  late TextEditingController _nomeCtrl;
  late TextEditingController _emailCtrl;
  late TextEditingController _telefoneCtrl;
  late TextEditingController _cpfCnpjCtrl;
  late TextEditingController _cidadeCtrl;
  late TextEditingController _ufCtrl;
  late TextEditingController _areaTotalCtrl;
  late TextEditingController _regiaoCtrl;
  late TextEditingController _safraCtrl;
  late TextEditingController _tecnicoCtrl;
  late TextEditingController _obsCtrl;

  late List<ClientCultura> _culturasEditadas;
  DateTime? _dataNascimentoEdit;
  String? _tipoPropriedadeEdit;
  String? _sistemaIrrigacaoEdit;
  String? _soloTipoEdit;
  bool _usaAssistenciaEdit = false;
  String? _fotoPathEdit;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    final c = widget.client;
    _nomeCtrl = TextEditingController(text: c.name);
    _emailCtrl = TextEditingController(text: c.email ?? '');
    _telefoneCtrl = TextEditingController(text: c.phone);
    _cpfCnpjCtrl = TextEditingController(text: c.cpfCnpj ?? '');
    _cidadeCtrl = TextEditingController(text: c.city);
    _ufCtrl = TextEditingController(text: c.state);
    _areaTotalCtrl = TextEditingController(text: c.areaTotal?.toString() ?? '');
    _regiaoCtrl = TextEditingController(text: c.regiaoAgricola ?? '');
    _safraCtrl = TextEditingController(text: c.safraAtual ?? '');
    _tecnicoCtrl = TextEditingController(text: c.tecnicoResponsavel ?? '');
    _obsCtrl = TextEditingController(text: c.observation ?? '');
    _culturasEditadas = List.from(widget.culturas);
    _dataNascimentoEdit = c.dataNascimento;
    _tipoPropriedadeEdit = c.tipoPropriedade;
    _sistemaIrrigacaoEdit = c.sistemaIrrigacao;
    _soloTipoEdit = c.soloTipo;
    _usaAssistenciaEdit = c.usaAssistenciaTecnica ?? false;
    _fotoPathEdit = c.photoPath;
  }

  @override
  void dispose() {
    _nomeCtrl.dispose();
    _emailCtrl.dispose();
    _telefoneCtrl.dispose();
    _cpfCnpjCtrl.dispose();
    _cidadeCtrl.dispose();
    _ufCtrl.dispose();
    _areaTotalCtrl.dispose();
    _regiaoCtrl.dispose();
    _safraCtrl.dispose();
    _tecnicoCtrl.dispose();
    _obsCtrl.dispose();
    super.dispose();
  }

  void _salvar() {
    if (_formKey.currentState?.validate() != true) return;
    HapticFeedback.mediumImpact();

    final clienteAtualizado = widget.client.copyWith(
      name: _nomeCtrl.text.trim(),
      phone: _telefoneCtrl.text.trim(),
      city: _cidadeCtrl.text.trim(),
      state: _ufCtrl.text.trim().toUpperCase(),
      email: _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
      observation: _obsCtrl.text.trim().isEmpty ? null : _obsCtrl.text.trim(),
      photoPath: _fotoPathEdit,
      cpfCnpj: _cpfCnpjCtrl.text.isEmpty
          ? null
          : _cpfCnpjCtrl.text.replaceAll(RegExp(r'\D'), ''),
      dataNascimento: _dataNascimentoEdit,
      areaTotal: double.tryParse(_areaTotalCtrl.text),
      tipoPropriedade: _tipoPropriedadeEdit,
      sistemaIrrigacao: _sistemaIrrigacaoEdit,
      soloTipo: _soloTipoEdit,
      regiaoAgricola:
          _regiaoCtrl.text.trim().isEmpty ? null : _regiaoCtrl.text.trim(),
      safraAtual:
          _safraCtrl.text.trim().isEmpty ? null : _safraCtrl.text.trim(),
      usaAssistenciaTecnica: _usaAssistenciaEdit,
      tecnicoResponsavel:
          _usaAssistenciaEdit && _tecnicoCtrl.text.trim().isNotEmpty
              ? _tecnicoCtrl.text.trim()
              : null,
      updatedAt: DateTime.now(),
    );

    final culturasComId = _culturasEditadas
        .map((c) => c.copyWith(clientId: clienteAtualizado.id))
        .toList();

    widget.onSave(clienteAtualizado, culturasComId);
  }

  Future<void> _pickImage() async {
    await showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Câmera'),
              onTap: () async {
                Navigator.of(ctx).pop();
                final picked =
                    await ImagePicker().pickImage(source: ImageSource.camera);
                if (!mounted) return;
                if (picked != null) setState(() => _fotoPathEdit = picked.path);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Galeria'),
              onTap: () async {
                Navigator.of(ctx).pop();
                final picked =
                    await ImagePicker().pickImage(source: ImageSource.gallery);
                if (!mounted) return;
                if (picked != null) setState(() => _fotoPathEdit = picked.path);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _abrirBottomSheetCultura() async {
    final formKey = GlobalKey<FormState>();
    CulturaTipo? culturaSel;
    final areaCtrl = TextEditingController();
    final variedadeCtrl = TextEditingController();
    final safraCtrl = TextEditingController();
    final obsCtrl = TextEditingController();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Adicionar Cultura',
                      style: Theme.of(ctx)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<CulturaTipo>(
                    decoration: _deco('Cultura *'),
                    items: CulturaTipo.values
                        .map((c) =>
                            DropdownMenuItem(value: c, child: Text(c.label)))
                        .toList(),
                    onChanged: (v) => setS(() => culturaSel = v),
                    validator: (v) => v == null ? 'Selecione uma cultura' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: areaCtrl,
                    decoration: _deco('Área (ha) *'),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    validator: (v) {
                      final d = double.tryParse(v ?? '');
                      if (d == null || d <= 0) return 'Informe área > 0';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: variedadeCtrl,
                    decoration: _deco('Variedade / Cultivar'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(controller: safraCtrl, decoration: _deco('Safra')),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: obsCtrl,
                    decoration: _deco('Observação'),
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
                          clientId: widget.client.id,
                          cultura: culturaSel!.name,
                          areaHa: double.parse(areaCtrl.text),
                          variedade: variedadeCtrl.text.isEmpty
                              ? null
                              : variedadeCtrl.text,
                          safra: safraCtrl.text.isEmpty ? null : safraCtrl.text,
                          observacao:
                              obsCtrl.text.isEmpty ? null : obsCtrl.text,
                          createdAt: DateTime.now(),
                          updatedAt: DateTime.now(),
                        );
                        Navigator.of(ctx).pop();
                        setState(() => _culturasEditadas.add(nova));
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

  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  InputDecoration _deco(String label, {Widget? suffixIcon}) => InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.grey[50],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        suffixIcon: suffixIcon,
      );

  Widget _field(
    TextEditingController ctrl,
    String label, {
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    Widget? suffixIcon,
    int maxLines = 1,
    List<TextInputFormatter>? inputFormatters,
  }) =>
      TextFormField(
        controller: ctrl,
        decoration: _deco(label, suffixIcon: suffixIcon),
        keyboardType: maxLines > 1 ? TextInputType.multiline : keyboardType,
        maxLines: maxLines,
        validator: validator,
        inputFormatters: inputFormatters,
      );

  Widget _sectionTitle(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Text(
          t,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.4,
            color: Colors.black87,
          ),
        ),
      );

  Widget _chipRow(
    String title,
    List<String> options,
    List<String> labels,
    String? selected,
    ValueChanged<String?> onSelected,
  ) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(fontSize: 13, color: Colors.black54)),
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

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              children: [
                TextButton(
                  onPressed: widget.onCancel,
                  child: const Text('Cancelar',
                      style: TextStyle(color: Colors.grey)),
                ),
                const Spacer(),
                const Text(
                  'Editar Cliente',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.4,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: _salvar,
                  child: const Text(
                    'Salvar',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: PremiumTokens.brandGreen),
                  ),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Foto
                  Center(
                    child: Column(
                      children: [
                        GestureDetector(
                          onTap: _pickImage,
                          child: ClientAvatarWidget(
                            fotoPath: _fotoPathEdit,
                            nome: _nomeCtrl.text.isEmpty
                                ? widget.client.name
                                : _nomeCtrl.text,
                            radius: 48,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text('Toque para alterar foto',
                            style: TextStyle(color: Colors.grey, fontSize: 12)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  _sectionTitle('Identificação'),
                  _field(_nomeCtrl, 'Nome Completo *', validator: (v) {
                    if (v == null || v.trim().length < 2) {
                      return 'Mínimo 2 caracteres';
                    }
                    return null;
                  }),
                  const SizedBox(height: 12),
                  _field(_emailCtrl, 'E-mail',
                      keyboardType: TextInputType.emailAddress, validator: (v) {
                    if (v == null || v.isEmpty) return null;
                    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v)) {
                      return 'E-mail inválido';
                    }
                    return null;
                  }),
                  const SizedBox(height: 12),
                  _field(_telefoneCtrl, 'Telefone',
                      keyboardType: TextInputType.phone),
                  const SizedBox(height: 12),
                  _field(_cpfCnpjCtrl, 'CPF / CNPJ',
                      keyboardType: TextInputType.number),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () async {
                      final p = await showDatePicker(
                        context: context,
                        initialDate: _dataNascimentoEdit ?? DateTime(1990),
                        firstDate: DateTime(1920),
                        lastDate: DateTime.now(),
                      );
                      if (p != null) setState(() => _dataNascimentoEdit = p);
                    },
                    child: AbsorbPointer(
                      child: _field(
                        TextEditingController(
                            text: _dataNascimentoEdit != null
                                ? _formatDate(_dataNascimentoEdit!)
                                : ''),
                        'Data de Nascimento',
                        suffixIcon:
                            const Icon(Icons.calendar_today, size: 18),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  _sectionTitle('Localização'),
                  Row(
                    children: [
                      Expanded(flex: 2, child: _field(_cidadeCtrl, 'Cidade')),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 1,
                        child: _field(
                          _ufCtrl,
                          'UF',
                          inputFormatters: [
                            LengthLimitingTextInputFormatter(2),
                            UpperCaseFormatter(),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  _sectionTitle('Propriedade'),
                  _field(_areaTotalCtrl, 'Área Total (ha)',
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true)),
                  const SizedBox(height: 16),
                  _chipRow(
                      'Tipo',
                      const ['propria', 'arrendada', 'mista'],
                      const ['Própria', 'Arrendada', 'Mista'],
                      _tipoPropriedadeEdit,
                      (v) => setState(() => _tipoPropriedadeEdit = v)),
                  const SizedBox(height: 16),
                  _chipRow(
                      'Irrigação',
                      const ['sequeiro', 'irrigado', 'misto'],
                      const ['Sequeiro', 'Irrigado', 'Misto'],
                      _sistemaIrrigacaoEdit,
                      (v) => setState(() => _sistemaIrrigacaoEdit = v)),
                  const SizedBox(height: 16),
                  _chipRow(
                      'Solo',
                      const ['arenoso', 'argiloso', 'misto', 'outro'],
                      const ['Arenoso', 'Argiloso', 'Misto', 'Outro'],
                      _soloTipoEdit,
                      (v) => setState(() => _soloTipoEdit = v)),
                  const SizedBox(height: 16),
                  _field(_regiaoCtrl, 'Região Agrícola'),
                  const SizedBox(height: 12),
                  _field(_safraCtrl, 'Safra Atual'),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Usa Assistência Técnica'),
                    value: _usaAssistenciaEdit,
                    activeThumbColor: PremiumTokens.brandGreen,
                    onChanged: (v) => setState(() => _usaAssistenciaEdit = v),
                  ),
                  AnimatedSize(
                    duration: const Duration(milliseconds: 200),
                    child: Visibility(
                      visible: _usaAssistenciaEdit,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: _field(_tecnicoCtrl, 'Técnico Responsável'),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  _sectionTitle('Culturas'),
                  if (_culturasEditadas.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(24),
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Column(children: [
                        Icon(Icons.eco, size: 36, color: Colors.grey[400]),
                        const SizedBox(height: 8),
                        Text('Nenhuma cultura',
                            style: TextStyle(color: Colors.grey[600])),
                      ]),
                    )
                  else
                    ...List.generate(
                      _culturasEditadas.length,
                      (i) => CulturaItemWidget(
                        cultura: _culturasEditadas[i],
                        onRemove: () =>
                            setState(() => _culturasEditadas.removeAt(i)),
                      ),
                    ),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    icon: const Icon(Icons.add, color: PremiumTokens.brandGreen),
                    label: const Text('+ Adicionar Cultura',
                        style: TextStyle(color: PremiumTokens.brandGreen)),
                    onPressed: _abrirBottomSheetCultura,
                  ),
                  const SizedBox(height: 28),
                  _sectionTitle('Observações'),
                  TextFormField(
                    controller: _obsCtrl,
                    decoration: _deco('Observações'),
                    maxLines: 4,
                  ),
                  const SizedBox(height: 32),
                  const SizedBox(height: kFabSafeArea),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
