import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'i_drawing_sync_quota.dart';

/// Implementação registrada em [main.dart] via adapter de planos.
final drawingSyncQuotaProvider = Provider<IDrawingSyncQuota>((ref) {
  throw UnimplementedError(
    'drawingSyncQuotaProvider: registrar adapter no ProviderScope.',
  );
});