import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'i_active_visit_context_lookup.dart';

/// Provider neutro do contexto herdado por ações abertas durante uma visita.
final activeVisitContextLookupProvider = Provider<IActiveVisitContextLookup>((
  ref,
) {
  throw UnimplementedError(
    'activeVisitContextLookupProvider: registrar '
    'ActiveVisitContextLookupAdapter no ProviderScope.',
  );
});
