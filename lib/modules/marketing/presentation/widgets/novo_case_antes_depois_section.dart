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
  final void Function(int index, NovoCaseComparacao comparacao) onComparacaoChanged;
  final ValueChanged<int> onAddParametro;
  final void Function(int comparacaoIndex, ParametroComparativo parametro)
      onParametroChanged;
  final void Function(int comparacaoIndex, String parametroId) onDeleteParametro;
  final void Function(int comparacaoIndex, String? parametroId) onSelectParametro;
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

  List<ParametroComparativo> get _todosParametros {
    return comparacoes.expand((c) => c.parametros).toList();
  }

  String get _testeLabel {
    final trimmed = produtoUtilizado.trim();
    return trimmed.isEmpty ? 'Produto' : trimmed;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ...List.generate(comparacoes.length, (index) {
          final comparacao = comparacoes[index];
          final titulo = 'Comparação ${index + 1}';
          return Padding(
            padding: EdgeInsets.only(bottom: index < comparacoes.length - 1 ? 8 : 0),
            child: _ComparacaoBloco(
              titulo: titulo,
              showRemove: index > 0,
              comparacao: comparacao,
              onRemove: () => onRemoveComparacao(index),
              onFotoAntesChanged: (url) => onComparacaoChanged(
                index,
                comparacao.copyWith(fotoAntesUrl: url, clearFotoAntes: url == null),
              ),
              onFotoDepoisChanged: (url) => onComparacaoChanged(
                index,
                comparacao.copyWith(
                  fotoDepoisUrl: url,
                  clearFotoDepois: url == null,
                ),
              ),
              parametros: comparacao.parametros,
              parametroSelecionadoId: comparacao.parametroSelecionadoId,
              testeLabel: _testeLabel,
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
        if (_todosParametros.isNotEmpty) ...[
          novoCaseSectionLabel('Resultado Geral'),
          const SizedBox(height: 8),
          ComparativoChart(
            parametros: _todosParametros,
            selecionadoId: null,
            onSelect: (_) {},
            testeLabel: _testeLabel,
          ),
          const SizedBox(height: 16),
        ],
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

class _ComparacaoBloco extends StatelessWidget {
  final String titulo;
  final bool showRemove;
  final NovoCaseComparacao comparacao;
  final VoidCallback onRemove;
  final void Function(String?) onFotoAntesChanged;
  final void Function(String?) onFotoDepoisChanged;
  final List<ParametroComparativo> parametros;
  final String? parametroSelecionadoId;
  final String testeLabel;
  final VoidCallback onAddParametroForBloco;
  final ValueChanged<String?> onSelectParametro;
  final ValueChanged<ParametroComparativo> onParametroChanged;
  final ValueChanged<String> onDeleteParametro;

  const _ComparacaoBloco({
    required this.titulo,
    required this.showRemove,
    required this.comparacao,
    required this.onRemove,
    required this.onFotoAntesChanged,
    required this.onFotoDepoisChanged,
    required this.parametros,
    required this.parametroSelecionadoId,
    required this.testeLabel,
    required this.onAddParametroForBloco,
    required this.onSelectParametro,
    required this.onParametroChanged,
    required this.onDeleteParametro,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                titulo,
                style: TextStyle(
                  color: novoCasePrimaryTextColor(context),
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
            if (showRemove)
              IconButton(
                onPressed: () {
                  HapticFeedback.selectionClick();
                  onRemove();
                },
                icon: const Icon(Icons.delete_outline),
                tooltip: 'Remover comparação',
              ),
          ],
        ),
        const SizedBox(height: 8),
        ...parametros.map(
          (parametro) => ParametroCard(
            key: ValueKey('${comparacao.id}-${parametro.id}'),
            parametro: parametro,
            selected: parametroSelecionadoId == parametro.id,
            onChanged: onParametroChanged,
            onDelete: () => onDeleteParametro(parametro.id),
            onTap: () => onSelectParametro(
              parametroSelecionadoId == parametro.id ? null : parametro.id,
            ),
          ),
        ),
        OutlinedButton.icon(
          onPressed: onAddParametroForBloco,
          icon: const Icon(Icons.add_rounded),
          label: const Text('Adicionar Parâmetro'),
          style: novoCaseGhostOutlinedButtonStyle(context),
        ),
        const SizedBox(height: 12),
        ComparativoChart(
          parametros: parametros,
          selecionadoId: parametroSelecionadoId,
          onSelect: onSelectParametro,
          testeLabel: testeLabel,
        ),
        const SizedBox(height: 12),
        novoCaseSectionLabel('Fotos'),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Antes *',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                      color: novoCaseSecondaryTextColor(context),
                    ),
                  ),
                  const SizedBox(height: 6),
                  FotoPickerWidget(
                    label: 'Foto Antes',
                    url: comparacao.fotoAntesUrl,
                    folder: 'antes_depois',
                    height: 140,
                    required: comparacao.fotoAntesUrl == null,
                    includeVegetalInversion: true,
                    onChanged: onFotoAntesChanged,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Depois *',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                      color: novoCaseSecondaryTextColor(context),
                    ),
                  ),
                  const SizedBox(height: 6),
                  FotoPickerWidget(
                    label: 'Foto Depois',
                    url: comparacao.fotoDepoisUrl,
                    folder: 'antes_depois',
                    height: 140,
                    required: comparacao.fotoDepoisUrl == null,
                    includeVegetalInversion: true,
                    onChanged: onFotoDepoisChanged,
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
