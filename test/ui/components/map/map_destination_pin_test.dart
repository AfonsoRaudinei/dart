import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/core/design/sf_icons.dart';
import 'package:soloforte_app/ui/components/map/widgets/map_destination_pin.dart';

void main() {
  testWidgets('MapDestinationPin usa pin SF e não Icons.place', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: Center(child: MapDestinationPin())),
      ),
    );

    expect(find.byIcon(SFIcons.pinFill), findsOneWidget);
    expect(find.byIcon(Icons.place), findsNothing);
  });
}
