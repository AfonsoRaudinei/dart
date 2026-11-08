import 'dart:async';
import 'package:soloforte_app/core/ui/sheets/solo_forte_sheet_visuals.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/ui/sheets/sheet_keyboard_inset.dart';
import '../../../core/ui/sheets/soloforte_sheet.dart';
import '../../../core/ui/sheets/widgets/sheet_input_field.dart';
import '../../../core/services/geocoding/city_geocoder.dart';
import '../../../core/services/geocoding/ibge_localidades_datasource.dart';

/// Escolhe o município a geocodificar após busca (testável).
IbgeMunicipio? resolveMapMunicipalityForSearch({
  required List<IbgeMunicipio> filtered,
  required String query,
  IbgeMunicipio? selected,
}) {
  if (selected != null) return selected;
  final term = query.trim();
  if (term.isEmpty) return null;

  final exact = filtered
      .where((m) => m.nome.toLowerCase() == term.toLowerCase())
      .toList();
  if (exact.length == 1) return exact.first;
  if (filtered.length == 1) return filtered.single;
  return null;
}

/// Abre busca IBGE de município para navegar no mapa.
Future<void> showMapMunicipalitySearch(
  BuildContext context, {
  required void Function(LatLng point, String label) onSelected,
}) {
  return showSoloForteSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    maxHeightFraction: 0.78,
    builder: (_) => MapMunicipalitySearchSheet(onSelected: onSelected),
  );
}

class MapMunicipalitySearchSheet extends StatefulWidget {
  const MapMunicipalitySearchSheet({super.key, required this.onSelected});

  final void Function(LatLng point, String label) onSelected;

  @override
  State<MapMunicipalitySearchSheet> createState() =>
      _MapMunicipalitySearchSheetState();
}

