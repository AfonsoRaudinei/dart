import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/ui/sheets/sheet_tokens.dart';
import '../../../../ui/theme/premium/design_tokens.dart';
import '../../domain/entities/avaliacao_item.dart';
import '../../domain/entities/parametro_comparativo.dart';
import 'comparativo_chart.dart';
import 'foto_picker_widget.dart';
import 'novo_case_form_helpers.dart';
import 'parametro_card.dart';

class AvaliacaoCard extends StatefulWidget {
  final AvaliacaoItem avaliacao;
  final int index;
  final bool expanded;
  final ValueChanged<AvaliacaoItem> onChanged;
  final VoidCallback onDelete;
  final VoidCallback onDuplicate;
  final VoidCallback onToggleExpanded;

  const AvaliacaoCard({
    super.key,
    required this.avaliacao,
    required this.index,
    required this.expanded,
    required this.onChanged,
    required this.onDelete,
    required this.onDuplicate,
    required this.onToggleExpanded,
  });

  @override
  State<AvaliacaoCard> createState() => _AvaliacaoCardState();
}

class _AvaliacaoCardState extends State<AvaliacaoCard> {
  static const _uuid = Uuid();
  static const _culturas = [
    'Soja',
    'Milho',
    'Algodão',
    'Feijão',
    'Arroz',
    'Sorgo',
    'Trigo',
    'Outro',
  ];

  late final TextEditingController _tituloCtrl;
  late final TextEditingController _ladoACtrl;
  late final TextEditingController _ladoBCtrl;
  late final TextEditingController _observacoesCtrl;
  String? _selectedParametroId;

  @override
  void initState() {
    super.initState();
    _tituloCtrl = TextEditingController(text: widget.avaliacao.titulo);
    _ladoACtrl = TextEditingController(text: widget.avaliacao.nomeLadoA);
    _ladoBCtrl = TextEditingController(text: widget.avaliacao.nomeLadoB);
    _observacoesCtrl = TextEditingController(
      text: widget.avaliacao.observacoes ?? '',
    );
  }

