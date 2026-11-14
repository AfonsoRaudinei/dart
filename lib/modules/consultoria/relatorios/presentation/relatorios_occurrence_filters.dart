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

final _occurrencePlaceIndexProvider = FutureProvider.autoDispose
    .family<_OccurrencePlaceIndex, _OccurrencePlaceRequest>((
      ref,
      request,
    ) async {
      final farmLookup = _tryReadContract(() => ref.read(iFarmLookupProvider));
      final fieldLookup = _tryReadContract(
        () => ref.read(iFieldLookupProvider),
      );
      final visitLookup = _tryReadContract(
        () => ref.read(visitSessionLookupProvider),
      );
      if (farmLookup == null || fieldLookup == null) {
        return _OccurrencePlaceIndex.empty;
      }
      final catalog = await loadOccurrencePlaceCatalog(
        clientId: request.clientId,
        farmLookup: farmLookup,
        fieldLookup: fieldLookup,
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

/// Fazenda só vale depois do índice e se ainda existir no catálogo.
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
  if (!placeIndexReady) return true;
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
