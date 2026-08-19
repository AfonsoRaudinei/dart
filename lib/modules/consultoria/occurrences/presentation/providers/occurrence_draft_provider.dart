import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/occurrence_form_draft.dart';

/// Rascunhos de criação keyed por pin do mapa (`OccurrenceFormDraft.pinKeyFor`).
///
/// **Sem `autoDispose`:** ninguém faz `watch` neste provider — só `read`. Com
/// autoDispose o rascunho era descartado no instante em que o sheet fechava,
/// que é justamente quando ele precisa sobreviver (REGRA-OCC-5). A limpeza é
/// explícita via [clearOccurrenceDraft] ao salvar ou descartar.
final occurrenceDraftProvider =
    StateProvider.family<OccurrenceFormDraft?, String>((ref, pinKey) => null);

void clearOccurrenceDraft(WidgetRef ref, double latitude, double longitude) {
  final pinKey = OccurrenceFormDraft.pinKeyFor(latitude, longitude);
  ref.read(occurrenceDraftProvider(pinKey).notifier).state = null;
}
