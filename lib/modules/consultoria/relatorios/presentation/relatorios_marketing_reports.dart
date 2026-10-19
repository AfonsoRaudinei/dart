part of 'relatorios_page.dart';

class _MarketingCasesReportsSection extends ConsumerStatefulWidget {
  final DateFormat dateFormat;
  final String? selectedProducerClientId;
  final ValueChanged<String> onProducerSelected;

  const _MarketingCasesReportsSection({
    required this.dateFormat,
    required this.selectedProducerClientId,
    required this.onProducerSelected,
  });

  @override
  ConsumerState<_MarketingCasesReportsSection> createState() =>
      _MarketingCasesReportsSectionState();
}

enum _MarketingCaseFilter { all, resultado, antesDepois, avaliacao }

enum _MarketingCaseStatusFilter { all, published, draft }

HtmlReportViewerActions _marketingReportViewerActions(
  ProviderContainer container,
  MarketingCaseReportSnapshot item,
) {
  final lookup = container.read(marketingCaseReportsLookupProvider);
  final lat = item.lat;
  final lng = item.lng;
  final hasLocation =
      lat.isFinite && lng.isFinite && !(lat == 0 && lng == 0);
  final isDraft = item.statusValue.toLowerCase() == 'draft';

  return HtmlReportViewerActions(
    onEdit: (viewerContext) async {
      Navigator.of(viewerContext).pop();
      await lookup.showEditSheet(viewerContext, item.id);
    },
    onViewLocation: hasLocation
        ? (viewerContext) async {
            Navigator.of(viewerContext).pop();
            viewerContext.go(
              '${AppRoutes.map}?modo=foco&lat=${lat.toStringAsFixed(6)}'
              '&lng=${lng.toStringAsFixed(6)}',
            );
          }
        : null,
    onPublish: isDraft
        ? (viewerContext) async {
            final published =
                await lookup.publishDraftCase(viewerContext, item.id);
            if (published && viewerContext.mounted) {
              ScaffoldMessenger.of(viewerContext).showSnackBar(
                const SnackBar(content: Text('Case publicado com sucesso!')),
              );
            }
            return published;
          }
        : null,
    publishDialogTitle: 'Publicar case?',
    publishDialogMessage: 'O case será publicado no mapa conforme seu plano.',
    onDelete: (viewerContext) async {
      await lookup.deleteCase(item.id);
      return true;
    },
    deleteDialogTitle: 'Excluir publicação?',
    deleteDialogMessage:
        'A publicação será removida da lista e marcada para sincronização.',
  );
}

