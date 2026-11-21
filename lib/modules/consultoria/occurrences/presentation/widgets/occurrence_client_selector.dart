import 'package:flutter/material.dart';
import 'package:soloforte_app/core/contracts/i_client_lookup.dart';
import 'package:soloforte_app/core/ui/sheets/sheet_client_search_field.dart';
import 'package:soloforte_app/core/ui/sheets/solo_forte_sheet_visuals.dart';

/// Busca de cliente da ocorrência: digita-se parte do nome e a lista filtra.
class OccurrenceClientSelector extends StatelessWidget {
  final Future<List<ClientSummary>> clientsFuture;
  final ClientSummary? selectedClient;
  final ValueChanged<ClientSummary?> onChanged;

  const OccurrenceClientSelector({
    super.key,
    required this.clientsFuture,
    required this.selectedClient,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final muted = SoloForteSheetVisuals.of(context).subtitleColor;
    return FutureBuilder<List<ClientSummary>>(
      future: clientsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return SizedBox(
            height: 48,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Carregando clientes…',
                style: TextStyle(color: muted, fontSize: 14),
              ),
            ),
          );
        }
        return SheetClientSearchField(
          clients: snapshot.data ?? const <ClientSummary>[],
          selectedClientId: selectedClient?.id,
          onChanged: onChanged,
        );
      },
    );
  }
}
