import 'package:flutter/material.dart';
import 'package:soloforte_app/core/ui/sheets/sheet_tokens.dart';
import 'package:soloforte_app/core/ui/sheets/soloforte_sheet.dart';
import 'package:soloforte_app/ui/theme/premium/design_tokens.dart';

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
    final isIos = soloForteSheetIsIos(context);
    final accent = isIos
        ? SoloForteSheetSkinIos.iconStroke
        : PremiumTokens.brandGreen;
    final chipBg = isIos
        ? SoloForteSheetSkinIos.cardBackground
        : Colors.white;
    final selectedLabel = isIos
        ? SoloForteSheetSkinIos.ctaText
        : Colors.white;
    final unselectedLabel = isIos
        ? SoloForteSheetSkinIos.subtitleColor
        : context.premiumTextSecondary;
    final sectionLabel = isIos
        ? SoloForteSheetSkinIos.subtitleColor
        : context.premiumTextSecondary;
    final barBg = isIos
        ? SoloForteSheetSkinIos.background.withValues(alpha: 0.9)
        : context.premiumSurface.withValues(alpha: 0.5);
    final barBorder = isIos
        ? SoloForteSheetSkinIos.rowDivider
        : context.premiumHairline;

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
                side: isIos
                    ? const BorderSide(color: SoloForteSheetSkinIos.cardBorder)
                    : null,
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
                side: isIos
                    ? const BorderSide(color: SoloForteSheetSkinIos.cardBorder)
                    : null,
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
                side: isIos
                    ? const BorderSide(color: SoloForteSheetSkinIos.cardBorder)
                    : null,
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
              side: isIos
                  ? const BorderSide(color: SoloForteSheetSkinIos.cardBorder)
                  : null,
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