class _MarketingCasesReportsSectionState
    extends ConsumerState<_MarketingCasesReportsSection> {
  // Marketing card share API (BUG-007): showPackShare: false

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
        title: 'Marketing',
        onRetry: () => ref.invalidate(marketingCaseReportsListProvider),
      );
    }

    final occurrencesAsync = ref.watch(occurrencesListProvider);
    if (occurrencesAsync.isLoading && !occurrencesAsync.hasValue) {
      return const _SectionLoading(title: 'Marketing');
    }
    if (occurrencesAsync.hasError && !occurrencesAsync.hasValue) {
      return _SectionError(
        title: 'Marketing',
        onRetry: () => ref.invalidate(occurrencesListProvider),
      );
    }
    final allOccurrences = occurrencesAsync.valueOrNull ?? const <Occurrence>[];

    return casesAsync.when(
      data: (visible) {
        final producerCounts = _producerCountsFromIds([
          ...visible.map((c) => c.clientId),
          ...allOccurrences.map((o) => o.clientId),
        ]);
        final producerIds = producerCounts.keys.toList()..sort();
        final effectiveClientId = resolveRelatoriosProducerClientId(
          selectedClientId: widget.selectedProducerClientId,
          routeClientId: _relatoriosRouteClienteId(context),
          producerIds: producerIds,
        );
        final needsProducerPick =
            producerIds.length > 1 && effectiveClientId == null;
        final byProducer = producerIds.isEmpty
            ? visible
            : needsProducerPick
            ? const <MarketingCaseReportSnapshot>[]
            : visible
                .where((item) => item.clientId == effectiveClientId)
                .toList();
        final statusFiltered = _applyStatusFilter(byProducer);
        final filtered = _applyTypeFilter(statusFiltered);
        final grouped = _groupByFarm(filtered);
        final clientOccurrences = effectiveClientId == null
            ? const <Occurrence>[]
            : _sortOccurrencesByCreatedAt(
                allOccurrences
                    .where((o) => o.clientId == effectiveClientId)
                    .toList(),
              );
        final showClientHub =
            !needsProducerPick && effectiveClientId != null;
        final totalHubItems = clientOccurrences.length + filtered.length;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _InsetGroupHeader(
              title: showClientHub ? 'Relatórios do produtor' : 'Marketing',
              count: showClientHub ? totalHubItems : filtered.length,
            ),
            _relatoriosProducerSelectorBlock(
              context: context,
              producerIds: producerIds,
              itemCounts: producerCounts,
              effectiveClientId: effectiveClientId,
              onSelected: widget.onProducerSelected,
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
            if (visible.isEmpty && allOccurrences.isEmpty)
              _PremiumEmptyState(
                message:
                    'Nenhuma publicação ainda. Crie um case de marketing no mapa (toque longo).',
                ctaLabel: 'Abrir mapa',
                onCta: () => context.go(AppRoutes.map),
              )
            else if (needsProducerPick)
              _PremiumEmptyState(
                message:
                    'Selecione um produtor para ver os relatórios deste cliente.',
              )
            else if (showClientHub && effectiveClientId != null) ...[
              if (clientOccurrences.isEmpty &&
                  filtered.isEmpty &&
                  byProducer.isNotEmpty)
                _PremiumEmptyState(
                  message: 'Nenhuma publicação neste filtro.',
                  ctaLabel: 'Mostrar todas',
                  onCta: () {
                    _selectFilter(_MarketingCaseFilter.all);
                    _selectStatusFilter(_MarketingCaseStatusFilter.all);
                  },
                )
              else
                ..._buildProducerReportHub(
                  context: context,
                  ref: ref,
                  dateFormat: dateFormat,
                  effectiveClientId: effectiveClientId,
                  occurrences: clientOccurrences,
                  marketingItems: filtered,
                ),
            ]
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
                    (item) => _marketingReportCard(
                      context,
                      ref,
                      dateFormat,
                      item,
                    ),
                  ),
                ];
              }),
          ],
        );
      },
      loading: () => const _SectionLoading(title: 'Marketing'),
      error: (e, st) {
        AppLogger.error(
          'marketingCaseReportsListProvider ERROR',
          tag: 'RelatoriosScreen',
          error: e,
          stackTrace: st,
        );
        return _SectionError(
          title: 'Marketing',
          onRetry: () => ref.invalidate(marketingCaseReportsListProvider),
        );
      },
    );
  }
}

Widget _marketingReportCard(
  BuildContext context,
  WidgetRef ref,
  DateFormat dateFormat,
  MarketingCaseReportSnapshot item,
) {
  final tipoColor = _relatoriosMarketingTipoColor(item.tipo);
  return _GeneratedReportCard(
    leading: _relatoriosReportIconBadge(
      icon: _relatoriosMarketingTipoIcon(item.tipo),
      accent: tipoColor,
    ),
    eyebrow: _relatoriosMarketingTipoSectionTitle(item.tipo),
    title: item.produtorFazenda,
    subtitle: _marketingStatusLabel(item.statusValue),
    date: dateFormat.format(item.criadoEm.toLocal()),
    enabled: true,
    statusLabel: _marketingStatusLabel(item.statusValue),
    statusColor: _marketingStatusColor(item.statusValue),
    buildPayload: () => _buildMarketingPayload(ref, item),
    viewerActions: _marketingReportViewerActions(
      ProviderScope.containerOf(context, listen: false),
      item,
    ),
  );
}

