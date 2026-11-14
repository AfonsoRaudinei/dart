import 'dart:convert';
import 'package:soloforte_app/core/ui/sheets/solo_forte_sheet_visuals.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/constants/layout_constants.dart';
import '../../../../core/contracts/i_active_visit_context_lookup.dart';
import '../../../../ui/theme/premium/design_tokens.dart';
import '../../domain/entities/avaliacao_item.dart';
import '../../domain/entities/marketing_case.dart';
import '../../domain/entities/parametro_comparativo.dart';
import '../../domain/enums/case_tipo.dart';
import '../../domain/enums/marketing_case_status.dart';
import '../../domain/enums/plano_marketing.dart';
import '../../domain/enums/produtividade_unidade.dart';
import '../providers/marketing_providers.dart';
import '../widgets/case_selectors_widget.dart';
import '../models/novo_case_comparacao.dart';
import '../widgets/novo_case_antes_depois_section.dart';
import '../widgets/novo_case_form_helpers.dart';
import '../widgets/marketing_client_selector.dart';
import '../widgets/novo_case_header.dart';
import '../widgets/novo_case_publicar_button.dart';
import '../widgets/novo_case_resultado_section.dart';
import '../../../../core/contracts/i_client_lookup.dart';

class NovoCaseSheet extends ConsumerStatefulWidget {
  final double lat;
  final double lng;
  final CaseTipo tipo;
  final ActiveVisitContext? initialVisitContext;
  final VoidCallback onClose;
  final void Function(MarketingCase) onPublicar;
  final bool compactHeader;

