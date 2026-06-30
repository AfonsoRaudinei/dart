import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soloforte_app/core/contracts/i_field_lookup.dart';

import 'package:soloforte_app/modules/drawing/infra/field_lookup_adapter.dart';
import 'package:soloforte_app/modules/drawing/presentation/providers/drawing_provider.dart';

final drawingFieldLookupProvider = Provider<FieldLookupAdapter>((ref) {
  final store = ref.watch(drawingLocalStoreProvider);
  return FieldLookupAdapter(store);
});

@Deprecated('Use core/contracts/i_field_lookup_provider.dart instead.')
final iFieldLookupProvider = Provider<IFieldLookup>((ref) {
  return ref.watch(drawingFieldLookupProvider);
});
