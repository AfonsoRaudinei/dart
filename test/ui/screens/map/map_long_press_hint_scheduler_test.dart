import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:soloforte_app/core/infra/preferences_service.dart';
import 'package:soloforte_app/ui/components/map/map_sheet_state.dart';
import 'package:soloforte_app/ui/screens/map/providers/map_armed_mode_provider.dart';
import 'package:soloforte_app/ui/screens/map/utils/map_long_press_hint_scheduler.dart';

void main() {
  late PreferencesService prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = PreferencesService(await SharedPreferences.getInstance());
  });

  group('mapLongPressHintEnvironmentReady', () {
    test('false when map not ready', () {
      expect(
        mapLongPressHintEnvironmentReady(
          prefs: prefs,
          mapReady: false,
          armedMode: ArmedMode.none,
          sheetState: null,
          isModalOpen: false,
        ),
        isFalse,
      );
    });

    test('true when map ready and UI idle', () {
      expect(
        mapLongPressHintEnvironmentReady(
          prefs: prefs,
          mapReady: true,
          armedMode: ArmedMode.none,
          sheetState: null,
          isModalOpen: false,
        ),
        isTrue,
      );
    });

    test('false when modal or sheet open', () {
      expect(
        mapLongPressHintEnvironmentReady(
          prefs: prefs,
          mapReady: true,
          armedMode: ArmedMode.none,
          sheetState: null,
          isModalOpen: true,
        ),
        isFalse,
      );
      expect(
        mapLongPressHintEnvironmentReady(
          prefs: prefs,
          mapReady: true,
          armedMode: ArmedMode.none,
          sheetState: const MapSheetState(type: MapSheetType.occurrences),
          isModalOpen: false,
        ),
        isFalse,
      );
    });
  });
}
