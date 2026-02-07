import 'package:flutter/material.dart';
import 'package:soloforte_app/ui/theme/soloforte_theme.dart';
import '../../domain/occurrence.dart';

/// Filtros minimalistas para ocorrências
class OccurrenceFilters {
  final Set<OccurrenceCategory> categories;
  final Set<String> statuses; // 'draft', 'confirmed'
  final bool onlyActiveVisit;

  const OccurrenceFilters({
    this.categories = const {},
    this.statuses = const {},
    this.onlyActiveVisit = false,
  });

  bool get hasAnyFilter =>
      categories.isNotEmpty || statuses.isNotEmpty || onlyActiveVisit;

  OccurrenceFilters copyWith({
    Set<OccurrenceCategory>? categories,
    Set<String>? statuses,
    bool? onlyActiveVisit,
  }) {
    return OccurrenceFilters(
      categories: categories ?? this.categories,
      statuses: statuses ?? this.statuses,
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: SoloForteColors.grayLight.withValues(alpha: 0.5),
        border: Border(bottom: BorderSide(color: SoloForteColors.borderLight)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Text(
                'Filtros',
                style: SoloTextStyles.label.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              if (filters.hasAnyFilter)
                TextButton(
                  onPressed: () => onChanged(filters.clear()),
                  child: Text(
                    'Limpar',
                    style: TextStyle(
                      color: SoloForteColors.greenIOS,
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          // Categorias
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
                        color: isSelected
                            ? Colors.white
                            : SoloForteColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                selectedColor: SoloForteColors.greenIOS,
                backgroundColor: Colors.white,
                checkmarkColor: Colors.white,
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
          // Status
          Wrap(
            spacing: 8,
            children: [
              FilterChip(
                selected: filters.statuses.contains('draft'),
                label: const Text('Rascunho', style: TextStyle(fontSize: 11)),
                selectedColor: Colors.orange,
                backgroundColor: Colors.white,
                checkmarkColor: Colors.white,
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
                label: const Text('Confirmada', style: TextStyle(fontSize: 11)),
                selectedColor: SoloForteColors.greenIOS,
                backgroundColor: Colors.white,
                checkmarkColor: Colors.white,
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
          if (activeVisitId != null) ...[
            const SizedBox(height: 8),
            FilterChip(
              selected: filters.onlyActiveVisit,
              label: const Text(
                'Somente desta visita',
                style: TextStyle(fontSize: 11),
              ),
              selectedColor: SoloForteColors.brand,
              backgroundColor: Colors.white,
              checkmarkColor: Colors.white,
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
