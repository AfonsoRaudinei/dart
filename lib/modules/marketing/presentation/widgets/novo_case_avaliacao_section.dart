import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../ui/theme/premium/design_tokens.dart';
import '../../domain/entities/avaliacao_item.dart';
import 'avaliacao_card.dart';
import 'conclusao_bloco_widget.dart';
import 'novo_case_form_helpers.dart';

class NovoCaseAvaliacaoSection extends StatelessWidget {
  final List<AvaliacaoItem> avaliacoes;
  final String? avaliacaoAbertaId;
  final TextEditingController nomeTalhaoCtrl;
  final TextEditingController tamanhoHaCtrl;
  final bool hasConclusao;
  final TextEditingController conclusaoCtrl;
  final VoidCallback onAddAvaliacao;
  final ValueChanged<String> onToggleAvaliacao;
  final ValueChanged<AvaliacaoItem> onAvaliacaoChanged;
  final ValueChanged<String> onRemoveAvaliacao;
  final ValueChanged<String> onDuplicateAvaliacao;
  final VoidCallback onAddConclusao;
  final VoidCallback onRemoveConclusao;

  const NovoCaseAvaliacaoSection({
    super.key,
    required this.avaliacoes,
    required this.avaliacaoAbertaId,
    required this.nomeTalhaoCtrl,
    required this.tamanhoHaCtrl,
    required this.hasConclusao,
    required this.conclusaoCtrl,
    required this.onAddAvaliacao,
    required this.onToggleAvaliacao,
    required this.onAvaliacaoChanged,
    required this.onRemoveAvaliacao,
    required this.onDuplicateAvaliacao,
    required this.onAddConclusao,
    required this.onRemoveConclusao,
  });

  Widget _buildActionButton({
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
          mainAxisAlignment: MainAxisAlignment.center,
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

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        novoCaseSectionLabel('Dados do Talhão'),
        const SizedBox(height: 8),
        novoCaseFieldBox(
          child: Column(
            children: [
              novoCaseTextInput(
                nomeTalhaoCtrl,
                'Nome do Talhão *',
                required: true,
              ),
              const NovoCaseFDivider(),
              novoCaseTextInput(
                tamanhoHaCtrl,
                'Tamanho (ha)',
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        novoCaseSectionLabel('Avaliações (${avaliacoes.length})'),
        const SizedBox(height: 10),
        ...List.generate(avaliacoes.length, (index) {
          final avaliacao = avaliacoes[index];
          return AvaliacaoCard(
            key: ValueKey(avaliacao.id),
            avaliacao: avaliacao,
            index: index,
            expanded: avaliacaoAbertaId == avaliacao.id,
            onToggleExpanded: () => onToggleAvaliacao(avaliacao.id),
            onChanged: onAvaliacaoChanged,
            onDelete: () => onRemoveAvaliacao(avaliacao.id),
            onDuplicate: () => onDuplicateAvaliacao(avaliacao.id),
          );
        }),
        _buildActionButton(
          icon: Icons.add_circle_outline,
          label: 'Adicionar Avaliação',
          color: PremiumTokens.brandGreen,
          onTap: onAddAvaliacao,
        ),
        const SizedBox(height: 16),
        if (!hasConclusao)
          _buildActionButton(
            icon: Icons.notes_rounded,
            label: 'Adicionar Conclusão Técnica',
            color: const Color(0xFF0057FF),
            onTap: onAddConclusao,
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
