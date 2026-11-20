import 'package:flutter/material.dart';
import 'package:soloforte_app/core/ui/sheets/solo_forte_sheet_visuals.dart';
import '../../domain/repositories/i_clients_repository.dart';

/// Filtra itens por nome (case-insensitive) e ordena alfabeticamente.
@visibleForTesting
List<T> filterDrawingHierarchyByName<T>(
  List<T> items,
  String query,
  String Function(T item) nameOf,
) {
  final normalized = query.trim().toLowerCase();
  final filtered = items.where((item) {
    if (normalized.isEmpty) return true;
    return nameOf(item).toLowerCase().contains(normalized);
  }).toList();
  filtered.sort(
    (a, b) =>
        nameOf(a).toLowerCase().compareTo(nameOf(b).toLowerCase()),
  );
  return filtered;
}

@visibleForTesting
List<Client> filterDrawingClients(List<Client> clients, String query) {
  return filterDrawingHierarchyByName(clients, query, (c) => c.name);
}

@visibleForTesting
List<Farm> filterDrawingFarms(List<Farm> farms, String query) {
  return filterDrawingHierarchyByName(farms, query, (f) => f.name);
}

InputDecoration drawingHierarchySearchDecoration(
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

class DrawingHierarchyNameTile extends StatelessWidget {
  const DrawingHierarchyNameTile({
    super.key,
    required this.title,
    required this.selected,
    required this.visuals,
    required this.onTap,
    this.subtitle,
    this.leading,
    this.titleColor,
  });

  final String title;
  final String? subtitle;
  final bool selected;
  final SoloForteSheetVisuals visuals;
  final VoidCallback onTap;
  final Widget? leading;
  final Color? titleColor;

  @override
  Widget build(BuildContext context) {
    final radius = visuals.cardRadius;
    final accentTitle = titleColor ?? visuals.titleColor;
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
            child: Row(
              children: [
                if (leading != null) ...[
                  leading!,
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: subtitle == null
                      ? Text(
                          title,
                          style: TextStyle(
                            color: accentTitle,
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
                                color: accentTitle,
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Widget _drawingHierarchyMutedLine(
  SoloForteSheetVisuals v,
  String text, {
  EdgeInsets padding = EdgeInsets.zero,
}) {
  return Padding(
    padding: padding,
    child: Text(
      text,
      style: TextStyle(color: v.subtitleColor, fontSize: 14),
    ),
  );
}

/// Busca inline de cliente (padrão VisitSheet — sem lista completa com query vazia).
class DrawingClientSearchField extends StatelessWidget {
  const DrawingClientSearchField({
    super.key,
    required this.visuals,
    required this.clients,
    required this.searchController,
    required this.query,
    required this.selectedClient,
    required this.onQueryChanged,
    required this.onSelectClient,
    this.isLoading = false,
    this.enabled = true,
    this.clearable = false,
    this.onClearSelection,
    this.emptyHint = 'Digite para buscar…',
    this.searchHint = 'Buscar cliente',
    this.validator,
  });

  final SoloForteSheetVisuals visuals;
  final List<Client> clients;
  final TextEditingController searchController;
  final String query;
  final Client? selectedClient;
  final ValueChanged<String> onQueryChanged;
  final ValueChanged<Client> onSelectClient;
  final bool isLoading;
  final bool enabled;
  final bool clearable;
  final VoidCallback? onClearSelection;
  final String emptyHint;
  final String searchHint;
  final FormFieldValidator<Client?>? validator;

  List<Client> _displayClients() {
    final queryEmpty = query.trim().isEmpty;
    if (queryEmpty) {
      final id = selectedClient?.id;
      if (id == null) return const [];
      return clients.where((c) => c.id == id).toList();
    }
    return filterDrawingClients(clients, query);
  }

  Widget _buildClientBody({
    required void Function(Client client) onClientTap,
    VoidCallback? onClearTap,
  }) {
    final v = visuals;
    final queryEmpty = query.trim().isEmpty;
    final displayItems = _displayClients();
    final fieldEnabled = enabled && !isLoading;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: searchController,
          enabled: fieldEnabled,
          onChanged: onQueryChanged,
          style: TextStyle(color: v.titleColor, fontSize: 16),
          decoration: drawingHierarchySearchDecoration(
            v,
            hintText: isLoading ? 'Carregando...' : searchHint,
          ),
        ),
        const SizedBox(height: 8),
        if (isLoading)
          _drawingHierarchyMutedLine(v, 'Carregando...')
        else if (clients.isEmpty)
          _drawingHierarchyMutedLine(v, 'Nenhum cliente encontrado')
        else if (queryEmpty && selectedClient == null)
          _drawingHierarchyMutedLine(v, emptyHint)
        else if (!queryEmpty && displayItems.isEmpty)
          _drawingHierarchyMutedLine(v, 'Nenhum cliente para esta busca')
        else ...[
          if (clearable &&
              onClearTap != null &&
              (!queryEmpty || selectedClient != null))
            DrawingHierarchyNameTile(
              title: '— Nenhum —',
              selected: selectedClient == null,
              visuals: v,
              onTap: onClearTap,
            ),
          for (final client in displayItems)
            DrawingHierarchyNameTile(
              title: client.name,
              selected: client.id == selectedClient?.id,
              visuals: v,
              onTap: () => onClientTap(client),
            ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (validator == null) {
      return _buildClientBody(
        onClientTap: onSelectClient,
        onClearTap: onClearSelection,
      );
    }

    return FormField<Client?>(
      initialValue: selectedClient,
      validator: validator,
      builder: (state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildClientBody(
              onClientTap: (client) {
                state.didChange(client);
                onSelectClient(client);
              },
              onClearTap: onClearSelection == null
                  ? null
                  : () {
                      state.didChange(null);
                      onClearSelection!();
                    },
            ),
            if (state.hasError)
              Padding(
                padding: const EdgeInsets.only(top: 8, left: 12),
                child: Text(
                  state.errorText!,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                    fontSize: 12,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

/// Busca inline de fazenda; [onNewFarm] exibe tile **Nova Fazenda** com cliente ativo.
class DrawingFarmSearchField extends StatelessWidget {
  const DrawingFarmSearchField({
    super.key,
    required this.visuals,
    required this.farms,
    required this.searchController,
    required this.query,
    required this.selectedFarm,
    required this.clientSelected,
    required this.onQueryChanged,
    required this.onSelectFarm,
    this.isLoading = false,
    this.enabled = true,
    this.onNewFarm,
    this.clearable = false,
    this.onClearSelection,
    this.emptyHint = 'Digite para buscar…',
    this.searchHint = 'Buscar fazenda / grupo',
    this.validator,
  });

  final SoloForteSheetVisuals visuals;
  final List<Farm> farms;
  final TextEditingController searchController;
  final String query;
  final Farm? selectedFarm;
  final bool clientSelected;
  final ValueChanged<String> onQueryChanged;
  final ValueChanged<Farm> onSelectFarm;
  final bool isLoading;
  final bool enabled;
  final VoidCallback? onNewFarm;
  final bool clearable;
  final VoidCallback? onClearSelection;
  final String emptyHint;
  final String searchHint;
  final FormFieldValidator<Farm?>? validator;

  List<Farm> _displayFarms() {
    final queryEmpty = query.trim().isEmpty;
    if (queryEmpty) {
      final id = selectedFarm?.id;
      if (id == null) return const [];
      return farms.where((f) => f.id == id).toList();
    }
    return filterDrawingFarms(farms, query);
  }

  Widget _buildFarmBody({
    required void Function(Farm farm) onFarmTap,
    VoidCallback? onClearTap,
  }) {
    final v = visuals;
    final queryEmpty = query.trim().isEmpty;
    final displayItems = _displayFarms();
    final showNewFarm = clientSelected && onNewFarm != null;
    final fieldEnabled = enabled && clientSelected && !isLoading;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: searchController,
          enabled: fieldEnabled,
          onChanged: onQueryChanged,
          style: TextStyle(color: v.titleColor, fontSize: 16),
          decoration: drawingHierarchySearchDecoration(
            v,
            hintText: !clientSelected
                ? 'Selecione o cliente primeiro'
                : (isLoading ? 'Carregando...' : searchHint),
          ),
        ),
        const SizedBox(height: 8),
        if (!clientSelected)
          _drawingHierarchyMutedLine(v, 'Selecione o cliente primeiro')
        else if (isLoading)
          _drawingHierarchyMutedLine(v, 'Carregando...')
        else if (farms.isEmpty && !showNewFarm)
          _drawingHierarchyMutedLine(v, 'Nenhuma fazenda encontrada')
        else if (queryEmpty && selectedFarm == null && !showNewFarm)
          _drawingHierarchyMutedLine(v, emptyHint)
        else if (!queryEmpty && displayItems.isEmpty && !showNewFarm)
          _drawingHierarchyMutedLine(v, 'Nenhuma fazenda para esta busca')
        else ...[
          if (clearable &&
              onClearTap != null &&
              (!queryEmpty || selectedFarm != null))
            DrawingHierarchyNameTile(
              title: '— Nenhuma —',
              selected: selectedFarm == null,
              visuals: v,
              onTap: onClearTap,
            ),
          for (final farm in displayItems)
            DrawingHierarchyNameTile(
              title: farm.name,
              selected: farm.id == selectedFarm?.id,
              visuals: v,
              onTap: () => onFarmTap(farm),
            ),
          if (showNewFarm)
            DrawingHierarchyNameTile(
              title: 'Nova Fazenda',
              selected: false,
              visuals: v,
              titleColor: v.accent,
              leading: Icon(Icons.add_circle_outline, size: 18, color: v.accent),
              onTap: onNewFarm!,
            ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (validator == null) {
      return _buildFarmBody(
        onFarmTap: onSelectFarm,
        onClearTap: onClearSelection,
      );
    }

    return FormField<Farm?>(
      initialValue: selectedFarm,
      validator: validator,
      builder: (state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildFarmBody(
              onFarmTap: (farm) {
                state.didChange(farm);
                onSelectFarm(farm);
              },
              onClearTap: onClearSelection == null
                  ? null
                  : () {
                      state.didChange(null);
                      onClearSelection!();
                    },
            ),
            if (state.hasError)
              Padding(
                padding: const EdgeInsets.only(top: 8, left: 12),
                child: Text(
                  state.errorText!,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                    fontSize: 12,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}