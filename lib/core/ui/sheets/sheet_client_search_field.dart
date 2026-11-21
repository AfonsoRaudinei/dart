import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../contracts/i_client_lookup.dart';
import 'solo_forte_sheet_visuals.dart';

/// Campo para achar um cliente digitando parte do nome (ou da cidade).
/// Substitui o dropdown, que ficava enorme com muitos clientes.
/// Visual dos sheets (sombra, raio, cores por tema). Só depende de
/// `core/contracts/` — sem import de módulos.
class SheetClientSearchField extends StatefulWidget {
  const SheetClientSearchField({
    super.key,
    required this.clients,
    required this.selectedClientId,
    required this.onChanged,
    this.hintText = 'Buscar cliente (opcional)',
  });

  final List<ClientSummary> clients;
  final String? selectedClientId;

  /// Cliente escolhido, ou `null` ao limpar/editar o texto.
  final ValueChanged<ClientSummary?> onChanged;
  final String hintText;

  @override
  State<SheetClientSearchField> createState() => _SheetClientSearchFieldState();
}

class _SheetClientSearchFieldState extends State<SheetClientSearchField> {
  // Largura da lista = largura do campo (LayoutBuilder não serve em dialogs).
  final _campoKey = GlobalKey();
  late final TextEditingController _controller;
  final _focusNode = FocusNode();

  ClientSummary? _porId(String? id) {
    if (id == null) return null;
    for (final c in widget.clients) {
      if (c.id == id) return c;
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: _porId(widget.selectedClientId)?.name ?? '',
    );
  }

  @override
  void didUpdateWidget(covariant SheetClientSearchField oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Seleção vinda de fora (ex.: pré-preenchimento): espelha no texto.
    final externo = _porId(widget.selectedClientId);
    if (widget.selectedClientId != oldWidget.selectedClientId &&
        externo != null &&
        _controller.text != externo.name) {
      _controller.text = externo.name;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final v = SoloForteSheetVisuals.of(context);
    return RawAutocomplete<ClientSummary>(
      textEditingController: _controller,
      focusNode: _focusNode,
      displayStringForOption: (c) => c.name,
      optionsBuilder: (value) =>
          filterClientsByQuery(widget.clients, value.text),
      onSelected: (c) {
        widget.onChanged(c);
        _focusNode.unfocus();
      },
      fieldViewBuilder: (context, controller, focusNode, _) {
        return ListenableBuilder(
          listenable: controller,
          builder: (context, _) {
            final texto = controller.text;
            final semResultado =
                texto.trim().isNotEmpty &&
                widget.selectedClientId == null &&
                filterClientsByQuery(widget.clients, texto).isEmpty;
            return Container(
              key: _campoKey,
              decoration: BoxDecoration(
                color: v.cardBackground,
                borderRadius: BorderRadius.circular(v.cardRadius),
                border: Border.all(color: v.cardBorder),
                boxShadow: v.cardShadows,
              ),
              child: TextField(
                key: const Key('sheet_client_search'),
                controller: controller,
                focusNode: focusNode,
                textInputAction: TextInputAction.search,
                textCapitalization: TextCapitalization.words,
                autocorrect: false,
                enableSuggestions: false,
                style: TextStyle(color: v.onSheetPrimary, fontSize: 14),
                onChanged: (t) {
                  final atual = _porId(widget.selectedClientId);
                  if (atual != null && atual.name != t) widget.onChanged(null);
                },
                decoration: InputDecoration(
                  isDense: true,
                  filled: false,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  disabledBorder: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 14,
                  ),
                  hintText: widget.hintText,
                  hintStyle: TextStyle(color: v.subtitleColor, fontSize: 14),
                  helperText: semResultado ? 'Nenhum cliente encontrado' : null,
                  helperStyle: TextStyle(color: v.subtitleColor, fontSize: 12),
                  prefixIcon: Icon(
                    CupertinoIcons.search,
                    size: 18,
                    color: v.subtitleColor,
                  ),
                  prefixIconConstraints: const BoxConstraints(minWidth: 38),
                  suffixIcon: texto.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Limpar',
                          icon: Icon(
                            CupertinoIcons.xmark_circle_fill,
                            size: 18,
                            color: v.subtitleColor.withValues(alpha: 0.6),
                          ),
                          onPressed: () {
                            controller.clear();
                            widget.onChanged(null);
                            focusNode.requestFocus();
                          },
                        ),
                ),
              ),
            );
          },
        );
      },
      optionsViewBuilder: (context, onSelected, options) {
        final largura =
            (_campoKey.currentContext?.findRenderObject() as RenderBox?)
                ?.size
                .width ??
            280.0;
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 6,
            color: v.cardBackground,
            shadowColor: Colors.black.withValues(alpha: 0.25),
            borderRadius: BorderRadius.circular(v.cardRadius),
            clipBehavior: Clip.antiAlias,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: 220,
                minWidth: largura,
                maxWidth: largura,
              ),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: options.length,
                itemBuilder: (context, i) {
                  final c = options.elementAt(i);
                  return InkWell(
                    onTap: () => onSelected(c),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 11,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            c.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: v.onSheetPrimary,
                              fontSize: 14,
                            ),
                          ),
                          if (c.city != null && c.city!.isNotEmpty)
                            Text(
                              c.city!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: v.subtitleColor,
                                fontSize: 12,
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Filtra [clients] por [query], sem diferenciar maiúsculas nem acentos.
/// Busca no nome e na cidade. Consulta vazia devolve todos.
List<ClientSummary> filterClientsByQuery(
  List<ClientSummary> clients,
  String query,
) {
  final termo = _normalizar(query.trim());
  if (termo.isEmpty) return clients;
  return clients
      .where(
        (c) =>
            _normalizar(c.name).contains(termo) ||
            _normalizar(c.city ?? '').contains(termo),
      )
      .toList();
}

const _comAcento = 'áàâãäéèêëíìîïóòôõöúùûüçñ';
const _semAcento = 'aaaaaeeeeiiiiooooouuuucn';

String _normalizar(String texto) {
  final buffer = StringBuffer();
  for (final rune in texto.toLowerCase().runes) {
    final char = String.fromCharCode(rune);
    final i = _comAcento.indexOf(char);
    buffer.write(i >= 0 ? _semAcento[i] : char);
  }
  return buffer.toString();
}
