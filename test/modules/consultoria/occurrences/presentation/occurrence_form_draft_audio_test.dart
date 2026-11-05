import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/modules/consultoria/occurrences/presentation/models/occurrence_form_draft.dart';

void main() {
  test('OccurrenceFormDraft considera áudio como conteúdo', () {
    const draft = OccurrenceFormDraft(
      audioPath: 'media/audio_test.m4a',
      audioDurationSec: 8,
    );
    expect(draft.isEffectivelyEmpty, isFalse);
  });

  test('OccurrenceFormDraft copyWith clearAudioPath', () {
    const draft = OccurrenceFormDraft(
      audioPath: 'media/a.m4a',
      audioDurationSec: 5,
    );
    final cleared = draft.copyWith(clearAudioPath: true, clearAudioDurationSec: true);
    expect(cleared.audioPath, isNull);
    expect(cleared.audioDurationSec, isNull);
    expect(cleared.isEffectivelyEmpty, isTrue);
  });
}
