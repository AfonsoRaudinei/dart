import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/novo_case_comparacao.dart';
import '../../domain/entities/parametro_comparativo.dart';
import 'comparativo_chart.dart';
import 'conclusao_bloco_widget.dart';
import 'foto_picker_widget.dart';
import 'novo_case_form_helpers.dart';
import 'parametro_card.dart';

/// Seção unificada Antes/Depois: N comparações (fotos + parâmetros), conclusão opcional.
class NovoCaseAntesDepoisSection extends StatelessWidget {
  final List<NovoCaseComparacao> comparacoes;
  final String produtoUtilizado;
  final bool hasConclusao;
  final TextEditingController conclusaoCtrl;
  final VoidCallback onAddComparacao;
  final ValueChanged<int> onRemoveComparacao;
  final void Function(int index, NovoCaseComparacao comparacao)
  onComparacaoChanged;
  final ValueChanged<int> onAddParametro;
  final void Function(int comparacaoIndex, ParametroComparativo parametro)
  onParametroChanged;
  final void Function(int comparacaoIndex, String parametroId)
  onDeleteParametro;
  final void Function(int comparacaoIndex, String? parametroId)
  onSelectParametro;
  final VoidCallback onAddConclusao;
  final VoidCallback onRemoveConclusao;

  const NovoCaseAntesDepoisSection({
    super.key,
    required this.comparacoes,
    required this.produtoUtilizado,
    required this.hasConclusao,
    required this.conclusaoCtrl,
    required this.onAddComparacao,
    required this.onRemoveComparacao,
    required this.onComparacaoChanged,
    required this.onAddParametro,
    required this.onParametroChanged,
    required this.onDeleteParametro,
    required this.onSelectParametro,
    required this.onAddConclusao,
    required this.onRemoveConclusao,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ...List.generate(comparacoes.length, (index) {
          final comparacao = comparacoes[index];
          final titulo = 'Comparação ${index + 1}';
          return Padding(
            padding: EdgeInsets.only(
              bottom: index < comparacoes.length - 1 ? 8 : 0,
            ),
            child: _ComparacaoBloco(
              key: ValueKey(comparacao.id),
              titulo: titulo,
              showRemove: index > 0,
              comparacao: comparacao,
              onRemove: () => onRemoveComparacao(index),
              onChanged: (updated) => onComparacaoChanged(index, updated),
              parametros: comparacao.parametros,
              parametroSelecionadoId: comparacao.parametroSelecionadoId,
              onAddParametroForBloco: () => onAddParametro(index),
              onSelectParametro: (id) => onSelectParametro(index, id),
              onParametroChanged: (p) => onParametroChanged(index, p),
              onDeleteParametro: (id) => onDeleteParametro(index, id),
            ),
          );
        }),
        OutlinedButton.icon(
          onPressed: onAddComparacao,
          icon: const Icon(Icons.add_rounded),
          label: const Text('Adicionar comparação'),
          style: novoCaseGhostOutlinedButtonStyle(context),
        ),
        const SizedBox(height: 16),
        if (!hasConclusao)
          OutlinedButton.icon(
            onPressed: () {
              HapticFeedback.selectionClick();
              onAddConclusao();
            },
            icon: const Icon(Icons.notes_rounded),
            label: const Text('Adicionar Conclusão Técnica'),
            style: novoCaseGhostOutlinedButtonStyle(context),
          )
        else
          ConclusaoBlocoWidget(
            conclusaoCtrl: conclusaoCtrl,
            onRemove: onRemoveConclusao,
          ),
        const SizedBox(height: 20),
      ],
    );
  }
}

class _ComparacaoBloco extends StatefulWidget {
  final String titulo;
  final bool showRemove;
  final NovoCaseComparacao comparacao;
  final VoidCallback onRemove;
  final ValueChanged<NovoCaseComparacao> onChanged;
  final List<ParametroComparativo> parametros;
  final String? parametroSelecionadoId;
  final VoidCallback onAddParametroForBloco;
  final ValueChanged<String?> onSelectParametro;
  final ValueChanged<ParametroComparativo> onParametroChanged;
  final ValueChanged<String> onDeleteParametro;

