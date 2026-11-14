import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'i_occurrence_access_reader.dart';

final occurrenceAccessReaderProvider = Provider<IOccurrenceAccessReader>((ref) {
  return const _NoOccurrenceAccessReader();
});

/// Pin Bronze do consultor: vínculo ativo e consultor Bronze+ (produtor sem plano ok).
final authorizedClientIdsProvider = FutureProvider<Set<String>>((ref) async {
  return ref.watch(occurrenceAccessReaderProvider).loadBronzePinClientIds();
});

/// Ocorrências compartilhadas: Bronze+ do consultor e do produtor.
final occurrenceShareClientIdsProvider = FutureProvider<Set<String>>((
  ref,
) async {
  return ref.watch(occurrenceAccessReaderProvider).loadActiveClientIds();
});

/// Relatórios do convite (`share_reports`), sem gate de plano.
final linkedReportClientIdsProvider = FutureProvider<Set<String>>((ref) async {
  return ref.watch(occurrenceAccessReaderProvider).loadReportClientIds();
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
  Future<Set<String>> loadLinkedClientIds() async => const {};

  @override
  Future<Set<String>> loadBronzePinClientIds() async => const {};

  @override
  Future<Set<String>> loadReportClientIds() async => const {};

  @override
  Future<Set<String>> loadActiveFieldIdsForOccurrences() async => const {};

  @override
  Future<Map<String, String>> loadLinkedClientNames() async => const {};
}
