import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:soloforte_app/core/ui/sheets/sheet_tokens.dart';
import 'package:soloforte_app/core/ui/sheets/soloforte_sheet.dart';

import '../../domain/entities/marketing_case.dart';
import '../../domain/enums/case_tipo.dart';
import '../../domain/enums/marketing_case_status.dart';

/// Sheet mínimo de edição de case (owner direto ou proposta de contraparte).
class MarketingCaseEditSheet extends StatefulWidget {
  final MarketingCase initial;
  final bool asProposal;
  final Future<void> Function(MarketingCase updated) onSubmit;

  const MarketingCaseEditSheet({
    super.key,
    required this.initial,
    required this.onSubmit,
    this.asProposal = false,
  });

  static Future<void> show({
    required BuildContext context,
    required MarketingCase initial,
    required Future<void> Function(MarketingCase updated) onSubmit,
    bool asProposal = false,
  }) {
    return showSoloForteSheet(
      context: context,
      maxHeightFraction: 0.9,
      showDragHandle: true,
      builder: (_) => MarketingCaseEditSheet(
        initial: initial,
        onSubmit: onSubmit,
        asProposal: asProposal,
      ),
    );
  }

  @override
  State<MarketingCaseEditSheet> createState() => _MarketingCaseEditSheetState();
}

class _MarketingCaseEditSheetState extends State<MarketingCaseEditSheet> {
  late final TextEditingController _produto;
  late final TextEditingController _localizacao;
  late final TextEditingController _descricao;
  late final TextEditingController _prodSem;
  late final TextEditingController _prodCom;
  late final TextEditingController _custo;
  late final TextEditingController _valorGrao;
  late final TextEditingController _ganho;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final c = widget.initial;
    _produto = TextEditingController(text: c.produtoUtilizado);
    _localizacao = TextEditingController(text: c.localizacaoTexto);
    _descricao = TextEditingController(text: c.descricao ?? '');
    _prodSem = TextEditingController(
      text: c.prodSemProduto?.toString() ?? '',
    );
    _prodCom = TextEditingController(
      text: c.prodComProduto?.toString() ?? '',
    );
    _custo = TextEditingController(
      text: c.custoProdutoPorHa?.toString() ?? '',
    );
    _valorGrao = TextEditingController(text: c.valorGrao?.toString() ?? '');
    _ganho = TextEditingController(text: c.ganhoProdutividade ?? '');
  }

  @override
  void dispose() {
    _produto.dispose();
    _localizacao.dispose();
    _descricao.dispose();
    _prodSem.dispose();
    _prodCom.dispose();
    _custo.dispose();
    _valorGrao.dispose();
    _ganho.dispose();
    super.dispose();
  }

  double? _parse(String raw) {
    final t = raw.trim().replaceAll(',', '.');
    if (t.isEmpty) return null;
    return double.tryParse(t);
  }

  Future<void> _submit() async {
    final produto = _produto.text.trim();
    final local = _localizacao.text.trim();
    if (produto.isEmpty || local.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Produto e localização são obrigatórios.')),
      );
      return;
    }

    setState(() => _saving = true);
    HapticFeedback.mediumImpact();

    final updated = MarketingCase.fromJson({
      ...widget.initial.toJson(),
      'produto_utilizado': produto,
      'localizacao_texto': local,
      'descricao': _descricao.text.trim().isEmpty
          ? null
          : _descricao.text.trim(),
      if (widget.initial.tipo == CaseTipo.resultado) ...{
        'prod_sem_produto': _parse(_prodSem.text),
        'prod_com_produto': _parse(_prodCom.text),
        'custo_produto_por_ha': _parse(_custo.text),
        'valor_grao': _parse(_valorGrao.text),
      },
      if (widget.initial.tipo == CaseTipo.antesDepois)
        'ganho_produtividade': _ganho.text.trim().isEmpty
            ? null
            : _ganho.text.trim(),
      'status': MarketingCaseStatus.published.toValue(),
      'atualizado_em': DateTime.now().toIso8601String(),
      'avaliacoes': widget.initial.avaliacoes.map((e) => e.toJson()).toList(),
    });

    try {
      await widget.onSubmit(updated);
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível salvar a edição.')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Text(
            widget.asProposal ? 'Sugerir edição' : 'Editar case',
            style: const TextStyle(
              color: SoloForteSheetTokens.inputText,
              fontWeight: FontWeight.w800,
              fontSize: 20,
            ),
          ),
          const SizedBox(height: 16),
          _field('Produto', _produto),
          _field('Localização', _localizacao),
          _field('Descrição', _descricao, maxLines: 3),
          if (widget.initial.tipo == CaseTipo.resultado) ...[
            _field('Prod. sem produto', _prodSem, keyboard: TextInputType.number),
            _field('Prod. com produto', _prodCom, keyboard: TextInputType.number),
            _field('Custo produto/ha', _custo, keyboard: TextInputType.number),
            _field('Valor do grão', _valorGrao, keyboard: TextInputType.number),
          ],
          if (widget.initial.tipo == CaseTipo.antesDepois)
            _field('Ganho de produtividade', _ganho),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _saving ? null : _submit,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF34C759),
              minimumSize: const Size.fromHeight(48),
            ),
            child: Text(
              _saving
                  ? 'Salvando…'
                  : (widget.asProposal ? 'Enviar para aprovação' : 'Salvar'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _field(
    String label,
    TextEditingController controller, {
    int maxLines = 1,
    TextInputType? keyboard,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboard,
        style: const TextStyle(color: SoloForteSheetTokens.inputText),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: SoloForteSheetTokens.inputHint),
          filled: true,
          fillColor: SoloForteSheetTokens.inputBackground,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}
