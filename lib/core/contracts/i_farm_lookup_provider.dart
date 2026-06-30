import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'i_farm_lookup.dart';

/// Provider da interface IFarmLookup.
/// A implementação concreta (FarmLookupAdapter de consultoria/clients/infra/)
/// deve ser registrada via ProviderScope.overrides em main.dart.
final iFarmLookupProvider = Provider<IFarmLookup>((ref) {
  throw UnimplementedError(
    'iFarmLookupProvider: registrar FarmLookupAdapter no ProviderScope '
    '(veja main.dart)',
  );
});
