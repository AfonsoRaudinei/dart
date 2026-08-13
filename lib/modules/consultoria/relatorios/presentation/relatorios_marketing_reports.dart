part of 'relatorios_page.dart';

class _MarketingCasesReportsSection extends ConsumerStatefulWidget {
  final DateFormat dateFormat;

  const _MarketingCasesReportsSection({required this.dateFormat});

  @override
  ConsumerState<_MarketingCasesReportsSection> createState() =>
      _MarketingCasesReportsSectionState();
}

enum _MarketingCaseFilter { all, resultado, antesDepois, avaliacao }

enum _MarketingCaseStatusFilter { all, published, draft }

class _MarketingCasesReportsSectionState
    extends ConsumerState<_MarketingCasesReportsSection> {
  _MarketingCaseFilter _filter = _MarketingCaseFilter.all;
  _MarketingCaseStatusFilter _statusFilter = _MarketingCaseStatusFilter.all;

  void _selectFilter(_MarketingCaseFilter value) {
    if (_filter == value) return;
    setState(() => _filter = value);
  }

  void _selectStatusFilter(_MarketingCaseStatusFilter value) {
    if (_statusFilter == value) return;
    setState(() => _statusFilter = value);
  }

  List<MarketingCaseReportSnapshot> _applyStatusFilter(
    List<MarketingCaseReportSnapshot> cases,
  ) {
    switch (_statusFilter) {
      case _MarketingCaseStatusFilter.published:
        return cases
            .where((item) => item.statusValue.toLowerCase() == 'published')
            .toList();
      case _MarketingCaseStatusFilter.draft:
        return cases
            .where((item) => item.statusValue.toLowerCase() == 'draft')
            .toList();
      case _MarketingCaseStatusFilter.all:
        return cases;
    }
  }

  List<MarketingCaseReportSnapshot> _applyTypeFilter(
    List<MarketingCaseReportSnapshot> cases,
  ) {
    switch (_filter) {
      case _MarketingCaseFilter.resultado:
        return cases.where((item) => item.tipo == 'resultado').toList();
      case _MarketingCaseFilter.antesDepois:
        return cases.where((item) => item.tipo == 'antes_depois').toList();
      case _MarketingCaseFilter.avaliacao:
        return cases.where((item) => item.tipo == 'avaliacao').toList();
      case _MarketingCaseFilter.all:
        return cases;
    }
  }

  Map<String, List<MarketingCaseReportSnapshot>> _groupByFarm(
    List<MarketingCaseReportSnapshot> cases,
  ) {
    final map = <String, List<MarketingCaseReportSnapshot>>{};
    for (final item in cases) {
      final key = item.produtorFazenda.trim().isEmpty
          ? 'Sem fazenda'
          : item.produtorFazenda.trim();
      map.putIfAbsent(key, () => []).add(item);
    }
    final keys = map.keys.toList()..sort();
    return {for (final key in keys) key: map[key]!};
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    MarketingCaseReportSnapshot item,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Excluir publicação?'),
        content: const Text(
          'A publicação será removida da lista e marcada para sincronização.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(marketingCaseReportsLookupProvider).deleteCase(item.id);
  }

  Future<void> _publishDraft(
    BuildContext context,
    WidgetRef ref,
    MarketingCaseReportSnapshot item,
  ) async {
    final published = await ref
        .read(marketingCaseReportsLookupProvider)
        .publishDraftCase(context, item.id);
    if (!context.mounted || !published) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Case publicado com sucesso!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = widget.dateFormat;
    late final AsyncValue<List<MarketingCaseReportSnapshot>> casesAsync;
    try {
      casesAsync = ref.watch(marketingCaseReportsListProvider);
    } catch (e, st) {
      AppLogger.error(
        'marketingCaseReportsListProvider falhou na criação',
        tag: 'RelatoriosScreen',
        error: e,
        stackTrace: st,
      );
      return _SectionError(
        title: 'Publicações',
        onRetry: () => ref.invalidate(marketingCaseReportsListProvider),
      );
    }

    return casesAsync.when(
      data: (visible) {
        final statusFiltered = _applyStatusFilter(visible);
        final filtered = _applyTypeFilter(statusFiltered);
        final grouped = _groupByFarm(filtered);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _InsetGroupHeader(
              title: 'Publicações',
              count: filtered.length,
            ),
            if (visible.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
                child: _MarketingCaseStatusFilterBar(
                  selected: _statusFilter,
                  onSelected: _selectStatusFilter,
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 0, 4, 12),
                child: _MarketingCaseFilterBar(
                  selected: _filter,
                  onSelected: _selectFilter,
                ),
              ),
            ],
            if (visible.isEmpty)
              _PremiumEmptyState(
                message:
                    'Nenhuma publicação ainda. Crie um case de marketing no mapa (toque longo).',
                ctaLabel: 'Abrir mapa',
                onCta: () => context.go(AppRoutes.map),
              )
            else if (filtered.isEmpty)
              _PremiumEmptyState(
                message: 'Nenhuma publicação neste filtro.',
                ctaLabel: 'Mostrar todas',
                onCta: () {
                  _selectFilter(_MarketingCaseFilter.all);
                  _selectStatusFilter(_MarketingCaseStatusFilter.all);
                },
              )
            else
              ...grouped.entries.expand((entry) {
                final farmKey = entry.key;
                final items = entry.value;
                return <Widget>[
                  if (grouped.length > 1)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(4, 4, 4, 8),
                      child: Text(
                        '$farmKey · ${items.length} disponível(is)',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: context.premiumTextSecondary,
                        ),
                      ),
                    ),
                  ...items.map(
                    (item) => _GeneratedReportCard(
                      eyebrow: 'Marketing',
                      title: item.produtorFazenda,
                      subtitle:
                          '${item.tipoLabel} • ${_marketingStatusLabel(item.statusValue)}',
                      date: dateFormat.format(item.criadoEm.toLocal()),
                      enabled: true,
                      statusLabel: _marketingStatusLabel(item.statusValue),
                      statusColor: _marketingStatusColor(item.statusValue),
                      menuTooltip: 'Ações da publicação',
                      buildPayload: () => _buildMarketingPayload(ref, item),
                      onEdit: () => ref
                          .read(marketingCaseReportsLookupProvider)
                          .showEditSheet(context, item.id),
                      onPublish: item.statusValue.toLowerCase() == 'draft'
                          ? () => _publishDraft(context, ref, item)
                          : null,
                      onViewLocation: () {
                        final lat = item.lat;
                        final lng = item.lng;
                        if (!lat.isFinite ||
                            !lng.isFinite ||
                            (lat == 0 && lng == 0)) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Coordenadas da mídia inválidas.'),
                            ),
                          );
                          return;
                        }
                        context.go(
                          '${AppRoutes.map}?modo=foco&lat=${lat.toStringAsFixed(6)}'
                          '&lng=${lng.toStringAsFixed(6)}&caseId=${Uri.encodeComponent(item.id)}',
                        );
                      },
                      onDelete: () => _confirmDelete(context, ref, item),
                    ),
                  ),
                ];
              }),
          ],
        );
      },
      loading: () => const _SectionLoading(title: 'Publicações'),
      error: (e, st) {
        AppLogger.error(
          'marketingCaseReportsListProvider ERROR',
          tag: 'RelatoriosScreen',
          error: e,
          stackTrace: st,
        );
        return _SectionError(
          title: 'Publicações',
          onRetry: () => ref.invalidate(marketingCaseReportsListProvider),
        );
      },
    );
  }
}

