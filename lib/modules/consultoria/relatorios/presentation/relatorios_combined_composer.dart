part of 'relatorios_page.dart';

class _CombinedReportEvent {
  final String key;
  final String kind;
  final DateTime occurredAt;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accent;
  final Future<String> Function(WidgetRef ref) buildFragment;

  const _CombinedReportEvent({
    required this.key,
    required this.kind,
    required this.occurredAt,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accent,
    required this.buildFragment,
  });
}

List<_CombinedReportEvent> _combinedEventsForProducer({
  required List<RelatorioTecnico> visits,
  required List<Occurrence> occurrences,
  required List<MarketingCaseReportSnapshot> marketing,
}) {
  final events = <_CombinedReportEvent>[
    for (final report in visits)
      _CombinedReportEvent(
        key: 'visita:${report.id}',
        kind: 'visita',
        occurredAt: report.periodStart,
        title: (report.title?.trim().isNotEmpty == true)
            ? report.title!.trim()
            : report.farmName,
        subtitle: report.farmName,
        icon: SFIcons.calendar,
        accent: PremiumTokens.brandGreen,
        buildFragment: (ref) =>
            buildRelatorioVisitHtml(ref, report, asFragment: true),
      ),
    for (final occurrence in occurrences)
      _CombinedReportEvent(
        key: 'ocorrencia:${occurrence.id}',
        kind: 'ocorrencia',
        occurredAt: occurrence.createdAt,
        title: _occurrenceCardTitle(occurrence),
        subtitle: _occurrenceCardSubtitle(occurrence) ?? 'Ocorrência',
        icon: _relatoriosOccurrenceCategoryIcon(occurrence.category),
        accent: _relatoriosOccurrenceCategoryColor(occurrence.category),
        buildFragment: (ref) =>
            _buildOccurrenceReportHtml(ref, occurrence, asFragment: true),
      ),
    for (final item in marketing)
      _CombinedReportEvent(
        key: 'mkt:${item.id}',
        kind: CombinadoHtmlRenderer.marketingKindFromTipo(item.tipo),
        occurredAt: item.criadoEm,
        title: item.produtorFazenda,
        subtitle: _relatoriosMarketingTipoSectionTitle(item.tipo),
        icon: _relatoriosMarketingTipoIcon(item.tipo),
        accent: _relatoriosMarketingTipoColor(item.tipo),
        buildFragment: (ref) async {
          final branding = await _resolveReportBrandingContext(
            ref,
            fallbackConsultantName: item.nomeVendedor ?? 'Equipe técnica',
            fallbackConsultantRole: 'Consultoria',
          );
          final bundle = await ref
              .read(marketingCaseReportsLookupProvider)
              .buildExportBundle(
                item.id,
                fallbackConsultantName: item.nomeVendedor ?? 'Equipe técnica',
                fallbackConsultantRole: 'Consultoria',
                reportBrandName: branding.brandName,
                reportLogoPath: branding.logoPath,
                consultantName: branding.consultantName,
                consultantRole: branding.consultantRole,
                asFragment: true,
              );
          return bundle.html;
        },
      ),
  ];
  events.sort((a, b) => b.occurredAt.compareTo(a.occurredAt));
  return events;
}

class _CombinedReportsComposer extends ConsumerStatefulWidget {
  final String clientId;
  final DateFormat dateFormat;
  final List<_CombinedReportEvent> events;

  const _CombinedReportsComposer({
    required this.clientId,
    required this.dateFormat,
    required this.events,
  });

  @override
  ConsumerState<_CombinedReportsComposer> createState() =>
      _CombinedReportsComposerState();
}

class _CombinedReportsComposerState
    extends ConsumerState<_CombinedReportsComposer> {
  late Set<String> _selected;
  final List<Set<String>> _undoStack = [];

  @override
  void initState() {
    super.initState();
    _selected = widget.events.map((e) => e.key).toSet();
  }

  @override
  void didUpdateWidget(covariant _CombinedReportsComposer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.clientId != widget.clientId) {
      _undoStack.clear();
      _selected = widget.events.map((e) => e.key).toSet();
      return;
    }
    final keys = widget.events.map((e) => e.key).toSet();
    final oldKeys = oldWidget.events.map((e) => e.key).toSet();
    final wasSelectingAllOld =
        oldKeys.isNotEmpty && oldKeys.difference(_selected).isEmpty;
    if (wasSelectingAllOld && _undoStack.isEmpty) {
      _selected = keys;
      return;
    }
    _selected = _selected.intersection(keys);
    if (_selected.isEmpty && _undoStack.isEmpty) {
      _selected = keys;
    }
  }

  void _toggle(String key) {
    _undoStack.add(Set<String>.of(_selected));
    setState(() {
      if (!_selected.remove(key)) {
        _selected.add(key);
      }
    });
  }

  void _undo() {
    if (_undoStack.isEmpty) return;
    setState(() => _selected = _undoStack.removeLast());
  }

  void _clear() {
    if (_selected.isEmpty) return;
    _undoStack.add(Set<String>.of(_selected));
    setState(() => _selected = <String>{});
  }

  List<_CombinedReportEvent> get _selectedEvents =>
      widget.events.where((event) => _selected.contains(event.key)).toList();

  @override
  Widget build(BuildContext context) {
    final selectedCount = _selected.length;
    final nowLabel = widget.dateFormat.format(DateTime.now());
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _RelatoriosSectionLabel(
          icon: SFIcons.layers,
          iconColor: const Color(0xFF2C5564),
          title: 'Combinar relatórios',
          count: widget.events.length,
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
          child: Row(
            children: [
              TextButton.icon(
                onPressed: _undoStack.isEmpty ? null : _undo,
                icon: const Icon(Icons.undo_rounded, size: 18),
                label: const Text('Desfazer'),
              ),
              TextButton(
                onPressed: _selected.isEmpty ? null : _clear,
                child: const Text('Limpar'),
              ),
              const Spacer(),
              Text(
                '$selectedCount selecionado(s)',
                style: TextStyle(
                  fontSize: 12,
                  color: context.premiumTextSecondary,
                ),
              ),
            ],
          ),
        ),
        ...widget.events.map(_eventTile),
        const SizedBox(height: 8),
        _GeneratedReportCard(
          leading: _relatoriosReportIconBadge(
            icon: SFIcons.layers,
            accent: const Color(0xFF2C5564),
          ),
          eyebrow: 'Gerado sob demanda',
          title: 'Relatório combinado',
          subtitle: selectedCount == 0
              ? 'Selecione pelo menos um relatório'
              : '$selectedCount relatório(s) em ordem cronológica',
          date: nowLabel,
          enabled: selectedCount >= 1,
          buildPayload: () => _buildCombinedReportPayload(
            ref,
            clientId: widget.clientId,
            selected: _selectedEvents,
          ),
        ),
      ],
    );
  }

  Widget _eventTile(_CombinedReportEvent event) {
    final checked = _selected.contains(event.key);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        key: ValueKey(event.key),
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => _toggle(event.key),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
            child: Row(
              children: [
                _relatoriosReportIconBadge(
                  icon: event.icon,
                  accent: event.accent,
                  size: 40,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: context.premiumTextPrimary,
                        ),
                      ),
                      Text(
                        '${CombinadoHtmlRenderer.kindLabel(event.kind)} · ${widget.dateFormat.format(event.occurredAt.toLocal())}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: context.premiumTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                IgnorePointer(
                  child: Checkbox(value: checked, onChanged: (_) {}),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
