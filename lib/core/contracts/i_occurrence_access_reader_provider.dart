import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'i_occurrence_access_reader.dart';

final occurrenceAccessReaderProvider = Provider<IOccurrenceAccessReader>((ref) {
  return const _NoOccurrenceAccessReader();
});

class _NoOccurrenceAccessReader implements IOccurrenceAccessReader {
  const _NoOccurrenceAccessReader();

  @override
  Future<Set<String>> loadActiveClientIds() async => const {};
}