String _marketingStatusLabel(String statusValue) {
  switch (statusValue.toLowerCase()) {
    case 'published':
      return 'Disponível';
    case 'draft':
      return 'Rascunho';
    case 'pending_sync':
      return 'Pendente sync';
    case 'archived':
      return 'Arquivado';
    default:
      return statusValue;
  }
}

Color _marketingStatusColor(String statusValue) {
  switch (statusValue.toLowerCase()) {
    case 'published':
      return PremiumTokens.brandGreen;
    case 'draft':
      return const Color(0xFFFF9500);
    case 'pending_sync':
      return const Color(0xFF007AFF);
    case 'archived':
      return Colors.grey;
    default:
      return PremiumTokens.brandGreen;
  }
}

class _MarketingCaseStatusFilterBar extends StatelessWidget {
  final _MarketingCaseStatusFilter selected;
  final ValueChanged<_MarketingCaseStatusFilter> onSelected;

  const _MarketingCaseStatusFilterBar({
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 6,
      children: [
        _statusChip(context, 'Todas', _MarketingCaseStatusFilter.all),
        _statusChip(context, 'Publicados', _MarketingCaseStatusFilter.published),
        _statusChip(context, 'Rascunhos', _MarketingCaseStatusFilter.draft),
      ],
    );
  }

  Widget _statusChip(
    BuildContext context,
    String label,
    _MarketingCaseStatusFilter value,
  ) {
    final isSelected = selected == value;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onSelected(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFF9500) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? const Color(0xFFFF9500)
                : const Color(0xFFD1D1D6),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : context.premiumTextPrimary,
          ),
        ),
      ),
    );
  }
}

class _MarketingCaseFilterBar extends StatelessWidget {
  final _MarketingCaseFilter selected;
  final ValueChanged<_MarketingCaseFilter> onSelected;

  const _MarketingCaseFilterBar({
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 6,
      children: [
        _filterChip(context, 'Todas', _MarketingCaseFilter.all),
        _filterChip(context, 'Resultado', _MarketingCaseFilter.resultado),
        _filterChip(context, 'Antes/Depois', _MarketingCaseFilter.antesDepois),
        _filterChip(context, 'Avaliação', _MarketingCaseFilter.avaliacao),
      ],
    );
  }

  Widget _filterChip(
    BuildContext context,
    String label,
    _MarketingCaseFilter value,
  ) {
    final isSelected = selected == value;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onSelected(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? PremiumTokens.brandGreen : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? PremiumTokens.brandGreen
                : const Color(0xFFD1D1D6),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : context.premiumTextPrimary,
          ),
        ),
      ),
    );
  }
}
