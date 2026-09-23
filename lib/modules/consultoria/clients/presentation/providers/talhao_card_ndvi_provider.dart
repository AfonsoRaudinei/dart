import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Mapa (false) ou NDVI (true) nos cards de talhão de uma fazenda.
/// Sessão apenas — não persiste. Um controle por fazenda.
final talhaoCardNdviEnabledProvider = StateProvider.autoDispose
    .family<bool, String>((ref, farmId) => false);

class TalhaoCardNdviToggle extends ConsumerWidget {
  const TalhaoCardNdviToggle({super.key, required this.farmId});

  final String farmId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enabled = ref.watch(talhaoCardNdviEnabledProvider(farmId));
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
      selected: {enabled},
      onSelectionChanged: (selection) {
        ref.read(talhaoCardNdviEnabledProvider(farmId).notifier).state =
            selection.first;
      },
    );
  }
}