List<Widget> _buildProducerReportHub({
  required BuildContext context,
  required WidgetRef ref,
  required DateFormat dateFormat,
  required String effectiveClientId,
  required List<Occurrence> occurrences,
  required List<MarketingCaseReportSnapshot> marketingItems,
}) {
  final widgets = <Widget>[];
  final nowLabel = dateFormat.format(DateTime.now());

  if (occurrences.isEmpty && marketingItems.isEmpty) {
    widgets.add(
      const _PremiumEmptyState(
        message: 'Nenhum relatório para este produtor ainda.',
      ),
    );
    return widgets;
  }

  if (occurrences.isNotEmpty) {
    widgets.add(
      _RelatoriosSectionLabel(
        icon: SFIcons.assignment,
        iconColor: const Color(0xFF2C5564),
        title: 'Ocorrências',
        count: occurrences.length,
      ),
    );
    widgets.add(
      _GeneratedReportCard(
        leading: _relatoriosReportIconBadge(
          icon: SFIcons.assignment,
          accent: const Color(0xFF2C5564),
        ),
        eyebrow: 'Exportar lista',
        title: 'Lista de Ocorrências',
        subtitle: '${occurrences.length} ocorrência(s)',
        date: nowLabel,
        enabled: true,
        buildPayload: () => _buildOccurrenceListPayload(
          ref,
          occurrences,
          effectiveClientId,
        ),
      ),
    );
    widgets.addAll(
      occurrences.map(
        (occurrence) => _OccurrenciaCard(
          occurrence: occurrence,
          dateFormat: dateFormat,
        ),
      ),
    );
  }

  const tipos = ['resultado', 'antes_depois', 'avaliacao'];
  for (final tipo in tipos) {
    final items = marketingItems.where((item) => item.tipo == tipo).toList();
    if (items.isEmpty) continue;
    final color = _relatoriosMarketingTipoColor(tipo);
    widgets.add(
      _RelatoriosSectionLabel(
        icon: _relatoriosMarketingTipoIcon(tipo),
        iconColor: color,
        title: _relatoriosMarketingTipoSectionTitle(tipo),
        count: items.length,
      ),
    );
    widgets.addAll(
      items.map((item) => _marketingReportCard(context, ref, dateFormat, item)),
    );
  }

  return widgets;
}

String _marketingStatusLabel(String statusValue) {
  switch (statusValue.toLowerCase()) {
    case 'published':
      return 'Marketing';
    case 'draft':
      return 'Não gerado';
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
        _statusChip(
          context,
          'Todas',
          _MarketingCaseStatusFilter.all,
          SFIcons.layers,
        ),
        _statusChip(
          context,
          'Marketing',
          _MarketingCaseStatusFilter.published,
          SFIcons.campaign,
        ),
        _statusChip(
          context,
          'Não gerados',
          _MarketingCaseStatusFilter.draft,
          SFIcons.edit,
        ),
      ],
    );
  }

  Widget _statusChip(
    BuildContext context,
    String label,
    _MarketingCaseStatusFilter value,
    IconData icon,
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
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.white : context.premiumTextSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : context.premiumTextPrimary,
              ),
            ),
          ],
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
        _filterChip(
          context,
          'Todas',
          _MarketingCaseFilter.all,
          SFIcons.layers,
        ),
        _filterChip(
          context,
          'Resultado',
          _MarketingCaseFilter.resultado,
          SFIcons.trendingUp,
        ),
        _filterChip(
          context,
          'Lado a lado',
          _MarketingCaseFilter.antesDepois,
          SFIcons.compareArrows,
        ),
        _filterChip(
          context,
          'Avaliação',
          _MarketingCaseFilter.avaliacao,
          SFIcons.starOutline,
        ),
      ],
    );
  }

  Widget _filterChip(
    BuildContext context,
    String label,
    _MarketingCaseFilter value,
    IconData icon,
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
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.white : context.premiumTextSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : context.premiumTextPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
