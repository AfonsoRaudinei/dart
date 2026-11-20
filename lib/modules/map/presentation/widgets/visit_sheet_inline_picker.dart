import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soloforte_app/core/contracts/i_visit_client_lookup.dart';
import 'package:soloforte_app/core/ui/sheets/solo_forte_sheet_visuals.dart';

Widget visitSheetFieldLabel(SoloForteSheetVisuals v, String label) {
  return Text(
    label,
    style: TextStyle(color: v.subtitleColor, fontSize: 12),
  );
}

Widget visitSheetMutedLine(SoloForteSheetVisuals v, String text, {EdgeInsets? padding}) {
  return Padding(
    padding: padding ?? const EdgeInsets.symmetric(vertical: 12),
    child: Text(
      text,
      style: TextStyle(color: v.subtitleColor, fontSize: 14),
    ),
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

class VisitSheetNameTile extends StatelessWidget {
  const VisitSheetNameTile({
    super.key,
    required this.title,
    required this.selected,
    required this.visuals,
    required this.onTap,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final bool selected;
  final SoloForteSheetVisuals visuals;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final radius = visuals.cardRadius;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: visuals.cardBackground,
        borderRadius: BorderRadius.circular(radius),
        child: InkWell(
          borderRadius: BorderRadius.circular(radius),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(radius),
              border: Border.all(
                color: selected ? visuals.focusBorder : visuals.cardBorder,
                width: selected ? 1.5 : 1,
              ),
            ),
            child: subtitle == null
                ? Text(
                    title,
                    style: TextStyle(
                      color: visuals.titleColor,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: visuals.titleColor,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: TextStyle(
                          color: visuals.subtitleColor,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

List<VisitClientSummary> filterVisitClients(
  List<VisitClientSummary> clients,
  String query,
) {
  final normalized = query.trim().toLowerCase();
  final items = clients.where((client) {
    if (normalized.isEmpty) return true;
    return client.name.toLowerCase().contains(normalized);
  }).toList();
  items.sort(
    (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
  );
  return items;
}

class VisitSheetProdutorPicker extends StatelessWidget {
  const VisitSheetProdutorPicker({
    super.key,
    required this.visuals,
    required this.clientsAsync,
    required this.searchController,
    required this.clientQuery,
    required this.selectedClientId,
    required this.onQueryChanged,
    required this.onSelectClient,
  });

  final SoloForteSheetVisuals visuals;
  final AsyncValue<List<VisitClientSummary>> clientsAsync;
  final TextEditingController searchController;
  final String clientQuery;
  final String? selectedClientId;
  final ValueChanged<String> onQueryChanged;
  final ValueChanged<VisitClientSummary> onSelectClient;

  @override
  Widget build(BuildContext context) {
    final clients = clientsAsync.valueOrNull ?? [];
    final items = filterVisitClients(clients, clientQuery);
    final isLoading = clientsAsync.isLoading;
    final v = visuals;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        visitSheetFieldLabel(v, 'Produtor'),
        const SizedBox(height: 6),
        TextField(
          controller: searchController,
          enabled: !isLoading,
          onChanged: onQueryChanged,
          style: TextStyle(color: v.titleColor, fontSize: 16),
          decoration: visitSheetSearchDecoration(
            v,
            hintText: isLoading ? 'Carregando...' : 'Buscar produtor',
          ),
        ),
        const SizedBox(height: 8),
        if (isLoading)
          visitSheetMutedLine(v, 'Carregando...')
        else if (clients.isEmpty)
          visitSheetMutedLine(v, 'Nenhum produtor encontrado', padding: EdgeInsets.zero)
        else if (items.isEmpty)
          visitSheetMutedLine(
            v,
            'Nenhum produtor para esta busca',
            padding: EdgeInsets.zero,
          )
        else
          for (final client in items)
            VisitSheetNameTile(
              title: client.name,
              selected: client.id == selectedClientId,
              visuals: v,
              onTap: () => onSelectClient(client),
            ),
      ],
    );
  }
}