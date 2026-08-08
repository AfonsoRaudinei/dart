import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/modules/consultoria/occurrences/presentation/models/occurrence_form_draft.dart';

void main() {
  group('OccurrenceFormDraft', () {
    test('pinKeyFor arredonda coordenadas com 6 casas', () {
      expect(
        OccurrenceFormDraft.pinKeyFor(-10.1823456789, -48.3339876543),
        '-10.182346_-48.333988',
      );
    });

    test('isEffectivelyEmpty ignora clientId sozinho', () {
      const draft = OccurrenceFormDraft(clientId: 'client-1');
      expect(draft.isEffectivelyEmpty, isTrue);
    });

    test('isEffectivelyEmpty detecta categoria selecionada', () {
      const draft = OccurrenceFormDraft(selectedCategoryValue: 'doenca');
      expect(draft.isEffectivelyEmpty, isFalse);
    });

    test('isEffectivelyEmpty detecta foto anexada', () {
      const draft = OccurrenceFormDraft(
        fotos: {'doenca': ['/tmp/photo.jpg']},
      );
      expect(draft.isEffectivelyEmpty, isFalse);
    });
  });
}
