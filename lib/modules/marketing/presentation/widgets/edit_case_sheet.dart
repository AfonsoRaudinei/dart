import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/ui/sheets/sheet_tokens.dart';
import '../../../../ui/theme/premium/design_tokens.dart';
import '../../domain/entities/marketing_case.dart';
import '../../domain/enums/case_tipo.dart';
import '../../domain/enums/plano_marketing.dart';
import '../../domain/enums/produtividade_unidade.dart';
import 'case_selectors_widget.dart';
import 'novo_case_form_helpers.dart';

class EditCaseSheet extends StatefulWidget {
  final MarketingCase caso;
  final VoidCallback onClose;
  final void Function(MarketingCase) onSalvar;

  const EditCaseSheet({
    super.key,
    required this.caso,
    required this.onClose,
    required this.onSalvar,
  });

  @override
  State<EditCaseSheet> createState() => _EditCaseSheetState();
}

class _EditCaseSheetState extends State<EditCaseSheet> {
  final _formKey = GlobalKey<FormState>();
  final _produtorCtrl = TextEditingController();
  final _produtoCtrl = TextEditingController();
  final _produtividadeCtrl = TextEditingController();
  final _nomeVendedorCtrl = TextEditingController();
  final _telefoneCtrl = TextEditingController();
  final _nomeTalhaoCtrl = TextEditingController();
  final _tamanhoHaCtrl = TextEditingController();
  final _conclusaoCtrl = TextEditingController();
  final _conclusaoTecnicaCtrl = TextEditingController();

