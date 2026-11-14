part of 'relatorios_page.dart';

const _kOccurrencePlaceAll = '';

class _OccurrencePlaceIndex {
  const _OccurrencePlaceIndex({required this.catalog, required this.places});

  static const empty = _OccurrencePlaceIndex(
    catalog: OccurrencePlaceCatalog(),
    places: {},
  );

  final OccurrencePlaceCatalog catalog;
  final Map<String, OccurrencePlace> places;
}

class _OccurrencePlaceRequest {
  _OccurrencePlaceRequest({required this.clientId, required this.queries})
    : signature = _signatureOf(clientId, queries);

  final String clientId;
  final List<OccurrencePlaceQuery> queries;
  final String signature;

  static String _signatureOf(
    String clientId,
    List<OccurrencePlaceQuery> queries,
  ) {
    final lines = [
      for (final query in queries)
        '${query.id}\t${query.persistedFieldId ?? ''}\t${query.lat ?? ''}\t'
            '${query.lng ?? ''}\t${query.visitSessionId ?? ''}',
    ]..sort();
    return '$clientId\n${lines.join('\n')}';
  }

  @override
  bool operator ==(Object other) =>
      other is _OccurrencePlaceRequest && other.signature == signature;

  @override
  int get hashCode => signature.hashCode;
}

_OccurrencePlaceRequest _occurrencePlaceRequest(
  String clientId,
  List<Occurrence> occurrences,
) {
  return _OccurrencePlaceRequest(
    clientId: clientId,
    queries: [
      for (final occurrence in occurrences)
        OccurrencePlaceQuery(
          id: occurrence.id,
          persistedFieldId: occurrence.fieldId,
          lat: occurrence.lat,
          lng: occurrence.long,
          visitSessionId: occurrence.visitSessionId,
        ),
    ],
  );
}

/// Catálogo do produtor. A chave é só o cliente: criar ou apagar ocorrência
/// não recarrega fazendas e talhões.
final _occurrencePlaceCatalogProvider = FutureProvider.autoDispose
    .family<OccurrencePlaceCatalog, String>((ref, clientId) async {
      final farmLookup = _tryReadContract(() => ref.read(iFarmLookupProvider));
      final fieldLookup = _tryReadContract(
        () => ref.read(iFieldLookupProvider),
      );
      if (farmLookup == null || fieldLookup == null) {
        return const OccurrencePlaceCatalog();
      }
      return loadOccurrencePlaceCatalog(
        clientId: clientId,
        farmLookup: farmLookup,
        fieldLookup: fieldLookup,
      );
    });

final _occurrencePlaceIndexProvider = FutureProvider.autoDispose
    .family<_OccurrencePlaceIndex, _OccurrencePlaceRequest>((
      ref,
      request,
    ) async {
      final catalog = await ref.watch(
        _occurrencePlaceCatalogProvider(request.clientId).future,
      );
      final visitLookup = _tryReadContract(
        () => ref.read(visitSessionLookupProvider),
      );
      final places = await indexOccurrencePlaces(
        queries: request.queries,
        catalog: catalog,
        visitSessionLookup: visitLookup,
      );
      return _OccurrencePlaceIndex(catalog: catalog, places: places);
    });

List<OccurrenceCategory> _occurrenceCategoriesPresent(
  List<Occurrence> occurrences,
) {
  final present = <OccurrenceCategory>{
    for (final occurrence in occurrences)
      OccurrenceCategory.fromString(occurrence.category),
  };
  return [
    for (final category in OccurrenceCategory.values)
      if (present.contains(category)) category,
  ];
}

/// Fazenda só vale depois do catálogo e se ainda existir nele.
String? _acceptedOccurrenceFarmId(
  OccurrencePlaceCatalog catalog,
  bool catalogReady,
  String? farmId,
) {
  if (farmId == null || !catalogReady) return null;
  if (!catalog.farms.any((farm) => farm.id == farmId)) return null;
  return farmId;
}

String? _acceptedOccurrenceFieldId(
  OccurrencePlaceCatalog catalog,
  String? farmId,
  String? fieldId,
) {
  if (farmId == null || fieldId == null) return null;
  final fields = catalog.fieldsByFarm[farmId] ?? const <FieldSummary>[];
  if (!fields.any((field) => field.id == fieldId)) return null;
  return fieldId;
}

