part of 'relatorios_page.dart';

class _CombinedReportEvent {
  final String key;
  final String kind;
  final DateTime occurredAt;
  final String title;
  final String subtitle;
  final String detail;
  final IconData icon;
  final Color accent;
  final Future<String> Function(WidgetRef ref) buildFragment;

  const _CombinedReportEvent({
    required this.key,
    required this.kind,
    required this.occurredAt,
    required this.title,
    required this.subtitle,
    this.detail = '',
    required this.icon,
    required this.accent,
    required this.buildFragment,
  });
}

String _visitEventDetail(RelatorioTecnico report) {
  final title = (report.title?.trim().isNotEmpty == true)
      ? report.title!.trim()
      : report.farmName.trim();
  final parts = <String>[];
  final farm = report.farmName.trim();
  if (farm.isNotEmpty && farm != title) parts.add(farm);

  final talhaoNames = <String>[
    for (final talhao in report.talhoes)
      if (talhao.nomeTalhao.trim().isNotEmpty) talhao.nomeTalhao.trim(),
  ];
  if (talhaoNames.isNotEmpty) {
    final shown = talhaoNames.length <= 2
        ? talhaoNames.join(', ')
        : '${talhaoNames[0]}, ${talhaoNames[1]} +${talhaoNames.length - 2}';
    if (shown != title && !parts.contains(shown)) parts.add(shown);
  }

  final culturas = report.talhoes
      .map((talhao) => talhao.cultura?.trim() ?? '')
      .where((cultura) => cultura.isNotEmpty)
      .toSet();
  if (culturas.length == 1) {
    final cultura = culturas.first;
    if (cultura != title && !parts.contains(cultura)) parts.add(cultura);
  }
  return parts.join(' · ');
}

Future<String> _occurrenceEventDetail(
  WidgetRef ref,
  Occurrence occurrence,
) async {
  var fazenda = '';
  var talhao = '';
  try {
    final location = await resolveOccurrenceLocationNames(
      clientId: occurrence.clientId,
      lat: occurrence.lat,
      lng: occurrence.long,
      visitSessionId: occurrence.visitSessionId,
      farmLookup: _tryReadContract(() => ref.read(iFarmLookupProvider)),
      fieldLookup: _tryReadContract(() => ref.read(iFieldLookupProvider)),
      visitSessionLookup: _tryReadContract(
        () => ref.read(visitSessionLookupProvider),
      ),
    );
    fazenda = location.fazenda.trim();
    talhao = location.talhao.trim();
  } catch (_) {
    fazenda = '';
    talhao = '';
  }

  final parts = <String>[];
  if (fazenda.isEmpty && talhao.isEmpty) {
    final description = occurrence.description.trim();
    if (description.isNotEmpty) {
      parts.add(
        description.length > 80 ? description.substring(0, 80) : description,
      );
    }
  } else {
    if (fazenda.isNotEmpty) parts.add(fazenda);
    if (talhao.isNotEmpty && !parts.contains(talhao)) parts.add(talhao);
  }
  final cultivar = occurrence.cultivar?.trim() ?? '';
  if (cultivar.isNotEmpty && !parts.contains(cultivar)) parts.add(cultivar);
  final estadio = occurrence.estadioFenologico?.trim() ?? '';
  if (estadio.isNotEmpty && !parts.contains(estadio)) parts.add(estadio);

  final type = occurrence.type.trim();
  if (type.isNotEmpty) {
    final urgency = _occurrenceUrgencyLabel(type);
    final above =
        '${_occurrenceCardTitle(occurrence)} ${CombinadoHtmlRenderer.kindLabel('ocorrencia')}';
    if (!above.toLowerCase().contains(urgency.toLowerCase())) {
      final label = 'Urgência: $urgency';
      if (!parts.contains(label)) parts.add(label);
    }
  }
  return parts.join(' · ');
}

String _marketingEventDetail(MarketingCaseReportSnapshot item) {
  final title = item.produtorFazenda.trim();
  final parts = <String>[];
  void add(String? raw) {
    final value = raw?.trim() ?? '';
    if (value.isEmpty || value == title || parts.contains(value)) return;
    parts.add(value);
  }

  add(item.produtoUtilizado);
  add(item.nomeTalhao);
  add(item.localizacaoTexto);
  return parts.join(' · ');
}

