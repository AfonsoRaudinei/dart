import 'package:flutter/material.dart';
import 'package:soloforte_app/core/ui/sheets/solo_forte_sheet_visuals.dart';
import 'package:soloforte_app/core/contracts/i_client_lookup.dart';
import 'package:soloforte_app/modules/consultoria/occurrences/presentation/widgets/occurrence_form_widgets.dart';

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
    final v = SoloForteSheetVisuals.of(context);
    final isIos = occurrenceFormIsIos(context);
    final surface = v.cardBackground;
    final border = v.cardBorder;
    final muted = v.subtitleColor;
    final title = v.onSheetPrimary;
    final iconColor = isIos ? v.iconStroke : v.subtitleColor;
    final radius = v.cardRadius;
    final dropdownBg = isIos ? v.sheetBackground : v.cardBackground;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: border),
      ),
      child: FutureBuilder<List<ClientSummary>>(
        future: clientsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return SizedBox(
              height: 48,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Carregando clientes…',
                  style: TextStyle(color: muted),
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
              dropdownColor: dropdownBg,
              iconEnabledColor: iconColor,
              hint: Text(
                'Selecionar cliente (opcional)',
                style: TextStyle(color: muted),
              ),
              items: clients
                  .map(
                    (c) => DropdownMenuItem<ClientSummary>(
                      value: c,
                      child: Text(
                        c.name,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: title),
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
