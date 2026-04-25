import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:soloforte_app/ui/theme/premium/design_tokens.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../domain/occurrence.dart';
import '../../presentation/controllers/occurrence_controller.dart';
import 'package:soloforte_app/core/contracts/i_visit_session_lookup.dart';
import 'package:soloforte_app/core/contracts/i_visit_session_lookup_provider.dart';
import './occurrence_filters.dart';
import './occurrence_fenologia_data.dart';

final _activeVisitSessionProvider = FutureProvider.autoDispose<VisitSessionSummary?>(
  (ref) => ref.watch(visitSessionLookupProvider).getActiveSession(),
);

/// Bottom Sheet com lista de ocorrências filtrada por viewport
class OccurrenceListSheet extends ConsumerStatefulWidget {
  final LatLngBounds? mapBounds;
  final VoidCallback? onClose;
  final Function(Occurrence)? onOccurrenceTap;
  final VoidCallback? onRequestNewOccurrence;
  // R1+R2: parâmetros para uso encapsulado em DraggableScrollableSheet
  final ScrollController? scrollController;
  final bool showHandle;
  final bool showDecoration;

  const OccurrenceListSheet({
    super.key,
    this.mapBounds,
    this.onClose,
    this.onOccurrenceTap,
    this.onRequestNewOccurrence,
    this.scrollController,
    this.showHandle = true,
    this.showDecoration = true,
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
    final visitState = ref.watch(_activeVisitSessionProvider);
    final activeVisitId = visitState.value?.isActive == true
        ? visitState.value!.id
        : null;

    return Stack(
      children: [
        Container(
          decoration: widget.showDecoration
              ? BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16.0),
                    topRight: Radius.circular(16.0),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 20,
                      offset: const Offset(0, -5),
                    ),
                  ],
                )
              : null,
          child: Column(
            mainAxisSize:
                widget.showDecoration ? MainAxisSize.min : MainAxisSize.max,
            children: [
              // Drag handle — suprimido quando encapsulado em modal
              if (widget.showHandle) ...[  
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: PremiumTokens.surfaceLight,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Ocorrências',
                        style: Theme.of(context).textTheme.titleMedium!.copyWith(fontWeight: FontWeight.w600),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.close,
                        color: PremiumTokens.textSecondaryLight,
                      ),
                      onPressed: widget.onClose ?? () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: PremiumTokens.hairlineLight),
              // Filtros
              OccurrenceFilterSelector(
                filters: _filters,
                activeVisitId: activeVisitId,
                onChanged: (newFilters) {
                  setState(() => _filters = newFilters);
                },
              ),
              const Divider(height: 1, color: PremiumTokens.hairlineLight),
              // Lista
              Flexible(
                child: occurrencesAsync.when(
                  data: (allOccurrences) {
                    final inViewport = widget.mapBounds != null
                        ? allOccurrences.where((occ) {
                            final coords = occ.getCoordinates();
                            if (coords == null) return false;
                            final point = LatLng(
                              coords['lat']!,
                              coords['long']!,
                            );
                            return widget.mapBounds!.contains(point);
                          }).toList()
                        : allOccurrences;

                    // Aplicar filtros
                    final filtered = inViewport
                        .where(
                          (occ) => _filters.matches(
                            occ,
                            activeVisitId: activeVisitId,
                          ),
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
                              const Icon(
                                Icons.warning_amber_rounded,
                                size: 48,
                                color: PremiumTokens.textTertiaryLight,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _filters.hasAnyFilter
                                    ? 'Nenhuma ocorrência com os filtros ativos'
                                    : 'Nenhuma ocorrência nesta área',
                                style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                                  color: PremiumTokens.textSecondaryLight,
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
                      controller: widget.scrollController,
                      shrinkWrap: widget.scrollController == null,
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
                        color: PremiumTokens.brandGreen,
                      ),
                    ),
                  ),
                  error: (err, stack) => const Center(
                    child: Padding(
                      padding: EdgeInsets.all(40),
                      child: Text(
                        'Erro ao carregar ocorrências',
                        style: TextStyle(color: Color(0xFFFF3B30)),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
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

  // ── Helpers ──────────────────────────────────────────────────

  Color _catColor(OccurrenceCategory cat) {
    return cat.markerColor;
  }

  IconData _catIcon(OccurrenceCategory cat) {
    switch (cat) {
      case OccurrenceCategory.doenca:
        return Icons.coronavirus_outlined;
      case OccurrenceCategory.insetos:
        return Icons.bug_report_outlined;
      case OccurrenceCategory.daninhas:
        return Icons.grass_outlined;
      case OccurrenceCategory.nutricional:
        return Icons.science_outlined;
      case OccurrenceCategory.agua:
        return Icons.water_drop_outlined;
    }
  }

  List<OccurrenceCategory> _activeCategories() {
    if (occurrence.categoriasJson != null) {
      try {
        final list = jsonDecode(occurrence.categoriasJson!) as List;
        return list
            .map((s) => OccurrenceCategory.fromString(s as String))
            .toList();
      } catch (_) {}
    }
    if (occurrence.category != null) {
      return [OccurrenceCategory.fromString(occurrence.category)];
    }
    return [];
  }

  String? _firstMetricLabel() {
    if (occurrence.metricasJson == null) return null;
    try {
      final map =
          jsonDecode(occurrence.metricasJson!) as Map<String, dynamic>;
      for (final catEntry in map.entries) {
        final metrics = catEntry.value as Map<String, dynamic>;
        for (final m in metrics.entries) {
          final v = m.value as int;
          if (v > 0) {
            return '${_metricDisplayName(m.key)}: ${kSliderLabels[v.clamp(0, 3)]}';
          }
        }
      }
    } catch (_) {}
    return null;
  }

  String _metricDisplayName(String key) {
    switch (key) {
      case 'incidencia': return 'Incidência';
      case 'severidade': return 'Severidade';
      case 'desfolha': return 'Desfolha';
      case 'infestacao': return 'Infestação';
      case 'acamamento': return 'Acamamento';
      case 'status': return 'Status Hídrico';
      default: return key;
    }
  }

  Color _syncColor() {
    switch (occurrence.syncStatus) {
      case 'synced': return const Color(0xFF34C759);
      case 'updated': return const Color(0xFF30B0C7);
      case 'deleted': return const Color(0xFFFF3B30);
      default: return const Color(0xFFFF9500); // local
    }
  }

  String _syncLabel() {
    switch (occurrence.syncStatus) {
      case 'synced': return 'Sincronizado';
      case 'updated': return 'Atualizado';
      case 'deleted': return 'Excluído';
      default: return 'Local';
    }
  }

  String _formatDate(DateTime date) {
    final d = date.day.toString().padLeft(2, '0');
    final mo = date.month.toString().padLeft(2, '0');
    final h = date.hour.toString().padLeft(2, '0');
    final mi = date.minute.toString().padLeft(2, '0');
    return '$d/$mo/${date.year} $h:$mi';
  }

  @override
  Widget build(BuildContext context) {
    final cats = _activeCategories();
    final primaryCat = cats.isNotEmpty
        ? cats.first
        : OccurrenceCategory.fromString(occurrence.category);
    final color = _catColor(primaryCat);
    final isDraft = occurrence.status == 'draft';
    final isFromVisit = occurrence.visitSessionId == activeVisitId &&
        activeVisitId != null;
    final firstMetric = _firstMetricLabel();
    final syncColor = _syncColor();
    final hasPhoto = occurrence.photoPath != null &&
        occurrence.photoPath!.isNotEmpty;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isSelected
              ? color.withOpacity(.08)
              : const Color(0xFF1C1C1E),
          border: Border.all(
            color: isSelected ? color : Colors.white12,
            width: isSelected ? 1.5 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Thumbnail ou ícone ──────────────────────────────────
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                bottomLeft: Radius.circular(12),
              ),
              child: hasPhoto
                  ? Image.file(
                      File(occurrence.photoPath!),
                      width: 60,
                      height: 80,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _CategoryIcon(
                        cat: primaryCat,
                        color: color,
                        icon: _catIcon(primaryCat),
                      ),
                    )
                  : _CategoryIcon(
                      cat: primaryCat,
                      color: color,
                      icon: _catIcon(primaryCat),
                    ),
            ),
            const SizedBox(width: 10),

            // ── Conteúdo ─────────────────────────────────────────
            Expanded(
              child: Padding(
                padding:
                    const EdgeInsets.fromLTRB(0, 10, 10, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Linha 1: categorias + badges
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            cats.map((c) => c.label).join(' + '),
                            style: TextStyle(
                              color: color,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isDraft)
                          const _MiniChip(
                            label: 'Rascunho',
                            color: Color(0xFFFF9500),
                          ),
                      ],
                    ),

                    // Linha 2: estádio + cultivar
                    if (occurrence.estadioFenologico != null ||
                        occurrence.cultivar != null) ...
                      [
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            if (occurrence.estadioFenologico != null)
                              _MiniChip(
                                label:
                                    'Estádio ${occurrence.estadioFenologico}',
                                color:
                                    PremiumTokens.brandGreen,
                              ),
                            if (occurrence.cultivar != null) ...
                              [
                                const SizedBox(width: 4),
                                Text(
                                  occurrence.cultivar!,
                                  style: const TextStyle(
                                    color: Colors.white54,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                          ],
                        ),
                      ],

                    // Linha 3: description
                    if (occurrence.description.isNotEmpty) ...
                      [
                        const SizedBox(height: 4),
                        Text(
                          occurrence.description,
                          style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 12),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],

                    // Linha 4: primeira métrica
                    if (firstMetric != null) ...
                      [
                        const SizedBox(height: 4),
                        Text(
                          firstMetric,
                          style: TextStyle(
                            color: color.withOpacity(.8),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],

                    // Linha 5: data + badges
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        if (isFromVisit)
                          const _MiniChip(
                            label: '✓ Em Visita',
                            color: PremiumTokens.brandGreen,
                          ),
                        const Spacer(),
                        // Sync badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(
                            color: syncColor.withOpacity(.15),
                            borderRadius:
                                BorderRadius.circular(4),
                          ),
                          child: Text(
                            _syncLabel(),
                            style: TextStyle(
                              color: syncColor,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _formatDate(occurrence.createdAt),
                          style: const TextStyle(
                              color: Colors.white24,
                              fontSize: 10),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Widgets auxiliares do card ──────────────────────────────────────────────────

class _CategoryIcon extends StatelessWidget {
  final OccurrenceCategory cat;
  final Color color;
  final IconData icon;
  const _CategoryIcon({
    required this.cat,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) => Container(
        width: 60,
        height: 80,
        color: const Color(0xFF1C1C1E),
        child: Center(
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 22,
            ),
          ),
        ),
      );
}

class _MiniChip extends StatelessWidget {
  final String label;
  final Color color;
  const _MiniChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: color.withOpacity(.15),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 9,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
}
