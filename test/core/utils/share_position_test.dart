import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/core/utils/share_position.dart';

void main() {
  testWidgets('sharePositionOriginFor retorna retangulo nao zero', (
    tester,
  ) async {
    late Rect origin;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            origin = sharePositionOriginFor(context);
            return const SizedBox(width: 120, height: 48);
          },
        ),
      ),
    );

    expect(origin.width, greaterThan(0));
    expect(origin.height, greaterThan(0));
  });
}
