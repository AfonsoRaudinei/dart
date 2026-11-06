import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/modules/consultoria/occurrences/domain/occurrence.dart';
import 'package:soloforte_app/modules/consultoria/occurrences/presentation/widgets/occurrence_audio_field.dart';
import 'package:soloforte_app/modules/consultoria/occurrences/presentation/widgets/occurrence_detail_audio_section.dart';

Occurrence _occurrenceWithAudio() => Occurrence(
  id: 'id-1',
  type: 'Média',
  description: 'Teste',
  createdAt: DateTime.utc(2026, 11, 5),
  audioPath: 'media/audio_outro_aparelho.m4a',
  audioDurationSec: 12,
);

Widget _host(Widget child) => MaterialApp(
  home: Scaffold(body: SingleChildScrollView(child: child)),
);

void main() {
  group('OccurrenceDetailAudioSection', () {
    testWidgets('sem arquivo local mostra aviso e oculta Play', (tester) async {
      var calls = 0;
      await tester.pumpWidget(
        _host(
          OccurrenceDetailAudioSection(
            occurrence: _occurrenceWithAudio(),
            cardBg: Colors.black,
            cardRadius: 12,
            isIos: false,
            isDark: true,
            resolvePath: (_) async {
              calls++;
              return null;
            },
          ),
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(
        find.text(OccurrenceDetailAudioSection.missingLocalFileLabel),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.play_arrow_rounded), findsNothing);
      expect(calls, 1);
    });

    testWidgets('download grava efeito e o segundo resolve mostra Play', (
      tester,
    ) async {
      var calls = 0;
      var downloaded = false;
      await tester.pumpWidget(
        _host(
          OccurrenceDetailAudioSection(
            occurrence: _occurrenceWithAudio(),
            cardBg: Colors.black,
            cardRadius: 12,
            isIos: false,
            isDark: true,
            resolvePath: (_) async {
              calls++;
              if (!downloaded) return null;
              return '/docs/media/audio_outro_aparelho.m4a';
            },
            downloadMissing: (_) async {
              downloaded = true;
              return true;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);
      expect(
        find.text(OccurrenceDetailAudioSection.missingLocalFileLabel),
        findsNothing,
      );
      expect(downloaded, isTrue);
      expect(calls, 2);
    });

    testWidgets('download que falha mantém aviso sem Play e um resolve', (
      tester,
    ) async {
      var calls = 0;
      await tester.pumpWidget(
        _host(
          OccurrenceDetailAudioSection(
            occurrence: _occurrenceWithAudio(),
            cardBg: Colors.black,
            cardRadius: 12,
            isIos: false,
            isDark: true,
            resolvePath: (_) async {
              calls++;
              return null;
            },
            downloadMissing: (_) async => false,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text(OccurrenceDetailAudioSection.missingLocalFileLabel),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.play_arrow_rounded), findsNothing);
      expect(calls, 1);
    });

    testWidgets('com arquivo local mostra Play sem aviso', (tester) async {
      await tester.pumpWidget(
        _host(
          OccurrenceDetailAudioSection(
            occurrence: _occurrenceWithAudio(),
            cardBg: Colors.black,
            cardRadius: 12,
            isIos: false,
            isDark: true,
            resolvePath: (_) async => '/docs/media/audio_outro_aparelho.m4a',
          ),
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);
      expect(
        find.text(OccurrenceDetailAudioSection.missingLocalFileLabel),
        findsNothing,
      );
    });
  });

  group('OccurrenceAudioField', () {
    testWidgets('sem arquivo local mostra aviso e oculta Ouvir', (
      tester,
    ) async {
      var calls = 0;
      await tester.pumpWidget(
        _host(
          OccurrenceAudioField(
            storedPath: 'media/audio_outro_aparelho.m4a',
            durationSec: 12,
            onChanged: (_) {},
            resolvePath: (_) async {
              calls++;
              return null;
            },
          ),
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(
        find.text(OccurrenceDetailAudioSection.missingLocalFileLabel),
        findsOneWidget,
      );
      expect(find.text('Ouvir'), findsNothing);
      expect(find.byTooltip('Excluir áudio'), findsOneWidget);
      expect(calls, 1);
    });

    testWidgets('com arquivo local mostra Ouvir', (tester) async {
      await tester.pumpWidget(
        _host(
          OccurrenceAudioField(
            storedPath: 'media/audio_local.m4a',
            durationSec: 8,
            onChanged: (_) {},
            resolvePath: (_) async => '/docs/media/audio_local.m4a',
          ),
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(find.text('Ouvir'), findsOneWidget);
      expect(find.text('Áudio gravado · 8s'), findsOneWidget);
    });
  });
}
