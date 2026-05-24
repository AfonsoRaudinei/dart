import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'i_field_lookup.dart';

/// Provider neutro de IFieldLookup.
/// A implementação concreta deve ser registrada via ProviderScope.overrides.
final iFieldLookupProvider = Provider<IFieldLookup>((ref) {
  throw UnimplementedError(
    'iFieldLookupProvider: registrar FieldLookupAdapter no ProviderScope.',
  );
});