List<_CombinedReportEvent> _assembleCombinedEvents({
  required List<RelatorioTecnico> visits,
  required List<Occurrence> occurrences,
  required List<MarketingCaseReportSnapshot> marketing,
  required Color visitAccent,
  Map<String, String> occurrenceDetails = const {},
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
        detail: _visitEventDetail(report),
        icon: SFIcons.calendar,
        accent: visitAccent,
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
        detail: occurrenceDetails[occurrence.id] ?? '',
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
        detail: _marketingEventDetail(item),
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

Future<List<_CombinedReportEvent>> _combinedEventsForProducer({
  required BuildContext context,
  required WidgetRef ref,
  required bool Function() isAlive,
  required List<RelatorioTecnico> visits,
  required List<Occurrence> occurrences,
  required List<MarketingCaseReportSnapshot> marketing,
}) async {
  final details = <String, String>{};
  for (final occurrence in occurrences) {
    if (!isAlive()) break;
    try {
      details[occurrence.id] = await _occurrenceEventDetail(ref, occurrence);
    } catch (_) {
      details[occurrence.id] = '';
    }
  }
  return _assembleCombinedEvents(
    visits: visits,
    occurrences: occurrences,
    marketing: marketing,
    visitAccent: context.themeAccent,
    occurrenceDetails: details,
  );
}

class _CombinedEventsLoader extends ConsumerStatefulWidget {
  final String clientId;
  final DateFormat dateFormat;
  final List<RelatorioTecnico> visits;
  final List<Occurrence> occurrences;
  final List<MarketingCaseReportSnapshot> marketing;

  const _CombinedEventsLoader({
    required this.clientId,
    required this.dateFormat,
    required this.visits,
    required this.occurrences,
    required this.marketing,
  });

  @override
  ConsumerState<_CombinedEventsLoader> createState() =>
      _CombinedEventsLoaderState();
}

class _CombinedEventsLoaderState extends ConsumerState<_CombinedEventsLoader> {
  List<_CombinedReportEvent> _events = const [];
  bool _ready = false;
  bool _initialEventsBuilt = false;
  int _generation = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialEventsBuilt) {
      _initialEventsBuilt = true;
      _events = _assembleFromWidget();
      _ready = true;
    }
  }

  @override
  void didUpdateWidget(covariant _CombinedEventsLoader oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_sourceSignature(oldWidget) == _sourceSignature(widget)) return;
    _events = _assembleFromWidget();
    _ready = true;
    _load();
  }

  List<_CombinedReportEvent> _assembleFromWidget() {
    return _assembleCombinedEvents(
      visits: widget.visits,
      occurrences: widget.occurrences,
      marketing: widget.marketing,
      visitAccent: context.themeAccent,
    );
  }

  String _sourceSignature(_CombinedEventsLoader source) {
    final visits = source.visits
        .map(
          (report) =>
              '${report.id}|${report.farmName}|${report.title}|${report.talhoes.map((t) => '${t.nomeTalhao}:${t.cultura}').join(',')}',
        )
        .join(';');
    final occurrences = source.occurrences
        .map(
          (item) =>
              '${item.id}|${item.updatedAt.toIso8601String()}|${item.description}|${item.cultivar}|${item.estadioFenologico}|${item.type}|${item.lat}|${item.long}',
        )
        .join(';');
    final marketing = source.marketing
        .map(
          (item) =>
              '${item.id}|${item.produtoUtilizado}|${item.nomeTalhao}|${item.localizacaoTexto}|${item.produtorFazenda}',
        )
        .join(';');
    return '${source.clientId}#$visits#$occurrences#$marketing';
  }

  Future<void> _load() async {
    final generation = ++_generation;
    try {
      final events = await _combinedEventsForProducer(
        context: context,
        ref: ref,
        isAlive: () => mounted && generation == _generation,
        visits: widget.visits,
        occurrences: widget.occurrences,
        marketing: widget.marketing,
      );
      if (!mounted || generation != _generation) return;
      setState(() {
        _events = events;
        _ready = true;
      });
    } catch (_) {
      if (!mounted || generation != _generation) return;
      setState(() => _ready = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) return const SizedBox.shrink();
    return _CombinedReportsComposer(
      clientId: widget.clientId,
      dateFormat: widget.dateFormat,
      events: _events,
    );
  }
}