  const _ComparacaoBloco({
    super.key,
    required this.titulo,
    required this.showRemove,
    required this.comparacao,
    required this.onRemove,
    required this.onChanged,
    required this.parametros,
    required this.parametroSelecionadoId,
    required this.onAddParametroForBloco,
    required this.onSelectParametro,
    required this.onParametroChanged,
    required this.onDeleteParametro,
  });

  @override
  State<_ComparacaoBloco> createState() => _ComparacaoBlocoState();
}

class _ComparacaoBlocoState extends State<_ComparacaoBloco> {
  final Map<String, TextEditingController> _rotulos = {};
  late final TextEditingController _textoCtrl;

  @override
  void initState() {
    super.initState();
    _textoCtrl = TextEditingController(text: widget.comparacao.texto);
    for (final slot in widget.comparacao.fotos) {
      _rotulos[slot.id] = TextEditingController(text: slot.rotulo);
    }
  }

  @override
  void didUpdateWidget(covariant _ComparacaoBloco oldWidget) {
    super.didUpdateWidget(oldWidget);
    _dropUnusedRotulos();
    for (final slot in widget.comparacao.fotos) {
      final controller = _rotulos[slot.id];
      if (controller == null) {
        _rotulos[slot.id] = TextEditingController(text: slot.rotulo);
      } else {
        _align(controller, slot.rotulo);
      }
    }
    _align(_textoCtrl, widget.comparacao.texto);
  }

  @override
  void dispose() {
    for (final controller in _rotulos.values) {
      controller.dispose();
    }
    _textoCtrl.dispose();
    super.dispose();
  }

