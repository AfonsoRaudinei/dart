import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/contracts/i_ndvi_field_refresh.dart';
import '../presentation/providers/ndvi_providers.dart';

class NdviFieldRefreshAdapter implements INdviFieldRefresh {
  NdviFieldRefreshAdapter(this._ref);

  final Ref _ref;

  @override
  Future<void> clearCacheAndReload(String fieldId) async {
    await _ref.read(ndviRepositoryProvider).deleteByFieldId(fieldId);
    _ref.invalidate(ndviImagesProvider(fieldId));
    _ref.invalidate(ndviLatestProvider(fieldId));
    _ref.invalidate(ndviEnsureCurrentDateProvider(fieldId));
  }
}