  late CaseTipo _tipo;
  late PlanoMarketing _visibilidade;
  ProdutividadeUnidade? _produtividadeUnidade;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final caso = widget.caso;
    _tipo = caso.tipo;
    _visibilidade = caso.visibilidade;
    _produtividadeUnidade = caso.produtividadeUnidade;
    _produtorCtrl.text = caso.produtorFazenda;
    _produtoCtrl.text = caso.produtoUtilizado;
    _produtividadeCtrl.text = caso.produtividadeValor?.toString() ?? '';
    _nomeVendedorCtrl.text = caso.nomeVendedor ?? '';
    _telefoneCtrl.text = caso.telefoneVendedor ?? '';
    _nomeTalhaoCtrl.text = caso.nomeTalhao ?? '';
    _tamanhoHaCtrl.text = caso.tamanhoHa?.toString() ?? '';
    _conclusaoCtrl.text = caso.conclusao ?? '';
    _conclusaoTecnicaCtrl.text = caso.conclusaoTecnica ?? '';
  }

  @override
  void dispose() {
    _produtorCtrl.dispose();
    _produtoCtrl.dispose();
    _produtividadeCtrl.dispose();
    _nomeVendedorCtrl.dispose();
    _telefoneCtrl.dispose();
    _nomeTalhaoCtrl.dispose();
    _tamanhoHaCtrl.dispose();
    _conclusaoCtrl.dispose();
    _conclusaoTecnicaCtrl.dispose();
    super.dispose();
  }

  void _handleSalvar() {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    if (_tipo == CaseTipo.avaliacao && _nomeTalhaoCtrl.text.trim().isEmpty) {
      _showError('Preencha o nome do talhão.');
      return;
    }

    final produtividadeValor = _parseDouble(_produtividadeCtrl.text);
    final tamanhoHa = _parseDouble(_tamanhoHaCtrl.text);
    final produtividadeUnidade = _tipo == CaseTipo.avaliacao ||
            produtividadeValor == null
        ? null
        : (_produtividadeUnidade ?? ProdutividadeUnidade.scHa);

    setState(() => _isSaving = true);
    HapticFeedback.mediumImpact();

    final casoOriginal = widget.caso;
    final updatedCase = MarketingCase(
      id: casoOriginal.id,
      tipo: _tipo,
      visibilidade: _visibilidade,
      lat: casoOriginal.lat,
      lng: casoOriginal.lng,
      localizacaoTexto: casoOriginal.localizacaoTexto,
      produtorFazenda: _produtorCtrl.text.trim(),
      produtoUtilizado: _produtoCtrl.text.trim(),
      dataCase: casoOriginal.dataCase,
      produtividadeValor: _tipo == CaseTipo.avaliacao ? null : produtividadeValor,
      produtividadeUnidade: produtividadeUnidade,
      nomeVendedor: _trimmedOrNull(_nomeVendedorCtrl.text),
      telefoneVendedor: _trimmedOrNull(_telefoneCtrl.text),
      descricao: casoOriginal.descricao,
      fotoPrincipalUrl: casoOriginal.fotoPrincipalUrl,
      quantidadeProduzida: casoOriginal.quantidadeProduzida,
      prodSemProduto: casoOriginal.prodSemProduto,
      prodComProduto: casoOriginal.prodComProduto,
      unidadeProdutividade: casoOriginal.unidadeProdutividade,
      custoProdutoPorHa: casoOriginal.custoProdutoPorHa,
      valorGrao: casoOriginal.valorGrao,
      clientId: casoOriginal.clientId,
      ownerUserId: casoOriginal.ownerUserId,
      fotoAntesUrl: casoOriginal.fotoAntesUrl,
      fotoDepoisUrl: casoOriginal.fotoDepoisUrl,
      ganhoProdutividade: casoOriginal.ganhoProdutividade,
      economiaGerada: casoOriginal.economiaGerada,
      parametrosJson: casoOriginal.parametrosJson,
      nomeTalhao: _trimmedOrNull(_nomeTalhaoCtrl.text),
      tamanhoHa: tamanhoHa,
      avaliacoes: casoOriginal.avaliacoes,
      avaliacoesJson: casoOriginal.avaliacoesJson,
      roi: casoOriginal.roi,
      conclusao: _trimmedOrNull(_conclusaoCtrl.text),
      conclusaoTecnica: _trimmedOrNull(_conclusaoTecnicaCtrl.text),
      ativo: casoOriginal.ativo,
      status: casoOriginal.status,
      criadoEm: casoOriginal.criadoEm,
      atualizadoEm: DateTime.now().toUtc(),
      syncStatus: casoOriginal.syncStatus,
      deletadoEm: casoOriginal.deletadoEm,
    );

    widget.onSalvar(updatedCase);
    if (mounted) {
      setState(() => _isSaving = false);
    }
  }

  String? _trimmedOrNull(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  double? _parseDouble(String raw) {
    final normalized = raw.trim().replaceAll(',', '.');
    if (normalized.isEmpty) return null;
    return double.tryParse(normalized);
  }

  void _showError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Material(
        color: Colors.transparent,
        child: Container(
          decoration: const BoxDecoration(
            color: SoloForteSheetTokens.sheetBackground,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              20,
              12,
              20,
              20 + MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: PremiumTokens.hairlineLight,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Editar case',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: widget.onClose,
                        icon: const Icon(Icons.close, color: Colors.white),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.caso.localizacaoTexto,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: SoloForteSheetTokens.inputHint,
                    ),
                  ),
                  const SizedBox(height: 20),
                  novoCaseSectionLabel('Tipo do case'),
                  const SizedBox(height: 10),
                  CaseTipoSelector(
                    selectedTipo: _tipo,
                    onChanged: (value) => setState(() => _tipo = value),
                  ),
                  const SizedBox(height: 20),
                  novoCaseSectionLabel('Visibilidade'),
                  const SizedBox(height: 10),
                  PlanoMarketingSelector(
                    selectedPlano: _visibilidade,
                    onChanged: (value) => setState(() => _visibilidade = value),
                  ),
                  const SizedBox(height: 20),
                  novoCaseSectionLabel('Dados principais'),
                  const SizedBox(height: 10),
                  novoCaseFieldBox(
                    child: Column(
                      children: [
                        novoCaseTextInput(
                          _produtorCtrl,
                          'Produtor / Fazenda',
                          required: true,
                        ),
                        const NovoCaseFDivider(),
                        novoCaseTextInput(
                          _produtoCtrl,
                          'Produto utilizado',
                          required: true,
                        ),
                        const NovoCaseFDivider(),
                        novoCaseTextInput(
                          _nomeVendedorCtrl,
                          'Nome do vendedor',
                        ),
                        const NovoCaseFDivider(),
                        novoCaseTextInput(
                          _telefoneCtrl,
                          'Telefone do vendedor',
                          keyboardType: TextInputType.phone,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  novoCaseSectionLabel('Produtividade'),
                  const SizedBox(height: 10),
                  novoCaseFieldBox(
                    child: Column(
                      children: [
                        novoCaseTextInput(
                          _produtividadeCtrl,
                          'Valor da produtividade',
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                        ),
                        const NovoCaseFDivider(),
                        DropdownButtonFormField<ProdutividadeUnidade>(
                          initialValue: _produtividadeUnidade,
                          dropdownColor: SoloForteSheetTokens.inputBackground,
                          iconEnabledColor: Colors.white,
                          style: const TextStyle(
                            color: SoloForteSheetTokens.inputText,
                          ),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(vertical: 12),
                            isDense: true,
                          ),
                          hint: const Text(
                            'Unidade da produtividade',
                            style: TextStyle(
                              color: SoloForteSheetTokens.inputHint,
                            ),
                          ),
                          items: ProdutividadeUnidade.values
                              .map(
                                (unit) => DropdownMenuItem(
                                  value: unit,
                                  child: Text(unit.toValue()),
                                ),
                              )
                              .toList(),
                          onChanged: _tipo == CaseTipo.avaliacao
                              ? null
                              : (value) => setState(
                                  () => _produtividadeUnidade = value,
                                ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  novoCaseSectionLabel('Talhão'),
                  const SizedBox(height: 10),
                  novoCaseFieldBox(
                    child: Column(
                      children: [
                        novoCaseTextInput(
                          _nomeTalhaoCtrl,
                          'Nome do talhão',
                          required: _tipo == CaseTipo.avaliacao,
                        ),
                        const NovoCaseFDivider(),
                        novoCaseTextInput(
                          _tamanhoHaCtrl,
                          'Tamanho (ha)',
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  novoCaseSectionLabel('Conclusão'),
                  const SizedBox(height: 10),
                  novoCaseFieldBox(
                    child: Column(
                      children: [
                        novoCaseTextInput(
                          _conclusaoCtrl,
                          'Conclusão',
                          maxLines: 3,
                        ),
                        const NovoCaseFDivider(),
                        novoCaseTextInput(
                          _conclusaoTecnicaCtrl,
                          'Conclusão técnica',
                          maxLines: 4,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _isSaving ? null : widget.onClose,
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(
                              color: PremiumTokens.hairlineLight,
                            ),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: const Text('Cancelar'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          onPressed: _isSaving ? null : _handleSalvar,
                          style: FilledButton.styleFrom(
                            backgroundColor: PremiumTokens.brandGreen,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: Text(_isSaving ? 'Salvando...' : 'Salvar'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
