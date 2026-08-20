import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:soloforte_app/core/infra/preferences_service.dart';
import 'package:soloforte_app/ui/screens/map/utils/map_long_press_prefs.dart';

void main() {
  late PreferencesService prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = PreferencesService(await SharedPreferences.getInstance());
  });

  group('shouldShowMapLongPressHint', () {
    test('returns true when never used and no sessions recorded', () {
      expect(shouldShowMapLongPressHint(prefs), isTrue);
    });

    test('returns false after markMapLongPressUsed', () async {
      await markMapLongPressUsed(prefs);
      expect(shouldShowMapLongPressHint(prefs), isFalse);
    });

    test('returns false after max hint sessions without using gesture', () async {
      for (var i = 0; i < kMapLongPressHintMaxSessions; i++) {
        await recordMapLongPressHintSession(prefs);
      }
      expect(mapLongPressHintSessionCount(prefs), kMapLongPressHintMaxSessions);
      expect(shouldShowMapLongPressHint(prefs), isFalse);
    });

    test('returns true when sessions below max and gesture unused', () async {
      await recordMapLongPressHintSession(prefs);
      expect(mapLongPressHintSessionCount(prefs), 1);
      expect(shouldShowMapLongPressHint(prefs), isTrue);
    });

    test('hint copy references free map area', () {
      expect(kMapLongPressHintMessage, contains('área livre'));
      expect(kMapLongPressOccupiedFeedbackMessage, contains('área livre'));
    });
  });

  group('recordMapLongPressHintSession', () {
    test('does not exceed max sessions', () async {
      for (var i = 0; i < kMapLongPressHintMaxSessions + 2; i++) {
        await recordMapLongPressHintSession(prefs);
      }
      expect(mapLongPressHintSessionCount(prefs), kMapLongPressHintMaxSessions);
    });
  });
}
