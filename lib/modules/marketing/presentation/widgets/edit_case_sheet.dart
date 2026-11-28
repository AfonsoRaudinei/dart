import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soloforte_app/core/ui/sheets/solo_forte_sheet_visuals.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/constants/layout_constants.dart';
import '../../../../core/contracts/i_client_lookup.dart';
import '../../../../core/contracts/i_client_lookup_provider.dart';
import '../../../../ui/theme/premium/design_tokens.dart';
import '../../domain/entities/avaliacao_item.dart';
import '../../domain/entities/marketing_case.dart';
import '../../domain/entities/parametro_comparativo.dart';
import '../../domain/enums/case_tipo.dart';
import '../../domain/enums/plano_marketing.dart';
import '../../domain/enums/produtividade_unidade.dart';
import '../../domain/marketing_visibility_policy.dart';
import '../../../planos/domain/entities/user_plan.dart';
import '../../../planos/presentation/providers/plano_providers.dart';
import 'case_selectors_widget.dart';
import 'fotos_resultado_picker_widget.dart';
import 'marketing_client_selector.dart';
import 'novo_case_antes_depois_section.dart';
import 'novo_case_form_helpers.dart';
import '../models/novo_case_comparacao.dart';

class EditCaseSheet extends ConsumerStatefulWidget {
  final MarketingCase caso;
  final VoidCallback onClose;
  final Future<void> Function(MarketingCase) onSalvar;

  const EditCaseSheet({
    super.key,
    required this.caso,
    required this.onClose,
    required this.onSalvar,
  });

  @override
  ConsumerState<EditCaseSheet> createState() => _EditCaseSheetState();
}

class _EditCaseSheetState extends ConsumerState<EditCaseSheet> {
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

