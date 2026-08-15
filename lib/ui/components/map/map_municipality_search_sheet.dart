import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/ui/sheets/sheet_tokens.dart';
import '../../../core/ui/sheets/soloforte_sheet.dart';
import '../../../core/ui/sheets/widgets/sheet_input_field.dart';
import '../../../modules/clima/data/datasources/ibge_localidades_datasource.dart';
import '../../../modules/clima/data/services/city_geocoder.dart';

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

class _MapMunicipalitySearchSheetState extends State<MapMunicipalitySearchSheet> {
  final _datasource = IbgeLocalidadesDatasource();
  final _searchController = TextEditingController();

  List<IbgeEstado> _estados = [];
  List<IbgeMunicipio> _municipios = [];
  IbgeEstado? _estadoSelecionado;
  bool _loadingEstados = true;
  bool _loadingMunicipios = false;
  bool _geocoding = false;
  String? _error;

  InputDecoration _fieldDecoration(bool isIos) {
    final fill = isIos
        ? SoloForteSheetSkinIos.cardBackground
        : SoloForteSheetTokens.inputBackground;
    final radius = isIos
        ? SoloForteSheetSkinIos.cardRadius
        : SoloForteSheetTokens.inputRadius;
    final hint = isIos
        ? SoloForteSheetSkinIos.subtitleColor
        : SoloForteSheetTokens.inputHint;
    final focus = isIos
        ? SoloForteSheetSkinIos.iconStroke
        : SoloForteSheetTokens.chipBorderActive;
    final side = isIos
        ? const BorderSide(color: SoloForteSheetSkinIos.cardBorder)
        : BorderSide.none;

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
    _searchController.addListener(() => setState(() {}));
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
        _error = 'Não foi possível localizar ${municipio.nome}, ${municipio.uf}.';
      });
      return;
    }

    final label = '${municipio.nome}, ${municipio.uf}';
    widget.onSelected(LatLng(coords.lat, coords.lon), label);
    Navigator.of(context).pop();
  }

  List<IbgeMunicipio> get _filteredMunicipios {
    return _datasource.filterMunicipios(_municipios, _searchController.text);
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.paddingOf(context).bottom;
    final isIos = soloForteSheetIsIos(context);
    final titleColor = isIos
        ? SoloForteSheetSkinIos.titleColor
        : SoloForteSheetTokens.titleColor;
    final inputText = isIos
        ? SoloForteSheetSkinIos.titleColor
        : SoloForteSheetTokens.inputText;
    final hintColor = isIos
        ? SoloForteSheetSkinIos.subtitleColor
        : SoloForteSheetTokens.inputHint;
    final accent = isIos
        ? SoloForteSheetSkinIos.iconStroke
        : SoloForteSheetTokens.chipTextActive;
    final muted = isIos
        ? SoloForteSheetSkinIos.subtitleColor
        : SoloForteSheetTokens.categoryLabel;
    final listBg = isIos
        ? SoloForteSheetSkinIos.cardBackground
        : SoloForteSheetTokens.inputBackground;
    final listRadius = isIos
        ? SoloForteSheetSkinIos.cardRadius
        : SoloForteSheetTokens.inputRadius;
    final divider = isIos
        ? SoloForteSheetSkinIos.rowDivider
        : SoloForteSheetTokens.divider;
    final dropdownBg = isIos
        ? SoloForteSheetSkinIos.cardBackground
        : SoloForteSheetTokens.inputBackground;
    final iconColor = isIos
        ? SoloForteSheetSkinIos.subtitleColor
        : SoloForteSheetTokens.categoryLabel;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 4, 20, 16 + bottomPad),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ir para município',
            style: TextStyle(
              fontSize: SoloForteSheetTokens.titleFontSize,
              fontWeight: SoloForteSheetTokens.titleWeight,
              color: titleColor,
            ),
          ),
          const SizedBox(height: 16),
          if (_loadingEstados)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: CircularProgressIndicator(color: accent),
              ),
            )
          else ...[
            DropdownButtonFormField<IbgeEstado>(
              initialValue: _estadoSelecionado,
              dropdownColor: dropdownBg,
              style: TextStyle(
                color: inputText,
                fontSize: 16,
              ),
              iconEnabledColor: iconColor,
              decoration:
                  _fieldDecoration(isIos).copyWith(labelText: 'Estado (UF)'),
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
                prefixIcon: Icon(
                  Icons.search,
                  color: hintColor,
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  _error!,
                  style: TextStyle(
                    fontSize: 13,
                    color: accent,
                  ),
                ),
              ),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.42,
              ),
              child: _loadingMunicipios || _geocoding
                  ? Center(
                      child: CircularProgressIndicator(color: accent),
                    )
                  : _filteredMunicipios.isEmpty
                  ? Center(
                      child: Text(
                        'Nenhum município encontrado.',
                        style: TextStyle(
                          fontSize: 14,
                          color: muted,
                        ),
                      ),
                    )
                  : Container(
                      decoration: BoxDecoration(
                        color: listBg,
                        borderRadius: BorderRadius.circular(listRadius),
                        border: isIos
                            ? Border.all(
                                color: SoloForteSheetSkinIos.cardBorder,
                              )
                            : null,
                      ),
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: _filteredMunicipios.length,
                        separatorBuilder: (_, __) => Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Divider(
                            height: 1,
                            color: divider,
                          ),
                        ),
                        itemBuilder: (context, index) {
                          final municipio = _filteredMunicipios[index];
                          return Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                HapticFeedback.selectionClick();
                                _selectMunicipio(municipio);
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
                                    color: inputText,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
            ),
          ],
        ],
      ),
    );
  }
}
