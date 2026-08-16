import 'package:flutter/material.dart';
import 'package:soloforte_app/core/contracts/i_client_lookup.dart';
import 'package:soloforte_app/core/ui/sheets/sheet_tokens.dart';
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
    final isIos = occurrenceFormIsIos(context);
    final surface = isIos
        ? SoloForteSheetSkinIos.cardBackground
        : const Color(0xFF2C2C2E);
    final border = isIos
        ? SoloForteSheetSkinIos.cardBorder
        : const Color(0xFF3A3A3C);
    final muted = isIos
        ? SoloForteSheetSkinIos.subtitleColor
        : const Color(0xFF8E8E93);
    final title =
        isIos ? SoloForteSheetSkinIos.titleColor : Colors.white;
    final iconColor =
        isIos ? SoloForteSheetSkinIos.iconStroke : Colors.white70;
    final radius = isIos ? SoloForteSheetSkinIos.cardRadius : 12.0;
    final dropdownBg =
        isIos ? SoloForteSheetSkinIos.background : const Color(0xFF2C2C2E);

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
