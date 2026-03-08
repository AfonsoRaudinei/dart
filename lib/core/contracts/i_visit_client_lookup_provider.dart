import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'i_visit_client_lookup.dart';

/// Provider da interface IVisitClientLookup.
/// A implementação concreta deve ser registrada via ProviderScope.overrides.
final visitClientLookupProvider = Provider<IVisitClientLookup>((ref) {
  throw UnimplementedError(
    'visitClientLookupProvider: registrar VisitClientLookupAdapter no '
    'ProviderScope (veja main.dart e ADR-020)',
  );
});
