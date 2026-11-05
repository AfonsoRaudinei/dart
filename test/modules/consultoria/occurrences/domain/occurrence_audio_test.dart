import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/modules/consultoria/occurrences/domain/occurrence.dart';

void main() {
  test('Occurrence persiste audio_path e audio_duration_sec', () {
    final created = DateTime.utc(2026, 11, 5);
    final o = Occurrence(
      id: 'id-1',
      type: 'Média',
      description: 'Teste',
      createdAt: created,
      audioPath: 'media/audio_test.m4a',
      audioDurationSec: 12,
    );

    final map = o.toMap();
    expect(map['audio_path'], 'media/audio_test.m4a');
    expect(map['audio_duration_sec'], 12);

    final round = Occurrence.fromMap({
      ...map,
      'user_id': 'u1',
    });
    expect(round.audioPath, 'media/audio_test.m4a');
    expect(round.audioDurationSec, 12);
  });

  test('copyWith clearAudioPath remove áudio', () {
    final o = Occurrence(
      id: 'id-1',
      type: 'Média',
      description: 'Teste',
      createdAt: DateTime.utc(2026, 11, 5),
      audioPath: 'media/a.m4a',
      audioDurationSec: 5,
    );
    final cleared = o.copyWith(clearAudioPath: true, clearAudioDurationSec: true);
    expect(cleared.audioPath, isNull);
    expect(cleared.audioDurationSec, isNull);
  });
}
