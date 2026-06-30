import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'i_visit_session_lookup.dart';

/// Provider da interface IVisitSessionLookup.
/// A implementação concreta deve ser registrada via ProviderScope.overrides.
final visitSessionLookupProvider = Provider<IVisitSessionLookup>((ref) {
  throw UnimplementedError(
    'visitSessionLookupProvider: registrar VisitSessionLookupAdapter no '
    'ProviderScope (veja main.dart e ADR-020)',
  );
});
