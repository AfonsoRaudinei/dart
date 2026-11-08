import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/core/state/map_ui_providers.dart';
import 'package:soloforte_app/modules/map/presentation/providers/map_location_mode_provider.dart';
import 'package:soloforte_app/ui/components/map/widgets/map_north_reset_compass.dart';

void main() {
  testWidgets('bússola oculta quando rotação ~0° em modo idle', (tester) async {
    final mapController = MapController();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          mapCameraRotationProvider.overrideWith((ref) => 0),
          mapLocationModeProvider.overrideWith((ref) => MapLocationMode.idle),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                MapNorthResetCompass(mapController: mapController),
              ],
            ),
          ),
        ),
      ),
    );

    expect(find.byKey(const Key('map_north_reset_compass_btn')), findsNothing);
  });

  testWidgets('bússola visível quando rotacionado em idle', (tester) async {
    final mapController = MapController();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          mapCameraRotationProvider.overrideWith((ref) => 35),
          mapLocationModeProvider.overrideWith((ref) => MapLocationMode.idle),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                MapNorthResetCompass(mapController: mapController),
              ],
            ),
          ),
        ),
      ),
    );

    expect(find.byKey(const Key('map_north_reset_compass_btn')), findsOneWidget);
  });

  testWidgets('bússola oculta em modo following', (tester) async {
    final mapController = MapController();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          mapCameraRotationProvider.overrideWith((ref) => 40),
          mapLocationModeProvider.overrideWith(
            (ref) => MapLocationMode.following,
          ),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                MapNorthResetCompass(mapController: mapController),
              ],
            ),
          ),
        ),
      ),
    );

    expect(find.byKey(const Key('map_north_reset_compass_btn')), findsNothing);
  });
}
