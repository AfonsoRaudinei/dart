import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';
import '../../../../ui/theme/premium/design_tokens.dart';
import '../../domain/entities/avaliacao_bloco.dart';
import '../../domain/entities/avaliacao_lado.dart';
import '../../domain/entities/marketing_case.dart';
import '../../domain/entities/roi_bloco.dart';
import '../../domain/enums/avaliacao_layout.dart';
import '../../domain/enums/case_tipo.dart';
import '../../domain/enums/plano_marketing.dart';
import '../../domain/enums/produtividade_unidade.dart';
import '../widgets/avaliacao_bloco_widget.dart';
import '../widgets/case_selectors_widget.dart';
import '../widgets/novo_case_antes_depois_section.dart';
import '../widgets/novo_case_avaliacao_section.dart';
import '../widgets/novo_case_form_helpers.dart';
import '../widgets/novo_case_header.dart';
import '../widgets/novo_case_publicar_button.dart';
import '../widgets/novo_case_resultado_section.dart';
import '../../../../core/ui/sheets/sheet_tokens.dart';

class NovoCaseSheet extends StatefulWidget {
  final double lat;
  final double lng;
  final CaseTipo? initialTipo;
  final VoidCallback onClose;
  final void Function(MarketingCase) onPublicar;

  const NovoCaseSheet({
    super.key,
    required this.lat,
    required this.lng,
    this.initialTipo,
    required this.onClose,
    required this.onPublicar,
  });

  @override
  State<NovoCaseSheet> createState() => _NovoCaseSheetState();
}

class _NovoCaseSheetState extends State<NovoCaseSheet> {
  final _formKey = GlobalKey<FormState>();
  final _uuid = const Uuid();

  // ── Campos Comuns ──────────────────────────────────────────────
  late CaseTipo _tipo;
  PlanoMarketing _visibilidade = PlanoMarketing.prata;
  final _produtorCtrl = TextEditingController();
  final _produtoCtrl = TextEditingController();
  final _localizacaoCtrl = TextEditingController();
  final _nomeVendedorCtrl = TextEditingController();
  final _telefoneCtrl = TextEditingController();
  final _descricaoCtrl = TextEditingController();

  // ── Produtividade ──────────────────────────────────────────────
  final _produtividadeCtrl = TextEditingController();
  ProdutividadeUnidade _produtividadeUnidade = ProdutividadeUnidade.scHa;

  // ── Resultado ─────────────────────────────────────────────────
  final _qtdProduzidaCtrl = TextEditingController();
  final _economiaCtrl = TextEditingController();

  // ── Antes/Depois ──────────────────────────────────────────────
  final _ganhoProdutividadeCtrl = TextEditingController();

  // ── Avaliação/Campo — Talhão ───────────────────────────────────
  final _nomeTalhaoCtrl = TextEditingController();
  final _tamanhoHaCtrl = TextEditingController();

  // ── Avaliação — Blocos dinâmicos ───────────────────────────────
  final List<AvaliacaoBlocoState> _avaliacoes = [];

