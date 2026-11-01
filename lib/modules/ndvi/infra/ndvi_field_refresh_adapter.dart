import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/contracts/i_ndvi_field_refresh.dart';
import '../../../core/state/map_ndvi_overlay.dart';
import '../presentation/providers/ndvi_providers.dart';

class NdviFieldRefreshAdapter implements INdviFieldRefresh {
  NdviFieldRefreshAdapter(this._ref);

  final Ref _ref;

  @override
  Future<void> clearCacheAndReload(String fieldId) async {
    _ref.read(mapNdviRetainedSummaryProvider.notifier).keep(null);
    _ref.read(mapNdviOverlayDateErrorProvider.notifier).report(null);
    await _ref.read(ndviRepositoryProvider).deleteByFieldId(fieldId);
    _ref.invalidate(ndviImagesProvider(fieldId));
    _ref.invalidate(ndviLatestProvider(fieldId));
    _ref.invalidate(ndviEnsureCurrentDateProvider(fieldId));
    _ref.invalidate(mapNdviOverlaySummaryProvider);
  }
}
