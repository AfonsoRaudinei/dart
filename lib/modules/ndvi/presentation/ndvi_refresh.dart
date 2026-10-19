import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soloforte_app/core/contracts/i_ndvi_field_refresh_provider.dart';

/// Limpa cache local, PNGs e dispara novo fetch remoto para o talhão.
Future<void> refreshNdviForField(WidgetRef ref, String fieldId) async {
  await ref.read(ndviFieldRefreshProvider).clearCacheAndReload(fieldId);
}