bool _occurrenceMatchesPlace(
  Occurrence occurrence, {
  required String? farmId,
  required String? fieldId,
  required bool placeIndexReady,
  required Map<String, OccurrencePlace> places,
}) {
  if (farmId == null && fieldId == null) return true;
  // Com fazenda ou talhão escolhido, não solta a lista inteira enquanto o
  // índice novo ainda não chegou.
  if (!placeIndexReady) return false;
  final place = places[occurrence.id];
  if (place == null || !place.isKnown) return false;
  if (farmId != null && place.farmId != farmId) return false;
  if (fieldId != null && place.fieldId != fieldId) return false;
  return true;
}

List<Occurrence> _filterRelatorioOccurrences({
  required List<Occurrence> occurrences,
  required OccurrenceFilters filters,
  required String? farmId,
  required String? fieldId,
  required bool placeIndexReady,
  required Map<String, OccurrencePlace> places,
}) {
  return [
    for (final occurrence in occurrences)
      if (filters.matches(occurrence) &&
          _occurrenceMatchesPlace(
            occurrence,
            farmId: farmId,
            fieldId: fieldId,
            placeIndexReady: placeIndexReady,
            places: places,
          ))
        occurrence,
  ];
}

class _OccurrenceFiltersPanel extends StatelessWidget {
  final List<OccurrenceCategory> categories;
  final OccurrenceFilters filters;
  final bool oldestFirst;
  final bool showPlaceFilters;
  final bool placesLoading;
  final List<FarmSummary> farms;
  final List<FieldSummary> fields;
  final String? farmId;
  final String? fieldId;
  final VoidCallback onClear;
  final void Function(OccurrenceCategory category, bool selected)
  onToggleCategory;
  final VoidCallback onClearCategories;
  final void Function(String status, bool selected) onToggleStatus;
  final void Function(String storageValue, bool selected) onToggleAndamento;
  final ValueChanged<bool> onOldestFirst;
  final ValueChanged<String?> onFarmChanged;
  final ValueChanged<String?> onFieldChanged;

  const _OccurrenceFiltersPanel({
    required this.categories,
    required this.filters,
    required this.oldestFirst,
    required this.showPlaceFilters,
    required this.placesLoading,
    required this.farms,
    required this.fields,
    required this.farmId,
    required this.fieldId,
    required this.onClear,
    required this.onToggleCategory,
    required this.onClearCategories,
    required this.onToggleStatus,
    required this.onToggleAndamento,
    required this.onOldestFirst,
    required this.onFarmChanged,
    required this.onFieldChanged,
  });

