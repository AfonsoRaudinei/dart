import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/core/html_templates/report_photo_links.dart';
import 'package:soloforte_app/core/html_templates/report_photo_viewer.dart';

const _png1x1 =
    'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII=';

final _photos = [
  for (var i = 0; i < 3; i++)
    ReportPhoto(index: i, src: _png1x1, caption: 'Foto ${i + 1}'),
];

Future<void> _openViewer(WidgetTester tester, {int initialIndex = 0}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: TextButton(
              onPressed: () => ReportPhotoViewer.open(
                context,
                photos: _photos,
                initialIndex: initialIndex,
              ),
              child: const Text('Relatório'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Relatório'));
  await tester.pumpAndSettle();
}

Finder get _counter =>
    find.byKey(const ValueKey('report-photo-viewer-counter'));

String _counterText(WidgetTester tester) =>
    tester.widget<Text>(_counter).data ?? '';

void main() {
  testWidgets('abre na foto tocada e mostra contador N de M', (tester) async {
    await _openViewer(tester, initialIndex: 1);

    expect(find.byType(ReportPhotoViewer), findsOneWidget);
    expect(_counterText(tester), '2 de 3');
    expect(find.text('Foto 2'), findsOneWidget);
    expect(find.byType(InteractiveViewer), findsWidgets);
    expect(find.byType(AppBar), findsNothing);
  });

  testWidgets('swipe troca de foto e atualiza o contador', (tester) async {
    await _openViewer(tester);
    expect(_counterText(tester), '1 de 3');

    await tester.fling(find.byType(PageView), const Offset(-400, 0), 1500);
    await tester.pumpAndSettle();
    expect(_counterText(tester), '2 de 3');
    expect(find.text('Foto 2'), findsOneWidget);

    await tester.fling(find.byType(PageView), const Offset(-400, 0), 1500);
    await tester.pumpAndSettle();
    expect(_counterText(tester), '3 de 3');

    await tester.fling(find.byType(PageView), const Offset(400, 0), 1500);
    await tester.pumpAndSettle();
    expect(_counterText(tester), '2 de 3');
  });

  testWidgets('botão fechar volta ao relatório', (tester) async {
    await _openViewer(tester, initialIndex: 2);
    expect(find.byType(ReportPhotoViewer), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('report-photo-viewer-close')));
    await tester.pumpAndSettle();

    expect(find.byType(ReportPhotoViewer), findsNothing);
    expect(find.text('Relatório'), findsOneWidget);
  });

  testWidgets('duplo toque alterna zoom e trava o swipe', (tester) async {
    await _openViewer(tester);

    final viewer = find.byType(InteractiveViewer).first;
    await tester.tap(viewer);
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(viewer);
    await tester.pumpAndSettle();

    final controller = tester
        .widget<InteractiveViewer>(viewer)
        .transformationController!;
    expect(controller.value.getMaxScaleOnAxis(), greaterThan(1));
    expect(
      tester.widget<PageView>(find.byType(PageView)).physics,
      isA<NeverScrollableScrollPhysics>(),
    );

    await tester.tap(viewer);
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(viewer);
    await tester.pumpAndSettle();
    expect(controller.value.getMaxScaleOnAxis(), closeTo(1, 0.01));
  });

  testWidgets('foto inválida mostra texto neutro', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: ReportPhotoViewer(
          photos: [ReportPhoto(index: 0, src: 'data:image/png;base64,@@')],
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Foto indisponível'), findsOneWidget);
    expect(_counterText(tester), '1 de 1');
  });
}
