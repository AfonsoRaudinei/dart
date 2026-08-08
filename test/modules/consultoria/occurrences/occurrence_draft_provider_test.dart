import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/modules/consultoria/occurrences/presentation/models/occurrence_form_draft.dart';
import 'package:soloforte_app/modules/consultoria/occurrences/presentation/providers/occurrence_draft_provider.dart';

void main() {
  group('occurrenceDraftProvider', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('persiste e lê rascunho pelo pinKey', () {
      const lat = -10.182346;
      const lng = -48.333988;
      final pinKey = OccurrenceFormDraft.pinKeyFor(lat, lng);
      const draft = OccurrenceFormDraft(
        description: 'Lagarta no milho',
        selectedCategoryValue: 'insetos',
      );

      container.read(occurrenceDraftProvider(pinKey).notifier).state = draft;

      expect(container.read(occurrenceDraftProvider(pinKey)), draft);
    });

    test('clearOccurrenceDraft remove rascunho do pin', () {
      const lat = -10.0;
      const lng = -48.0;
      final pinKey = OccurrenceFormDraft.pinKeyFor(lat, lng);

      container.read(occurrenceDraftProvider(pinKey).notifier).state =
          const OccurrenceFormDraft(description: 'temp');

      container.read(occurrenceDraftProvider(pinKey).notifier).state = null;

      expect(container.read(occurrenceDraftProvider(pinKey)), isNull);
    });

    test('pins diferentes mantêm rascunhos isolados', () {
      final pinA = OccurrenceFormDraft.pinKeyFor(-10.1, -48.1);
      final pinB = OccurrenceFormDraft.pinKeyFor(-10.2, -48.2);

      container.read(occurrenceDraftProvider(pinA).notifier).state =
          const OccurrenceFormDraft(description: 'Pin A');
      container.read(occurrenceDraftProvider(pinB).notifier).state =
          const OccurrenceFormDraft(description: 'Pin B');

      expect(container.read(occurrenceDraftProvider(pinA))?.description, 'Pin A');
      expect(container.read(occurrenceDraftProvider(pinB))?.description, 'Pin B');
    });
  });
}
