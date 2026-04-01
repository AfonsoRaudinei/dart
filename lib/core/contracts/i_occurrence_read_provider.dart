// lib/core/contracts/i_occurrence_read_provider.dart
//
// Provider neutro de IOccurrenceRead.
// A implementação concreta deve ser registrada via ProviderScope.overrides.
// ADR-024

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'i_occurrence_read.dart';

final occurrenceReadProvider = Provider<IOccurrenceRead>((ref) {
  throw UnimplementedError(
    'occurrenceReadProvider: registrar OccurrenceReadAdapter no '
    'ProviderScope (veja main.dart e ADR-024)',
  );
});
