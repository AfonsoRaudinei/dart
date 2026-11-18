import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soloforte_app/core/ui/sheets/soloforte_sheet.dart';
import 'package:soloforte_app/core/ui/sheets/solo_forte_sheet_visuals.dart';

import '../../domain/enums/cultura_tipo.dart';
import '../client_list_filter_logic.dart';
import '../providers/clients_providers.dart';

Future<void> showClientListFiltersSheet(
  BuildContext context,
  WidgetRef ref,
) async {
  final clients = await ref.read(clientsListProvider.future);
  final cityOptions = distinctClientCityKeys(clients);
  final current = ref.read(clientAdvancedFiltersProvider);

  if (!context.mounted) return;

  await showSoloForteSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) {
      return _ClientListFiltersSheetBody(
        initial: current,
        cityOptions: cityOptions,
        onApply: (filters) {
          ref.read(clientAdvancedFiltersProvider.notifier).state = filters;
        },
      );
    },
  );
}

class _ClientListFiltersSheetBody extends StatefulWidget {
  final ClientListAdvancedFilters initial;
  final List<String> cityOptions;
  final ValueChanged<ClientListAdvancedFilters> onApply;

  const _ClientListFiltersSheetBody({
    required this.initial,
    required this.cityOptions,
    required this.onApply,
  });

  @override
  State<_ClientListFiltersSheetBody> createState() =>
      _ClientListFiltersSheetBodyState();
}

class _ClientListFiltersSheetBodyState extends State<_ClientListFiltersSheetBody> {
  late Set<String> _cities;
  late Set<CulturaTipo> _culturas;
  ClientListAreaRange? _areaRange;

  @override
  void initState() {
    super.initState();
    _cities = Set<String>.from(widget.initial.cityKeys);
    _culturas = Set<CulturaTipo>.from(widget.initial.culturas);
    _areaRange = widget.initial.areaRange;
  }

  ClientListAdvancedFilters get _draft => ClientListAdvancedFilters(
    cityKeys: _cities,
    culturas: _culturas,
    areaRange: _areaRange,
  );

  void _toggleCity(String key) {
    setState(() {
      if (_cities.contains(key)) {
        _cities.remove(key);
      } else {
        _cities.add(key);
      }
    });
  }

  void _toggleCultura(CulturaTipo tipo) {
    setState(() {
      if (_culturas.contains(tipo)) {
        _culturas.remove(tipo);
      } else {
        _culturas.add(tipo);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final v = SoloForteSheetVisuals.of(context);
    final titleColor = v.titleColor;
    final subtitle = v.subtitleColor;
    final accent = v.ctaBackground;
    final chipBg = v.cardBackground;
    final chipBorder = v.cardBorder;
    final selectedLabel = v.ctaText;
    final unselectedLabel = v.subtitleColor;
    final chipSide = v.isDark ? null : BorderSide(color: chipBorder);

    Widget sectionTitle(String text) => Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 8),
      child: Text(
        text,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w600,
          color: titleColor,
        ),
      ),
    );

    Widget filterChip({
      required bool selected,
      required String label,
      required VoidCallback onTap,
    }) {
      return GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? accent : chipBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: selected ? accent : chipBorder),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: selected ? selectedLabel : unselectedLabel,
              fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      );
    }

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      minChildSize: 0.45,
      maxChildSize: 0.92,
      builder: (context, scrollController) {
        return SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 12, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Filtros avançados',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: titleColor,
                        ),
                      ),
                    ),
                    if (_draft.hasAny)
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _cities.clear();
                            _culturas.clear();
                            _areaRange = null;
                          });
                        },
                        child: Text(
                          'Limpar',
                          style: TextStyle(color: accent, fontSize: 13),
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                  children: [
                    if (_draft.hasAny) ...[
                      Text(
                        'Seleção atual',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: subtitle,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          ..._cities.map(
                            (k) => filterChip(
                              selected: true,
                              label: clientCityKeyLabel(k),
                              onTap: () => _toggleCity(k),
                            ),
                          ),
                          ..._culturas.map(
                            (c) => filterChip(
                              selected: true,
                              label: c.label,
                              onTap: () => _toggleCultura(c),
                            ),
                          ),
                          if (_areaRange != null)
                            filterChip(
                              selected: true,
                              label: _areaRange!.label,
                              onTap: () => setState(() => _areaRange = null),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Divider(color: v.dividerColor),
                    ],
                    sectionTitle('Cidade'),
                    if (widget.cityOptions.isEmpty)
                      Text(
                        'Nenhuma cidade cadastrada nos clientes.',
                        style: TextStyle(color: subtitle, fontSize: 13),
                      )
                    else
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: widget.cityOptions.map((key) {
                          final selected = _cities.contains(key);
                          return FilterChip(
                            selected: selected,
                            label: Text(
                              clientCityKeyLabel(key),
                              style: TextStyle(
                                fontSize: 12,
                                color: selected ? selectedLabel : unselectedLabel,
                              ),
                            ),
                            selectedColor: accent,
                            backgroundColor: chipBg,
                            checkmarkColor: selectedLabel,
                            side: chipSide,
                            onSelected: (_) => _toggleCity(key),
                          );
                        }).toList(),
                      ),
                    sectionTitle('Cultura'),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: CulturaTipo.values
                          .where((c) => c != CulturaTipo.outro)
                          .map((tipo) {
                            final selected = _culturas.contains(tipo);
                            return FilterChip(
                              selected: selected,
                              label: Text(
                                tipo.label,
                                style: TextStyle(
                                  fontSize: 12,
                                  color:
                                      selected ? selectedLabel : unselectedLabel,
                                ),
                              ),
                              selectedColor: accent,
                              backgroundColor: chipBg,
                              checkmarkColor: selectedLabel,
                              side: chipSide,
                              onSelected: (_) => _toggleCultura(tipo),
                            );
                          })
                          .toList(),
                    ),
                    sectionTitle('Área'),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        FilterChip(
                          selected: _areaRange == null,
                          label: Text(
                            'Qualquer',
                            style: TextStyle(
                              fontSize: 12,
                              color: _areaRange == null
                                  ? selectedLabel
                                  : unselectedLabel,
                            ),
                          ),
                          selectedColor: accent,
                          backgroundColor: chipBg,
                          checkmarkColor: selectedLabel,
                          side: chipSide,
                          onSelected: (_) =>
                              setState(() => _areaRange = null),
                        ),
                        ...ClientListAreaRange.values.map((range) {
                          final selected = _areaRange == range;
                          return FilterChip(
                            selected: selected,
                            label: Text(
                              range.label,
                              style: TextStyle(
                                fontSize: 12,
                                color: selected ? selectedLabel : unselectedLabel,
                              ),
                            ),
                            selectedColor: accent,
                            backgroundColor: chipBg,
                            checkmarkColor: selectedLabel,
                            side: chipSide,
                            onSelected: (_) =>
                                setState(() => _areaRange = range),
                          );
                        }),
                      ],
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: accent,
                      foregroundColor: v.ctaText,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(v.ctaRadius),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () {
                      widget.onApply(_draft);
                      Navigator.of(context).pop();
                    },
                    child: const Text('Aplicar filtros'),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}