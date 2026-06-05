part of 'occurrence_creation_sheet.dart';

extension _OccurrenceCreationSheetUiHelpers on _OccurrenceCreationSheetState {
  Widget _buildNutrientGrid(Color color) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: kNutrientes.map((entry) {
          final sym = entry.$1;
          final name = entry.$2;
          final sel = _nutrientes.contains(sym);
          return GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              _toggleNutriente(sym, sel);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: sel
                    ? color.withValues(alpha: .25)
                    : const Color(0xFF1C1C1E),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: sel ? color : Colors.white12,
                  width: sel ? 1.5 : 1,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    sym,
                    style: TextStyle(
                      color: sel ? color : Colors.white60,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    name.substring(0, name.length.clamp(0, 6)),
                    style: TextStyle(
                      color: sel ? color.withValues(alpha: .8) : Colors.white24,
                      fontSize: 9,
                    ),
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildAguaSection(Color color) {
    final current = _metricValue(OccurrenceCategory.agua, 'status');
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
      child: Row(
        children: List.generate(kAguaLabels.length, (i) {
          final sel = current == i;
          return Expanded(
            child: GestureDetector(
              onTap: () => _setMetric(OccurrenceCategory.agua, 'status', i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                margin: const EdgeInsets.only(right: 6),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: sel
                      ? color.withValues(alpha: .2)
                      : const Color(0xFF1C1C1E),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: sel ? color : Colors.white12,
                    width: sel ? 1.5 : 1,
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      i == 0
                          ? '💧'
                          : i == 1
                          ? '🏜'
                          : '🌊',
                      style: const TextStyle(fontSize: 18),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      kAguaLabels[i],
                      style: TextStyle(
                        color: sel ? color : Colors.white38,
                        fontWeight: sel ? FontWeight.bold : FontWeight.normal,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
