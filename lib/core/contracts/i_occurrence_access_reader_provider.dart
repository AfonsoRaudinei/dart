import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'i_occurrence_access_reader.dart';

final occurrenceAccessReaderProvider = Provider<IOccurrenceAccessReader>((ref) {
  return const _NoOccurrenceAccessReader();
});

/// `clients.id` ativos concedidos ao usuário autenticado (ADR-041).
final authorizedClientIdsProvider = FutureProvider<Set<String>>((ref) async {
  return ref.watch(occurrenceAccessReaderProvider).loadActiveClientIds();
});

class _NoOccurrenceAccessReader implements IOccurrenceAccessReader {
  const _NoOccurrenceAccessReader();

  @override
  Future<Set<String>> loadActiveClientIds() async => const {};
}
