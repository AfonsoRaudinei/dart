import 'package:flutter/material.dart';
import 'package:soloforte_app/core/contracts/i_client_lookup.dart';

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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C2E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF3A3A3C)),
      ),
      child: FutureBuilder<List<ClientSummary>>(
        future: clientsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SizedBox(
              height: 48,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Carregando clientes…',
                  style: TextStyle(color: Color(0xFF8E8E93)),
                ),
              ),
            );
          }

          final clients = snapshot.data ?? const <ClientSummary>[];
          final selected = clients
              .where((c) => c.id == selectedClient?.id)
              .cast<ClientSummary?>()
              .firstOrNull;

          return DropdownButtonHideUnderline(
            child: DropdownButton<ClientSummary>(
              isExpanded: true,
              value: selected,
              dropdownColor: const Color(0xFF2C2C2E),
              iconEnabledColor: Colors.white70,
              hint: const Text(
                'Selecionar cliente (opcional)',
                style: TextStyle(color: Color(0xFF8E8E93)),
              ),
              items: clients
                  .map(
                    (c) => DropdownMenuItem<ClientSummary>(
                      value: c,
                      child: Text(
                        c.name,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  )
                  .toList(),
              onChanged: onChanged,
            ),
          );
        },
      ),
    );
  }
}