  const NovoCaseSheet({
    super.key,
    required this.lat,
    required this.lng,
    required this.tipo,
    this.initialVisitContext,
    required this.onClose,
    required this.onPublicar,
    this.compactHeader = false,
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
  String? _clientId;
  String? _selectedClientNameForFallback;

  // ── Produtividade ──────────────────────────────────────────────
  final _produtividadeCtrl = TextEditingController();
  ProdutividadeUnidade _produtividadeUnidade = ProdutividadeUnidade.scHa;

  // ── Resultado ─────────────────────────────────────────────────
  final _prodSemProdutoCtrl = TextEditingController();
  final _prodComProdutoCtrl = TextEditingController();
  final _custoProdutoPorHaCtrl = TextEditingController();
  final _valorGraoCtrl = TextEditingController();

  // ── Antes/Depois unificado (N comparações) ─────────────────────
  late final List<NovoCaseComparacao> _comparacoes;

  // ── Talhão / cultura (opcional na identificação) ───────────────
  final _nomeTalhaoCtrl = TextEditingController();
  final _tamanhoHaCtrl = TextEditingController();
  final _culturaCtrl = TextEditingController();

  // ── Conclusão (1 por case) ────────────────────────────────────
  bool _hasConclusao = false;
  final _conclusaoCtrl = TextEditingController();

  // ── URLs de Foto ───────────────────────────────────────────────
  String? _fotoPrincipalUrl; // Resultado

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tipo = widget.tipo == CaseTipo.avaliacao
        ? CaseTipo.antesDepois
        : widget.tipo;
    _comparacoes = [NovoCaseComparacao(id: _uuid.v4())];
    _dataCase = DateTime.now();
    final initialContext = widget.initialVisitContext;
    if (initialContext == null) return;
    _clientId = initialContext.clientId;
    _selectedClientNameForFallback = initialContext.clientName?.trim();
    _produtorCtrl.text = marketingVisitInitialProdutorFieldText(
      producerFarmLabel: initialContext.producerFarmLabel,
      clientName: initialContext.clientName,
    );
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
    _culturaCtrl.dispose();
    _conclusaoCtrl.dispose();
    super.dispose();
  }

  void _addComparacao() {
    setState(() {
      _comparacoes.add(NovoCaseComparacao(id: _uuid.v4()));
    });
    HapticFeedback.lightImpact();
  }

  void _removeComparacao(int index) {
    if (index <= 0 || index >= _comparacoes.length) return;
    setState(() => _comparacoes.removeAt(index));
    HapticFeedback.selectionClick();
  }

  void _updateComparacao(int index, NovoCaseComparacao comparacao) {
    if (index < 0 || index >= _comparacoes.length) return;
    setState(() => _comparacoes[index] = comparacao);
  }

  void _handlePublicar() {
    final newCase = _validateAndBuildCase();
    if (newCase == null) return;

    setState(() => _isLoading = true);
    HapticFeedback.mediumImpact();

    try {
      widget.onPublicar(newCase);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleSalvarRascunho() async {
    final newCase = _validateAndBuildCase();
    if (newCase == null) return;

    setState(() => _isLoading = true);
    HapticFeedback.mediumImpact();

    try {
      await ref.read(marketingCasesProvider.notifier).saveAsDraft(newCase);
      if (!mounted) return;
      widget.onClose();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Rascunho salvo. Veja em Relatórios → Marketing (Não gerado).',
          ),
          duration: Duration(seconds: 4),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      _showError('Erro ao salvar rascunho: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Valida o formulário e monta o case. Retorna null se inválido.
  MarketingCase? _validateAndBuildCase() {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return null;

    if (_tipo == CaseTipo.resultado && _fotoPrincipalUrl == null) {
      _showError('Foto principal obrigatória para o tipo Resultado.');
      return null;
    }
    if (_tipo == CaseTipo.antesDepois) {
      final primeira = _comparacoes.first;
      if (!primeira.temAlgumaFoto) {
        _showError('Adicione pelo menos uma foto na Comparação 1.');
        return null;
      }
      if (!_validateComparacoesParametros()) return null;
    }

    if (_tipo == CaseTipo.resultado && !_hasResultadoRoiInputs) {
      _showError('Preencha os dados de ROI do resultado.');
      return null;
    }
    if (_dataCase == null) {
      _showError('Selecione a data do case.');
      return null;
    }

    final caseId = _uuid.v4();
    final now = DateTime.now();
    final primeira = _comparacoes.first;
    final cultura = _culturaCtrl.text.trim();
    final avaliacoes = _tipo == CaseTipo.antesDepois
        ? [
            for (var i = 0; i < _comparacoes.length; i++)
              _avaliacaoDaComparacao(_comparacoes[i], i, cultura),
          ]
        : const <AvaliacaoItem>[];
    final fotosLegadas = _tipo == CaseTipo.antesDepois
        ? _urlsPreenchidas(primeira)
        : const <String>[];

    return MarketingCase(
      id: caseId,
      tipo: _tipo,
      visibilidade: _visibilidade,
      lat: widget.lat,
      lng: widget.lng,
      localizacaoTexto: _localizacaoCtrl.text.trim(),
      produtorFazenda: marketingEffectiveProdutorFazenda(
        manualProdutor: _produtorCtrl.text,
        selectedClientName: _selectedClientNameForFallback,
      ),
      produtoUtilizado: _produtoCtrl.text.trim(),
      dataCase: _dataCase,
      produtividadeValor: _tipo == CaseTipo.antesDepois
          ? _parseDouble(_produtividadeCtrl.text)
          : null,
      produtividadeUnidade: _tipo == CaseTipo.antesDepois
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
      clientId: _clientId,
      fotoAntesUrl: fotosLegadas.isNotEmpty ? fotosLegadas.first : null,
      fotoDepoisUrl: fotosLegadas.length > 1 ? fotosLegadas[1] : null,
      economiaGerada: null,
      ganhoProdutividade: null,
      parametrosJson:
          _tipo == CaseTipo.antesDepois && primeira.parametros.isNotEmpty
          ? jsonEncode(primeira.parametros.map((p) => p.toJson()).toList())
          : null,
      nomeTalhao: _tipo == CaseTipo.antesDepois
          ? _optionalText(_nomeTalhaoCtrl.text)
          : null,
      tamanhoHa: _tipo == CaseTipo.antesDepois
          ? _parseDouble(_tamanhoHaCtrl.text)
          : null,
      avaliacoes: const [],
      avaliacoesJson: avaliacoes.isNotEmpty
          ? jsonEncode(avaliacoes.map((item) => item.toJson()).toList())
          : null,
      roi: null,
      conclusao: null,
      conclusaoTecnica: (_hasConclusao && _conclusaoCtrl.text.trim().isNotEmpty)
          ? _conclusaoCtrl.text.trim()
          : null,
      ativo: true,
      status: MarketingCaseStatus.draft,
      criadoEm: now,
      atualizadoEm: now,
      syncStatus: 'local_only',
    );
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
        return 'Antes/Depois';
    }
  }

  String? _optionalText(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  String? _urlOuNull(String? url) {
    final trimmed = url?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    return trimmed;
  }

  List<String> _urlsPreenchidas(NovoCaseComparacao comparacao) {
    final urls = <String>[];
    for (final slot in comparacao.fotos) {
      final url = _urlOuNull(slot.url);
      if (url != null) urls.add(url);
    }
    return urls;
  }

  AvaliacaoItem _avaliacaoDaComparacao(
    NovoCaseComparacao comparacao,
    int index,
    String cultura,
  ) {
    final fotos = comparacao.fotos;
    final texto = comparacao.texto.trim();
    return AvaliacaoItem(
      id: comparacao.id,
      titulo: 'Comparação ${index + 1}',
      nomeLadoA: fotos.isNotEmpty ? fotos[0].rotulo.trim() : '',
      nomeLadoB: fotos.length > 1 ? fotos[1].rotulo.trim() : '',
      nomeLadoC: fotos.length > 2 ? fotos[2].rotulo.trim() : null,
      fotoLadoAPath: fotos.isNotEmpty ? _urlOuNull(fotos[0].url) : null,
      fotoLadoBPath: fotos.length > 1 ? _urlOuNull(fotos[1].url) : null,
      fotoLadoCPath: fotos.length > 2 ? _urlOuNull(fotos[2].url) : null,
      cultura: cultura.isEmpty ? null : cultura,
      parametros: comparacao.parametros,
      observacoes: texto.isEmpty ? null : texto,
    );
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

  bool _validateComparacoesParametros() {
    for (final comparacao in _comparacoes) {
      for (final parametro in comparacao.parametros) {
        if (parametro.titulo.trim().isEmpty) {
          _showError('Preencha o título do parâmetro comparativo.');
          return false;
        }
      }
    }
    return true;
  }

  void _addParametroComparativo(int comparacaoIndex) {
    if (comparacaoIndex < 0 || comparacaoIndex >= _comparacoes.length) return;
    final parametro = ParametroComparativo(
      id: _uuid.v4(),
      titulo: '',
      testemunha: 0,
      teste: 0,
    );
    setState(() {
      final comparacao = _comparacoes[comparacaoIndex];
      final updated = List<ParametroComparativo>.from(comparacao.parametros)
        ..add(parametro);
      _comparacoes[comparacaoIndex] = comparacao.copyWith(
        parametros: updated,
        parametroSelecionadoId: parametro.id,
      );
    });
    HapticFeedback.lightImpact();
  }

  void _updateParametroComparativo(
    int comparacaoIndex,
    ParametroComparativo parametro,
  ) {
    if (comparacaoIndex < 0 || comparacaoIndex >= _comparacoes.length) return;
    final comparacao = _comparacoes[comparacaoIndex];
    final index = comparacao.parametros.indexWhere((p) => p.id == parametro.id);
    if (index < 0) return;
    final updated = List<ParametroComparativo>.from(comparacao.parametros);
    updated[index] = parametro;
    setState(() {
      _comparacoes[comparacaoIndex] = comparacao.copyWith(parametros: updated);
    });
  }

  void _deleteParametroComparativo(int comparacaoIndex, String id) {
    if (comparacaoIndex < 0 || comparacaoIndex >= _comparacoes.length) return;
    final comparacao = _comparacoes[comparacaoIndex];
    final updated = comparacao.parametros.where((p) => p.id != id).toList();
    setState(() {
      _comparacoes[comparacaoIndex] = comparacao.copyWith(
        parametros: updated,
        parametroSelecionadoId: comparacao.parametroSelecionadoId == id
            ? null
            : comparacao.parametroSelecionadoId,
        clearParametroSelecionado: comparacao.parametroSelecionadoId == id,
      );
    });
    HapticFeedback.selectionClick();
  }

  void _selectParametroComparativo(int comparacaoIndex, String? id) {
    if (comparacaoIndex < 0 || comparacaoIndex >= _comparacoes.length) return;
    setState(() {
      final comparacao = _comparacoes[comparacaoIndex];
      _comparacoes[comparacaoIndex] = comparacao.copyWith(
        parametroSelecionadoId: id,
        clearParametroSelecionado: id == null,
      );
    });
  }

  void _handleClientChanged(ClientSummary? client) {
    setState(() {
      if (client == null) {
        _clientId = null;
        _selectedClientNameForFallback = null;
        return;
      }

      _clientId = client.id;
      _selectedClientNameForFallback = client.name.trim();
    });
  }

  // ── Build ──────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final keyboard = MediaQuery.of(context).viewInsets.bottom;
    final fabClearance = MediaQuery.paddingOf(context).bottom + kFabSafeArea;
    return Padding(
      padding: EdgeInsets.only(bottom: keyboard > 0 ? keyboard : fabClearance),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              NovoCaseHeader(
                lat: widget.lat,
                lng: widget.lng,
                tipoLabel: _tipoLabel,
                onClose: widget.onClose,
                showTitle: !widget.compactHeader,
              ),
              SizedBox(height: widget.compactHeader ? 12 : 24),
              novoCaseSectionLabel('Visibilidade'),
              const SizedBox(height: 8),
              PlanoMarketingSelector(
                selectedPlano: _visibilidade,
                onChanged: (p) => setState(() => _visibilidade = p),
              ),
              const SizedBox(height: 20),
              novoCaseSectionLabel('Identificação'),
              const SizedBox(height: 8),
              MarketingClientSelector(
                selectedClientId: _clientId,
                onChanged: _handleClientChanged,
              ),
              const SizedBox(height: 4),
              novoCaseFieldBox(
                child: Column(
                  children: [
                    novoCaseTextInput(
                      _produtorCtrl,
                      marketingProdutorFieldRequired(clientId: _clientId)
                          ? 'Produtor / Fazenda *'
                          : 'Produtor / Fazenda',
                      required: marketingProdutorFieldRequired(
                        clientId: _clientId,
                      ),
                    ),
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
                    if (_tipo == CaseTipo.antesDepois) ...[
                      const NovoCaseFDivider(),
                      novoCaseTextInput(
                        _nomeTalhaoCtrl,
                        'Nome do Talhão (opcional)',
                      ),
                      const NovoCaseFDivider(),
                      novoCaseTextInput(
                        _tamanhoHaCtrl,
                        'Tamanho (ha) (opcional)',
                        keyboardType: TextInputType.number,
                      ),
                      const NovoCaseFDivider(),
                      novoCaseTextInput(_culturaCtrl, 'Cultura (opcional)'),
                    ],
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
                  onFotoChanged: (url) =>
                      setState(() => _fotoPrincipalUrl = url),
                  prodSemProdutoCtrl: _prodSemProdutoCtrl,
                  prodComProdutoCtrl: _prodComProdutoCtrl,
                  custoProdutoPorHaCtrl: _custoProdutoPorHaCtrl,
                  valorGraoCtrl: _valorGraoCtrl,
                  unidade: _produtividadeUnidade,
                  tamanhoHa: _parseDouble(_tamanhoHaCtrl.text),
                  areaTotal: null,
                  onUnidadeChanged: (unidade) =>
                      setState(() => _produtividadeUnidade = unidade),
                  onRoiChanged: () => setState(() {}),
                ),
              if (_tipo == CaseTipo.antesDepois)
                NovoCaseAntesDepoisSection(
                  comparacoes: _comparacoes,
                  produtoUtilizado: _produtoCtrl.text,
                  hasConclusao: _hasConclusao,
                  conclusaoCtrl: _conclusaoCtrl,
                  onAddComparacao: _addComparacao,
                  onRemoveComparacao: _removeComparacao,
                  onComparacaoChanged: _updateComparacao,
                  onAddParametro: _addParametroComparativo,
                  onParametroChanged: _updateParametroComparativo,
                  onDeleteParametro: _deleteParametroComparativo,
                  onSelectParametro: _selectParametroComparativo,
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
              OutlinedButton.icon(
                onPressed: _isLoading ? null : _handleSalvarRascunho,
                icon: const Icon(Icons.save_outlined, size: 20),
                label: Text(
                  _isLoading ? 'Salvando...' : 'Salvar rascunho (Relatórios)',
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: context.themeAccent,
                  side: BorderSide(color: context.themeAccent),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: widget.onClose,
                child: Text(
                  'Cancelar',
                  style: TextStyle(color: context.premiumTextSecondary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Builders locais ────────────────────────────────────────────

  Widget _buildUnidadeDropdown() {
    final v = SoloForteSheetVisuals.of(context);
    final dropdownBg = v.cardBackground;
    final dropdownFg = v.titleColor;

    return DropdownButtonHideUnderline(
      child: DropdownButton<ProdutividadeUnidade>(
        value: _produtividadeUnidade,
        onChanged: (v) => setState(() => _produtividadeUnidade = v!),
        items: ProdutividadeUnidade.values.map((u) {
          return DropdownMenuItem(
            value: u,
            child: Text(
              u.toValue(),
              style: TextStyle(fontSize: 13, color: dropdownFg),
            ),
          );
        }).toList(),
        style: TextStyle(fontSize: 13, color: dropdownFg),
        dropdownColor: dropdownBg,
        iconEnabledColor: v.subtitleColor,
      ),
    );
  }

  Widget _buildDataCasePicker() {
    final selected = _dataCase;
    final v = SoloForteSheetVisuals.of(context);
    final dateColor = v.titleColor;
    final hintColor = v.subtitleColor;
    return GestureDetector(
      onTap: _selectDataCase,
      child: novoCaseFieldBox(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              Icon(
                Icons.calendar_today_outlined,
                size: 18,
                color: context.themeAccent,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  selected == null
                      ? 'Selecionar data'
                      : _formatDatePtBr(selected),
                  style: TextStyle(
                    color: selected == null ? hintColor : dateColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Icon(Icons.keyboard_arrow_down_rounded, color: hintColor),
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
}