  void _dropUnusedRotulos() {
    final vivos = widget.comparacao.fotos.map((slot) => slot.id).toSet();
    final mortos = _rotulos.keys.where((id) => !vivos.contains(id)).toList();
    for (final id in mortos) {
      final controller = _rotulos.remove(id);
      if (controller == null) continue;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        controller.dispose();
      });
    }
  }

  void _align(TextEditingController controller, String value) {
    if (controller.text == value) return;
    controller.value = TextEditingValue(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
    );
  }

  void _setRotulo(int index, String rotulo) {
    final fotos = [
      for (var i = 0; i < widget.comparacao.fotos.length; i++)
        if (i == index)
          widget.comparacao.fotos[i].copyWith(rotulo: rotulo)
        else
          widget.comparacao.fotos[i],
    ];
    widget.onChanged(widget.comparacao.copyWith(fotos: fotos));
  }

  void _setUrl(int index, String? url) {
    final fotos = [
      for (var i = 0; i < widget.comparacao.fotos.length; i++)
        if (i == index)
          widget.comparacao.fotos[i].copyWith(url: url, clearUrl: url == null)
        else
          widget.comparacao.fotos[i],
    ];
    widget.onChanged(widget.comparacao.copyWith(fotos: fotos));
  }

  void _addFoto() {
    final fotos = widget.comparacao.fotos;
    if (fotos.length >= 3) return;
    final rotulo = fotos.length == 1 ? 'Depois' : '';
    HapticFeedback.selectionClick();
    widget.onChanged(
      widget.comparacao.copyWith(
        fotos: [
          ...fotos,
          NovoCaseFotoSlot(rotulo: rotulo),
        ],
      ),
    );
  }

  void _removeFoto(int index) {
    final fotos = widget.comparacao.fotos;
    if (fotos.length <= 1 || index < 0 || index >= fotos.length) return;
    HapticFeedback.selectionClick();
    widget.onChanged(
      widget.comparacao.copyWith(
        fotos: [
          for (var i = 0; i < fotos.length; i++)
            if (i != index) fotos[i],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final comparacao = widget.comparacao;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                widget.titulo,
                style: TextStyle(
                  color: novoCasePrimaryTextColor(context),
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
            if (widget.showRemove)
              IconButton(
                onPressed: () {
                  HapticFeedback.selectionClick();
                  widget.onRemove();
                },
                icon: const Icon(Icons.delete_outline),
                tooltip: 'Remover comparação',
              ),
          ],
        ),
        const SizedBox(height: 8),
        ...widget.parametros.map(
          (parametro) => ParametroCard(
            key: ValueKey('${comparacao.id}-${parametro.id}'),
            parametro: parametro,
            selected: widget.parametroSelecionadoId == parametro.id,
            onChanged: widget.onParametroChanged,
            onDelete: () => widget.onDeleteParametro(parametro.id),
            onTap: () => widget.onSelectParametro(
              widget.parametroSelecionadoId == parametro.id
                  ? null
                  : parametro.id,
            ),
          ),
        ),
        OutlinedButton.icon(
          onPressed: widget.onAddParametroForBloco,
          icon: const Icon(Icons.add_rounded),
          label: const Text('Adicionar Parâmetro'),
          style: novoCaseGhostOutlinedButtonStyle(context),
        ),
        const SizedBox(height: 12),
        ComparativoChart(
          parametros: widget.parametros,
          selecionadoId: widget.parametroSelecionadoId,
          onSelect: widget.onSelectParametro,
        ),
        const SizedBox(height: 12),
        novoCaseSectionLabel('Fotos'),
        const SizedBox(height: 8),
        _gradeFotos(context),
        if (comparacao.fotos.length < 3) ...[
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _addFoto,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Adicionar foto'),
            style: novoCaseGhostOutlinedButtonStyle(context),
          ),
        ],
        const SizedBox(height: 12),
        Text(
          'Texto',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 12,
            color: novoCaseSecondaryTextColor(context),
          ),
        ),
        const SizedBox(height: 6),
        novoCaseFieldBox(
          child: novoCaseTextInput(
            _textoCtrl,
            'Nota livre (opcional)',
            maxLines: 3,
            onChanged: (value) {
              widget.onChanged(comparacao.copyWith(texto: value));
            },
          ),
        ),
      ],
    );
  }

  Widget _gradeFotos(BuildContext context) {
    final n = widget.comparacao.fotos.length;
    if (n <= 1) return _slot(context, 0);
    if (n == 2) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: _slot(context, 0)),
          const SizedBox(width: 12),
          Expanded(child: _slot(context, 1)),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _slot(context, 0)),
            const SizedBox(width: 12),
            Expanded(child: _slot(context, 1)),
          ],
        ),
        const SizedBox(height: 12),
        _slot(context, 2),
      ],
    );
  }

  Widget _slot(BuildContext context, int index) {
    final slot = widget.comparacao.fotos[index];
    final controller = _rotulos[slot.id];
    final canRemove = widget.comparacao.fotos.length > 1;
    final rotulo = slot.rotulo.trim();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: controller == null
                  ? const SizedBox.shrink()
                  : novoCaseFieldBox(
                      child: novoCaseTextInput(
                        controller,
                        'Rótulo',
                        onChanged: (value) => _setRotulo(index, value),
                      ),
                    ),
            ),
            if (canRemove)
              IconButton(
                onPressed: () => _removeFoto(index),
                icon: const Icon(Icons.close_rounded),
                tooltip: 'Remover foto',
                visualDensity: VisualDensity.compact,
              ),
          ],
        ),
        const SizedBox(height: 6),
        FotoPickerWidget(
          label: rotulo.isEmpty ? 'Foto' : rotulo,
          url: slot.url,
          folder: 'antes_depois',
          height: 140,
          required: false,
          includeVegetalInversion: true,
          onChanged: (url) => _setUrl(index, url),
        ),
      ],
    );
  }
}