  // ── ROI (1 por case) ──────────────────────────────────────────
  bool _hasRoi = false;
  final _roiInvestimentoCtrl = TextEditingController();
  final _roiRetornoCtrl = TextEditingController();

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
    _tipo = widget.initialTipo ?? CaseTipo.resultado;
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
    _qtdProduzidaCtrl.dispose();
    _economiaCtrl.dispose();
    _ganhoProdutividadeCtrl.dispose();
    _nomeTalhaoCtrl.dispose();
    _tamanhoHaCtrl.dispose();
    _roiInvestimentoCtrl.dispose();
    _roiRetornoCtrl.dispose();
    _conclusaoCtrl.dispose();
    for (final av in _avaliacoes) {
      av.dispose();
    }
    super.dispose();
  }

  void _addAvaliacao() {
    setState(() {
      _avaliacoes.add(
        AvaliacaoBlocoState(
          id: _uuid.v4(),
          ladoA: AvaliacaoLadoState(defaultLabel: 'Produto A'),
          ladoB: AvaliacaoLadoState(defaultLabel: 'Produto B'),
        ),
      );
    });
    HapticFeedback.lightImpact();
  }

  void _removeAvaliacao(int index) {
    setState(() {
      _avaliacoes[index].dispose();
      _avaliacoes.removeAt(index);
    });
    HapticFeedback.selectionClick();
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

    if (_tipo == CaseTipo.resultado && _qtdProduzidaCtrl.text.isEmpty) {
      _showError('Preencha a quantidade produzida.');
      return;
    }
    if (_tipo == CaseTipo.antesDepois && _ganhoProdutividadeCtrl.text.isEmpty) {
      _showError('Preencha o ganho de produtividade.');
      return;
    }
    if (_tipo == CaseTipo.avaliacao && _nomeTalhaoCtrl.text.trim().isEmpty) {
      _showError('Preencha o nome do talhão.');
      return;
    }

    setState(() => _isLoading = true);
    HapticFeedback.mediumImpact();

    // Montar RoiBloco a partir dos controllers do widget dedicado
    RoiBloco? roiBloco;
    if (_hasRoi && _tipo == CaseTipo.avaliacao) {
      final inv = double.tryParse(
        _roiInvestimentoCtrl.text.replaceAll(',', '.'),
      );
      final ret = double.tryParse(_roiRetornoCtrl.text.replaceAll(',', '.'));
      if (inv != null && ret != null && inv != 0) {
        roiBloco = RoiBloco(
          investimento: inv,
          retorno: ret,
          roiCalculado: ((ret - inv) / inv) * 100,
        );
      }
    }

    // Converter AvaliacaoBlocoState → AvaliacaoBloco (domínio)
    final String caseId = _uuid.v4();
    final List<AvaliacaoBloco> avaliacoesDominio = _tipo == CaseTipo.avaliacao
        ? _avaliacoes.asMap().entries.map((entry) {
            final i = entry.key;
            final av = entry.value;
            return AvaliacaoBloco(
              id: av.id,
              caseId: caseId,
              ordem: i,
              layout: av.duasFotos
                  ? AvaliacaoLayout.duasFotos
                  : AvaliacaoLayout.umaFoto,
              colapsado: av.colapsado,
              ladoA: AvaliacaoLado(
                label: av.ladoA.labelCtrl.text,
                fotoUrl: av.ladoA.fotoUrl,
                tipoCultura: av.ladoA.tipoCultura,
                observacoes: av.ladoA.obsCtrl.text.trim().isEmpty
                    ? null
                    : av.ladoA.obsCtrl.text.trim(),
              ),
              ladoB: AvaliacaoLado(
                label: av.ladoB.labelCtrl.text,
                fotoUrl: av.ladoB.fotoUrl,
                tipoCultura: av.ladoB.tipoCultura,
                observacoes: av.ladoB.obsCtrl.text.trim().isEmpty
                    ? null
                    : av.ladoB.obsCtrl.text.trim(),
              ),
            );
          }).toList()
        : [];

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
      produtividadeValor: _tipo != CaseTipo.avaliacao
          ? double.tryParse(_produtividadeCtrl.text)
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
      quantidadeProduzida: _tipo == CaseTipo.resultado
          ? double.tryParse(_qtdProduzidaCtrl.text)
          : null,
      fotoAntesUrl: _tipo == CaseTipo.antesDepois ? _fotoAntesUrl : null,
      fotoDepoisUrl: _tipo == CaseTipo.antesDepois ? _fotoDepoisUrl : null,
      economiaGerada: _economiaCtrl.text.trim().isEmpty
          ? null
          : _economiaCtrl.text.trim(),
      ganhoProdutividade: _tipo == CaseTipo.antesDepois
          ? _ganhoProdutividadeCtrl.text.trim()
          : null,
      nomeTalhao: _tipo == CaseTipo.avaliacao
          ? _nomeTalhaoCtrl.text.trim()
          : null,
      tamanhoHa: _tipo == CaseTipo.avaliacao
          ? double.tryParse(_tamanhoHaCtrl.text)
          : null,
      avaliacoes: avaliacoesDominio,
      roi: roiBloco,
      conclusao: (_hasConclusao && _conclusaoCtrl.text.trim().isNotEmpty)
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
              onClose: widget.onClose,
            ),
            const SizedBox(height: 24),
            novoCaseSectionLabel('Tipo de Case'),
            const SizedBox(height: 8),
            CaseTipoSelector(
              selectedTipo: _tipo,
              onChanged: (t) => setState(() => _tipo = t),
            ),
            const SizedBox(height: 20),
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
            if (_tipo != CaseTipo.avaliacao) ...[
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
                qtdProduzidaCtrl: _qtdProduzidaCtrl,
                economiaCtrl: _economiaCtrl,
              ),
            if (_tipo == CaseTipo.antesDepois)
              NovoCaseAntesDepoisSection(
                fotoAntesUrl: _fotoAntesUrl,
                fotoDepoisUrl: _fotoDepoisUrl,
                onFotoAntesChanged: (url) =>
                    setState(() => _fotoAntesUrl = url),
                onFotoDepoisChanged: (url) =>
                    setState(() => _fotoDepoisUrl = url),
                ganhoProdutividadeCtrl: _ganhoProdutividadeCtrl,
                economiaCtrl: _economiaCtrl,
              ),
            if (_tipo == CaseTipo.avaliacao)
              NovoCaseAvaliacaoSection(
                avaliacoes: _avaliacoes,
                nomeTalhaoCtrl: _nomeTalhaoCtrl,
                tamanhoHaCtrl: _tamanhoHaCtrl,
                hasRoi: _hasRoi,
                roiInvestimentoCtrl: _roiInvestimentoCtrl,
                roiRetornoCtrl: _roiRetornoCtrl,
                hasConclusao: _hasConclusao,
                conclusaoCtrl: _conclusaoCtrl,
                onAddAvaliacao: _addAvaliacao,
                onRemoveAvaliacao: _removeAvaliacao,
                onAddRoi: () => setState(() => _hasRoi = true),
                onRemoveRoi: () => setState(() {
                  _hasRoi = false;
                  _roiInvestimentoCtrl.clear();
                  _roiRetornoCtrl.clear();
                }),
                onAddConclusao: () => setState(() => _hasConclusao = true),
                onRemoveConclusao: () => setState(() {
                  _hasConclusao = false;
                  _conclusaoCtrl.clear();
                }),
                onChanged: () => setState(() {}),
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
}
