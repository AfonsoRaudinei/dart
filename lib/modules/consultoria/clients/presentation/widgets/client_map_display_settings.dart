import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:soloforte_app/core/state/map_state.dart';
import 'package:soloforte_app/core/ui/area_display_unit_chips.dart';

/// Preferências globais de label e unidade de área no mapa principal.
class ClientMapDisplaySettings extends ConsumerWidget {
  const ClientMapDisplaySettings({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final labelMode = ref.watch(talhaoMapLabelModeProvider);
    final modeNotifier = ref.read(talhaoMapLabelModeProvider.notifier);
    final showUnitChips =
        labelMode == TalhaoMapLabelMode.nameAndArea ||
        labelMode == TalhaoMapLabelMode.areaOnly;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Exibição no mapa',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _LabelModeChip(
              label: 'Nome+área',
              selected: labelMode == TalhaoMapLabelMode.nameAndArea,
              onTap: () => modeNotifier.setMode(TalhaoMapLabelMode.nameAndArea),
            ),
            _LabelModeChip(
              label: 'Nome',
              selected: labelMode == TalhaoMapLabelMode.nameOnly,
              onTap: () => modeNotifier.setMode(TalhaoMapLabelMode.nameOnly),
            ),
            _LabelModeChip(
              label: 'Área',
              selected: labelMode == TalhaoMapLabelMode.areaOnly,
              onTap: () => modeNotifier.setMode(TalhaoMapLabelMode.areaOnly),
            ),
            _LabelModeChip(
              label: 'Oculto',
              selected: labelMode == TalhaoMapLabelMode.hidden,
              onTap: () => modeNotifier.setMode(TalhaoMapLabelMode.hidden),
            ),
          ],
        ),
        if (showUnitChips) ...[
          const SizedBox(height: 12),
          Text(
            'Unidade de área',
            style: TextStyle(fontSize: 13, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          AreaDisplayUnitChips(
            selected: ref.watch(areaDisplayUnitProvider),
            onSelected: ref.read(areaDisplayUnitProvider.notifier).setUnit,
          ),
        ],
      ],
    );
  }
}

class _LabelModeChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _LabelModeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? const Color(0xFF248A3D) : Colors.grey[200],
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: selected ? Colors.white : Colors.black87,
            ),
          ),
        ),
      ),
    );
  }
}
