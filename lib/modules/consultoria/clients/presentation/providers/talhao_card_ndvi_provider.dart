import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soloforte_app/core/infra/preferences_service.dart';

import 'field_providers.dart';

String _talhaoCardNdviPrefsKey(String fieldId) =>
    'consultoria_talhao_card_ndvi_$fieldId';

/// Mapa (false) ou NDVI (true) no card de um talhão — persiste por [fieldId].
final talhaoCardNdviEnabledProvider = StateProvider.family<bool, String>(
  (ref, fieldId) {
    return ref.read(preferencesServiceProvider).getBool(
          _talhaoCardNdviPrefsKey(fieldId),
        ) ??
        false;
  },
);

void setTalhaoCardNdviEnabled(WidgetRef ref, String fieldId, bool enabled) {
  ref.read(talhaoCardNdviEnabledProvider(fieldId).notifier).state = enabled;
  ref.read(preferencesServiceProvider).setBool(
        _talhaoCardNdviPrefsKey(fieldId),
        enabled,
      );
}

void setTalhaoCardNdviEnabledForFarm(
  WidgetRef ref, {
  required Iterable<String> fieldIds,
  required bool enabled,
}) {
  for (final fieldId in fieldIds) {
    setTalhaoCardNdviEnabled(ref, fieldId, enabled);
  }
}

/// Atalho por fazenda: aplica a todos os talhões; seleção vazia quando há modos mistos.
class TalhaoCardNdviToggle extends ConsumerWidget {
  const TalhaoCardNdviToggle({super.key, required this.farmId});

  final String farmId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fields = ref.watch(farmLinkedFieldsProvider(farmId)).asData?.value;
    final fieldIds = fields?.map((f) => f.id).toList() ?? const <String>[];

    if (fieldIds.isEmpty) {
      return const SizedBox.shrink();
    }

    final modes = fieldIds
        .map((id) => ref.watch(talhaoCardNdviEnabledProvider(id)))
        .toList();
    final allNdvi = modes.every((m) => m);
    final allMap = modes.every((m) => !m);

    final Set<bool> selected;
    if (allNdvi) {
      selected = {true};
    } else if (allMap) {
      selected = {false};
    } else {
      selected = {};
    }

    return SegmentedButton<bool>(
      showSelectedIcon: false,
      style: const ButtonStyle(
        visualDensity: VisualDensity.compact,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      segments: const [
        ButtonSegment<bool>(value: false, label: Text('Mapa')),
        ButtonSegment<bool>(value: true, label: Text('NDVI')),
      ],
      selected: selected,
      onSelectionChanged: (selection) {
        setTalhaoCardNdviEnabledForFarm(
          ref,
          fieldIds: fieldIds,
          enabled: selection.first,
        );
      },
    );
  }
}

/// Alterna mapa/NDVI só neste talhão (ícone na barra de ações do card).
class TalhaoCardNdviModeIconButton extends ConsumerWidget {
  const TalhaoCardNdviModeIconButton({super.key, required this.fieldId});

  final String fieldId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ndvi = ref.watch(talhaoCardNdviEnabledProvider(fieldId));
    return IconButton(
      tooltip: ndvi ? 'Ver mapa no card' : 'Ver NDVI no card',
      icon: Icon(ndvi ? Icons.map_outlined : Icons.grass_outlined, size: 20),
      onPressed: () => setTalhaoCardNdviEnabled(ref, fieldId, !ndvi),
    );
  }
}
