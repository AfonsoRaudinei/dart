import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soloforte_app/core/contracts/i_ndvi_field_presenter_provider.dart';
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
  const TalhaoCardNdviModeIconButton({
    super.key,
    required this.fieldId,
    this.fieldName,
    this.areaHa,
    this.onAfterSheetClosed,
  });

  final String fieldId;
  final String? fieldName;
  final double? areaHa;
  final VoidCallback? onAfterSheetClosed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ndvi = ref.watch(talhaoCardNdviEnabledProvider(fieldId));
    return IconButton(
      tooltip: ndvi ? 'Ver mapa no card' : 'Ver NDVI no card',
      icon: Icon(ndvi ? Icons.map_outlined : Icons.grass_outlined, size: 20),
      onPressed: () async {
        if (!ndvi) {
          setTalhaoCardNdviEnabled(ref, fieldId, true);
          if (fieldName != null) {
            await ref.read(ndviFieldPresenterProvider).showTalhaoSheet(
                  context,
                  fieldId: fieldId,
                  fieldName: fieldName!,
                  areaHa: areaHa,
                );
            onAfterSheetClosed?.call();
          }
        } else {
          setTalhaoCardNdviEnabled(ref, fieldId, false);
        }
      },
    );
  }
}
