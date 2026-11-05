import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:soloforte_app/modules/consultoria/occurrences/presentation/widgets/occurrence_photo_gallery.dart';

class _FakePathProvider extends Fake
    with MockPlatformInterfaceMixin
    implements PathProviderPlatform {
  _FakePathProvider(this.documentsPath);

  final String documentsPath;

  @override
  Future<String?> getApplicationDocumentsPath() async => documentsPath;
}

/// PNG 1×1 RGB válido — Image.file precisa decodificar, não aceita bytes lixo.
final _kPng1x1 = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==',
);

Future<void> _setKeyboardView(WidgetTester tester) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1.0;
  tester.view.padding = const FakeViewPadding(bottom: 34);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPadding);
  addTearDown(tester.view.resetViewInsets);
}

Future<void> _pumpUntilFound(
  WidgetTester tester,
  Finder finder, {
  int attempts = 40,
}) async {
  for (var i = 0; i < attempts; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 25)),
    );
    await tester.pump();
    if (finder.evaluate().isNotEmpty) return;
  }
  fail('Não encontrou $finder após resolver o path da foto.');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory docsDir;
  late Directory photoDir;
  late File photoFile;

  setUp(() async {
    docsDir = await Directory.systemTemp.createTemp('occ_caption_docs_');
    photoDir = await Directory.systemTemp.createTemp('occ_caption_photo_');
    PathProviderPlatform.instance = _FakePathProvider(docsDir.path);
    photoFile = File(p.join(photoDir.path, 'leaf.png'));
    await photoFile.writeAsBytes(_kPng1x1);
  });

  tearDown(() async {
    if (await docsDir.exists()) await docsDir.delete(recursive: true);
    if (await photoDir.exists()) await photoDir.delete(recursive: true);
  });

  testWidgets(
    'legenda permanece visível com teclado e Fechar devolve o texto',
    (tester) async {
      await _setKeyboardView(tester);

      int? capturedIndex;
      String? capturedCaption;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OccurrencePhotoGallery(
              paths: [photoFile.path],
              readOnly: false,
              onCaptionChanged: (index, caption) {
                capturedIndex = index;
                capturedCaption = caption;
              },
            ),
          ),
        ),
      );

      await _pumpUntilFound(tester, find.byType(Image));
      await tester.tap(find.byType(Image));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      final captionField = find.byKey(
        const Key('occurrence_photo_caption_field'),
      );
      expect(captionField, findsOneWidget);

      await tester.tap(captionField);
      await tester.pump();

      tester.view.viewInsets = const FakeViewPadding(bottom: 300);
      await tester.pump();

      expect(captionField, findsOneWidget);
      final fieldRect = tester.getRect(captionField);
      final viewSize = tester.view.physicalSize / tester.view.devicePixelRatio;
      final visible = Rect.fromLTWH(
        0,
        0,
        viewSize.width,
        viewSize.height - 300,
      );
      expect(fieldRect.intersect(visible), isNot(Rect.zero));

      await tester.enterText(captionField, 'Folha com mancha');
      await tester.pump();

      expect(find.widgetWithText(TextButton, 'Fechar'), findsOneWidget);
      await tester.tap(find.widgetWithText(TextButton, 'Fechar'));
      await tester.pumpAndSettle(
        const Duration(milliseconds: 100),
        EnginePhase.sendSemanticsUpdate,
        const Duration(seconds: 5),
      );

      expect(capturedIndex, 0);
      expect(capturedCaption, 'Folha com mancha');
      expect(captionField, findsNothing);
    },
  );
}
