// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:soloforte_app/core/constants/layout_constants.dart';
import 'package:soloforte_app/core/ui/sheets/sheet_tokens.dart';
import 'package:soloforte_app/core/ui/sheets/soloforte_sheet.dart';
import 'package:soloforte_app/ui/theme/premium/design_tokens.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import '../../domain/client.dart';
import '../../domain/client_cultura.dart';
import '../../domain/enums/cultura_tipo.dart';
import '../widgets/client_avatar_widget.dart';
import '../widgets/cultura_item_widget.dart';
import '../widgets/client_detail_sub_widgets.dart';

part 'client_edit_form_sheets.dart';

// ── Formulário de edição de cliente (extraído de client_detail_screen) ───
// Sprint 7 — Bounded Context Hygiene: mantém client_detail_screen < 900 linhas.

typedef ClientEditSaveCallback =
    void Function(Client clienteAtualizado, List<ClientCultura> culturasComId);

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
  late TextEditingController _dataNascimentoCtrl;
  late TextEditingController _cidadeCtrl;
  late TextEditingController _ufCtrl;
  late TextEditingController _areaTotalCtrl;
  late TextEditingController _regiaoCtrl;
  late TextEditingController _safraCtrl;
  late TextEditingController _tecnicoCtrl;
  late TextEditingController _obsCtrl;

  late List<ClientCultura> _culturasEditadas;
  late List<_AreaPropriedade> _areasPropriedadeEditadas;
  DateTime? _dataNascimentoEdit;
  String? _tipoPropriedadeEdit;
  String? _sistemaIrrigacaoEdit;
  String? _soloTipoEdit;
  bool _usaAssistenciaEdit = false;
  String? _fotoPathEdit;
  final _formKey = GlobalKey<FormState>();

  void _patch(VoidCallback fn) => setState(fn);

  @override
  void initState() {
    super.initState();
    final c = widget.client;
    _nomeCtrl = TextEditingController(text: c.name);
    _emailCtrl = TextEditingController(text: c.email ?? '');
    _telefoneCtrl = TextEditingController(text: c.phone);
    _cpfCnpjCtrl = TextEditingController(text: c.cpfCnpj ?? '');
    _dataNascimentoCtrl = TextEditingController(
      text: c.dataNascimento != null ? _formatDate(c.dataNascimento!) : '',
    );
    _cidadeCtrl = TextEditingController(text: c.city);
    _ufCtrl = TextEditingController(text: c.state);
    _areaTotalCtrl = TextEditingController(text: c.areaTotal?.toString() ?? '');
    _regiaoCtrl = TextEditingController(text: c.regiaoAgricola ?? '');
    _safraCtrl = TextEditingController(text: c.safraAtual ?? '');
    _tecnicoCtrl = TextEditingController(text: c.tecnicoResponsavel ?? '');
    _obsCtrl = TextEditingController(text: c.observation ?? '');
    _culturasEditadas = List.from(widget.culturas);
    _areasPropriedadeEditadas = _seedAreasFromClient(c);
    _dataNascimentoEdit = c.dataNascimento;
    _tipoPropriedadeEdit = c.tipoPropriedade;
    _sistemaIrrigacaoEdit = c.sistemaIrrigacao;
    _soloTipoEdit = c.soloTipo;
    _usaAssistenciaEdit = c.usaAssistenciaTecnica ?? false;
    _fotoPathEdit = c.photoPath;
    _sincronizarResumoAreas();
  }

  @override
  void dispose() {
    _nomeCtrl.dispose();
    _emailCtrl.dispose();
    _telefoneCtrl.dispose();
    _cpfCnpjCtrl.dispose();
    _dataNascimentoCtrl.dispose();
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
      areaTotal: _parseArea(_areaTotalCtrl.text),
      tipoPropriedade: _tipoPropriedadeEdit,
      sistemaIrrigacao: _sistemaIrrigacaoEdit,
      soloTipo: _soloTipoEdit,
      regiaoAgricola: _regiaoCtrl.text.trim().isEmpty
          ? null
          : _regiaoCtrl.text.trim(),
      safraAtual: _safraCtrl.text.trim().isEmpty
          ? null
          : _safraCtrl.text.trim(),
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

  List<_AreaPropriedade> _seedAreasFromClient(Client client) {
    final total = client.areaTotal;
    final tipo = client.tipoPropriedade;
    if (total == null || total <= 0) return [];
    if (tipo == 'propria' || tipo == 'arrendada') {
      return [_AreaPropriedade(areaHa: total, tipo: tipo!)];
    }
    return [];
  }

  double? _parseArea(String? value) =>
      double.tryParse((value ?? '').trim().replaceAll(',', '.'));

  void _sincronizarResumoAreas() {
    if (_areasPropriedadeEditadas.isEmpty) return;
    final total = _areasPropriedadeEditadas.fold<double>(
      0,
      (sum, area) => sum + area.areaHa,
    );
    final tipos = _areasPropriedadeEditadas.map((area) => area.tipo).toSet();
    _areaTotalCtrl.text = total.toString();
    _tipoPropriedadeEdit = tipos.length > 1 ? 'mista' : tipos.firstOrNull;
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
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
    bool readOnly = false,
    VoidCallback? onTap,
  }) => TextFormField(
    controller: ctrl,
    decoration: _deco(label, suffixIcon: suffixIcon),
    keyboardType: maxLines > 1 ? TextInputType.multiline : keyboardType,
    maxLines: maxLines,
    validator: validator,
    inputFormatters: inputFormatters,
    readOnly: readOnly,
    onTap: onTap,
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

  Widget _buildResumoAreas() {
    final total = _areasPropriedadeEditadas.fold<double>(
      0,
      (sum, area) => sum + area.areaHa,
    );
    final propria = _areasPropriedadeEditadas
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

  Widget _buildResumoLegadoArea() {
    final totalLegacy = _parseArea(_areaTotalCtrl.text);
    if (totalLegacy == null || totalLegacy <= 0) {
      return Text(
        'Nenhuma área adicionada',
        style: TextStyle(color: Colors.grey[600]),
      );
    }

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
            'Área total registrada: ${_formatArea(totalLegacy)} ha',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Text(
            widget.client.tipoPropriedade == 'mista'
                ? 'Detalhe própria/arrendada ainda não foi preenchido neste cadastro antigo.'
                : 'Toque em "Adicionar Área" para detalhar própria/arrendada e recalcular o percentual final.',
            style: TextStyle(color: Colors.grey[700], fontSize: 12),
          ),
        ],
      ),
    );
  }

  String _formatArea(double value) => value == value.truncateToDouble()
      ? value.toStringAsFixed(0)
      : value.toStringAsFixed(2).replaceFirst(RegExp(r'0+$'), '');

  String _formatPercentual(double area, double total) =>
      '${total == 0 ? '0' : (area / total * 100).toStringAsFixed(1)}%';

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
                  child: const Text(
                    'Cancelar',
                    style: TextStyle(color: Colors.grey),
                  ),
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
                      color: PremiumTokens.brandGreen,
                    ),
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
                        const Text(
                          'Toque para alterar foto',
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  _sectionTitle('Identificação'),
                  _field(
                    _nomeCtrl,
                    'Nome Completo *',
                    validator: (v) {
                      if (v == null || v.trim().length < 2) {
                        return 'Mínimo 2 caracteres';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  _field(
                    _emailCtrl,
                    'E-mail',
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
                    _telefoneCtrl,
                    'Telefone',
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 12),
                  _field(
                    _cpfCnpjCtrl,
                    'CPF / CNPJ',
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 12),
                  _field(
                    _dataNascimentoCtrl,
                    'Data de Nascimento',
                    readOnly: true,
                    onTap: () async {
                      final p = await showDatePicker(
                        context: context,
                        initialDate: _dataNascimentoEdit ?? DateTime(1990),
                        firstDate: DateTime(1920),
                        lastDate: DateTime.now(),
                        locale: const Locale('pt', 'BR'),
                      );
                      if (p != null) {
                        setState(() {
                          _dataNascimentoEdit = p;
                          _dataNascimentoCtrl.text = _formatDate(p);
                        });
                      }
                    },
                    suffixIcon: const Icon(Icons.calendar_today, size: 18),
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
                  if (_areasPropriedadeEditadas.isEmpty)
                    _buildResumoLegadoArea()
                  else ...[
                    ...List.generate(_areasPropriedadeEditadas.length, (i) {
                      final area = _areasPropriedadeEditadas[i];
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
                            _areasPropriedadeEditadas.removeAt(i);
                            if (_areasPropriedadeEditadas.isEmpty) {
                              _areaTotalCtrl.text =
                                  widget.client.areaTotal?.toString() ?? '';
                              _tipoPropriedadeEdit =
                                  widget.client.tipoPropriedade;
                            } else {
                              _sincronizarResumoAreas();
                            }
                          }),
                        ),
                      );
                    }),
                    const SizedBox(height: 8),
                    _buildResumoAreas(),
                  ],
                  TextButton.icon(
                    onPressed: _abrirBottomSheetArea,
                    icon: const Icon(
                      Icons.add,
                      color: PremiumTokens.brandGreen,
                    ),
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
                    _sistemaIrrigacaoEdit,
                    (v) => setState(() => _sistemaIrrigacaoEdit = v),
                  ),
                  const SizedBox(height: 16),
                  _chipRow(
                    'Solo',
                    const ['arenoso', 'argiloso', 'misto', 'outro'],
                    const ['Arenoso', 'Argiloso', 'Misto', 'Outro'],
                    _soloTipoEdit,
                    (v) => setState(() => _soloTipoEdit = v),
                  ),
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
                      child: Column(
                        children: [
                          Icon(Icons.eco, size: 36, color: Colors.grey[400]),
                          const SizedBox(height: 8),
                          Text(
                            'Nenhuma cultura',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
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
                    icon: const Icon(
                      Icons.add,
                      color: PremiumTokens.brandGreen,
                    ),
                    label: const Text(
                      '+ Adicionar Cultura',
                      style: TextStyle(color: PremiumTokens.brandGreen),
                    ),
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

class _AreaPropriedade {
  final double areaHa;
  final String tipo;

  const _AreaPropriedade({required this.areaHa, required this.tipo});

  String get tipoLabel => tipo == 'propria' ? 'Própria' : 'Arrendada';
}
