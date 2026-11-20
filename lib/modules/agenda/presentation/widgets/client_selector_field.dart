import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soloforte_app/core/contracts/i_client_lookup.dart';
import 'package:soloforte_app/core/contracts/i_client_lookup_provider.dart';

/// Campo de busca de cliente para uso interno em agenda/.
/// Digita-se parte do nome (ou da cidade) e a lista é filtrada; tocar em
/// uma sugestão seleciona o cliente. Depende apenas de core/contracts/ —
/// zero import de consultoria/. ADR-015: usa IClientLookup da zona neutra.
class ClientSelectorField extends ConsumerWidget {
  final String? selectedClientId;
  final ValueChanged<String?> onChanged;
  final bool obrigatorio;

  const ClientSelectorField({
    super.key,
    required this.onChanged,
    this.selectedClientId,
    this.obrigatorio = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clientsAsync = ref.watch(_clientsAtivosProvider);

    return clientsAsync.when(
      loading: () => const LinearProgressIndicator(),
      error: (e, _) => Text(
        'Erro ao carregar clientes: $e',
        style: const TextStyle(color: Colors.red),
      ),
      data: (clients) => _ClientSearchField(
        clients: clients,
        selectedClientId: selectedClientId,
        onChanged: onChanged,
        obrigatorio: obrigatorio,
      ),
    );
  }
}

/// Filtra [clients] por [query], sem diferenciar maiúsculas nem acentos.
/// Busca no nome e na cidade. Consulta vazia devolve todos.
List<ClientSummary> filtrarClientes(List<ClientSummary> clients, String query) {
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

class _ClientSearchField extends StatefulWidget {
  const _ClientSearchField({
    required this.clients,
    required this.selectedClientId,
    required this.onChanged,
    required this.obrigatorio,
  });

  final List<ClientSummary> clients;
  final String? selectedClientId;
  final ValueChanged<String?> onChanged;
  final bool obrigatorio;

  @override
  State<_ClientSearchField> createState() => _ClientSearchFieldState();
}

class _ClientSearchFieldState extends State<_ClientSearchField> {
  // LayoutBuilder não funciona dentro do AlertDialog (que mede dimensões
  // intrínsecas), então a largura da lista vem da medição do próprio campo.
  final _campoKey = GlobalKey();

  List<ClientSummary> get clients => widget.clients;
  String? get selectedClientId => widget.selectedClientId;
  ValueChanged<String?> get onChanged => widget.onChanged;
  bool get obrigatorio => widget.obrigatorio;

  ClientSummary? _porId(String? id) {
    if (id == null) return null;
    for (final c in clients) {
      if (c.id == id) return c;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return FormField<String>(
      initialValue: selectedClientId,
      validator: obrigatorio
          ? (value) => (value == null || value.isEmpty)
                ? 'Busque e selecione um cliente'
                : null
          : null,
      builder: (state) {
        return KeyedSubtree(
          key: _campoKey,
          child: Builder(
            builder: (context) {
              return RawAutocomplete<ClientSummary>(
                initialValue: TextEditingValue(
                  text: _porId(selectedClientId)?.name ?? '',
                ),
                displayStringForOption: (c) => c.name,
                optionsBuilder: (value) => filtrarClientes(clients, value.text),
                onSelected: (c) {
                  state.didChange(c.id);
                  onChanged(c.id);
                  FocusScope.of(context).unfocus();
                },
                fieldViewBuilder: (context, controller, focusNode, onSubmit) {
                  return ListenableBuilder(
                    listenable: controller,
                    builder: (context, _) {
                      final texto = controller.text;
                      final semResultado =
                          state.value == null &&
                          texto.trim().isNotEmpty &&
                          filtrarClientes(clients, texto).isEmpty;
                      return TextField(
                        key: const Key('agenda_cliente_busca'),
                        controller: controller,
                        focusNode: focusNode,
                        textInputAction: TextInputAction.search,
                        textCapitalization: TextCapitalization.words,
                        autocorrect: false,
                        enableSuggestions: false,
                        onChanged: (t) {
                          final atual = _porId(state.value);
                          if (atual != null && atual.name != t) {
                            state.didChange(null);
                            onChanged(null);
                          }
                        },
                        decoration: InputDecoration(
                          labelText: obrigatorio ? 'Cliente *' : 'Cliente',
                          hintText: 'Buscar cliente pelo nome',
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: texto.isEmpty
                              ? null
                              : IconButton(
                                  tooltip: 'Limpar',
                                  icon: const Icon(Icons.close),
                                  onPressed: () {
                                    controller.clear();
                                    state.didChange(null);
                                    onChanged(null);
                                    focusNode.requestFocus();
                                  },
                                ),
                          helperText: semResultado
                              ? 'Nenhum cliente encontrado'
                              : null,
                          errorText: state.errorText,
                        ),
                      );
                    },
                  );
                },
                optionsViewBuilder: (context, onSelected, options) {
                  final larguraCampo =
                      (_campoKey.currentContext?.findRenderObject()
                              as RenderBox?)
                          ?.size
                          .width ??
                      280.0;
                  return Align(
                    alignment: Alignment.topLeft,
                    child: Material(
                      elevation: 4,
                      borderRadius: BorderRadius.circular(8),
                      clipBehavior: Clip.antiAlias,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxHeight: 220,
                          maxWidth: larguraCampo,
                          minWidth: larguraCampo,
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
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      c.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    if (c.city != null && c.city!.isNotEmpty)
                                      Text(
                                        c.city!,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(color: Colors.grey[600]),
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
            },
          ),
        );
      },
    );
  }
}

/// Provider interno — lista apenas ativos via IClientLookup de core/contracts/.
/// Não exportado — uso exclusivo de widgets em agenda/.
final _clientsAtivosProvider = FutureProvider.autoDispose<List<ClientSummary>>(
  (ref) => ref.watch(clientLookupProvider).listAtivos(),
);
