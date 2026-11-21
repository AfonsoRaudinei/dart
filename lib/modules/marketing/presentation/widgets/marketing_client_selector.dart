import 'package:flutter/material.dart';
import 'package:soloforte_app/core/ui/sheets/sheet_client_search_field.dart';
import 'package:soloforte_app/core/ui/sheets/solo_forte_sheet_visuals.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/contracts/i_client_lookup.dart';
import '../../../../core/contracts/i_client_lookup_provider.dart';

/// Busca opcional de cliente (digitando) para formulários de marketing.
/// Depende apenas de core/contracts/ — zero import de consultoria/ ou agenda/.
class MarketingClientSelector extends ConsumerWidget {
  final String? selectedClientId;
  final ValueChanged<ClientSummary?> onChanged;

  const MarketingClientSelector({
    super.key,
    required this.selectedClientId,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clientsAsync = ref.watch(_marketingClientsAtivosProvider);
    final muted = SoloForteSheetVisuals.of(context).subtitleColor;

    Widget mensagem(String texto) => SizedBox(
      height: 48,
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(texto, style: TextStyle(color: muted, fontSize: 14)),
      ),
    );

    return clientsAsync.when(
      loading: () => mensagem('Carregando clientes…'),
      error: (_, __) => mensagem('Erro ao carregar clientes'),
      data: (clients) => SheetClientSearchField(
        clients: clients,
        selectedClientId: selectedClientId,
        onChanged: onChanged,
      ),
    );
  }
}

/// Provider interno — lista apenas ativos via IClientLookup de core/contracts/.
/// Não exportado — uso exclusivo de widgets em marketing/.
final _marketingClientsAtivosProvider =
    FutureProvider.autoDispose<List<ClientSummary>>(
      (ref) => ref.watch(clientLookupProvider).listAtivos(),
    );