  @override
  void didUpdateWidget(covariant AvaliacaoCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.avaliacao.id != widget.avaliacao.id) {
      _tituloCtrl.text = widget.avaliacao.titulo;
      _ladoACtrl.text = widget.avaliacao.nomeLadoA;
      _ladoBCtrl.text = widget.avaliacao.nomeLadoB;
      _observacoesCtrl.text = widget.avaliacao.observacoes ?? '';
      _selectedParametroId = null;
    }
  }

  @override
  void dispose() {
    _tituloCtrl.dispose();
    _ladoACtrl.dispose();
    _ladoBCtrl.dispose();
    _observacoesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final avaliacao = widget.avaliacao;
    final media = _formatSigned(avaliacao.mediaGanhoPercent);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: SoloForteSheetTokens.inputBackground,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: PremiumTokens.hairlineLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: widget.onToggleExpanded,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 13,
                    backgroundColor: PremiumTokens.brandGreen.withValues(
                      alpha: 0.12,
                    ),
                    child: Text(
                      '${widget.index + 1}',
                      style: const TextStyle(
                        color: PremiumTokens.brandGreen,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${_title(avaliacao)} — ${avaliacao.nomeLadoA} vs ${avaliacao.nomeLadoB}',
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: SoloForteSheetTokens.inputText,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Média: $media% · ${avaliacao.parametros.length} parâmetros',
                          style: const TextStyle(
                            fontSize: 11,
                            color: SoloForteSheetTokens.inputHint,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Duplicar avaliação',
                    onPressed: widget.onDuplicate,
                    icon: const Icon(Icons.copy_rounded, size: 18),
                  ),
                  IconButton(
                    tooltip: 'Remover avaliação',
                    onPressed: _confirmDelete,
                    icon: const Icon(
                      Icons.delete_outline_rounded,
                      color: PremiumTokens.alertError,
                      size: 18,
                    ),
                  ),
                  Icon(
                    widget.expanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                  ),
                ],
              ),
            ),
          ),
          if (widget.expanded) ...[
            const Divider(height: 1, color: PremiumTokens.hairlineLight),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  novoCaseTextInput(
                    _tituloCtrl,
                    'Título da avaliação',
                    onChanged: (_) => _emitText(),
                  ),
                  const NovoCaseFDivider(),
                  Row(
                    children: [
                      Expanded(
                        child: novoCaseTextInput(
                          _ladoACtrl,
                          'Nome Lado A',
                          onChanged: (_) => _emitText(),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: novoCaseTextInput(
                          _ladoBCtrl,
                          'Nome Lado B',
                          onChanged: (_) => _emitText(),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: FotoPickerWidget(
                          label: 'Foto Lado A',
                          url: avaliacao.fotoLadoAPath,
                          folder: 'avaliacoes',
                          height: 128,
                          onChanged: (url) => widget.onChanged(
                            avaliacao.copyWith(
                              fotoLadoAPath: url,
                              clearFotoLadoA: url == null,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FotoPickerWidget(
                          label: 'Foto Lado B',
                          url: avaliacao.fotoLadoBPath,
                          folder: 'avaliacoes',
                          height: 128,
                          onChanged: (url) => widget.onChanged(
                            avaliacao.copyWith(
                              fotoLadoBPath: url,
                              clearFotoLadoB: url == null,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _CulturaDropdown(
                    value: avaliacao.cultura,
                    culturas: _culturas,
                    onChanged: (value) => widget.onChanged(
                      avaliacao.copyWith(
                        cultura: value,
                        clearCultura: value == null,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  novoCaseSectionLabel('Parâmetros Comparativos'),
                  const SizedBox(height: 10),
                  ...avaliacao.parametros.map(
                    (parametro) => ParametroCard(
                      key: ValueKey(parametro.id),
                      parametro: parametro,
                      selected: parametro.id == _selectedParametroId,
                      onTap: () =>
                          setState(() => _selectedParametroId = parametro.id),
                      onChanged: _updateParametro,
                      onDelete: () => _deleteParametro(parametro.id),
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: _addParametro,
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Adicionar Parâmetro'),
                  ),
                  if (avaliacao.parametros.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    ComparativoChart(
                      parametros: avaliacao.parametros,
                      selecionadoId: _selectedParametroId,
                      onSelect: (id) =>
                          setState(() => _selectedParametroId = id),
                      testemunhaLabel: avaliacao.nomeLadoA,
                      testeLabel: avaliacao.nomeLadoB,
                    ),
                  ],
                  const SizedBox(height: 14),
                  novoCaseTextInput(
                    _observacoesCtrl,
                    'Observações...',
                    maxLines: 3,
                    onChanged: (_) => _emitText(),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _emitText() {
    final observacoes = _observacoesCtrl.text.trim();
    widget.onChanged(
      widget.avaliacao.copyWith(
        titulo: _tituloCtrl.text.trim(),
        nomeLadoA: _defaultText(_ladoACtrl.text, 'Lado A'),
        nomeLadoB: _defaultText(_ladoBCtrl.text, 'Lado B'),
        observacoes: observacoes.isEmpty ? null : observacoes,
        clearObservacoes: observacoes.isEmpty,
      ),
    );
  }

  void _addParametro() {
    final parametro = ParametroComparativo(
      id: _uuid.v4(),
      titulo: '',
      testemunha: 0,
      teste: 0,
    );
    widget.onChanged(
      widget.avaliacao.copyWith(
        parametros: [...widget.avaliacao.parametros, parametro],
      ),
    );
    setState(() => _selectedParametroId = parametro.id);
    HapticFeedback.lightImpact();
  }

  void _updateParametro(ParametroComparativo parametro) {
    widget.onChanged(
      widget.avaliacao.copyWith(
        parametros: widget.avaliacao.parametros
            .map((item) => item.id == parametro.id ? parametro : item)
            .toList(),
      ),
    );
  }

  void _deleteParametro(String id) {
    widget.onChanged(
      widget.avaliacao.copyWith(
        parametros: widget.avaliacao.parametros
            .where((item) => item.id != id)
            .toList(),
      ),
    );
    if (_selectedParametroId == id) {
      setState(() => _selectedParametroId = null);
    }
    HapticFeedback.selectionClick();
  }

  void _confirmDelete() {
    HapticFeedback.selectionClick();
    showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remover avaliação?'),
        content: const Text('Esta avaliação será removida do case.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: PremiumTokens.alertError,
            ),
            child: const Text('Remover'),
          ),
        ],
      ),
    ).then((confirmed) {
      if (confirmed == true) widget.onDelete();
    });
  }

  static String _title(AvaliacaoItem avaliacao) {
    return avaliacao.titulo.trim().isEmpty
        ? 'Avaliação'
        : avaliacao.titulo.trim();
  }

  static String _defaultText(String value, String fallback) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? fallback : trimmed;
  }

  static String _formatSigned(double value) {
    final formatted = value.toStringAsFixed(1).replaceAll('.', ',');
    return value >= 0 ? '+$formatted' : formatted;
  }
}

class _CulturaDropdown extends StatelessWidget {
  final String? value;
  final List<String> culturas;
  final ValueChanged<String?> onChanged;

  const _CulturaDropdown({
    required this.value,
    required this.culturas,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: value != null && culturas.contains(value) ? value : null,
      decoration: const InputDecoration(
        hintText: 'Cultura',
        border: InputBorder.none,
        filled: true,
        fillColor: SoloForteSheetTokens.inputBackground,
      ),
      dropdownColor: SoloForteSheetTokens.inputBackground,
      items: culturas
          .map((item) => DropdownMenuItem(value: item, child: Text(item)))
          .toList(),
      onChanged: onChanged,
    );
  }
}
