import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:soloforte_app/ui/theme/soloforte_theme.dart';
import '../../domain/occurrence.dart';
import '../../presentation/controllers/occurrence_controller.dart';
import '../../../../visitas/presentation/controllers/visit_controller.dart';
import './occurrence_filters.dart';

/// Bottom Sheet com lista de ocorrências filtrada por viewport
class OccurrenceListSheet extends ConsumerStatefulWidget {
  final LatLngBounds? mapBounds;
  final VoidCallback? onClose;
  final Function(Occurrence)? onOccurrenceTap;

  const OccurrenceListSheet({
    super.key,
    this.mapBounds,
    this.onClose,
    this.onOccurrenceTap,
  });

  @override
  ConsumerState<OccurrenceListSheet> createState() =>
      _OccurrenceListSheetState();
}

class _OccurrenceListSheetState extends ConsumerState<OccurrenceListSheet> {
  OccurrenceFilters _filters = const OccurrenceFilters();
  Occurrence? _selectedOccurrence;

  @override
  Widget build(BuildContext context) {
    final occurrencesAsync = ref.watch(occurrencesListProvider);
    final visitState = ref.watch(visitControllerProvider);
    final activeVisitId = visitState.value?.status == 'active'
        ? visitState.value!.id
        : null;

    return Container(
      decoration: BoxDecoration(
        color: SoloForteColors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(SoloRadius.lg),
          topRight: Radius.circular(SoloRadius.lg),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: SoloForteColors.grayLight,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Ocorrências',
                    style: SoloTextStyles.headingMedium,
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.close,
                    color: SoloForteColors.textSecondary,
                  ),
                  onPressed: widget.onClose ?? () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: SoloForteColors.borderLight),
          // Filtros
          OccurrenceFilterSelector(
            filters: _filters,
            activeVisitId: activeVisitId,
            onChanged: (newFilters) {
              setState(() => _filters = newFilters);
            },
          ),
          const Divider(height: 1, color: SoloForteColors.borderLight),
          // Lista
          Flexible(
            child: occurrencesAsync.when(
              data: (allOccurrences) {
                // Filtrar por viewport
                final inViewport = widget.mapBounds != null
                    ? allOccurrences.where((occ) {
                        if (occ.lat == null || occ.long == null) return false;
                        final point = LatLng(occ.lat!, occ.long!);
                        return widget.mapBounds!.contains(point);
                      }).toList()
                    : allOccurrences;

                // Aplicar filtros
                final filtered = inViewport
                    .where(
                      (occ) =>
                          _filters.matches(occ, activeVisitId: activeVisitId),
                    )
                    .toList();

                // Ordenar: visita ativa primeiro, depois mais recentes
                filtered.sort((a, b) {
                  // Primeiro: ocorrências da visita ativa
                  if (activeVisitId != null) {
                    final aInVisit = a.visitSessionId == activeVisitId;
                    final bInVisit = b.visitSessionId == activeVisitId;
                    if (aInVisit && !bInVisit) return -1;
                    if (!aInVisit && bInVisit) return 1;
                  }
                  // Depois: mais recentes primeiro
                  return b.createdAt.compareTo(a.createdAt);
                });

                if (filtered.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(40),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.warning_amber_rounded,
                            size: 48,
                            color: SoloForteColors.textTertiary,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _filters.hasAnyFilter
                                ? 'Nenhuma ocorrência com os filtros ativos'
                                : 'Nenhuma ocorrência nesta área',
                            style: SoloTextStyles.body.copyWith(
                              color: SoloForteColors.textSecondary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          if (_filters.hasAnyFilter) ...[
                            const SizedBox(height: 12),
                            TextButton(
                              onPressed: () {
                                setState(() => _filters = _filters.clear());
                              },
                              child: const Text('Limpar filtros'),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final occ = filtered[index];
                    final isSelected = _selectedOccurrence?.id == occ.id;
                    return _OccurrenceListItem(
                      occurrence: occ,
                      isSelected: isSelected,
                      activeVisitId: activeVisitId,
                      onTap: () {
                        if (isSelected) {
                          // Segundo tap: notificar para abrir editor
                          widget.onOccurrenceTap?.call(occ);
                        } else {
                          // Primeiro tap: marcar como selecionado
                          setState(() => _selectedOccurrence = occ);
                          // Notificar para centralizar no mapa
                          widget.onOccurrenceTap?.call(occ);
                        }
                      },
                    );
                  },
                );
              },
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: CircularProgressIndicator(
                    color: SoloForteColors.greenIOS,
                  ),
                ),
              ),
              error: (err, stack) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(40),
                  child: Text(
                    'Erro ao carregar ocorrências',
                    style: TextStyle(color: SoloForteColors.error),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OccurrenceListItem extends StatelessWidget {
  final Occurrence occurrence;
  final bool isSelected;
  final String? activeVisitId;
  final VoidCallback onTap;

  const _OccurrenceListItem({
    required this.occurrence,
    required this.isSelected,
    required this.onTap,
    this.activeVisitId,
  });

  Color _getCategoryColor() {
    final category = OccurrenceCategory.fromString(occurrence.category);
    switch (category) {
      case OccurrenceCategory.doenca:
        return Colors.blue.shade700;
      case OccurrenceCategory.insetos:
        return Colors.red.shade700;
      case OccurrenceCategory.daninhas:
        return Colors.orange.shade700;
      case OccurrenceCategory.nutricional:
        return Colors.grey.shade600;
      case OccurrenceCategory.agua:
        return Colors.cyan.shade700;
    }
  }

  @override
  Widget build(BuildContext context) {
    final category = OccurrenceCategory.fromString(occurrence.category);
    final color = _getCategoryColor();
    final isDraft = occurrence.status == 'draft';
    final isFromVisit = occurrence.visitSessionId == activeVisitId;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? SoloForteColors.greenIOS.withValues(alpha: 0.1)
              : SoloForteColors.grayLight,
          border: Border.all(
            color: isSelected
                ? SoloForteColors.greenIOS
                : SoloForteColors.borderLight,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(SoloRadius.md),
        ),
        child: Row(
          children: [
            // Ícone da categoria
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  category.emoji,
                  style: const TextStyle(fontSize: 24),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Conteúdo
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          category.label,
                          style: SoloTextStyles.headingMedium.copyWith(
                            fontSize: 14,
                            color: color,
                          ),
                        ),
                      ),
                      if (isDraft)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Rascunho',
                            style: TextStyle(
                              color: Colors.orange.shade700,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    occurrence.description.length > 60
                        ? '${occurrence.description.substring(0, 60)}...'
                        : occurrence.description,
                    style: SoloTextStyles.body.copyWith(fontSize: 12),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (isFromVisit)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: SoloForteColors.greenIOS.withValues(
                              alpha: 0.1,
                            ),
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.check_circle,
                                size: 10,
                                color: SoloForteColors.greenIOS,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                'Em Visita',
                                style: TextStyle(
                                  color: SoloForteColors.greenIOS,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      const Spacer(),
                      Text(
                        _formatDate(occurrence.createdAt),
                        style: SoloTextStyles.label,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              isSelected ? Icons.open_in_new : Icons.chevron_right,
              color: SoloForteColors.textSecondary,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 60) return 'Há ${diff.inMinutes}min';
    if (diff.inHours < 24) return 'Há ${diff.inHours}h';
    if (diff.inDays < 7) return 'Há ${diff.inDays}d';
    return '${date.day}/${date.month}';
  }
}
