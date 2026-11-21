import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soloforte_app/core/contracts/i_visit_client_lookup.dart';
import 'package:soloforte_app/core/ui/sheets/solo_forte_sheet_visuals.dart';

Widget visitSheetFieldLabel(SoloForteSheetVisuals v, String label) {
  return Text(label, style: TextStyle(color: v.subtitleColor, fontSize: 12));
}

Widget visitSheetMutedLine(
  SoloForteSheetVisuals v,
  String text, {
  EdgeInsets? padding,
}) {
  return Padding(
    padding: padding ?? const EdgeInsets.symmetric(vertical: 12),
    child: Text(text, style: TextStyle(color: v.subtitleColor, fontSize: 14)),
  );
}

InputDecoration visitSheetSearchDecoration(
  SoloForteSheetVisuals v, {
  required String hintText,
}) {
  final radius = v.cardRadius;
  final border = v.cardBorder;
  return InputDecoration(
    hintText: hintText,
    hintStyle: TextStyle(color: v.subtitleColor, fontSize: 16),
    prefixIcon: Icon(Icons.search, color: v.subtitleColor),
    filled: true,
    fillColor: v.cardBackground,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(radius),
      borderSide: BorderSide(color: border),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(radius),
      borderSide: BorderSide(color: border),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(radius),
      borderSide: BorderSide(color: v.focusBorder, width: 1.5),
    ),
    disabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(radius),
      borderSide: BorderSide(color: border),
    ),
  );
}

const _comAcento = 'áàâãäéèêëíìîïóòôõöúùûüçñ';
const _semAcento = 'aaaaaeeeeiiiiooooouuuucn';

String _normalizeVisitSearch(String texto) {
  final buffer = StringBuffer();
  for (final rune in texto.toLowerCase().runes) {
    final char = String.fromCharCode(rune);
    final i = _comAcento.indexOf(char);
    buffer.write(i >= 0 ? _semAcento[i] : char);
  }
  return buffer.toString();
}

/// Nomes não vazios, sem diferenciar maiúsculas nem acentos.
/// Consulta vazia devolve todos, ordenados. Cada palavra da consulta
/// precisa aparecer no nome, em qualquer ordem.
List<VisitClientSummary> filterVisitClients(
  List<VisitClientSummary> clients,
  String query,
) {
  final tokens = _normalizeVisitSearch(
    query.trim(),
  ).split(RegExp(r'\s+')).where((token) => token.isNotEmpty).toList();
  final items = clients.where((client) {
    final name = _normalizeVisitSearch(client.name.trim());
    if (name.isEmpty) return false;
    if (tokens.isEmpty) return true;
    return tokens.every(name.contains);
  }).toList();
  items.sort(
    (a, b) =>
        _normalizeVisitSearch(a.name).compareTo(_normalizeVisitSearch(b.name)),
  );
  return items;
}

class VisitSheetProdutorPicker extends StatefulWidget {
  const VisitSheetProdutorPicker({
    super.key,
    required this.visuals,
    required this.clientsAsync,
    required this.searchController,
    required this.selectedClientId,
    required this.onSelectClient,
    required this.onClearClient,
    required this.onRetry,
  });

  final SoloForteSheetVisuals visuals;
  final AsyncValue<List<VisitClientSummary>> clientsAsync;
  final TextEditingController searchController;
  final String? selectedClientId;
  final ValueChanged<VisitClientSummary> onSelectClient;
  final VoidCallback onClearClient;
  final VoidCallback onRetry;

  @override
  State<VisitSheetProdutorPicker> createState() =>
      _VisitSheetProdutorPickerState();
}

class _VisitSheetProdutorPickerState extends State<VisitSheetProdutorPicker> {
  final _fieldKey = GlobalKey();
  final _focusNode = FocusNode();
  bool _nameSyncScheduled = false;

  @override
  void initState() {
    super.initState();
    _scheduleSelectedNameSync();
  }

