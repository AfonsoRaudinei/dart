import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:soloforte_app/core/infra/preferences_service.dart';
import 'package:soloforte_app/modules/consultoria/occurrences/domain/occurrence.dart';
import 'package:soloforte_app/modules/consultoria/occurrences/presentation/controllers/occurrence_controller.dart';
import 'package:soloforte_app/ui/components/map/widgets/isolated_marker_layers.dart';

void main() {
  testWidgets(
    'IsolatedOccurrenceMarkersLayer não renderiza MarkerLayer quando showMarkers está desativado',
    (tester) async {
      final preferencesService = await _buildPreferencesService(
        showMarkers: false,
      );
      final occurrence = _buildOccurrence();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            preferencesServiceProvider.overrideWithValue(preferencesService),
            occurrencesListProvider.overrideWith((ref) async => [occurrence]),
          ],
          child: MaterialApp(
            home: FlutterMap(
              options: const MapOptions(
                initialCenter: LatLng(-10.25, -48.32),
                initialZoom: 14,
              ),
              children: [
                IsolatedOccurrenceMarkersLayer(onOccurrenceTap: (_) {}),
              ],
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(MarkerLayer), findsNothing);
    },
  );

  testWidgets(
    'IsolatedOccurrenceMarkersLayer renderiza markers e encaminha tap da ocorrência',
    (tester) async {
      final preferencesService = await _buildPreferencesService(
        showMarkers: true,
      );
      final occurrence = _buildOccurrence();
      Occurrence? tappedOccurrence;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            preferencesServiceProvider.overrideWithValue(preferencesService),
            occurrencesListProvider.overrideWith((ref) async => [occurrence]),
          ],
          child: MaterialApp(
            home: FlutterMap(
              options: const MapOptions(
                initialCenter: LatLng(-10.25, -48.32),
                initialZoom: 14,
              ),
              children: [
                IsolatedOccurrenceMarkersLayer(
                  onOccurrenceTap: (selected) => tappedOccurrence = selected,
                ),
              ],
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(MarkerLayer), findsOneWidget);

      await tester.tap(find.byType(GestureDetector).first);
      await tester.pump();

      expect(tappedOccurrence?.id, occurrence.id);
    },
  );
}

Future<PreferencesService> _buildPreferencesService({
  required bool showMarkers,
}) async {
  SharedPreferences.setMockInitialValues({'map_show_markers_v1': showMarkers});
  return PreferencesService(await SharedPreferences.getInstance());
}

Occurrence _buildOccurrence() {
  return Occurrence(
    id: 'occ-1',
    type: 'Alta',
    description: 'Ocorrência de teste',
    lat: -10.25,
    long: -48.32,
    category: 'doenca',
    createdAt: DateTime.utc(2026, 7, 20),
  );
}