  late final CaseTipo _tipo;
  late PlanoMarketing _visibilidade;
  ProdutividadeUnidade? _produtividadeUnidade;
  String? _clientId;
  String? _selectedClientNameForFallback;
  List<String> _fotosResultado = const [];
  final _uuid = const Uuid();
  List<NovoCaseComparacao> _comparacoes = [];
  bool _hasConclusao = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final caso = widget.caso;
    _tipo = caso.tipo;
    _visibilidade = caso.visibilidade;
    _clientId = caso.clientId;
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
    _hasConclusao = _conclusaoTecnicaCtrl.text.trim().isNotEmpty;
    _fotosResultado = caso.fotosResultadoEfetivas;
    if (_tipo == CaseTipo.antesDepois) {
      _comparacoes = _comparacoesDoCase(caso);
    }
    _hydrateSelectedClientNameFallback();
  }

  /// Blocos de `avaliacoes_json`. Um bloco "tem conteúdo" com ao menos uma
  /// foto (A/B/C) ou um parâmetro com título. Se nenhum tem e o legado
  /// (`foto_antes_url`/`foto_depois_url`/`parametros_json`) está preenchido,
  /// o legado forma a Comparação 1 — herdando id e texto do primeiro bloco,
  /// se houver (bloco só com texto não perde a observação). Demais blocos
  /// seguem como estão.
  List<NovoCaseComparacao> _comparacoesDoCase(MarketingCase caso) {
    final itens = caso.avaliacoesLivres;
    final fotoAntes = _urlOuNull(caso.fotoAntesUrl);
    final fotoDepois = _urlOuNull(caso.fotoDepoisUrl);
    final parametros = caso.parametros;
    final legadoPreenchido =
        fotoAntes != null || fotoDepois != null || parametros.isNotEmpty;
    if (itens.isNotEmpty &&
        (itens.any(_blocoTemConteudo) || !legadoPreenchido)) {
      return [for (final item in itens) _comparacaoDoItem(item)];
    }
    final primeiro = itens.firstOrNull;
    return [
      NovoCaseComparacao(
        id: primeiro == null || primeiro.id.isEmpty ? _uuid.v4() : primeiro.id,
        fotoAntesUrl: fotoAntes,
        fotoDepoisUrl: fotoDepois,
        texto: primeiro?.observacoes ?? '',
        parametros: parametros,
      ),
      for (final item in itens.skip(1)) _comparacaoDoItem(item),
    ];
  }

  bool _blocoTemConteudo(AvaliacaoItem item) =>
      item.parametros.any((p) => p.titulo.trim().isNotEmpty) ||
      [
        item.fotoLadoAPath,
        item.fotoLadoBPath,
        item.fotoLadoCPath,
      ].any((foto) => _urlOuNull(foto) != null);

  NovoCaseComparacao _comparacaoDoItem(AvaliacaoItem item) {
    final fotoB = _urlOuNull(item.fotoLadoBPath);
    final fotoC = _urlOuNull(item.fotoLadoCPath);
    final temB = fotoB != null || item.nomeLadoB.trim().isNotEmpty;
    final temC = fotoC != null || item.nomeLadoC != null;
    return NovoCaseComparacao(
      id: item.id.isEmpty ? _uuid.v4() : item.id,
      fotos: [
        NovoCaseFotoSlot(
          rotulo: item.nomeLadoA,
          url: _urlOuNull(item.fotoLadoAPath),
        ),
        if (temB || temC) NovoCaseFotoSlot(rotulo: item.nomeLadoB, url: fotoB),
        if (temC) NovoCaseFotoSlot(rotulo: item.nomeLadoC ?? '', url: fotoC),
      ],
      texto: item.observacoes ?? '',
      parametros: item.parametros,
    );
  }

  Future<void> _hydrateSelectedClientNameFallback() async {
    final clientId = _clientId;
    if (clientId == null) return;
    final client = await ref.read(clientLookupProvider).findById(clientId);
    if (!mounted || client == null) return;
    setState(() => _selectedClientNameForFallback = client.name.trim());
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

  Future<void> _handleSalvar() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    if (_tipo == CaseTipo.avaliacao && _nomeTalhaoCtrl.text.trim().isEmpty) {
      _showError('Preencha o nome do talhão.');
      return;
    }

    if (_tipo == CaseTipo.resultado && _fotosResultado.isEmpty) {
      _showError('Foto principal obrigatória para o tipo Resultado.');
      return;
    }
    if (_tipo == CaseTipo.antesDepois) {
      if (!_comparacoes.first.temAlgumaFoto) {
        _showError('Adicione pelo menos uma foto na Comparação 1.');
        return;
      }
      if (!_validateComparacoesParametros()) return;
    }

    final produtividadeValor = _parseDouble(_produtividadeCtrl.text);
    final tamanhoHa = _parseDouble(_tamanhoHaCtrl.text);
    final produtividadeUnidade = produtividadeValor == null
        ? null
        : (_produtividadeUnidade ?? ProdutividadeUnidade.scHa);

    setState(() => _isSaving = true);
    HapticFeedback.mediumImpact();

    final casoOriginal = widget.caso;
    final antesDepois = _tipo == CaseTipo.antesDepois;
    final avaliacoes = antesDepois
        ? _avaliacoesDasComparacoes(casoOriginal)
        : const <AvaliacaoItem>[];
    final fotosPrimeira = antesDepois
        ? _urlsPreenchidas(_comparacoes.first)
        : const <String>[];
    final parametrosPrimeira = antesDepois
        ? _comparacoes.first.parametros
        : const <ParametroComparativo>[];
    final updatedCase = MarketingCase(
      id: casoOriginal.id,
      tipo: _tipo,
      visibilidade: _visibilidade,
      lat: casoOriginal.lat,
      lng: casoOriginal.lng,
      localizacaoTexto: casoOriginal.localizacaoTexto,
      produtorFazenda: marketingEffectiveProdutorFazenda(
        manualProdutor: _produtorCtrl.text,
        selectedClientName: _selectedClientNameForFallback,
      ),
      produtoUtilizado: _produtoCtrl.text.trim(),
      dataCase: casoOriginal.dataCase,
      produtividadeValor: produtividadeValor,
      produtividadeUnidade: produtividadeUnidade,
      nomeVendedor: _trimmedOrNull(_nomeVendedorCtrl.text),
      telefoneVendedor: _trimmedOrNull(_telefoneCtrl.text),
      descricao: casoOriginal.descricao,
      fotoPrincipalUrl: _fotosResultado.firstOrNull,
      fotosResultado: _fotosResultado,
      quantidadeProduzida: casoOriginal.quantidadeProduzida,
      prodSemProduto: casoOriginal.prodSemProduto,
      prodComProduto: casoOriginal.prodComProduto,
      unidadeProdutividade: casoOriginal.unidadeProdutividade,
      custoProdutoPorHa: casoOriginal.custoProdutoPorHa,
      valorGrao: casoOriginal.valorGrao,
      clientId: _clientId,
      ownerUserId: casoOriginal.ownerUserId,
      sourceCaseId: casoOriginal.sourceCaseId,
      drawingId: casoOriginal.drawingId,
      testeExecucaoId: casoOriginal.testeExecucaoId,
      liberadoEm: casoOriginal.liberadoEm,
      publicoAte: casoOriginal.publicoAte,
      fotoAntesUrl: antesDepois
          ? (fotosPrimeira.isNotEmpty ? fotosPrimeira.first : null)
          : casoOriginal.fotoAntesUrl,
      fotoDepoisUrl: antesDepois
          ? (fotosPrimeira.length > 1 ? fotosPrimeira[1] : null)
          : casoOriginal.fotoDepoisUrl,
      ganhoProdutividade: casoOriginal.ganhoProdutividade,
      economiaGerada: casoOriginal.economiaGerada,
      parametrosJson: antesDepois
          ? (parametrosPrimeira.isEmpty
                ? null
                : jsonEncode(
                    parametrosPrimeira.map((p) => p.toJson()).toList(),
                  ))
          : casoOriginal.parametrosJson,
      nomeTalhao: _trimmedOrNull(_nomeTalhaoCtrl.text),
      tamanhoHa: tamanhoHa,
      avaliacoes: casoOriginal.avaliacoes,
      avaliacoesJson: antesDepois
          ? jsonEncode(avaliacoes.map((item) => item.toJson()).toList())
          : casoOriginal.avaliacoesJson,
      roi: casoOriginal.roi,
      conclusao: _trimmedOrNull(_conclusaoCtrl.text),
      conclusaoTecnica: antesDepois && !_hasConclusao
          ? null
          : _trimmedOrNull(_conclusaoTecnicaCtrl.text),
      ativo: casoOriginal.ativo,
      status: casoOriginal.status,
      criadoEm: casoOriginal.criadoEm,
      atualizadoEm: DateTime.now().toUtc(),
      syncStatus: casoOriginal.syncStatus,
      deletadoEm: casoOriginal.deletadoEm,
    );

    final sanitizedCase = _sanitizeForTipo(updatedCase);

    try {
      await widget.onSalvar(sanitizedCase);
    } catch (_) {
      if (mounted) {
        _showError('Não foi possível salvar as alterações. Tente novamente.');
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  MarketingCase _sanitizeForTipo(MarketingCase marketingCase) {
    final json = <String, dynamic>{
      ...marketingCase.toJson(),
      'user_id': marketingCase.ownerUserId,
      'avaliacoes': marketingCase.avaliacoes
          .map((item) => item.toJson())
          .toList(),
    };

    switch (marketingCase.tipo) {
      case CaseTipo.resultado:
        json['foto_antes_url'] = null;
        json['foto_depois_url'] = null;
        json['ganho_produtividade'] = null;
        json['economia_gerada'] = null;
        json['parametros_json'] = null;
        json['avaliacoes'] = <Map<String, dynamic>>[];
        json['avaliacoes_json'] = null;
        break;
      case CaseTipo.antesDepois:
        json['foto_principal_url'] = null;
        json['fotos_resultado_json'] = null;
        json['quantidade_produzida'] = null;
        json['prod_sem_produto'] = null;
        json['prod_com_produto'] = null;
        json['unidade_produtividade'] = null;
        json['custo_produto_por_ha'] = null;
        json['valor_grao'] = null;
        json['roi_investimento'] = null;
        json['roi_retorno'] = null;
        json['roi_calculado'] = null;
        json['avaliacoes'] = <Map<String, dynamic>>[];
        break;
      case CaseTipo.avaliacao:
        json['foto_principal_url'] = null;
        json['fotos_resultado_json'] = null;
        json['quantidade_produzida'] = null;
        json['prod_sem_produto'] = null;
        json['prod_com_produto'] = null;
        json['unidade_produtividade'] = null;
        json['custo_produto_por_ha'] = null;
        json['valor_grao'] = null;
        json['roi_investimento'] = null;
        json['roi_retorno'] = null;
        json['roi_calculado'] = null;
        json['foto_antes_url'] = null;
        json['foto_depois_url'] = null;
        json['ganho_produtividade'] = null;
        json['economia_gerada'] = null;
        json['parametros_json'] = null;
        break;
    }

    return MarketingCase.fromJson(json);
  }

  String? _trimmedOrNull(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  String? _urlOuNull(String? url) {
    final trimmed = url?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }

  List<String> _urlsPreenchidas(NovoCaseComparacao comparacao) {
    return [
      for (final slot in comparacao.fotos)
        if (_urlOuNull(slot.url) != null) _urlOuNull(slot.url)!,
    ];
  }

  List<AvaliacaoItem> _avaliacoesDasComparacoes(MarketingCase casoOriginal) {
    String? cultura;
    for (final item in casoOriginal.avaliacoesLivres) {
      final valor = item.cultura?.trim();
      if (valor != null && valor.isNotEmpty) {
        cultura = valor;
        break;
      }
    }
    return [
      for (var i = 0; i < _comparacoes.length; i++)
        _avaliacaoDaComparacao(_comparacoes[i], i, cultura),
    ];
  }

  AvaliacaoItem _avaliacaoDaComparacao(
    NovoCaseComparacao comparacao,
    int index,
    String? cultura,
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
      cultura: cultura,
      parametros: comparacao.parametros,
      observacoes: texto.isEmpty ? null : texto,
    );
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

  void _addComparacao() {
    setState(() => _comparacoes.add(NovoCaseComparacao(id: _uuid.v4())));
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

  void _addParametro(int comparacaoIndex) {
    if (comparacaoIndex < 0 || comparacaoIndex >= _comparacoes.length) return;
    final parametro = ParametroComparativo(
      id: _uuid.v4(),
      titulo: '',
      testemunha: 0,
      teste: 0,
    );
    setState(() {
      final comparacao = _comparacoes[comparacaoIndex];
      _comparacoes[comparacaoIndex] = comparacao.copyWith(
        parametros: [...comparacao.parametros, parametro],
        parametroSelecionadoId: parametro.id,
      );
    });
    HapticFeedback.lightImpact();
  }

  void _updateParametro(int comparacaoIndex, ParametroComparativo parametro) {
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

  void _deleteParametro(int comparacaoIndex, String id) {
    if (comparacaoIndex < 0 || comparacaoIndex >= _comparacoes.length) return;
    final comparacao = _comparacoes[comparacaoIndex];
    setState(() {
      _comparacoes[comparacaoIndex] = comparacao.copyWith(
        parametros: comparacao.parametros.where((p) => p.id != id).toList(),
        clearParametroSelecionado: comparacao.parametroSelecionadoId == id,
      );
    });
  }

  void _selectParametro(int comparacaoIndex, String? id) {
    if (comparacaoIndex < 0 || comparacaoIndex >= _comparacoes.length) return;
    setState(() {
      final comparacao = _comparacoes[comparacaoIndex];
      _comparacoes[comparacaoIndex] = comparacao.copyWith(
        parametroSelecionadoId: id,
        clearParametroSelecionado: id == null,
      );
    });
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

  String get _produtividadeLabel =>
      _tipo == CaseTipo.avaliacao ? 'Produção ideal' : 'Valor da produtividade';

  Widget? _buildFotoSection() {
    switch (_tipo) {
      case CaseTipo.resultado:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            novoCaseSectionLabel('Fotos do Resultado'),
            const SizedBox(height: 10),
            FotosResultadoPickerWidget(
              urls: _fotosResultado,
              onChanged: (urls) => setState(() => _fotosResultado = urls),
            ),
          ],
        );
      case CaseTipo.antesDepois:
        return NovoCaseAntesDepoisSection(
          comparacoes: _comparacoes,
          produtoUtilizado: _produtoCtrl.text,
          hasConclusao: _hasConclusao,
          conclusaoCtrl: _conclusaoTecnicaCtrl,
          onAddComparacao: _addComparacao,
          onRemoveComparacao: _removeComparacao,
          onComparacaoChanged: _updateComparacao,
          onAddParametro: _addParametro,
          onParametroChanged: _updateParametro,
          onDeleteParametro: _deleteParametro,
          onSelectParametro: _selectParametro,
          onAddConclusao: () => setState(() => _hasConclusao = true),
          onRemoveConclusao: () => setState(() {
            _hasConclusao = false;
            _conclusaoTecnicaCtrl.clear();
          }),
        );
      case CaseTipo.avaliacao:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final plan =
        ref.watch(planoAtivoProvider).valueOrNull ?? UserPlan.free(userId: '');
    final enabledMetals = MarketingVisibilityPolicy.metaisSelecionaveis(plan);
    final seletorTravado = MarketingVisibilityPolicy.seletorTotalmenteTravado(
      plan,
    );
    final PlanoMarketing? selectedVisibilidadeUi = seletorTravado
        ? null
        : _visibilidade;

    final v = SoloForteSheetVisuals.of(context);
    final isIos = v.isIos;
    // Modal já pinta prata iOS — evitar segundo painel opaco (“dois sheets”).
    final sheetBg = v.sheetBackground;
    final sheetRadius = v.sheetRadius;
    final handleColor = v.handleColor;
    final titleColor = v.titleColor;
    final hintColor = v.subtitleColor;
    final lockAccent = isIos ? v.iconStroke : context.themeAccent;
    final dropdownBg = v.cardBackground;
    final fieldText = v.titleColor;
    final ctaBg = isIos ? v.ctaBackground : context.themeAccent;
    final ghostBorder = v.ghostBorder;
    final ghostFg = v.ghostText;
    final fotoSection = _buildFotoSection();

    return SafeArea(
      top: false,
      child: Material(
        color: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: sheetBg,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(sheetRadius),
            ),
            border: isIos
                ? Border(top: BorderSide(color: v.sheetBorder))
                : null,
          ),
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              20,
              12,
              20,
              20 + kFabSafeArea + MediaQuery.of(context).viewInsets.bottom,
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
                        color: handleColor,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Editar case',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                color: titleColor,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ),
                      IconButton(
                        onPressed: widget.onClose,
                        icon: Icon(Icons.close, color: titleColor),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.caso.localizacaoTexto,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: hintColor),
                  ),
                  const SizedBox(height: 20),
                  novoCaseSectionLabel('Tipo do case'),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: lockAccent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: lockAccent.withValues(alpha: 0.45),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.lock_outline,
                          size: 18,
                          color: lockAccent.withValues(alpha: 0.9),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          _tipoLabel,
                          style: Theme.of(context).textTheme.labelLarge
                              ?.copyWith(
                                color: titleColor,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  novoCaseSectionLabel('Visibilidade'),
                  const SizedBox(height: 10),
                  PlanoMarketingSelector(
                    selectedPlano: selectedVisibilidadeUi,
                    enabledMetals: enabledMetals,
                    onChanged: (value) => setState(() => _visibilidade = value),
                  ),
                  if (seletorTravado) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Disponível com plano pago',
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: v.subtitleColor),
                    ),
                  ],
                  const SizedBox(height: 20),
                  novoCaseSectionLabel('Dados principais'),
                  const SizedBox(height: 10),
                  MarketingClientSelector(
                    selectedClientId: _clientId,
                    onChanged: _handleClientChanged,
                  ),
                  const SizedBox(height: 8),
                  novoCaseFieldBox(
                    child: Column(
                      children: [
                        novoCaseTextInput(
                          _produtorCtrl,
                          'Produtor / Fazenda',
                          required: marketingProdutorFieldRequired(
                            clientId: _clientId,
                          ),
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
                          _produtividadeLabel,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                        ),
                        const NovoCaseFDivider(),
                        DropdownButtonFormField<ProdutividadeUnidade>(
                          initialValue: _produtividadeUnidade,
                          dropdownColor: dropdownBg,
                          iconEnabledColor: fieldText,
                          style: TextStyle(color: fieldText),
                          decoration: const InputDecoration(
                            // O tema global pinta o campo de branco; o card do
                            // novoCaseFieldBox já traz o fundo do sheet.
                            filled: false,
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            errorBorder: InputBorder.none,
                            focusedErrorBorder: InputBorder.none,
                            disabledBorder: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(vertical: 12),
                            isDense: true,
                          ),
                          hint: Text(
                            'Unidade da produtividade',
                            style: TextStyle(color: hintColor),
                          ),
                          items: ProdutividadeUnidade.values
                              .map(
                                (unit) => DropdownMenuItem(
                                  value: unit,
                                  child: Text(
                                    unit.toValue(),
                                    style: TextStyle(color: fieldText),
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (value) =>
                              setState(() => _produtividadeUnidade = value),
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
                  if (fotoSection != null) ...[
                    const SizedBox(height: 20),
                    fotoSection,
                  ],
                  if (_tipo != CaseTipo.antesDepois ||
                      _conclusaoCtrl.text.trim().isNotEmpty) ...[
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
                          // Antes/Depois edita a conclusão técnica no bloco da
                          // própria seção; aqui seria o mesmo campo duplicado.
                          if (_tipo != CaseTipo.antesDepois) ...[
                            const NovoCaseFDivider(),
                            novoCaseTextInput(
                              _conclusaoTecnicaCtrl,
                              'Conclusão técnica',
                              maxLines: 4,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _isSaving ? null : widget.onClose,
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: ghostBorder),
                            foregroundColor: ghostFg,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                isIos ? v.ghostRadius : 8,
                              ),
                            ),
                          ),
                          child: const Text('Cancelar'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          onPressed: _isSaving ? null : _handleSalvar,
                          style: FilledButton.styleFrom(
                            backgroundColor: ctaBg,
                            foregroundColor: v.ctaText,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(v.ctaRadius),
                            ),
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
