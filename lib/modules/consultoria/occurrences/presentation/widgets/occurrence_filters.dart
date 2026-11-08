import 'package:flutter/material.dart';
import 'package:soloforte_app/core/ui/sheets/solo_forte_sheet_visuals.dart';
import 'package:soloforte_app/ui/theme/premium/design_tokens.dart';

import '../../domain/occurrence.dart';
import '../../domain/occurrence_andamento.dart';

/// Filtros minimalistas para ocorrências
class OccurrenceFilters {
  final Set<OccurrenceCategory> categories;
  final Set<String> statuses; // 'draft', 'confirmed'
  final Set<String> andamentos;
  final bool onlyActiveVisit;

  const OccurrenceFilters({
    this.categories = const {},
    this.statuses = const {},
    this.andamentos = const {},
    this.onlyActiveVisit = false,
  });

  bool get hasAnyFilter =>
      categories.isNotEmpty ||
      statuses.isNotEmpty ||
      andamentos.isNotEmpty ||
      onlyActiveVisit;

  OccurrenceFilters copyWith({
    Set<OccurrenceCategory>? categories,
    Set<String>? statuses,
    Set<String>? andamentos,
    bool? onlyActiveVisit,
  }) {
    return OccurrenceFilters(
      categories: categories ?? this.categories,
      statuses: statuses ?? this.statuses,
      andamentos: andamentos ?? this.andamentos,
      onlyActiveVisit: onlyActiveVisit ?? this.onlyActiveVisit,
    );
  }

  /// Verifica se uma ocorrência passa pelos filtros ativos
  bool matches(Occurrence occurrence, {String? activeVisitId}) {
    // Filtro de categoria
    if (categories.isNotEmpty) {
      final occCategory = OccurrenceCategory.fromString(occurrence.category);
      if (!categories.contains(occCategory)) return false;
    }

    // Filtro de status
    if (statuses.isNotEmpty) {
      final occStatus = occurrence.status ?? 'draft';
      if (!statuses.contains(occStatus)) return false;
    }

    if (andamentos.isNotEmpty) {
      final value = occurrence.andamento ??
          OccurrenceAndamento.aberta.storageValue;
      if (!andamentos.contains(value)) return false;
    }

    // Filtro de visita ativa
    if (onlyActiveVisit) {
      if (activeVisitId == null) return false;
      if (occurrence.visitSessionId != activeVisitId) return false;
    }

    return true;
  }

  OccurrenceFilters clear() {
    return const OccurrenceFilters();
  }
}

/// Widget de seleção de filtros (minimalista)
class OccurrenceFilterSelector extends StatelessWidget {
  final OccurrenceFilters filters;
  final ValueChanged<OccurrenceFilters> onChanged;
  final String? activeVisitId;

  const OccurrenceFilterSelector({
    super.key,
    required this.filters,
    required this.onChanged,
    this.activeVisitId,
  });