  bool get _dirty =>
      filters.hasAnyFilter || farmId != null || fieldId != null || oldestFirst;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showPlaceFilters) ...[
          _label(context, 'Fazenda'),
          if (placesLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: LinearProgressIndicator(minHeight: 2),
            )
          else
            _placeDropdown(
              context,
              value: farmId ?? _kOccurrencePlaceAll,
              items: [
                const DropdownMenuItem<String>(
                  value: _kOccurrencePlaceAll,
                  child: Text('Todas'),
                ),
                for (final farm in farms)
                  if (farm.id.isNotEmpty)
                    DropdownMenuItem<String>(
                      value: farm.id,
                      child: Text(farm.name, overflow: TextOverflow.ellipsis),
                    ),
              ],
              onChanged: (value) => onFarmChanged(
                value == null || value == _kOccurrencePlaceAll ? null : value,
              ),
            ),
          const SizedBox(height: 12),
          _label(context, 'Talhão'),
          _placeDropdown(
            context,
            value: fieldId ?? _kOccurrencePlaceAll,
            items: [
              const DropdownMenuItem<String>(
                value: _kOccurrencePlaceAll,
                child: Text('Todos'),
              ),
              if (farmId != null)
                for (final field in fields)
                  if (field.id.isNotEmpty)
                    DropdownMenuItem<String>(
                      value: field.id,
                      child: Text(field.name, overflow: TextOverflow.ellipsis),
                    ),
            ],
            onChanged: farmId == null
                ? null
                : (value) => onFieldChanged(
                    value == null || value == _kOccurrencePlaceAll
                        ? null
                        : value,
                  ),
          ),
          const SizedBox(height: 12),
        ],
        _label(context, 'Categoria'),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _filterChip(
              context,
              label: 'Todas',
              selected: filters.categories.isEmpty,
              onSelected: (_) => onClearCategories(),
            ),
            for (final category in categories)
              _filterChip(
                context,
                label: category.label,
                selected: filters.categories.contains(category),
                onSelected: (selected) => onToggleCategory(category, selected),
              ),
          ],
        ),
        const SizedBox(height: 12),
        _label(context, 'Situação'),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _filterChip(
              context,
              label: 'Rascunho',
              selected: filters.statuses.contains('draft'),
              onSelected: (selected) => onToggleStatus('draft', selected),
            ),
            _filterChip(
              context,
              label: 'Confirmada',
              selected: filters.statuses.contains('confirmed'),
              onSelected: (selected) => onToggleStatus('confirmed', selected),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _label(context, 'Andamento'),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final step in OccurrenceAndamento.values)
              _filterChip(
                context,
                label: step.label,
                selected: filters.andamentos.contains(step.storageValue),
                onSelected: (selected) =>
                    onToggleAndamento(step.storageValue, selected),
              ),
          ],
        ),
        const SizedBox(height: 12),
        _label(context, 'Ordem'),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _filterChip(
              context,
              label: 'Mais recentes',
              selected: !oldestFirst,
              onSelected: (_) => onOldestFirst(false),
            ),
            _filterChip(
              context,
              label: 'Linha do tempo',
              selected: oldestFirst,
              onSelected: (_) => onOldestFirst(true),
            ),
          ],
        ),
        if (_dirty)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: onClear,
              child: Text(
                'Limpar',
                style: TextStyle(
                  color: context.themeAccent,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _label(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: context.premiumTextSecondary,
        ),
      ),
    );
  }

  Widget _placeDropdown(
    BuildContext context, {
    required String value,
    required List<DropdownMenuItem<String>> items,
    required ValueChanged<String?>? onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      decoration: BoxDecoration(
        color: context.premiumSurface,
        borderRadius: BorderRadius.circular(PremiumTokens.borderRadiusSm),
        border: Border.all(color: context.premiumHairline),
        boxShadow: PremiumTokens.premiumShadow,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: value,
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            color: context.premiumTextSecondary,
          ),
          borderRadius: BorderRadius.circular(PremiumTokens.borderRadiusSm),
          dropdownColor: context.premiumSurface,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: context.premiumTextPrimary,
          ),
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _filterChip(
    BuildContext context, {
    required String label,
    required bool selected,
    required ValueChanged<bool> onSelected,
  }) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      showCheckmark: false,
      labelStyle: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: selected ? Colors.white : context.premiumTextPrimary,
      ),
      selectedColor: context.themeAccent,
      backgroundColor: context.premiumSurface,
      side: BorderSide(
        color: selected ? context.themeAccent : context.premiumHairline,
      ),
      onSelected: onSelected,
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// SEÇÃO — Ocorrências Registradas
// ══════════════════════════════════════════════════════════════════════════════

class _OccurrenciasSection extends ConsumerStatefulWidget {
  final DateFormat dateFormat;
  final String? selectedProducerClientId;
  final ValueChanged<String> onProducerSelected;

  const _OccurrenciasSection({
    required this.dateFormat,
    required this.selectedProducerClientId,
    required this.onProducerSelected,
  });

  @override
  ConsumerState<_OccurrenciasSection> createState() =>
      _OccurrenciasSectionState();
}

class _OccurrenciasSectionState extends ConsumerState<_OccurrenciasSection> {
  OccurrenceFilters _filters = const OccurrenceFilters();
  String? _farmId;
  String? _fieldId;
  bool _oldestFirst = false;
  String? _boundProducerClientId;
  String? _retainedPlacesClientId;
  Map<String, OccurrencePlace>? _retainedPlaces;

  void _syncProducerClient(String? clientId) {
    if (_boundProducerClientId == clientId) return;
    _boundProducerClientId = clientId;
    _farmId = null;
    _fieldId = null;
    _retainedPlacesClientId = null;
    _retainedPlaces = null;
  }

  void _keepPlaces(String? clientId, Map<String, OccurrencePlace>? places) {
    if (clientId == null || places == null) return;
    _retainedPlacesClientId = clientId;
    _retainedPlaces = places;
  }

