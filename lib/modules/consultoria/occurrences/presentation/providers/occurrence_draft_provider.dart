import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/occurrence_form_draft.dart';

/// Rascunhos de criação keyed por pin do mapa (`OccurrenceFormDraft.pinKeyFor`).
final occurrenceDraftProvider = StateProvider.autoDispose
    .family<OccurrenceFormDraft?, String>((ref, pinKey) => null);

void clearOccurrenceDraft(WidgetRef ref, double latitude, double longitude) {
  final pinKey = OccurrenceFormDraft.pinKeyFor(latitude, longitude);
  ref.read(occurrenceDraftProvider(pinKey).notifier).state = null;
}
