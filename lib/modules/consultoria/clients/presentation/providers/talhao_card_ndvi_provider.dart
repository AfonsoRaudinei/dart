import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soloforte_app/core/infra/preferences_service.dart';

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
