import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/contracts/i_active_visit_context_lookup.dart';
import '../../../../core/contracts/i_client_lookup.dart';
import '../../../../core/contracts/i_client_lookup_provider.dart';
import '../../../../ui/theme/premium/design_tokens.dart';
import '../../domain/entities/avaliacao_item.dart';
import '../../domain/entities/marketing_case.dart';
import '../../domain/entities/parametro_comparativo.dart';
import '../../domain/enums/case_tipo.dart';
import '../../domain/enums/plano_marketing.dart';
import '../../domain/enums/produtividade_unidade.dart';
import '../widgets/case_selectors_widget.dart';
import '../widgets/novo_case_antes_depois_section.dart';
import '../widgets/novo_case_avaliacao_section.dart';
import '../widgets/novo_case_form_helpers.dart';
import '../widgets/novo_case_header.dart';
import '../widgets/novo_case_publicar_button.dart';
import '../widgets/novo_case_resultado_section.dart';
import '../../../../core/ui/sheets/sheet_tokens.dart';

class NovoCaseSheet extends ConsumerStatefulWidget {
  final double lat;
  final double lng;
  final CaseTipo tipo;
  final ActiveVisitContext? initialVisitContext;
  final VoidCallback onClose;
  final void Function(MarketingCase) onPublicar;

  const NovoCaseSheet({
    super.key,
    required this.lat,
    required this.lng,
    required this.tipo,
    this.initialVisitContext,
    required this.onClose,
    required this.onPublicar,
  });

  @override
  ConsumerState<NovoCaseSheet> createState() => _NovoCaseSheetState();
}

class _NovoCaseSheetState extends ConsumerState<NovoCaseSheet> {
  final _formKey = GlobalKey<FormState>();
  final _uuid = const Uuid();

  // ── Campos Comuns ──────────────────────────────────────────────
  late final CaseTipo _tipo;
  PlanoMarketing _visibilidade = PlanoMarketing.prata;
  final _produtorCtrl = TextEditingController();
  final _produtoCtrl = TextEditingController();
  final _localizacaoCtrl = TextEditingController();
  final _nomeVendedorCtrl = TextEditingController();
  final _telefoneCtrl = TextEditingController();
  final _descricaoCtrl = TextEditingController();
  DateTime? _dataCase;
  Future<List<ClientSummary>>? _clientesFuture;
  String? _clientId;
  double? _clientAreaTotal;

  // ── Produtividade ──────────────────────────────────────────────
  final _produtividadeCtrl = TextEditingController();
  ProdutividadeUnidade _produtividadeUnidade = ProdutividadeUnidade.scHa;

  // ── Resultado ─────────────────────────────────────────────────
  final _prodSemProdutoCtrl = TextEditingController();
  final _prodComProdutoCtrl = TextEditingController();
  final _custoProdutoPorHaCtrl = TextEditingController();
  final _valorGraoCtrl = TextEditingController();

  // ── Antes/Depois ──────────────────────────────────────────────
  final List<ParametroComparativo> _parametrosComparativos = [];
  String? _parametroSelecionadoId;

  // ── Avaliação/Campo — Talhão ───────────────────────────────────
  final _nomeTalhaoCtrl = TextEditingController();
  final _tamanhoHaCtrl = TextEditingController();

  // ── Avaliação — Ensaios comparativos livres ───────────────────
  final List<AvaliacaoItem> _avaliacoes = [];
  String? _avaliacaoAbertaId;

  // ── Conclusão (1 por case) ────────────────────────────────────
  bool _hasConclusao = false;
  final _conclusaoCtrl = TextEditingController();