  void _clearFilters() {
    setState(() {
      _filters = const OccurrenceFilters();
      _farmId = null;
      _fieldId = null;
      _oldestFirst = false;
    });
  }

  void _toggleCategory(OccurrenceCategory category, bool selected) {
    final next = {..._filters.categories};
    if (selected) {
      next.add(category);
    } else {
      next.remove(category);
    }
    setState(() => _filters = _filters.copyWith(categories: next));
  }

  void _toggleStatus(String status, bool selected) {
    final next = {..._filters.statuses};
    if (selected) {
      next.add(status);
    } else {
      next.remove(status);
    }
    setState(() => _filters = _filters.copyWith(statuses: next));
  }

  void _toggleAndamento(String storageValue, bool selected) {
    final next = {..._filters.andamentos};
    if (selected) {
      next.add(storageValue);
    } else {
      next.remove(storageValue);
    }
    setState(() => _filters = _filters.copyWith(andamentos: next));
  }

  void _selectFarm(String? farmId, OccurrencePlaceCatalog catalog) {
    setState(() {
      _farmId = farmId;
      if (farmId == null) {
        _fieldId = null;
        return;
      }
      final fields = catalog.fieldsByFarm[farmId] ?? const <FieldSummary>[];
      if (_fieldId != null && !fields.any((field) => field.id == _fieldId)) {
        _fieldId = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final producerScope = _watchRelatoriosProducerScope(ref);
    final occAsync = ref.watch(occurrencesListProvider);

    return occAsync.when(
      data: (raw) {
        final list = _scopeRelatoriosOccurrences(producerScope, raw);
        final nowLabel = widget.dateFormat.format(DateTime.now());
        final producerCounts = _producerCountsFromIds(
          list.map((o) => o.clientId),
        );
        final producerIds = producerCounts.keys.toList()..sort();
        final effectiveClientId = resolveRelatoriosProducerClientId(
          selectedClientId: widget.selectedProducerClientId,
          routeClientId: _relatoriosRouteClienteId(context),
          producerIds: producerIds,
        );
        _syncProducerClient(effectiveClientId);
        final scoped = producerIds.isEmpty
            ? list
            : effectiveClientId == null
            ? const <Occurrence>[]
            : list
                  .where(
                    (occurrence) => occurrence.clientId == effectiveClientId,
                  )
                  .toList();
        final needsProducerPick =
            producerIds.length > 1 && effectiveClientId == null;
        final placeRequest = effectiveClientId == null || scoped.isEmpty
            ? null
            : _occurrencePlaceRequest(effectiveClientId, scoped);
        final catalogAsync = effectiveClientId == null
            ? const AsyncData<OccurrencePlaceCatalog>(OccurrencePlaceCatalog())
            : ref.watch(_occurrencePlaceCatalogProvider(effectiveClientId));
        final indexAsync = placeRequest == null
            ? const AsyncData<_OccurrencePlaceIndex>(
                _OccurrencePlaceIndex.empty,
              )
            : ref.watch(_occurrencePlaceIndexProvider(placeRequest));
        if (indexAsync.hasValue) {
          _keepPlaces(effectiveClientId, indexAsync.requireValue.places);
        }
        final livePlaces = indexAsync.hasValue
            ? indexAsync.requireValue.places
            : null;
        final retainedPlaces =
            !indexAsync.hasError && _retainedPlacesClientId == effectiveClientId
            ? _retainedPlaces
            : null;
        final places =
            livePlaces ?? retainedPlaces ?? const <String, OccurrencePlace>{};
        final catalog =
            catalogAsync.valueOrNull ?? const OccurrencePlaceCatalog();
        final catalogReady = catalogAsync.hasValue;
        final placesLoading =
            (effectiveClientId != null &&
                catalogAsync.isLoading &&
                !catalogAsync.hasValue) ||
            (placeRequest != null &&
                indexAsync.isLoading &&
                !indexAsync.hasValue);
        final placeFilterActive = _farmId != null || _fieldId != null;
        final placeIndexReady =
            placeRequest == null ||
            livePlaces != null ||
            indexAsync.hasError ||
            (placeFilterActive && retainedPlaces != null);
        final farmId = _acceptedOccurrenceFarmId(
          catalog,
          catalogReady,
          _farmId,
        );
        final fieldId = _acceptedOccurrenceFieldId(catalog, farmId, _fieldId);
        final filtered = _filterRelatorioOccurrences(
          occurrences: needsProducerPick ? const <Occurrence>[] : scoped,
          filters: _filters,
          farmId: farmId,
          fieldId: fieldId,
          placeIndexReady: placeIndexReady,
          places: places,
        );
        final displayList = _sortOccurrencesByCreatedAt(
          filtered,
          oldestFirst: _oldestFirst,
        );
        final exportClientId = effectiveClientId;

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            _InsetGroupHeader(
              title: 'Ocorrências Registradas',
              count: needsProducerPick ? 0 : displayList.length,
            ),
            if (list.isNotEmpty && producerIds.isNotEmpty)
              _relatoriosProducerSelectorBlock(
                context: context,
                producerIds: producerIds,
                itemCounts: producerCounts,
                effectiveClientId: effectiveClientId,
                onSelected: widget.onProducerSelected,
              ),
            if (exportClientId != null && displayList.isNotEmpty) ...[
              _GeneratedReportCard(
                leading: _relatoriosReportIconBadge(
                  icon: SFIcons.assignment,
                  accent: const Color(0xFF2C5564),
                ),
                eyebrow: 'Exportar lista',
                title: 'Lista de Ocorrências',
                subtitle: '${displayList.length} ocorrência(s)',
                date: nowLabel,
                enabled: true,
                buildPayload: () => _buildOccurrenceListPayload(
                  ref,
                  displayList,
                  exportClientId,
                ),
              ),
              const SizedBox(height: 12),
            ],
            if (scoped.isNotEmpty) ...[
              _OccurrenceFiltersPanel(
                categories: _occurrenceCategoriesPresent(scoped),
                filters: _filters,
                oldestFirst: _oldestFirst,
                showPlaceFilters: effectiveClientId != null,
                placesLoading: placesLoading,
                farms: catalog.farms,
                fields: farmId == null
                    ? const <FieldSummary>[]
                    : (catalog.fieldsByFarm[farmId] ?? const <FieldSummary>[]),
                farmId: farmId,
                fieldId: fieldId,
                onClear: _clearFilters,
                onToggleCategory: _toggleCategory,
                onClearCategories: () => setState(
                  () => _filters = _filters.copyWith(categories: const {}),
                ),
                onToggleStatus: _toggleStatus,
                onToggleAndamento: _toggleAndamento,
                onOldestFirst: (value) {
                  if (_oldestFirst == value) return;
                  setState(() => _oldestFirst = value);
                },
                onFarmChanged: (value) => _selectFarm(value, catalog),
                onFieldChanged: (value) => setState(() => _fieldId = value),
              ),
              const SizedBox(height: 12),
            ],
            if (list.isEmpty)
              _PremiumEmptyState(
                message: 'Nenhuma ocorrência ainda.',
                ctaLabel: 'Abrir mapa',
                onCta: () => context.go(AppRoutes.map),
              )
            else if (needsProducerPick)
              const _PremiumEmptyState(message: 'Escolha o produtor.')
            else if (scoped.isNotEmpty && displayList.isEmpty)
              const _PremiumEmptyState(
                message: 'Nenhuma ocorrência neste filtro.',
              )
            else if (displayList.isEmpty)
              _PremiumEmptyState(
                message: 'Nenhuma ocorrência para este produtor.',
                ctaLabel: 'Abrir mapa',
                onCta: () => context.go(AppRoutes.map),
              )
            else
              ...displayList.map(
                (occurrence) => _OccurrenciaCard(
                  occurrence: occurrence,
                  dateFormat: widget.dateFormat,
                ),
              ),
            const SizedBox(height: kFabSafeArea),
          ],
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.all(16),
        child: _SectionLoading(title: 'Ocorrências Registradas'),
      ),
      error: (e, stack) {
        AppLogger.error(
          'occurrencesListProvider ERROR',
          tag: 'RelatoriosScreen',
          error: e,
          stackTrace: stack,
        );
        return Padding(
          padding: const EdgeInsets.all(16),
          child: _SectionError(
            title: 'Ocorrências Registradas',
            onRetry: () => ref.refresh(occurrencesListProvider),
          ),
        );
      },
    );
  }
}
