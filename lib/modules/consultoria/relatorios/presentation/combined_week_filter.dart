import 'package:flutter/material.dart';

import '../../../../ui/theme/premium/design_tokens.dart';
import '../domain/combined_week.dart';

/// Filtro por semana do relatório combinado: Tudo, Esta semana, Semana
/// passada ou qualquer outra semana escolhida no calendário.
class CombinedWeekFilter extends StatelessWidget {
  final CombinedWeek? week;
  final ValueChanged<CombinedWeek?> onChanged;

  const CombinedWeekFilter({
    super.key,
    required this.week,
    required this.onChanged,
  });

  Future<void> _pickWeek(BuildContext context) async {
    final now = DateTime.now();
    final firstDate = DateTime(now.year - 3);
    final start = week?.start ?? now;
    final picked = await showDatePicker(
      context: context,
      initialDate: start.isBefore(firstDate) ? firstDate : start,
      firstDate: firstDate,
      lastDate: now,
      helpText: 'Escolha um dia da semana',
    );
    if (picked == null) return;
    onChanged(CombinedWeek.of(picked));
  }

  @override
  Widget build(BuildContext context) {
    final current = week;
    final thisWeek = CombinedWeek.of(DateTime.now());
    final lastWeek = thisWeek.previous;
    final isOther =
        current != null && current != thisWeek && current != lastWeek;

    Widget chip(String label, bool selected, VoidCallback onTap) {
      return Padding(
        padding: const EdgeInsets.only(right: 8),
        child: ChoiceChip(
          label: Text(label),
          selected: selected,
          onSelected: (_) => onTap(),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                chip('Tudo', current == null, () => onChanged(null)),
                chip(
                  'Esta semana',
                  current == thisWeek,
                  () => onChanged(thisWeek),
                ),
                chip(
                  'Semana passada',
                  current == lastWeek,
                  () => onChanged(lastWeek),
                ),
                chip(
                  isOther ? current.label : 'Outra semana',
                  isOther,
                  () => _pickWeek(context),
                ),
              ],
            ),
          ),
          if (current != null)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                current.label,
                style: TextStyle(
                  fontSize: 12,
                  color: context.premiumTextSecondary,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