  // ── URLs de Foto ───────────────────────────────────────────────
  String? _fotoPrincipalUrl; // Resultado
  String? _fotoAntesUrl; // Antes/Depois
  String? _fotoDepoisUrl; // Antes/Depois

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tipo = widget.tipo;
    _dataCase = DateTime.now();
    if (_tipo == CaseTipo.resultado) {
      _clientesFuture = ref.read(clientLookupProvider).listAtivos();
    }
    final initialContext = widget.initialVisitContext;
    if (initialContext == null) return;
    _clientId = initialContext.clientId;
    _produtorCtrl.text = initialContext.producerFarmLabel ?? '';
    _localizacaoCtrl.text = initialContext.locationLabel ?? '';
    _nomeTalhaoCtrl.text = initialContext.fieldName ?? '';
    _tamanhoHaCtrl.text = initialContext.fieldAreaHa?.toString() ?? '';
  }

  @override
  void dispose() {
    _produtorCtrl.dispose();
    _produtoCtrl.dispose();
    _localizacaoCtrl.dispose();
    _nomeVendedorCtrl.dispose();
    _telefoneCtrl.dispose();
    _descricaoCtrl.dispose();
    _produtividadeCtrl.dispose();
    _prodSemProdutoCtrl.dispose();
    _prodComProdutoCtrl.dispose();
    _custoProdutoPorHaCtrl.dispose();
    _valorGraoCtrl.dispose();
    _nomeTalhaoCtrl.dispose();
    _tamanhoHaCtrl.dispose();
    _conclusaoCtrl.dispose();
    super.dispose();
  }

  void _addAvaliacao() {
    final avaliacao = AvaliacaoItem(
      id: _uuid.v4(),
      titulo: 'Avaliação ${_avaliacoes.length + 1}',
      nomeLadoA: 'Lado A',
      nomeLadoB: 'Lado B',
    );
    setState(() {
      _avaliacoes.add(avaliacao);
      _avaliacaoAbertaId = avaliacao.id;
    });
    HapticFeedback.lightImpact();
  }

  void _removeAvaliacao(String id) {
    setState(() {
      _avaliacoes.removeWhere((item) => item.id == id);
      if (_avaliacaoAbertaId == id) {
        _avaliacaoAbertaId = _avaliacoes.isEmpty ? null : _avaliacoes.last.id;
      }
    });
    HapticFeedback.selectionClick();
  }

  void _updateAvaliacao(AvaliacaoItem avaliacao) {
    final index = _avaliacoes.indexWhere((item) => item.id == avaliacao.id);
    if (index < 0) return;
    setState(() => _avaliacoes[index] = avaliacao);
  }

  void _duplicateAvaliacao(String id) {
    final index = _avaliacoes.indexWhere((item) => item.id == id);
    if (index < 0) return;
    final original = _avaliacoes[index];
    final duplicated = original.copyWith(
      id: _uuid.v4(),
      titulo:
          '${original.titulo.trim().isEmpty ? 'Avaliação' : original.titulo} (cópia)',
      parametros: original.parametros
          .map((parametro) => parametro.copyWith(id: _uuid.v4()))
          .toList(),
    );
    setState(() {
      _avaliacoes.insert(index + 1, duplicated);
      _avaliacaoAbertaId = duplicated.id;
    });
    HapticFeedback.lightImpact();
  }

  void _toggleAvaliacao(String id) {
    setState(() {
      _avaliacaoAbertaId = _avaliacaoAbertaId == id ? null : id;
    });
  }

  void _handlePublicar() {
    // 🔧 FIX: Fechar teclado antes da validação (Bug A)
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;

    // Validações de foto obrigatória
    if (_tipo == CaseTipo.resultado && _fotoPrincipalUrl == null) {
      _showError('Foto principal obrigatória para o tipo Resultado.');
      return;
    }
    if (_tipo == CaseTipo.antesDepois &&
        (_fotoAntesUrl == null || _fotoDepoisUrl == null)) {
      _showError('Adicione as fotos Antes e Depois.');
      return;
    }

    if (_tipo == CaseTipo.resultado && !_hasResultadoRoiInputs) {
      _showError('Preencha os dados de ROI do resultado.');
      return;
    }
    if (_tipo == CaseTipo.antesDepois && !_validateParametrosComparativos()) {
      return;
    }
    if (_dataCase == null) {
      _showError('Selecione a data do case.');
      return;
    }
    if (_tipo == CaseTipo.avaliacao && _nomeTalhaoCtrl.text.trim().isEmpty) {
      _showError('Preencha o nome do talhão.');
      return;
    }

    setState(() => _isLoading = true);
    HapticFeedback.mediumImpact();

    final String caseId = _uuid.v4();

    final now = DateTime.now();
    final newCase = MarketingCase(
      id: caseId,
      tipo: _tipo,
      visibilidade: _visibilidade,
      lat: widget.lat,
      lng: widget.lng,
      localizacaoTexto: _localizacaoCtrl.text.trim(),
      produtorFazenda: _produtorCtrl.text.trim(),
      produtoUtilizado: _produtoCtrl.text.trim(),
      dataCase: _dataCase,
      produtividadeValor: _tipo != CaseTipo.avaliacao
          ? _parseDouble(_produtividadeCtrl.text)
          : null,
      produtividadeUnidade: _tipo != CaseTipo.avaliacao
          ? _produtividadeUnidade
          : null,
      nomeVendedor: _nomeVendedorCtrl.text.trim().isEmpty
          ? null
          : _nomeVendedorCtrl.text.trim(),
      telefoneVendedor: _telefoneCtrl.text.trim().isEmpty
          ? null
          : _telefoneCtrl.text.trim(),
      descricao: _descricaoCtrl.text.trim().isEmpty
          ? null
          : _descricaoCtrl.text.trim(),
      fotoPrincipalUrl: _tipo == CaseTipo.resultado ? _fotoPrincipalUrl : null,
      quantidadeProduzida: null,
      prodSemProduto: _tipo == CaseTipo.resultado
          ? _parseDouble(_prodSemProdutoCtrl.text)
          : null,
      prodComProduto: _tipo == CaseTipo.resultado
          ? _parseDouble(_prodComProdutoCtrl.text)
          : null,
      unidadeProdutividade: _tipo == CaseTipo.resultado
          ? _produtividadeUnidade.toValue()
          : null,
      custoProdutoPorHa: _tipo == CaseTipo.resultado
          ? _parseDouble(_custoProdutoPorHaCtrl.text)
          : null,
      valorGrao: _tipo == CaseTipo.resultado
          ? _parseDouble(_valorGraoCtrl.text)
          : null,
      clientId: _tipo == CaseTipo.resultado ? _clientId : null,
      fotoAntesUrl: _tipo == CaseTipo.antesDepois ? _fotoAntesUrl : null,
      fotoDepoisUrl: _tipo == CaseTipo.antesDepois ? _fotoDepoisUrl : null,
      economiaGerada: null,
      ganhoProdutividade: null,
      parametrosJson:
          _tipo == CaseTipo.antesDepois && _parametrosComparativos.isNotEmpty
          ? jsonEncode(_parametrosComparativos.map((p) => p.toJson()).toList())
          : null,
      nomeTalhao: _tipo == CaseTipo.avaliacao
          ? _nomeTalhaoCtrl.text.trim()
          : null,
      tamanhoHa: _parseDouble(_tamanhoHaCtrl.text),
      avaliacoes: const [],
      avaliacoesJson: _tipo == CaseTipo.avaliacao && _avaliacoes.isNotEmpty
          ? jsonEncode(_avaliacoes.map((item) => item.toJson()).toList())
          : null,
      roi: null,
      conclusao: null,
      conclusaoTecnica: (_hasConclusao && _conclusaoCtrl.text.trim().isNotEmpty)
          ? _conclusaoCtrl.text.trim()
          : null,
      ativo: true,
      criadoEm: now,
      atualizadoEm: now,
      syncStatus: 'local_only',
    );

    try {
      widget.onPublicar(newCase);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: PremiumTokens.alertError,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  String get _tipoLabel {
    switch (_tipo) {
      case CaseTipo.resultado:
        return 'Resultado';
      case CaseTipo.antesDepois:
        return 'Antes/Depois';
      case CaseTipo.avaliacao:
        return 'Avaliação';
    }
  }

  double? _parseDouble(String value) {
    return double.tryParse(value.trim().replaceAll(',', '.'));
  }

  bool get _hasResultadoRoiInputs {
    final semProduto = _parseDouble(_prodSemProdutoCtrl.text);
    final comProduto = _parseDouble(_prodComProdutoCtrl.text);
    final custo = _parseDouble(_custoProdutoPorHaCtrl.text);
    final valor = _parseDouble(_valorGraoCtrl.text);
    return semProduto != null &&
        semProduto > 0 &&
        comProduto != null &&
        comProduto > 0 &&
        custo != null &&
        custo > 0 &&
        valor != null &&
        valor > 0;
  }

  bool _validateParametrosComparativos() {
    for (final parametro in _parametrosComparativos) {
      if (parametro.titulo.trim().isEmpty) {
        _showError('Preencha o título do parâmetro comparativo.');
        return false;
      }
    }
    return true;
  }

  void _addParametroComparativo() {
    setState(() {
      final parametro = ParametroComparativo(
        id: _uuid.v4(),
        titulo: '',
        testemunha: 0,
        teste: 0,
      );
      _parametrosComparativos.add(parametro);
      _parametroSelecionadoId = parametro.id;
    });
    HapticFeedback.lightImpact();
  }

  void _updateParametroComparativo(ParametroComparativo parametro) {
    final index = _parametrosComparativos.indexWhere(
      (p) => p.id == parametro.id,
    );
    if (index < 0) return;
    setState(() => _parametrosComparativos[index] = parametro);
  }

  void _deleteParametroComparativo(String id) {
    setState(() {
      _parametrosComparativos.removeWhere((p) => p.id == id);
      if (_parametroSelecionadoId == id) _parametroSelecionadoId = null;
    });
    HapticFeedback.selectionClick();
  }

  // ── Build ──────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 8,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            NovoCaseHeader(
              lat: widget.lat,
              lng: widget.lng,
              tipoLabel: _tipoLabel,
              onClose: widget.onClose,
            ),
            const SizedBox(height: 24),
            novoCaseSectionLabel('Visibilidade'),
            const SizedBox(height: 8),
            PlanoMarketingSelector(
              selectedPlano: _visibilidade,
              onChanged: (p) => setState(() => _visibilidade = p),
            ),
            const SizedBox(height: 20),
            novoCaseSectionLabel('Identificação'),
            const SizedBox(height: 8),
            novoCaseFieldBox(
              child: Column(
                children: [
                  novoCaseTextInput(
                    _produtorCtrl,
                    'Produtor / Fazenda *',
                    required: true,
                  ),
                  if (_tipo == CaseTipo.resultado) ...[
                    const NovoCaseFDivider(),
                    _buildClienteDropdown(),
                  ],
                  const NovoCaseFDivider(),
                  novoCaseTextInput(
                    _produtoCtrl,
                    'Produto Utilizado *',
                    required: true,
                  ),
                  const NovoCaseFDivider(),
                  novoCaseTextInput(
                    _localizacaoCtrl,
                    'Localização (ex: Jataizinho - PR) *',
                    required: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            novoCaseSectionLabel('Data do Case'),
            const SizedBox(height: 8),
            _buildDataCasePicker(),
            const SizedBox(height: 20),
            if (_tipo == CaseTipo.antesDepois) ...[
              novoCaseSectionLabel('Produtividade'),
              const SizedBox(height: 8),
              novoCaseFieldBox(
                child: Row(
                  children: [
                    Expanded(
                      child: novoCaseTextInput(
                        _produtividadeCtrl,
                        'Valor *',
                        keyboardType: TextInputType.number,
                        required: true,
                      ),
                    ),
                    const SizedBox(width: 12),
                    _buildUnidadeDropdown(),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
            if (_tipo == CaseTipo.resultado)
              NovoCaseResultadoSection(
                fotoPrincipalUrl: _fotoPrincipalUrl,
                onFotoChanged: (url) => setState(() => _fotoPrincipalUrl = url),
                prodSemProdutoCtrl: _prodSemProdutoCtrl,
                prodComProdutoCtrl: _prodComProdutoCtrl,
                custoProdutoPorHaCtrl: _custoProdutoPorHaCtrl,
                valorGraoCtrl: _valorGraoCtrl,
                unidade: _produtividadeUnidade,
                tamanhoHa: _parseDouble(_tamanhoHaCtrl.text),
                areaTotal: _clientAreaTotal,
                onUnidadeChanged: (unidade) =>
                    setState(() => _produtividadeUnidade = unidade),
                onRoiChanged: () => setState(() {}),
              ),
            if (_tipo == CaseTipo.antesDepois)
              NovoCaseAntesDepoisSection(
                fotoAntesUrl: _fotoAntesUrl,
                fotoDepoisUrl: _fotoDepoisUrl,
                onFotoAntesChanged: (url) =>
                    setState(() => _fotoAntesUrl = url),
                onFotoDepoisChanged: (url) =>
                    setState(() => _fotoDepoisUrl = url),
                parametros: _parametrosComparativos,
                parametroSelecionadoId: _parametroSelecionadoId,
                onAddParametro: _addParametroComparativo,
                onSelectParametro: (id) =>
                    setState(() => _parametroSelecionadoId = id),
                onParametroChanged: _updateParametroComparativo,
                onDeleteParametro: _deleteParametroComparativo,
              ),
            if (_tipo == CaseTipo.avaliacao)
              NovoCaseAvaliacaoSection(
                avaliacoes: _avaliacoes,
                avaliacaoAbertaId: _avaliacaoAbertaId,
                nomeTalhaoCtrl: _nomeTalhaoCtrl,
                tamanhoHaCtrl: _tamanhoHaCtrl,
                hasConclusao: _hasConclusao,
                conclusaoCtrl: _conclusaoCtrl,
                onAddAvaliacao: _addAvaliacao,
                onToggleAvaliacao: _toggleAvaliacao,
                onAvaliacaoChanged: _updateAvaliacao,
                onRemoveAvaliacao: _removeAvaliacao,
                onDuplicateAvaliacao: _duplicateAvaliacao,
                onAddConclusao: () => setState(() => _hasConclusao = true),
                onRemoveConclusao: () => setState(() {
                  _hasConclusao = false;
                  _conclusaoCtrl.clear();
                }),
              ),
            novoCaseSectionLabel('Vendedor (opcional)'),
            const SizedBox(height: 8),
            novoCaseFieldBox(
              child: Column(
                children: [
                  novoCaseTextInput(_nomeVendedorCtrl, 'Nome do Vendedor'),
                  const NovoCaseFDivider(),
                  novoCaseTextInput(
                    _telefoneCtrl,
                    'Telefone',
                    keyboardType: TextInputType.phone,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            novoCaseFieldBox(
              child: novoCaseTextInput(
                _descricaoCtrl,
                'Descrição (opcional)',
                maxLines: 3,
              ),
            ),
            const SizedBox(height: 32),
            NovoCasePublicarButton(
              isLoading: _isLoading,
              onPressed: _handlePublicar,
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: widget.onClose,
              child: const Text(
                'Cancelar',
                style: TextStyle(color: PremiumTokens.textSecondaryLight),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Builders locais ────────────────────────────────────────────

  Widget _buildUnidadeDropdown() {
    return DropdownButtonHideUnderline(
      child: DropdownButton<ProdutividadeUnidade>(
        value: _produtividadeUnidade,
        onChanged: (v) => setState(() => _produtividadeUnidade = v!),
        items: ProdutividadeUnidade.values.map((u) {
          return DropdownMenuItem(
            value: u,
            child: Text(u.toValue(), style: const TextStyle(fontSize: 13)),
          );
        }).toList(),
        style: Theme.of(context).textTheme.bodyMedium,
        dropdownColor: SoloForteSheetTokens.inputBackground,
      ),
    );
  }

  Widget _buildDataCasePicker() {
    final selected = _dataCase;
    return GestureDetector(
      onTap: _selectDataCase,
      child: novoCaseFieldBox(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              const Icon(
                Icons.calendar_today_outlined,
                size: 18,
                color: PremiumTokens.brandGreen,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  selected == null
                      ? 'Selecionar data'
                      : _formatDatePtBr(selected),
                  style: const TextStyle(
                    color: SoloForteSheetTokens.inputText,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: SoloForteSheetTokens.inputHint,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _selectDataCase() async {
    final now = DateTime.now();
    final initial = _dataCase ?? now;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(now.year + 5),
    );
    if (picked == null) return;
    setState(() => _dataCase = picked);
  }

  static String _formatDatePtBr(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }

  Widget _buildClienteDropdown() {
    final future = _clientesFuture;
    if (future == null) return const SizedBox.shrink();

    return FutureBuilder<List<ClientSummary>>(
      future: future,
      builder: (context, snapshot) {
        final clientes = snapshot.data ?? const <ClientSummary>[];
        final selectedExists = clientes.any((c) => c.id == _clientId);
        return InputDecorator(
          decoration: const InputDecoration(
            border: InputBorder.none,
            contentPadding: EdgeInsets.zero,
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: selectedExists ? _clientId : null,
              isExpanded: true,
              hint: const Text(
                'Buscar Produtor/Fazenda',
                style: TextStyle(
                  color: SoloForteSheetTokens.inputHint,
                  fontSize: 14,
                ),
              ),
              dropdownColor: SoloForteSheetTokens.inputBackground,
              items: clientes.map((client) {
                final subtitle = client.areaTotal > 0
                    ? ' · ${client.areaTotal.toStringAsFixed(1)} ha'
                    : '';
                return DropdownMenuItem<String>(
                  value: client.id,
                  child: Text(
                    '${client.name}$subtitle',
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: SoloForteSheetTokens.inputText,
                      fontSize: 14,
                    ),
                  ),
                );
              }).toList(),
              onChanged: clientes.isEmpty
                  ? null
                  : (id) {
                      final client = clientes.firstWhere((c) => c.id == id);
                      setState(() {
                        _clientId = client.id;
                        _clientAreaTotal = client.areaTotal > 0
                            ? client.areaTotal
                            : null;
                        _produtorCtrl.text = client.name;
                      });
                    },
            ),
          ),
        );
      },
    );
  }
}
