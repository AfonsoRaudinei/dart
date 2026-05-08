import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'i_user_location_lookup.dart';

/// Provider da interface IUserLocationLookup.
/// A implementação concreta (LocationLookupAdapter de dashboard/infra/)
/// deve ser registrada via ProviderScope.overrides em main.dart.
final userLocationLookupProvider = Provider<IUserLocationLookup>((ref) {
  throw UnimplementedError(
    'userLocationLookupProvider: registrar LocationLookupAdapter no ProviderScope '
    '(veja main.dart — padrão ADR-015)',
  );
});
