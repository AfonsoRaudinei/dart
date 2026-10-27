import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:soloforte_app/core/infra/preferences_service.dart';
import 'package:soloforte_app/core/state/map_ui_providers.dart';
import 'package:soloforte_app/ui/components/map/widgets/map_locality_context_chip.dart';

void main() {
  testWidgets('chip visível quando divisas UF ativas', (tester) async {
    SharedPreferences.setMockInitialValues({'map_state_boundaries_v1': true});
    final preferencesService = PreferencesService(
      await SharedPreferences.getInstance(),
    );

    const center = LatLng(-10.2, -48.3);
    final bounds = LatLngBounds(
      LatLng(center.latitude - 0.01, center.longitude - 0.01),
      LatLng(center.latitude + 0.01, center.longitude + 0.01),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          preferencesServiceProvider.overrideWithValue(preferencesService),
          mapCameraSnapshotProvider.overrideWith(
            (ref) => MapCameraSnapshot(
              center: center,
              zoom: 12,
              visibleBounds: bounds,
            ),
          ),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                MapLocalityContextChip(),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.byKey(const Key('map_locality_context_chip')), findsOneWidget);
  });

  testWidgets('chip oculto quando divisas UF desativadas', (tester) async {
    SharedPreferences.setMockInitialValues({'map_state_boundaries_v1': false});
    final preferencesService = PreferencesService(
      await SharedPreferences.getInstance(),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          preferencesServiceProvider.overrideWithValue(preferencesService),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                MapLocalityContextChip(),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.byKey(const Key('map_locality_context_chip')), findsNothing);
  });
}
