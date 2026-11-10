import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'i_occurrence_access_reader.dart';

final occurrenceAccessReaderProvider = Provider<IOccurrenceAccessReader>((ref) {
  return const _NoOccurrenceAccessReader();
});

/// `clients.id` ativos concedidos ao usuário autenticado (ADR-041).
final authorizedClientIdsProvider = FutureProvider<Set<String>>((ref) async {
  return ref.watch(occurrenceAccessReaderProvider).loadActiveClientIds();
});

/// Nome do cliente vinculado, usado quando o SQLite local do produtor
/// não tem a ficha do consultor.
final linkedClientNamesProvider = FutureProvider<Map<String, String>>((
  ref,
) async {
  return ref.watch(occurrenceAccessReaderProvider).loadLinkedClientNames();
});

class _NoOccurrenceAccessReader implements IOccurrenceAccessReader {
  const _NoOccurrenceAccessReader();

  @override
  Future<Set<String>> loadActiveClientIds() async => const {};

  @override
  Future<Map<String, String>> loadLinkedClientNames() async => const {};
}
