import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/ui/components/public_map/public_map_tagline_carousel.dart';

void main() {
  testWidgets('carrossel mostra o primeiro headline e faz fade no intervalo', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: PublicMapTaglineCarousel())),
    );
    await tester.pump();

    expect(
      find.text(PublicMapTaglineCarousel.slides.first.headline),
      findsOneWidget,
    );
    expect(find.text('Seu campo, do seu jeito.'), findsOneWidget);

    await tester.pump(
      PublicMapTaglineCarousel.interval + PublicMapTaglineCarousel.fadeDuration,
    );
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Feito por quem entende de lavoura.'), findsOneWidget);
  });

  testWidgets('bloco reserva altura fixa entre slides', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: PublicMapTaglineCarousel())),
    );
    await tester.pump();

    final firstHeight = tester
        .getSize(find.byType(PublicMapTaglineCarousel))
        .height;
    expect(firstHeight, PublicMapTaglineCarousel.blockHeight);

    await tester.pump(
      PublicMapTaglineCarousel.interval + PublicMapTaglineCarousel.fadeDuration,
    );

    expect(
      tester.getSize(find.byType(PublicMapTaglineCarousel)).height,
      PublicMapTaglineCarousel.blockHeight,
    );
  });

  testWidgets('carrossel exibe indicadores de página', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: PublicMapTaglineCarousel())),
    );
    await tester.pump();

    expect(find.byType(AnimatedContainer), findsNWidgets(3));
  });

  testWidgets('reduzir movimento mostra o texto já, sem animar', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: Scaffold(body: PublicMapTaglineCarousel()),
        ),
      ),
    );
    await tester.pump();

    final fade = tester.widgetList<FadeTransition>(find.byType(FadeTransition));
    expect(fade.every((f) => f.opacity.value == 1), isTrue);
  });
}
