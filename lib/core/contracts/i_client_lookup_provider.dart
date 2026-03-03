import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'i_client_lookup.dart';

/// Provider da interface IClientLookup.
/// A implementação concreta (ClientLookupAdapter de consultoria/clients/infra/)
/// deve ser registrada via ProviderScope.overrides em main.dart.
/// ADR-015.
final clientLookupProvider = Provider<IClientLookup>((ref) {
  throw UnimplementedError(
    'clientLookupProvider: registrar ClientLookupAdapter no ProviderScope '
    '(veja main.dart e ADR-015)',
  );
});
