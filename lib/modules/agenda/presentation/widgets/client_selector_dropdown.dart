import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soloforte_app/core/contracts/i_client_lookup.dart';
import 'package:soloforte_app/core/contracts/i_client_lookup_provider.dart';

/// Dropdown de seleção de cliente para uso interno em agenda/.
/// Depende apenas de core/contracts/ — zero import de consultoria/.
/// ADR-015: usa IClientLookup da zona neutra.
class ClientSelectorDropdown extends ConsumerWidget {
  final String? selectedClientId;
  final ValueChanged<String?> onChanged;
  final bool obrigatorio;

  const ClientSelectorDropdown({
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
      data: (clients) => DropdownButtonFormField<String>(
        initialValue: selectedClientId,
        decoration: InputDecoration(
          labelText: obrigatorio ? 'Cliente *' : 'Cliente',
          border: const OutlineInputBorder(),
          prefixIcon: const Icon(Icons.person_outline),
        ),
        hint: const Text('Selecionar cliente'),
        items: clients
            .map(
              (c) => DropdownMenuItem<String>(
                value: c.id,
                child: Text(c.name, overflow: TextOverflow.ellipsis),
              ),
            )
            .toList(),
        onChanged: onChanged,
        validator: obrigatorio
            ? (value) {
                if (value == null || value.isEmpty) {
                  return 'Selecione um cliente';
                }
                return null;
              }
            : null,
      ),
    );
  }
}

/// Provider interno — lista apenas ativos via IClientLookup de core/contracts/.
/// Não exportado — uso exclusivo de widgets em agenda/.
final _clientsAtivosProvider = FutureProvider.autoDispose<List<ClientSummary>>(
  (ref) => ref.watch(clientLookupProvider).listAtivos(),
);