class _MapMunicipalitySearchSheetState
    extends State<MapMunicipalitySearchSheet> {
  final _datasource = IbgeLocalidadesDatasource();
  final _searchController = TextEditingController();

  List<IbgeEstado> _estados = [];
  List<IbgeMunicipio> _municipios = [];
  IbgeEstado? _estadoSelecionado;
  IbgeMunicipio? _selectedMunicipio;
  bool _loadingEstados = true;
  bool _loadingMunicipios = false;
  bool _geocoding = false;
  String? _error;

  InputDecoration _fieldDecoration(SoloForteSheetVisuals v) {
    final isIos = v.isIos;
    final fill = v.inputFill;
    final radius = isIos
        ? v.cardRadius
        : v.inputRadius;
    final hint = v.inputHint;
    final focus = v.focusBorder;
    final side = v.isDark ? BorderSide.none : BorderSide(color: v.inputBorder);

    return InputDecoration(
      filled: true,
      fillColor: fill,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(radius)),
        borderSide: side,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(radius)),
        borderSide: side,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(radius)),
        borderSide: BorderSide(color: focus, width: 1.5),
      ),
      labelStyle: TextStyle(color: hint),
    );
  }

  @override
  void initState() {
    super.initState();
    _loadEstados();
    _searchController.addListener(() {
      setState(() {
        _error = null;
        _selectedMunicipio = null;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadEstados() async {
    try {
      final estados = await _datasource.fetchEstados();
      if (!mounted) return;
      setState(() {
        _estados = estados;
        _loadingEstados = false;
        _estadoSelecionado = estados.isNotEmpty ? estados.first : null;
      });
      if (_estadoSelecionado != null) {
        await _loadMunicipios(_estadoSelecionado!);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingEstados = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _loadMunicipios(IbgeEstado estado) async {
    setState(() {
      _loadingMunicipios = true;
      _error = null;
    });
    try {
      final municipios = await _datasource.fetchMunicipiosPorEstado(estado);
      if (!mounted) return;
      setState(() {
        _municipios = municipios;
        _loadingMunicipios = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingMunicipios = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _selectMunicipio(IbgeMunicipio municipio) async {
    setState(() {
      _geocoding = true;
      _error = null;
    });

    final coords = await CityGeocoder.instance.resolve(
      municipio: municipio.nome,
      uf: municipio.uf,
    );

    if (!mounted) return;

    if (coords == null) {
      setState(() {
        _geocoding = false;
        _error =
            'Não foi possível localizar ${municipio.nome}, ${municipio.uf}.';
      });
      return;
    }

    final label = '${municipio.nome}, ${municipio.uf}';
    widget.onSelected(LatLng(coords.lat, coords.lon), label);
    Navigator.of(context).pop();
  }

  Future<void> _submitSearch() async {
    if (_geocoding || _loadingMunicipios) return;

    final municipio = resolveMapMunicipalityForSearch(
      filtered: _filteredMunicipios,
      query: _searchController.text,
      selected: _selectedMunicipio,
    );

    if (municipio == null) {
      setState(() {
        _error = _searchController.text.trim().isEmpty
            ? 'Digite o nome do município ou selecione na lista.'
            : 'Selecione um município na lista ou refine a busca.';
      });
      return;
    }

    await _selectMunicipio(municipio);
  }

  List<IbgeMunicipio> get _filteredMunicipios {
    return _datasource.filterMunicipios(_municipios, _searchController.text);
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad = sheetFormKeyboardBottomPadding(
      safeBottom: MediaQuery.paddingOf(context).bottom,
      keyboard: MediaQuery.viewInsetsOf(context).bottom,
    );
        final v = SoloForteSheetVisuals.of(context);
    final isIos = v.isIos;
    final titleColor = v.titleColor;
    final inputText = v.inputText;
    final hintColor = v.inputHint;
    final accent = v.chipTextActive;
    final muted = v.subtitleColor;
    final listBg = v.inputFill;
    final listRadius = isIos
        ? v.cardRadius
        : v.inputRadius;
    final divider = v.dividerColor;
    final dropdownBg = v.inputFill;
    final iconColor = v.subtitleColor;
    final ctaBg = v.ctaBackground;
    final ctaFg = v.ctaText;
    final ghostBorder = v.ghostBorder;
    final ghostText = v.ghostText;
    final canSubmit = !_geocoding && !_loadingMunicipios;

    return SingleChildScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: EdgeInsets.fromLTRB(20, 4, 20, bottomPad),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ir para município',
            style: TextStyle(
              fontSize: v.titleFontSize,
              fontWeight: v.titleWeight,
              color: titleColor,
            ),
          ),
          const SizedBox(height: 16),
          if (_loadingEstados)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator(color: accent)),
            )
          else ...[
            DropdownButtonFormField<IbgeEstado>(
              initialValue: _estadoSelecionado,
              dropdownColor: dropdownBg,
              style: TextStyle(color: inputText, fontSize: 16),
              iconEnabledColor: iconColor,
              decoration: _fieldDecoration(
                v,
              ).copyWith(labelText: 'Estado (UF)'),
              items: _estados
                  .map(
                    (e) => DropdownMenuItem(
                      value: e,
                      child: Text('${e.nome} (${e.sigla})'),
                    ),
                  )
                  .toList(),
              onChanged: _geocoding
                  ? null
                  : (estado) {
                      if (estado == null) return;
                      HapticFeedback.selectionClick();
                      setState(() {
                        _estadoSelecionado = estado;
                        _searchController.clear();
                        _selectedMunicipio = null;
                      });
                      _loadMunicipios(estado);
                    },
            ),
            const SizedBox(height: 12),
            IgnorePointer(
              ignoring: _geocoding || _loadingMunicipios,
              child: SheetInputField(
                controller: _searchController,
                hintText: 'Buscar município…',
                prefixIcon: Icon(Icons.search, color: hintColor),
                textInputAction: TextInputAction.search,
                onSubmitted: (_) => _submitSearch(),
              ),
            ),
            const SizedBox(height: 12),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  _error!,
                  style: TextStyle(fontSize: 13, color: accent),
                ),
              ),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.42,
              ),
              child: _loadingMunicipios || _geocoding
                  ? Center(child: CircularProgressIndicator(color: accent))
                  : _filteredMunicipios.isEmpty
                  ? Center(
                      child: Text(
                        'Nenhum município encontrado.',
                        style: TextStyle(fontSize: 14, color: muted),
                      ),
                    )
                  : Container(
                      decoration: BoxDecoration(
                        color: listBg,
                        borderRadius: BorderRadius.circular(listRadius),
                        border: v.isDark
                            ? null
                            : Border.all(color: v.cardBorder),
                      ),
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: _filteredMunicipios.length,
                        separatorBuilder: (_, __) => Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Divider(height: 1, color: divider),
                        ),
                        itemBuilder: (context, index) {
                          final municipio = _filteredMunicipios[index];
                          final isSelected =
                              _selectedMunicipio?.id == municipio.id;
                          return Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                HapticFeedback.selectionClick();
                                setState(() => _selectedMunicipio = municipio);
                                unawaited(_selectMunicipio(municipio));
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                                child: Text(
                                  municipio.nome,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: isSelected
                                        ? FontWeight.w600
                                        : FontWeight.w400,
                                    color: isSelected ? accent : inputText,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: ghostText,
                      side: BorderSide(color: ghostBorder),
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          v.ghostRadius,
                        ),
                      ),
                    ),
                    onPressed: _geocoding
                        ? null
                        : () => Navigator.of(context).pop(),
                    child: const Text('Cancelar'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: ctaBg,
                      foregroundColor: ctaFg,
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          isIos
                              ? v.ctaRadius
                              : v.chipRadius,
                        ),
                      ),
                    ),
                    onPressed: canSubmit ? _submitSearch : null,
                    child: const Text('Ir'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