class _SavedChapterRow {
  final String key;
  final String title;
  final String subtitle;

  const _SavedChapterRow({
    required this.key,
    required this.title,
    required this.subtitle,
  });
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
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _selected = widget.events.map((event) => event.key).toSet();
  }

  @override
  void didUpdateWidget(covariant _CombinedReportsComposer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.clientId != widget.clientId) {
      _undoStack.clear();
      _selected = widget.events.map((event) => event.key).toSet();
      return;
    }
    final keys = widget.events.map((event) => event.key).toSet();
    final oldKeys = oldWidget.events.map((event) => event.key).toSet();
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

  Future<void> _saveCombination() async {
    if (_saving || _selectedEvents.length < 2) return;
    setState(() => _saving = true);
    try {
      await ref
          .read(relatorioCombinadoRepositoryProvider)
          .insert(
            clientId: widget.clientId,
            chapterKeys: _selectedEvents.map((event) => event.key).toList(),
          );
      ref.invalidate(relatoriosCombinadosProvider(widget.clientId));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Combinado salvo'),
          duration: Duration(seconds: 2),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            userFacingError(error, action: 'Erro ao salvar combinado'),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<_GeneratedReportPayload> _payloadForSaved(RelatorioCombinado saved) {
    final byKey = {for (final event in widget.events) event.key: event};
    final selected = <_CombinedReportEvent>[
      for (final key in saved.chapterKeys)
        if (byKey[key] != null) byKey[key]!,
    ];
    return _buildCombinedReportPayload(
      ref,
      clientId: widget.clientId,
      selected: selected,
      combinadoId: saved.id,
    );
  }

  HtmlReportViewerActions _actionsFor(RelatorioCombinado saved) {
    return HtmlReportViewerActions(
      onManageChapters: (viewerContext) =>
          _onManageChapters(viewerContext, saved),
      onDelete: (_) => _softDeleteSaved(saved),
      deleteDialogTitle: 'Excluir este combinado?',
      deleteDialogMessage: 'Os relatórios de origem permanecem.',
    );
  }

  Future<bool> _softDeleteSaved(RelatorioCombinado saved) async {
    await ref.read(relatorioCombinadoRepositoryProvider).softDelete(saved.id);
    ref.invalidate(relatoriosCombinadosProvider(widget.clientId));
    return true;
  }

  List<_SavedChapterRow> _chapterRows(RelatorioCombinado saved) {
    final byKey = {for (final event in widget.events) event.key: event};
    return [
      for (final key in saved.chapterKeys)
        _SavedChapterRow(
          key: key,
          title: byKey[key]?.title ?? key,
          subtitle: _chapterSubtitle(key, byKey[key]),
        ),
    ];
  }

  String _chapterSubtitle(String key, _CombinedReportEvent? event) {
    if (event != null) {
      final kind = CombinadoHtmlRenderer.kindLabel(event.kind);
      final date = widget.dateFormat.format(event.occurredAt.toLocal());
      return '$kind · $date';
    }
    if (key.startsWith('visita:')) {
      return CombinadoHtmlRenderer.kindLabel('visita');
    }
    if (key.startsWith('ocorrencia:')) {
      return CombinadoHtmlRenderer.kindLabel('ocorrencia');
    }
    if (key.startsWith('mkt:')) return 'Marketing';
    return '';
  }

  Future<String?> _pickChapterToRemove(
    BuildContext viewerContext,
    RelatorioCombinado saved,
  ) {
    final rows = _chapterRows(saved);
    return showSoloForteSheet<String>(
      context: viewerContext,
      builder: (sheetContext) {
        return ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.6,
          ),
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              const Text(
                'Capítulos',
                style: TextStyle(
                  color: SoloForteSheetTokens.titleColor,
                  fontSize: SoloForteSheetTokens.titleFontSize,
                  fontWeight: SoloForteSheetTokens.titleWeight,
                ),
              ),
              const SizedBox(height: 12),
              for (final row in rows)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              row.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (row.subtitle.isNotEmpty)
                              Text(
                                row.subtitle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Color(0xFFAEAEB2),
                                  fontSize: 12,
                                ),
                              ),
                          ],
                        ),
                      ),
                      TextButton(
                        key: ValueKey('tirar-${row.key}'),
                        onPressed: () async {
                          final confirmed = await showDialog<bool>(
                            context: sheetContext,
                            builder: (dialogContext) => AlertDialog(
                              title: const Text('Tirar deste combinado?'),
                              content: const Text('Sai só desta combinação.'),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.of(dialogContext).pop(false),
                                  child: const Text('Cancelar'),
                                ),
                                FilledButton(
                                  onPressed: () =>
                                      Navigator.of(dialogContext).pop(true),
                                  child: const Text('Tirar'),
                                ),
                              ],
                            ),
                          );
                          if (confirmed == true && sheetContext.mounted) {
                            Navigator.of(sheetContext).pop(row.key);
                          }
                        },
                        child: const Text('Tirar'),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pushCombinedViewer(
    BuildContext hostContext,
    RelatorioCombinado saved,
  ) async {
    final bodyBuilder = ref.read(htmlReportViewerBodyBuilderProvider);
    final payload = await _payloadForSaved(saved);
    if (!hostContext.mounted) return;
    await Navigator.of(hostContext).push(
      MaterialPageRoute(
        builder: (_) => HtmlReportViewer(
          title: payload.title,
          htmlContent: payload.html,
          fileBaseName: payload.fileBaseName,
          jsonData: payload.json,
          csvData: payload.csv,
          bodyBuilder: bodyBuilder,
          actions: _actionsFor(saved),
        ),
      ),
    );
  }

  Future<void> _onManageChapters(
    BuildContext viewerContext,
    RelatorioCombinado saved,
  ) async {
    final key = await _pickChapterToRemove(viewerContext, saved);
    if (key == null || !mounted) return;
    final updated = await ref
        .read(relatorioCombinadoRepositoryProvider)
        .removeChapter(saved.id, key);
    ref.invalidate(relatoriosCombinadosProvider(widget.clientId));
    if (!viewerContext.mounted) return;
    final hostContext = context;
    Navigator.of(viewerContext).pop();
    if (updated == null || !hostContext.mounted) return;
    unawaited(_pushCombinedViewer(hostContext, updated));
  }

  @override
  Widget build(BuildContext context) {
    final savedAsync = ref.watch(relatoriosCombinadosProvider(widget.clientId));
    final saved = savedAsync.valueOrNull ?? const <RelatorioCombinado>[];
    if (widget.events.isEmpty && saved.isEmpty) {
      if (savedAsync.isLoading) return const SizedBox.shrink();
      return const _PremiumEmptyState(
        message: 'Nenhum relatório deste produtor para combinar.',
      );
    }

    final selectedCount = _selected.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.events.isNotEmpty) ...[
          _RelatoriosSectionLabel(
            icon: SFIcons.layers,
            iconColor: const Color(0xFF2C5564),
            title: 'Combinar relatórios',
            count: widget.events.length,
          ),
          if (saved.isNotEmpty) _savedSection(saved),
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
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: selectedCount < 2 || _saving ? null : _saveCombination,
              child: const Text('Combinar'),
            ),
          ),
        ] else ...[
          _savedSection(saved),
          const _PremiumEmptyState(
            message: 'Nenhum relatório deste produtor para combinar.',
          ),
        ],
      ],
    );
  }

  Widget _savedSection(List<RelatorioCombinado> saved) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _RelatoriosSectionLabel(
          icon: SFIcons.layers,
          iconColor: const Color(0xFF2C5564),
          title: 'Combinados salvos',
          count: saved.length,
        ),
        for (final item in saved)
          _GeneratedReportCard(
            leading: _relatoriosReportIconBadge(
              icon: SFIcons.layers,
              accent: const Color(0xFF2C5564),
            ),
            eyebrow: 'Salvo',
            title: item.title,
            subtitle: '${item.chapterKeys.length} relatório(s)',
            date: widget.dateFormat.format(item.updatedAt.toLocal()),
            enabled: true,
            viewerActions: _actionsFor(item),
            buildPayload: () => _payloadForSaved(item),
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
                      if (event.detail.trim().isNotEmpty)
                        Text(
                          event.detail,
                          maxLines: 2,
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