  @override
  void didUpdateWidget(VisitSheetProdutorPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    _scheduleSelectedNameSync();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  VisitClientSummary? _clientById(String? id) {
    if (id == null) return null;
    final clients =
        widget.clientsAsync.valueOrNull ?? const <VisitClientSummary>[];
    for (final client in clients) {
      if (client.id == id) return client;
    }
    return null;
  }

  /// Com produtor já escolhido e o campo vazio, o nome entra no controller
  /// uma vez. Não apaga o que a pessoa está digitando.
  void _scheduleSelectedNameSync() {
    if (_nameSyncScheduled) return;
    final selected = _clientById(widget.selectedClientId);
    if (selected == null || selected.name.trim().isEmpty) return;
    if (widget.searchController.text.isNotEmpty) return;
    _nameSyncScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _nameSyncScheduled = false;
      if (!mounted) return;
      final current = _clientById(widget.selectedClientId);
      if (current == null || current.name.trim().isEmpty) return;
      if (widget.searchController.text.isNotEmpty) return;
      widget.searchController.text = current.name;
    });
  }

  Iterable<VisitClientSummary> _optionsFor(String text) {
    final selected = _clientById(widget.selectedClientId);
    if (selected != null && text == selected.name) {
      return const <VisitClientSummary>[];
    }
    if (text.trim().isEmpty) return const <VisitClientSummary>[];
    final clients =
        widget.clientsAsync.valueOrNull ?? const <VisitClientSummary>[];
    return filterVisitClients(clients, text);
  }

  double _fieldWidth() {
    final render = _fieldKey.currentContext?.findRenderObject();
    if (render is RenderBox && render.hasSize && render.size.width > 0) {
      return render.size.width;
    }
    return 280;
  }

  @override
  Widget build(BuildContext context) {
    final v = widget.visuals;
    return ListenableBuilder(
      listenable: widget.searchController,
      builder: (context, _) {
        final asyncClients = widget.clientsAsync;
        final clients =
            asyncClients.valueOrNull ?? const <VisitClientSummary>[];
        final initialLoad = asyncClients.isLoading && !asyncClients.hasValue;
        final loadFailed = asyncClients.hasError && !asyncClients.hasValue;
        final query = widget.searchController.text;
        final queryEmpty = query.trim().isEmpty;
        final selected = _clientById(widget.selectedClientId);
        final showingSelectedName = selected != null && query == selected.name;
        final matches = filterVisitClients(clients, query);
        final namedClients = filterVisitClients(clients, '');

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            visitSheetFieldLabel(v, 'Produtor'),
            const SizedBox(height: 6),
            RawAutocomplete<VisitClientSummary>(
              focusNode: _focusNode,
              textEditingController: widget.searchController,
              displayStringForOption: (client) => client.name,
              optionsBuilder: (value) => _optionsFor(value.text),
              onSelected: (client) {
                widget.onSelectClient(client);
                _focusNode.unfocus();
              },
              fieldViewBuilder: (context, controller, focusNode, onSubmit) {
                return TextField(
                  key: _fieldKey,
                  controller: controller,
                  focusNode: focusNode,
                  enabled: !initialLoad && !loadFailed,
                  style: TextStyle(color: v.titleColor, fontSize: 16),
                  textInputAction: TextInputAction.search,
                  autocorrect: false,
                  enableSuggestions: false,
                  onChanged: (text) {
                    final current = _clientById(widget.selectedClientId);
                    if (current != null && text != current.name) {
                      widget.onClearClient();
                    }
                  },
                  decoration: visitSheetSearchDecoration(
                    v,
                    hintText: initialLoad ? 'Carregando...' : 'Buscar produtor',
                  ),
                );
              },
              optionsViewBuilder: (context, onSelected, options) {
                if (_optionsFor(widget.searchController.text).isEmpty) {
                  return const SizedBox.shrink();
                }
                final width = _fieldWidth();
                final items = options.toList(growable: false);
                return Align(
                  alignment: Alignment.topLeft,
                  child: Material(
                    color: v.cardBackground,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      side: BorderSide(color: v.cardBorder),
                      borderRadius: BorderRadius.circular(v.cardRadius),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: 220,
                        minWidth: width,
                        maxWidth: width,
                      ),
                      child: ListView.builder(
                        padding: EdgeInsets.zero,
                        shrinkWrap: true,
                        itemCount: items.length,
                        itemBuilder: (context, index) {
                          final client = items[index];
                          return InkWell(
                            onTap: () => onSelected(client),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              child: Text(
                                client.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: v.titleColor,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                );
              },
            ),
            ..._statusLines(
              v,
              initialLoad: initialLoad,
              loadFailed: loadFailed,
              namedClients: namedClients,
              queryEmpty: queryEmpty,
              matches: matches,
              showingSelectedName: showingSelectedName,
            ),
          ],
        );
      },
    );
  }

  List<Widget> _statusLines(
    SoloForteSheetVisuals v, {
    required bool initialLoad,
    required bool loadFailed,
    required List<VisitClientSummary> namedClients,
    required bool queryEmpty,
    required List<VisitClientSummary> matches,
    required bool showingSelectedName,
  }) {
    if (loadFailed) {
      return [
        const SizedBox(height: 8),
        visitSheetMutedLine(
          v,
          'Não foi possível carregar os produtores.',
          padding: EdgeInsets.zero,
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            onPressed: widget.onRetry,
            style: TextButton.styleFrom(
              foregroundColor: v.titleColor,
              padding: const EdgeInsets.symmetric(vertical: 8),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              alignment: Alignment.centerLeft,
            ),
            child: const Text('Tentar de novo'),
          ),
        ),
      ];
    }
    if (initialLoad) return const [];
    if (namedClients.isEmpty) {
      return [
        const SizedBox(height: 8),
        visitSheetMutedLine(
          v,
          'Nenhum produtor encontrado',
          padding: EdgeInsets.zero,
        ),
      ];
    }
    if (queryEmpty && !showingSelectedName) {
      return [
        const SizedBox(height: 8),
        visitSheetMutedLine(
          v,
          'Digite para buscar o produtor',
          padding: EdgeInsets.zero,
        ),
      ];
    }
    if (!queryEmpty && matches.isEmpty && !showingSelectedName) {
      return [
        const SizedBox(height: 8),
        visitSheetMutedLine(
          v,
          'Nenhum produtor para esta busca',
          padding: EdgeInsets.zero,
        ),
      ];
    }
    return const [];
  }
}
