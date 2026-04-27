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
import '../widgets/roi_bloco_widget.dart';
import '../widgets/conclusao_bloco_widget.dart';
import '../widgets/foto_picker_widget.dart';
import '../widgets/case_selectors_widget.dart';
import '../../../../core/ui/sheets/sheet_tokens.dart';

class NovoCaseSheet extends StatefulWidget {
  final double lat;
  final double lng;
  final VoidCallback onClose;
  final void Function(MarketingCase) onPublicar;

  const NovoCaseSheet({
    super.key,
    required this.lat,
    required this.lng,
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
  CaseTipo _tipo = CaseTipo.resultado;
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
            _buildHeader(),
            const SizedBox(height: 24),
            _buildSectionLabel('Tipo de Case'),
            const SizedBox(height: 8),
            CaseTipoSelector(
              selectedTipo: _tipo,
              onChanged: (t) => setState(() => _tipo = t),
            ),
            const SizedBox(height: 20),
            _buildSectionLabel('Visibilidade'),
            const SizedBox(height: 8),
            PlanoMarketingSelector(
              selectedPlano: _visibilidade,
              onChanged: (p) => setState(() => _visibilidade = p),
            ),
            const SizedBox(height: 20),
            _buildSectionLabel('Identificação'),
            const SizedBox(height: 8),
            _buildFieldBox(
              child: Column(
                children: [
                  _buildTextInput(
                    _produtorCtrl,
                    'Produtor / Fazenda *',
                    required: true,
                  ),
                  const _FDivider(),
                  _buildTextInput(
                    _produtoCtrl,
                    'Produto Utilizado *',
                    required: true,
                  ),
                  const _FDivider(),
                  _buildTextInput(
                    _localizacaoCtrl,
                    'Localização (ex: Jataizinho - PR) *',
                    required: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            if (_tipo != CaseTipo.avaliacao) ...[
              _buildSectionLabel('Produtividade'),
              const SizedBox(height: 8),
              _buildFieldBox(
                child: Row(
                  children: [
                    Expanded(
                      child: _buildTextInput(
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
            if (_tipo == CaseTipo.resultado) _buildResultadoFields(),
            if (_tipo == CaseTipo.antesDepois) _buildAntesDepoisFields(),
            if (_tipo == CaseTipo.avaliacao) _buildAvaliacaoFields(),
            _buildSectionLabel('Vendedor (opcional)'),
            const SizedBox(height: 8),
            _buildFieldBox(
              child: Column(
                children: [
                  _buildTextInput(_nomeVendedorCtrl, 'Nome do Vendedor'),
                  const _FDivider(),
                  _buildTextInput(
                    _telefoneCtrl,
                    'Telefone',
                    keyboardType: TextInputType.phone,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _buildFieldBox(
              child: _buildTextInput(
                _descricaoCtrl,
                'Descrição (opcional)',
                maxLines: 3,
              ),
            ),
            const SizedBox(height: 32),
            _buildPublicarButton(),
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

  // ── Seções ─────────────────────────────────────────────────────

  Widget _buildResultadoFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSectionLabel('Foto Principal *'),
        const SizedBox(height: 8),
        FotoPickerWidget(
          label: 'Foto do Resultado (obrigatória)',
          url: _fotoPrincipalUrl,
          folder: 'resultado',
          height: 180,
          required: _fotoPrincipalUrl == null,
          onChanged: (url) => setState(() => _fotoPrincipalUrl = url),
        ),
        const SizedBox(height: 16),
        _buildSectionLabel('Dados do Resultado'),
        const SizedBox(height: 8),
        _buildFieldBox(
          child: Column(
            children: [
              _buildTextInput(
                _qtdProduzidaCtrl,
                'Quantidade Produzida *',
                keyboardType: TextInputType.number,
                required: true,
              ),
              const _FDivider(),
              _buildTextInput(
                _economiaCtrl,
                'Economia Gerada (ex: R\$ 22.000)',
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildAntesDepoisFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSectionLabel('Comparação Antes/Depois'),
        const SizedBox(height: 8),
        _buildFieldBox(
          child: Column(
            children: [
              _buildTextInput(
                _ganhoProdutividadeCtrl,
                'Ganho de Produtividade (ex: +38%) *',
                required: true,
              ),
              const _FDivider(),
              _buildTextInput(
                _economiaCtrl,
                'Economia Gerada (ex: R\$ 22.000)',
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Fotos Antes e Depois lado a lado
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Antes *',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                      color: SoloForteSheetTokens.inputHint,
                    ),
                  ),
                  const SizedBox(height: 6),
                  FotoPickerWidget(
                    label: 'Foto Antes',
                    url: _fotoAntesUrl,
                    folder: 'antes_depois',
                    height: 140,
                    required: _fotoAntesUrl == null,
                    onChanged: (url) => setState(() => _fotoAntesUrl = url),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Depois *',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                      color: SoloForteSheetTokens.inputHint,
                    ),
                  ),
                  const SizedBox(height: 6),
                  FotoPickerWidget(
                    label: 'Foto Depois',
                    url: _fotoDepoisUrl,
                    folder: 'antes_depois',
                    height: 140,
                    required: _fotoDepoisUrl == null,
                    onChanged: (url) => setState(() => _fotoDepoisUrl = url),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildAvaliacaoFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Dados do Talhão
        _buildSectionLabel('Dados do Talhão'),
        const SizedBox(height: 8),
        _buildFieldBox(
          child: Column(
            children: [
              _buildTextInput(
                _nomeTalhaoCtrl,
                'Nome do Talhão *',
                required: true,
              ),
              const _FDivider(),
              _buildTextInput(
                _tamanhoHaCtrl,
                'Tamanho (ha)',
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // ── Lista dinâmica de Avaliações ─────────────────────────
        if (_avaliacoes.isNotEmpty) ...[
          _buildSectionLabel('Avaliações (${_avaliacoes.length})'),
          const SizedBox(height: 10),
          ...List.generate(_avaliacoes.length, (i) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: AvaliacaoBlocoWidget(
                key: ValueKey(_avaliacoes[i].id),
                state: _avaliacoes[i],
                index: i,
                onRemove: () => _removeAvaliacao(i),
                onChanged: () => setState(() {}),
              ),
            );
          }),
        ],

        // Botão + Adicionar Avaliação
        GestureDetector(
          onTap: _addAvaliacao,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              border: Border.all(
                color: PremiumTokens.brandGreen.withValues(alpha: 0.5),
                style: BorderStyle.solid,
              ),
              borderRadius: BorderRadius.circular(12),
              color: PremiumTokens.brandGreen.withValues(alpha: 0.05),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.add_circle_outline,
                  color: PremiumTokens.brandGreen,
                  size: 18,
                ),
                SizedBox(width: 8),
                Text(
                  '+ Adicionar Avaliação',
                  style: TextStyle(
                    color: PremiumTokens.brandGreen,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // ── Bloco ROI ─────────────────────────────────────────────
        if (!_hasRoi)
          _buildAddBlocoButton(
            icon: Icons.trending_up_rounded,
            label: '+ Adicionar Bloco de ROI',
            color: const Color(0xFF34C759),
            onTap: () => setState(() => _hasRoi = true),
          )
        else ...[
          RoiBlocoWidget(
            investimentoCtrl: _roiInvestimentoCtrl,
            retornoCtrl: _roiRetornoCtrl,
            onRemove: () => setState(() {
              _hasRoi = false;
              _roiInvestimentoCtrl.clear();
              _roiRetornoCtrl.clear();
            }),
          ),
          const SizedBox(height: 12),
        ],

        const SizedBox(height: 12),

        // ── Bloco Conclusão ──────────────────────────────────────
        if (!_hasConclusao)
          _buildAddBlocoButton(
            icon: Icons.notes_rounded,
            label: '+ Adicionar Conclusão Técnica',
            color: const Color(0xFF0057FF),
            onTap: () => setState(() => _hasConclusao = true),
          )
        else
          ConclusaoBlocoWidget(
            conclusaoCtrl: _conclusaoCtrl,
            onRemove: () => setState(() {
              _hasConclusao = false;
              _conclusaoCtrl.clear();
            }),
          ),

        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildAddBlocoButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          border: Border.all(color: color.withValues(alpha: 0.4)),
          borderRadius: BorderRadius.circular(12),
          color: color.withValues(alpha: 0.05),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Builders comuns ───────────────────────────────────────────

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            gradient: PremiumTokens.brandGradient,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.campaign_rounded,
            color: Colors.white,
            size: 22,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Novo Case',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                'Lat: ${widget.lat.toStringAsFixed(5)}, Lng: ${widget.lng.toStringAsFixed(5)}',
                style: const TextStyle(
                  color: Color(0xFF8E8E93),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.close),
          onPressed: widget.onClose,
          color: PremiumTokens.textSecondaryLight,
        ),
      ],
    );
  }

  Widget _buildSectionLabel(String label) {
    return Text(
      label.toUpperCase(),
      style: const TextStyle(
        color: SoloForteSheetTokens.sectionLabel,
        fontWeight: SoloForteSheetTokens.sectionWeight,
        fontSize: SoloForteSheetTokens.sectionFontSize,
      ),
    );
  }

  Widget _buildTextInput(
    TextEditingController controller,
    String hint, {
    TextInputType keyboardType = TextInputType.text,
    bool required = false,
    int maxLines = 1,
    void Function(String)? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      onChanged: onChanged,
      style: const TextStyle(color: SoloForteSheetTokens.inputText),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: SoloForteSheetTokens.inputHint, fontSize: 14),
        filled: true,
        fillColor: SoloForteSheetTokens.inputBackground,
        border: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
        isDense: true,
      ),
      validator: required
          ? (v) => (v == null || v.trim().isEmpty) ? 'Campo obrigatório' : null
          : null,
    );
  }

  Widget _buildFieldBox({required Widget child}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: SoloForteSheetTokens.inputBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: PremiumTokens.hairlineLight),
      ),
      child: child,
    );
  }

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

  Widget _buildPublicarButton() {
    return ElevatedButton.icon(
      onPressed: _isLoading ? null : _handlePublicar,
      icon: _isLoading
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : const Icon(Icons.campaign_rounded, size: 20),
      label: Text(_isLoading ? 'Publicando...' : 'Publicar Case'),
      style: ElevatedButton.styleFrom(
        backgroundColor: PremiumTokens.brandGreen,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
      ),
    );
  }
}

// ── Divisor interno ────────────────────────────────────────────
class _FDivider extends StatelessWidget {
  const _FDivider();

  @override
  Widget build(BuildContext context) {
    return const Divider(
      height: 0.5,
      thickness: 0.5,
      color: PremiumTokens.hairlineLight,
    );
  }
}
