import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/ui/components/public_map/public_map_tagline_carousel.dart';

void main() {
  testWidgets('carrossel mostra o primeiro headline e faz fade no intervalo',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: PublicMapTaglineCarousel()),
      ),
    );
    await tester.pump();

    expect(
      find.text(PublicMapTaglineCarousel.slides.first.headline),
      findsOneWidget,
    );
    expect(find.text('Simples. Poderoso. Teu.'), findsOneWidget);

    await tester.pump(
      PublicMapTaglineCarousel.interval +
          PublicMapTaglineCarousel.fadeDuration,
    );

    expect(
      find.text('Tradição e tecnologia no mesmo solo.'),
      findsOneWidget,
    );
  });
}