  @override
  Widget build(BuildContext context) {
    final v = SoloForteSheetVisuals.of(context);
    final accent = v.isIos ? v.iconStroke : context.themeAccent;
    final chipBg = v.cardBackground;
    final selectedLabel = v.ctaText;
    final unselectedLabel = v.subtitleColor;
    final sectionLabel = v.subtitleColor;
    final barBg = v.sheetBackground.withValues(alpha: 0.9);
    final barBorder = v.dividerColor;
    final chipSide = v.isDark ? null : BorderSide(color: v.cardBorder);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: barBg,
        border: Border(bottom: BorderSide(color: barBorder)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Text(
                'Filtros',
                style: Theme.of(context).textTheme.labelSmall!.copyWith(
                  color: sectionLabel,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              if (filters.hasAnyFilter)
                TextButton(
                  onPressed: () => onChanged(filters.clear()),
                  child: Text(
                    'Limpar',
                    style: TextStyle(color: accent, fontSize: 12),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: OccurrenceCategory.values.map((category) {
              final isSelected = filters.categories.contains(category);
              return FilterChip(
                selected: isSelected,
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(category.emoji, style: const TextStyle(fontSize: 14)),
                    const SizedBox(width: 4),
                    Text(
                      category.label,
                      style: TextStyle(
                        fontSize: 11,
                        color: isSelected ? selectedLabel : unselectedLabel,
                      ),
                    ),
                  ],
                ),
                selectedColor: accent,
                backgroundColor: chipBg,
                checkmarkColor: selectedLabel,
                side: chipSide,
                onSelected: (selected) {
                  final newCategories = Set<OccurrenceCategory>.from(
                    filters.categories,
                  );
                  if (selected) {
                    newCategories.add(category);
                  } else {
                    newCategories.remove(category);
                  }
                  onChanged(filters.copyWith(categories: newCategories));
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              FilterChip(
                selected: filters.statuses.contains('draft'),
                label: Text(
                  'Rascunho',
                  style: TextStyle(
                    fontSize: 11,
                    color: filters.statuses.contains('draft')
                        ? selectedLabel
                        : unselectedLabel,
                  ),
                ),
                selectedColor: Colors.orange,
                backgroundColor: chipBg,
                checkmarkColor: selectedLabel,
                side: chipSide,
                onSelected: (selected) {
                  final newStatuses = Set<String>.from(filters.statuses);
                  if (selected) {
                    newStatuses.add('draft');
                  } else {
                    newStatuses.remove('draft');
                  }
                  onChanged(filters.copyWith(statuses: newStatuses));
                },
              ),
              FilterChip(
                selected: filters.statuses.contains('confirmed'),
                label: Text(
                  'Confirmada',
                  style: TextStyle(
                    fontSize: 11,
                    color: filters.statuses.contains('confirmed')
                        ? selectedLabel
                        : unselectedLabel,
                  ),
                ),
                selectedColor: accent,
                backgroundColor: chipBg,
                checkmarkColor: selectedLabel,
                side: chipSide,
                onSelected: (selected) {
                  final newStatuses = Set<String>.from(filters.statuses);
                  if (selected) {
                    newStatuses.add('confirmed');
                  } else {
                    newStatuses.remove('confirmed');
                  }
                  onChanged(filters.copyWith(statuses: newStatuses));
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Andamento',
            style: Theme.of(context).textTheme.labelSmall!.copyWith(
              color: sectionLabel,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final step in OccurrenceAndamento.values)
                FilterChip(
                  selected: filters.andamentos.contains(step.storageValue),
                  label: Text(
                    step.label,
                    style: TextStyle(
                      fontSize: 11,
                      color: filters.andamentos.contains(step.storageValue)
                          ? selectedLabel
                          : unselectedLabel,
                    ),
                  ),
                  selectedColor: occurrenceAndamentoChipColor(step),
                  backgroundColor: chipBg,
                  checkmarkColor: selectedLabel,
                  side: chipSide,
                  onSelected: (selected) {
                    final next = Set<String>.from(filters.andamentos);
                    if (selected) {
                      next.add(step.storageValue);
                    } else {
                      next.remove(step.storageValue);
                    }
                    onChanged(filters.copyWith(andamentos: next));
                  },
                ),
            ],
          ),
          if (activeVisitId != null) ...[
            const SizedBox(height: 8),
            FilterChip(
              selected: filters.onlyActiveVisit,
              label: Text(
                'Somente desta visita',
                style: TextStyle(
                  fontSize: 11,
                  color: filters.onlyActiveVisit
                      ? selectedLabel
                      : unselectedLabel,
                ),
              ),
              selectedColor: accent,
              backgroundColor: chipBg,
              checkmarkColor: selectedLabel,
              side: chipSide,
              onSelected: (selected) {
                onChanged(filters.copyWith(onlyActiveVisit: selected));
              },
            ),
          ],
        ],
      ),
    );
  }
}
